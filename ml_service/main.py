from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from typing import List, Dict, Optional
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
from sklearn.neighbors import NearestNeighbors
import numpy as np
import shutil
import os
import uuid
import threading
import time
import math
from model_vision import predict_image, fine_tune_model, FLAT_CLASSES
from nlp_moderator import analyze_review_text

app = FastAPI(title="Campus Swap ML Microservice")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

DATASET_DIR = "dataset/user_corrections"
TEMP_DIR = "temp_uploads"

# Ensure directories exist
os.makedirs(TEMP_DIR, exist_ok=True)
for category in FLAT_CLASSES:
    os.makedirs(os.path.join(DATASET_DIR, category), exist_ok=True)

class PredictResponse(BaseModel):
    """
    Schema for the ML prediction response.
    """
    category: str
    sub_category: str
    confidence: float

class FeedbackResponse(BaseModel):
    """
    Schema for user corrective feedback storage status.
    """
    message: str
    saved_path: str

@app.post("/predict/image", response_model=PredictResponse)
async def predict(file: UploadFile = File(...)):
    """
    Accepts an uploaded marketplace image, processes prediction, and returns category tags.

    Args:
        file (UploadFile): The raw image file to evaluate.

    Returns:
        PredictResponse: Predicted category, sub-category, and confidence metrics.

    Raises:
        HTTPException: 400 error if file extension is not supported (.png, .jpg, .jpeg).
    """
    if not file.filename.lower().endswith(('.png', '.jpg', '.jpeg')):
        raise HTTPException(status_code=400, detail="Invalid file type")
        
    # Save temp file
    file_path = os.path.join(TEMP_DIR, f"{uuid.uuid4()}_{file.filename}")
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    try:
        # Run prediction
        result = predict_image(file_path)
    finally:
        # Clean up
        if os.path.exists(file_path):
            os.remove(file_path)
            
    return result

@app.post("/feedback/image", response_model=FeedbackResponse)
async def feedback(
    file: UploadFile = File(...),
    correct_category: str = Form(...) # Expects "Category___SubCategory"
):
    """
    Saves an uploaded image in a feedback dataset folder to be utilized in shadow training.

    Args:
        file (UploadFile): The raw user feedback image.
        correct_category (str): The actual corrected class in "Category___SubCategory" format.

    Returns:
        FeedbackResponse: Success message and the relative path where image was saved.

    Raises:
        None
    """
    if correct_category not in FLAT_CLASSES:
        # Fallback to Others___Miscellaneous if not found
        correct_category = "Others___Miscellaneous"
        
    # Save the image into the corresponding category folder for future training
    ext = os.path.splitext(file.filename)[1]
    filename = f"{uuid.uuid4()}{ext}"
    target_dir = os.path.join(DATASET_DIR, correct_category)
    
    file_path = os.path.join(target_dir, filename)
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)
        
    return {"message": "Feedback saved for continuous learning", "saved_path": file_path}

@app.on_event("startup")
def startup_event():
    """
    FastAPI startup lifecycle event listener. Triggers background model-file hot-swapper thread.
    """
    def watch_model_files():
        """
        Periodically checks the modification time of 'custom_model.pth'.
        Triggers LiveModelContainer reload if model has been rebuilt.
        """
        model_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "custom_model.pth")
        classes_path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "custom_model_classes.json")
        
        last_modified = None
        if os.path.exists(model_path):
            last_modified = os.path.getmtime(model_path)
            
        print(f"[ML-HOT-SWAP] File Watcher thread active. Watching {model_path} for updates.")
        
        while True:
            time.sleep(5)
            try:
                if os.path.exists(model_path) and os.path.exists(classes_path):
                    current_mtime = os.path.getmtime(model_path)
                    if last_modified is None:
                        last_modified = current_mtime
                    elif current_mtime > last_modified:
                        print(f"[ML-HOT-SWAP] New weights modification detected (mtime: {current_mtime} > {last_modified}). Loading new model instance...")
                        # Brief sleep to ensure writing has fully finished
                        time.sleep(1)
                        from model_vision import live_model_container
                        success = live_model_container.load_model(model_path, classes_path)
                        if success:
                            last_modified = current_mtime
            except Exception as e:
                print(f"[ML-HOT-SWAP] Watcher thread error: {e}")
                
    watcher_thread = threading.Thread(target=watch_model_files, daemon=True)
    watcher_thread.start()

@app.post("/train/image-model")
async def train_model():
    """
    Initiates shadow training pipeline in a daemon thread.

    Returns:
        dict: A confirmation message indicating the training has started.

    Raises:
        None
    """
    print("[ML-SHADOW-TRAINING] Shadow Training triggered in background.")
    def train_task():
        """
        Executes categories load and shadow model training in the background.
        """
        from model_vision import fetch_categories_from_api, fine_tune_model, FLAT_CLASSES
        # Fetch dynamic categories from the database API to find updates
        fetch_categories_from_api()
        print(f"[ML-SHADOW-TRAINING] Background worker initiating Shadow Training with {len(FLAT_CLASSES)} subcategories.")
        success = fine_tune_model(DATASET_DIR, FLAT_CLASSES)
        if success:
            print("[ML-SHADOW-TRAINING] Background Shadow Training completed successfully. Hot swap will execute shortly.")
        else:
            print("[ML-SHADOW-TRAINING] Background Shadow Training failed.")
            
    thread = threading.Thread(target=train_task, daemon=True)
    thread.start()
    
    return {"message": "Shadow Training started in the background."}

@app.get("/admin/ml-metrics")
async def get_ml_metrics():
    """
    Retrieves the metrics history of previously executed model training runs and calculated pending samples.

    Returns:
        dict: Object containing history metrics array, pending sample counts, and total sample counts.

    Raises:
        None
    """
    import json
    metrics_file = os.path.join(DATASET_DIR, "metrics_history.json")
    
    # Calculate current pending images
    current_images = 0
    for root, dirs, files in os.walk(DATASET_DIR):
        for f in files:
            if f.lower().endswith(('.png', '.jpg', '.jpeg', '.webp')):
                current_images += 1
                
    history = []
    if os.path.exists(metrics_file):
        try:
            with open(metrics_file, 'r') as f:
                history = json.load(f)
        except Exception as e:
            print("Error reading metrics:", e)
            
    # Default if no history exists yet
    if not history:
        history = [
            {
                "version": "v1.0.0",
                "accuracy": "0.0%",
                "precision": "0.0%",
                "recall": "0.0%",
                "latency": "0ms",
                "dataset_size": 0,
                "classes": "Waiting for training"
            }
        ]
        
    latest = history[-1]
    pending = max(0, current_images - latest.get('dataset_size', 0))
    
    return {
        "history": history,
        "pending_samples": pending,
        "current_total_samples": current_images
    }

# --- FYP AI/ML Pricing & Description Generation Additions ---

class PriceSuggestionRequest(BaseModel):
    """
    Schema for pricing suggestion request body.
    """
    category: str
    condition: str

class PriceSuggestionResponse(BaseModel):
    """
    Schema for suggested price return payload.
    """
    estimated_price: float
    currency: str
    note: str

class DescriptionRequest(BaseModel):
    """
    Schema for description generation request parameters.
    """
    title: str
    category: str
    condition: str
    type: str

class DescriptionResponse(BaseModel):
    """
    Schema for generated description return payload.
    """
    description: str

@app.post("/predict-price", response_model=PriceSuggestionResponse)
async def predict_price(req: PriceSuggestionRequest):
    """
    Suggests a market price estimate based on category and item condition.

    Args:
        req (PriceSuggestionRequest): Request object with category and condition.

    Returns:
        PriceSuggestionResponse: Object containing estimated_price, currency, and note.

    Raises:
        None
    """
    category = req.category
    condition = req.condition
    
    # Base price calculation based on category
    base_prices = {
        "Books & Study Materials": 30.0,
        "Electronics & Gadgets": 200.0,
        "Fashion & Accessories": 45.0,
        "Furniture & Appliances": 90.0,
        "Sports": 80.0,
        "Stationery": 12.0,
        "Others": 20.0
    }
    
    base = base_prices.get(category, 25.0)
    
    # Condition multipliers
    multipliers = {
        "New": 0.95,
        "Like New": 0.85,
        "Good": 0.65,
        "Fair": 0.45,
        "Poor": 0.20
    }
    
    mult = multipliers.get(condition, 0.60)
    estimated = base * mult
    
    # Format estimate to two decimal places
    estimated = round(estimated, 2)
    
    return {
        "estimated_price": estimated,
        "currency": "RM",
        "note": f"Estimated using baseline pricing index for {category} at {condition} condition."
    }

try:
    import psycopg2
    from psycopg2.extras import RealDictCursor
except ImportError:
    psycopg2 = None

class PriceSuggestMLRequest(BaseModel):
    original_price: float
    months_used: float
    condition: str
    subcategory_id: Optional[str] = None
    listing_type: Optional[str] = 'Sale'

class PriceSuggestMLResponse(BaseModel):
    suggested_price: float
    min_price: float
    max_price: float
    suggested_rental_price: Optional[float] = None
    min_rental_price: Optional[float] = None
    max_rental_price: Optional[float] = None
    suggested_deposit: Optional[float] = None
    note: str

def get_db_connection():
    db_name = os.getenv("DB_NAME", "campus_swap")
    db_user = os.getenv("DB_USER", "postgres")
    db_pass = os.getenv("DB_PASS", os.getenv("DB_PASSWORD", "postgres"))
    db_host = os.getenv("DB_HOST", "localhost")
    db_port = os.getenv("DB_PORT", "5432")
    
    # Try reading from parent backend/.env file if not found in env
    if not os.getenv("DB_HOST"):
        backend_env_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), "backend", ".env")
        if os.path.exists(backend_env_path):
            try:
                with open(backend_env_path, "r") as f:
                    for line in f:
                        if "=" in line and not line.startswith("#"):
                            parts = line.strip().split("=", 1)
                            if len(parts) == 2:
                                k, v = parts
                                k = k.strip()
                                v = v.strip().strip('"').strip("'")
                                if k == "DB_NAME": db_name = v
                                elif k == "DB_USER": db_user = v
                                elif k in ("DB_PASS", "DB_PASSWORD"): db_pass = v
                                elif k == "DB_HOST": db_host = v
                                elif k == "DB_PORT": db_port = v
            except Exception as e:
                print(f"Error parsing backend .env: {e}")
                
    return psycopg2.connect(
        dbname=db_name,
        user=db_user,
        password=db_pass,
        host=db_host,
        port=db_port
    )

@app.post("/api/ml/suggest-price", response_model=PriceSuggestMLResponse)
async def suggest_price(req: PriceSuggestMLRequest):
    original_price = req.original_price
    months_used = req.months_used
    condition = req.condition
    subcategory_id = req.subcategory_id

    # 1. Base Depreciation Formula
    condition_factors = {
        "brand new": 1.0,
        "new": 1.0,
        "like new": 0.85,
        "good": 0.70,
        "fair": 0.50,
        "poor": 0.30
    }
    cond_key = condition.lower().strip()
    factor = condition_factors.get(cond_key, 0.70)
    
    age_decay = min(0.02 * max(0.0, months_used), 0.60)
    decay_factor = 1.0 - age_decay
    depreciation_price = original_price * factor * decay_factor

    # 2. Market Data Correction
    market_prices = []
    if subcategory_id and subcategory_id != 'Others':
        conn = None
        try:
            conn = get_db_connection()
            db_condition = condition
            if cond_key == "brand new":
                db_condition = "New"
            
            with conn.cursor() as cur:
                cur.execute(
                    'SELECT price FROM "Products" WHERE "sub_category_id" = %s AND "status" = \'Available\' AND "condition" = %s',
                    (subcategory_id, db_condition)
                )
                rows = cur.fetchall()
                market_prices = [float(row[0]) for row in rows]
        except Exception as e:
            print(f"Market Correction DB Query error: {e}")
        finally:
            if conn:
                conn.close()

    # Compute Median
    market_median = None
    if market_prices:
        n = len(market_prices)
        s = sorted(market_prices)
        market_median = s[n//2] if n % 2 == 1 else (s[n//2 - 1] + s[n//2]) / 2.0

    # 3. Weighted Average (70% Depreciation Formula + 30% Market Median)
    if market_median is not None:
        suggested = 0.70 * depreciation_price + 0.30 * market_median
        note = f"Suggested price computed via hybrid logic: 70% Depreciation (formula: RM {depreciation_price:.2f}) and 30% Market Correction (median: RM {market_median:.2f} based on {len(market_prices)} active listings)."
    else:
        suggested = depreciation_price
        note = f"Suggested price computed via depreciation formula (RM {depreciation_price:.2f}). No active market data found for subcategory {subcategory_id} with condition {condition}."

    suggested = max(1.0, round(suggested, 2))
    min_price = max(1.0, round(suggested * 0.90, 2))
    max_price = max(1.0, round(suggested * 1.10, 2))

    # Rental & Deposit Calculations (1% - 2.5% daily rental rate, 30% deposit)
    suggested_rental = max(1.0, round(suggested * 0.015, 2))
    min_rental = max(1.0, round(suggested * 0.010, 2))
    max_rental = max(1.0, round(suggested * 0.025, 2))
    suggested_deposit = max(5.0, round(suggested * 0.30, 2))

    return {
        "suggested_price": suggested,
        "min_price": min_price,
        "max_price": max_price,
        "suggested_rental_price": suggested_rental,
        "min_rental_price": min_rental,
        "max_rental_price": max_rental,
        "suggested_deposit": suggested_deposit,
        "note": note
    }

class DescriptionRequest(BaseModel):
    """
    Overriding schema for description generation request parameters, including optional fields.
    """
    title: str
    category: str
    condition: str
    type: str
    price: float = None
    location: str = None

class DescriptionResponse(BaseModel):
    """
    Overriding schema for description generation return payload.
    """
    description: str

TEMPLATES = {
    "Electronics & Gadgets": {
        "Sale": [
            "Letting go of my {item_name}. Condition is {condition}. Used carefully for assignments, selling because I upgraded. Works perfectly, test before you buy!",
            "Selling my {item_name} in {condition} condition. Very well taken care of with no hidden defects. Letting it go for RM{price}. PM to test it out!"
        ],
        "Rent": [
            "Need a {item_name} for a short-term project or event? Rent mine for RM{price}/day! Deposit required (refundable). Perfect working condition.",
            "Rushing a due or hosting an event? Rent my {item_name}! Works smoothly, highly reliable for emergencies. RM{price} per day/week."
        ]
    },
    "Fashion & Accessories": {
        "Sale": [
            "Pre-loved {item_name} looking for a new owner! Condition: {condition}. Worn only a few times. DM if interested!",
            "Clearing out my wardrobe! Selling this {item_name}. Condition is {condition}. Very versatile and letting go at a cheap price."
        ],
        "Rent": [
            "Got an annual dinner or prom? Rent this stunning {item_name} for just RM{price}! Worn once, dry-cleaned. Save money instead of buying new."
        ]
    },
    "Furniture & Appliances": {
        "Sale": [
            "Moving out sale! Selling my {item_name} in {condition} condition. Very sturdy and useful for hostel life. Self-pickup at {location}.",
            "Hostel essential! Letting go of my {item_name} (Condition: {condition}). Works perfectly. Note: Item is bulky, self-pickup required at {location}."
        ],
        "Rent": [
            "Staying for a short sem? Don't buy, just rent my {item_name} for RM{price}/month. Sturdy, clean, and saves you the hassle of moving it out later!"
        ]
    },
    "Books & Study Materials": {
        "Sale": [
            "Used study material: {item_name}. Condition is {condition} (some highlighted notes inside which might help you!). Useful for scoring A.",
            "Must-have {item_name} for your semester! Condition: {condition}. Contains useful senior notes to help you pass with flying colors. Letting go for RM{price}."
        ],
        "Rent": [
            "Need {item_name} for just one assignment or open-book exam? Rent it for RM{price} instead of buying! Please handle with care."
        ]
    },
    "Sports": {
        "Sale": [
            "Selling my {item_name}. Condition is {condition}. Great for weekend workouts or campus activities. PM for more details!"
        ],
        "Rent": [
            "Planning a weekend ride or camping trip? Rent my {item_name}! Well-maintained and ready to use. RM{price} per day, deposit required."
        ]
    },
    "Stationery": {
        "Sale": [
            "Extra {item_name} lying around. Condition: {condition}. Letting go for cheap. Good for everyday use!",
            "Brand new/Barely used {item_name}. Bought extra and clearing it out. Condition: {condition}. Grab it fast for RM{price}!"
        ],
        "Rent": [] # Usually not applicable for rent, kept empty for fallback safety
    },
    "Others": {
        "Sale": [
            "Letting go of {item_name}. Condition: {condition}. Selling it for RM{price}. PM if interested!"
        ],
        "Rent": [
            "Renting out my {item_name} for RM{price}. Condition is {condition}. DM me for availability and details!"
        ]
    }
}

@app.post("/generate-description", response_model=DescriptionResponse)
async def generate_description(req: DescriptionRequest):
    """
    Generates a creative, randomized marketplace description based on item title, category,
    condition, location, price, and listing type (Sale or Rent).

    Args:
        req (DescriptionRequest): Input parameters including title, category, condition, type, price, and location.

    Returns:
        DescriptionResponse: Object containing the formatted, generated description string.

    Raises:
        None
    """
    import random
    title = req.title
    category = req.category
    condition = req.condition
    listing_type = req.type
    
    # 1. Determine type description
    type_str = "for rent" if listing_type.lower() == "rent" else "for sale"
    
    # 2. Determine price dynamically if not provided or 0
    price_val = req.price
    if price_val is None or price_val <= 0:
        base_prices = {
            "Books & Study Materials": 30.0,
            "Electronics & Gadgets": 200.0,
            "Fashion & Accessories": 45.0,
            "Furniture & Appliances": 90.0,
            "Sports": 80.0,
            "Stationery": 12.0,
            "Others": 20.0
        }
        base = base_prices.get(category, 25.0)
        multipliers = {
            "New": 0.95,
            "Like New": 0.85,
            "Good": 0.65,
            "Fair": 0.45,
            "Poor": 0.20
        }
        mult = multipliers.get(condition, 0.60)
        price_val = round(base * mult, 2)
    else:
        price_val = round(price_val, 2)
        
    # 3. Determine location dynamically if not provided
    campus_spots = [
        "Mahallah/Hostel reception desk",
        "Campus Main Library",
        "Student Center foyer",
        "Block A lobby entrance",
        "Central Cafeteria"
    ]
    location_val = req.location or random.choice(campus_spots)
    
    # 4. Condition descriptive text
    condition_descriptions = {
        "New": "brand new, unused, and in its original box/packaging.",
        "Like New": "in pristine condition with no visible marks or cosmetic issues.",
        "Good": "in very good working shape with minor signs of gentle usage.",
        "Fair": "fully functional but shows normal wear and tear.",
        "Poor": "in functional condition but heavily used (priced low accordingly)."
    }
    cond_desc = condition_descriptions.get(condition, "in functional condition.")
    
    # 5. Structure category descriptive highlights
    cat_lower = category.lower()
    if "electronics" in cat_lower:
        highlights_list = [
            "Fully functional, tested, and works perfectly.",
            "Excellent battery health / power efficiency.",
            "Comes with charger or standard accessories if applicable."
        ]
        quick_note = "Great for lectures, study sessions, and daily student assignments."
    elif "books" in cat_lower:
        highlights_list = [
            "Essential resource for students taking relevant courses.",
            "No missing pages; clean copy with minimal highlighting.",
            "Cover and spine are well-preserved."
        ]
        quick_note = "Very helpful for reference, exam prep, and coursework."
    elif "fashion" in cat_lower:
        highlights_list = [
            "Comfortable fit with trendy/casual look.",
            "Thoroughly washed, sanitized, and ready to use/wear.",
            "No noticeable flaws, stains, or tears."
        ]
        quick_note = "Stylish and super comfortable for daily campus wear."
    elif "furniture" in cat_lower:
        highlights_list = [
            "Sturdy build quality, perfect for student dorms.",
            "Clean surfaces, showing only minor signs of usage.",
            "Easy to dismantle and transport around campus."
        ]
        quick_note = "Practical addition to make your hostel or student room cozy."
    else:
        highlights_list = [
            "Highly practical item for daily campus or dorm life.",
            "Fully cleaned and kept in a smoke-free/pet-free environment.",
            "Excellent budget-friendly alternative to buying new."
        ]
        quick_note = "A reliable daily companion in great condition."
        
    highlights_check = "\n".join([f"✓ {h}" for h in highlights_list])
    highlights_dash = "\n".join([f"- {h}" for h in highlights_list])
    highlights_fire = "\n".join([f"🔥 {h}" for h in highlights_list])

    # 6. Define Rich Layout Templates
    detailed_layout = (
        "Hi everyone! I am offering this {item_name} {type_str}.\n\n"
        "Item Details:\n"
        "• Category: {category}\n"
        "• Condition: The item is {cond_desc}\n\n"
        "Key Highlights:\n"
        "{highlights_check}\n\n"
        "Perfect for students looking for a smart, budget-friendly bargain. "
        "Feel free to drop me a message to discuss further or arrange a quick meetup at {location} to inspect the item!"
    )
    
    casual_layout = (
        "Hey fellow students! 👋 Selling/renting out my {item_name} ({type_str}).\n"
        "I don't really use it much anymore, so I figured someone else on campus could make better use of it. "
        "It's {cond_desc} and {quick_note.lower()}\n\n"
        "A few quick details:\n"
        "{highlights_dash}\n\n"
        "Perfect budget option if you want to save some cash. "
        "Just hit me up in the chat if you have any questions or want to meet up near {location} to check it out! 😊"
    )
    
    urgent_layout = (
        "🚨 STUDENT CLEARANCE / MOVING OUT SALE 🚨\n\n"
        "Need to let go of this {item_name} {type_str} as soon as possible! "
        "It is {cond_desc} and in perfect working order. {quick_note}\n\n"
        "Why grab this?\n"
        "{highlights_fire}\n\n"
        "First come, first served! Priced low to sell quickly. "
        "We can meet up directly at {location}. PM me now! ✉️"
    )

    # 7. Compile list of templates (User templates + Rich layouts)
    cat_templates = TEMPLATES.get(category)
    if not cat_templates:
        cat_templates = TEMPLATES["Others"]
        
    type_key = "Rent" if listing_type.lower() == "rent" else "Sale"
    templates_list = list(cat_templates.get(type_key, []))
    
    # Fallbacks if templates list is empty
    if not templates_list:
        templates_list = list(TEMPLATES["Others"].get(type_key, []))
        if not templates_list:
            templates_list = list(cat_templates.get("Sale", []))
            
    # Combine User Custom Templates with Rich Layouts
    templates_list.append(detailed_layout)
    templates_list.append(casual_layout)
    templates_list.append(urgent_layout)
    
    # 8. Randomly select one template
    selected_template = random.choice(templates_list)
    
    # 9. Format dynamically
    desc = selected_template.format(
        item_name=title,
        condition=condition,
        price=price_val,
        location=location_val,
        type_str=type_str,
        category=category,
        cond_desc=cond_desc,
        highlights_check=highlights_check,
        highlights_dash=highlights_dash,
        highlights_fire=highlights_fire,
        quick_note=quick_note
    )
    
    return {"description": desc}

# --- Hybrid Recommendation Engine Models & Endpoint ---

class InteractionItem(BaseModel):
    user_id: str
    product_id: str
    weight: float
    interaction_type: Optional[str] = 'view'
    created_at: Optional[str] = None

class ProductItem(BaseModel):
    id: str
    title: str
    description: str
    category: str
    subcategory: Optional[str] = None
    seller_id: Optional[str] = None
    seller_faculty: Optional[str] = None
    days_since_listed: Optional[float] = 0.0

class HybridRecommendRequest(BaseModel):
    user_id: str
    user_faculty: Optional[str] = None
    interactions: List[InteractionItem]
    products: List[ProductItem]
    followed_seller_ids: Optional[List[str]] = None
    followed_interacted_product_ids: Optional[List[str]] = None
    preference_tags: Optional[List[str]] = None
    primary_intent: Optional[str] = None
    recent_viewed_product_ids: Optional[List[str]] = None

class UserPreferenceSyncRequest(BaseModel):
    user_id: str
    primary_intent: str
    preference_tags: List[str]

user_preferences_cache: Dict[str, dict] = {}

@app.post("/api/user/sync-preferences")
async def sync_user_preferences(req: UserPreferenceSyncRequest):
    """
    Syncs and caches first-time user onboarding explicit preferences for Cold-Start ML vectorization.
    """
    user_preferences_cache[req.user_id] = {
        "primary_intent": req.primary_intent,
        "preference_tags": req.preference_tags,
        "synced_at": time.time()
    }
    return {
        "message": "User onboarding preferences synced successfully",
        "user_id": req.user_id,
        "cached_tags_count": len(req.preference_tags)
    }

class HybridRecommendResponse(BaseModel):
    recommended_product_ids: List[str]

@app.post("/api/recommend/hybrid", response_model=HybridRecommendResponse)
async def get_hybrid_recommendations(req: HybridRecommendRequest):
    """
    Generate recommendations for a user using an Interaction-Aware Hybrid ML approach:
    1. Content-Based Filtering (TF-IDF + Cosine Similarity) for Preference Learning
    2. Collaborative Filtering (KNN with Cosine Metric) for Community Patterns
    3. Contextual Multipliers (Followed Seller, Network Graph, Faculty Homophily, Freshness)
    4. Interaction-Aware Layer (Recent Exposure Decay, Related Subcategory Expansion, Exploration)
    5. Candidate Availability Fallback & Intra-List Diversity Re-Ranking
    """
    user_id = req.user_id
    interactions_data = [i.dict() for i in req.interactions]
    products_data = [p.dict() for p in req.products]
    user_pref_tags = req.preference_tags or []

    # Fallback to cached preferences if not provided in payload
    if not user_pref_tags and user_id in user_preferences_cache:
        user_pref_tags = user_preferences_cache[user_id].get("preference_tags", [])
    
    product_ids = [p['id'] for p in products_data]
    if not product_ids:
        return {"recommended_product_ids": []}
        
    # 1. Content-Based Filtering (TF-IDF + Cosine Similarity)
    documents = []
    for p in products_data:
        title = p.get('title', '') or ''
        desc = p.get('description', '') or ''
        cat = p.get('category', '') or ''
        subcat = p.get('subcategory', '') or ''
        documents.append(f"{title} {desc} {cat} {subcat}".lower())
        
    try:
        vectorizer = TfidfVectorizer(stop_words='english')
        tfidf_matrix = vectorizer.fit_transform(documents)
    except Exception as vec_err:
        print(f"TF-IDF Vectorization warning: {vec_err}. Falling back to default list.")
        return {"recommended_product_ids": product_ids[:10]}
        
    product_id_to_idx = {pid: idx for idx, pid in enumerate(product_ids)}
    
    user_interactions = [i for i in interactions_data if i['user_id'] == user_id]
    
    content_scores = np.zeros(len(products_data))
    user_profile_vec = np.zeros(tfidf_matrix.shape[1])

    # 1a. Incorporate User Interactions into TF-IDF vector (Authoritative Preference Signal)
    if user_interactions:
        for interaction in user_interactions:
            pid = interaction['product_id']
            if pid in product_id_to_idx:
                idx = product_id_to_idx[pid]
                weight = interaction.get('weight', 1.0)
                user_profile_vec += tfidf_matrix[idx].toarray()[0] * weight

    # 1b. Cold Start & Preference Boost: Transform explicit preference tags using TF-IDF and boost vector (weight 5.0 for cold-start, 2.0 when interactions present)
    if user_pref_tags:
        pref_text = " ".join(user_pref_tags).lower()
        try:
            pref_vec = vectorizer.transform([pref_text]).toarray()[0]
            tag_weight = 5.0 if not user_interactions else 2.0
            user_profile_vec += pref_vec * tag_weight
        except Exception as pref_err:
            print(f"Preference vectorization warning: {pref_err}")
            
    if np.any(user_profile_vec):
        user_profile_vec = user_profile_vec.reshape(1, -1)
        content_sims = cosine_similarity(user_profile_vec, tfidf_matrix)[0]
        max_sim = np.max(content_sims)
        if max_sim > 0:
            content_scores = content_sims / max_sim
        else:
            content_scores = content_sims

    # 2. Collaborative Filtering (KNN based on Cosine similarity)
    all_users = list(set([i['user_id'] for i in interactions_data]))
    all_products = list(set([i['product_id'] for i in interactions_data]))
    
    cf_scores = np.zeros(len(products_data))
    if user_id in all_users and len(all_users) > 1 and len(all_products) > 0:
        user_to_row = {uid: idx for idx, uid in enumerate(all_users)}
        prod_to_col = {pid: idx for idx, pid in enumerate(all_products)}
        
        interaction_matrix = np.zeros((len(all_users), len(all_products)))
        for interaction in interactions_data:
            uid = interaction['user_id']
            pid = interaction['product_id']
            weight = interaction.get('weight', 1.0)
            if uid in user_to_row and pid in prod_to_col:
                interaction_matrix[user_to_row[uid], prod_to_col[pid]] += weight
                
        n_neighbors = min(5, len(all_users))
        knn = NearestNeighbors(metric='cosine', algorithm='brute')
        knn.fit(interaction_matrix)
        
        target_user_row = interaction_matrix[user_to_row[user_id]].reshape(1, -1)
        distances, indices = knn.kneighbors(target_user_row, n_neighbors=n_neighbors)
        
        similarities = 1.0 - distances[0]
        neighbor_indices = indices[0]
        
        collaborative_predictions = np.zeros(len(all_products))
        sum_similarities = 0.0
        
        for sim, neighbor_idx in zip(similarities, neighbor_indices):
            neighbor_uid = all_users[neighbor_idx]
            if neighbor_uid == user_id:
                continue
            collaborative_predictions += interaction_matrix[neighbor_idx] * sim
            sum_similarities += sim
            
        if sum_similarities > 0:
            collaborative_predictions /= sum_similarities
            
        product_cf_raw = np.zeros(len(products_data))
        for idx, pid in enumerate(product_ids):
            if pid in prod_to_col:
                product_cf_raw[idx] = collaborative_predictions[prod_to_col[pid]]
                
        max_cf = np.max(product_cf_raw)
        if max_cf > 0:
            cf_scores = product_cf_raw / max_cf
        else:
            cf_scores = product_cf_raw

    # 3. Adaptive Hybrid Base Score Combination
    if 'sum_similarities' in locals() and sum_similarities >= 0.2 and len(all_users) >= 5:
        cb_weight = 0.75
        cf_weight = 0.25
    else:
        cb_weight = 1.00
        cf_weight = 0.00

    base_hybrid_scores = cb_weight * content_scores + cf_weight * cf_scores
    base_relevance_scores = np.copy(base_hybrid_scores)
    
    # 3a. Followed Seller Boost: +50% (1.5x multiplier)
    followed_sellers = set(req.followed_seller_ids or [])
    if followed_sellers:
        for idx, p in enumerate(products_data):
            seller_id = p.get('seller_id')
            if seller_id and seller_id in followed_sellers:
                base_relevance_scores[idx] *= 1.50

    # 3b. Social Collaborative Network Boost: +30% (1.3x multiplier)
    followed_network_pids = set(req.followed_interacted_product_ids or [])
    if followed_network_pids:
        for idx, p in enumerate(products_data):
            pid = p.get('id')
            if pid and pid in followed_network_pids:
                base_relevance_scores[idx] *= 1.30

    # 3c. Campus Context Homophily Boost: +15% (1.15x multiplier)
    user_faculty = (req.user_faculty or '').strip().lower()
    if user_faculty:
        for idx, p in enumerate(products_data):
            seller_faculty = (p.get('seller_faculty') or '').strip().lower()
            if seller_faculty and seller_faculty == user_faculty:
                base_relevance_scores[idx] *= 1.15

    # 3d. Time-Decay Freshness Factor: Exponential decay with max 60-day cap
    freshness_factors = np.ones(len(products_data))
    for idx, p in enumerate(products_data):
        days_listed = min(60.0, max(0.0, float(p.get('days_since_listed') or 0.0)))
        freshness_factors[idx] = math.exp(-0.02 * days_listed)
        base_relevance_scores[idx] *= freshness_factors[idx]

    # ==============================================================================
    # 4. Interaction-Aware Personalization Layer
    # ==============================================================================
    # Configurable Hyperparameters
    RECENT_VIEW_WINDOW = 15
    EXPOSURE_INITIAL_PENALTY = 0.92   # r=0 -> 92% suppression (E=0.08)
    EXPOSURE_DECAY_RATE = 0.15        # r=1 -> ~79% suppression (E=0.21), r=5 -> ~43% suppression (E=0.57), r=10 -> ~20% suppression (E=0.80)
    REPETITION_PENALTY_WEIGHT = 0.20  # +20% suppression per repeat view
    MIN_EXPOSURE_FLOOR = 0.02
    RELATED_SIMILARITY_THRESHOLD = 0.08
    MAX_RELATED_BONUS = 0.15
    EXPLORATION_WEIGHT = 0.05

    # 4a. Identify Interacted & Exposed Items
    user_interacted_pids = [i['product_id'] for i in user_interactions]
    user_interacted_set = set(user_interacted_pids)
    
    # Extract recent views (prefer explicitly passed optimized list, fallback to interaction order)
    if req.recent_viewed_product_ids is not None:
        recent_views = [pid for pid in req.recent_viewed_product_ids if pid]
    else:
        recent_views = [i['product_id'] for i in reversed(user_interactions) if i.get('interaction_type') == 'view']
    
    recent_view_window_list = recent_views[:RECENT_VIEW_WINDOW]
    recent_view_counts: Dict[str, int] = {}
    for pid in recent_views:
        recent_view_counts[pid] = recent_view_counts.get(pid, 0) + 1

    # 4b. Continuous Recency-Based Exposure Factor E(i)
    exposure_factors = np.ones(len(products_data))
    for idx, pid in enumerate(product_ids):
        if pid in recent_view_window_list:
            r = recent_view_window_list.index(pid)
            c = recent_view_counts.get(pid, 1)
            # Recency decay: r=0 -> 90% suppression; r=5 -> ~26% suppression; r=10 -> ~7% suppression
            suppression = EXPOSURE_INITIAL_PENALTY * math.exp(-EXPOSURE_DECAY_RATE * r) * (1.0 + REPETITION_PENALTY_WEIGHT * (c - 1))
            exposure_factors[idx] = max(MIN_EXPOSURE_FLOOR, 1.0 - suppression)

    # 4c. Related Subcategory Semantic Discovery (TF-IDF Cosine Similarity)
    related_bonus = np.zeros(len(products_data))
    interacted_indices = [product_id_to_idx[pid] for pid in user_interacted_pids if pid in product_id_to_idx]
    
    if interacted_indices:
        for idx, p in enumerate(products_data):
            pid = p['id']
            # Only boost items that are NOT the exact recently viewed items
            if pid not in recent_view_window_list[:3]:
                cand_vec = tfidf_matrix[idx]
                max_sim_to_interacted = 0.0
                for int_idx in interacted_indices:
                    sim_val = float(cosine_similarity(tfidf_matrix[int_idx], cand_vec)[0][0])
                    if sim_val > max_sim_to_interacted:
                        max_sim_to_interacted = sim_val
                
                if max_sim_to_interacted >= RELATED_SIMILARITY_THRESHOLD:
                    related_bonus[idx] = min(MAX_RELATED_BONUS, max_sim_to_interacted * 0.40)

    # 4d. Relevance-Gated Controlled Exploration
    exploration_bonus = np.zeros(len(products_data))
    for idx, p in enumerate(products_data):
        pid = p['id']
        if base_hybrid_scores[idx] >= 0.08 and pid not in user_interacted_set:
            exploration_bonus[idx] = EXPLORATION_WEIGHT * base_hybrid_scores[idx] * freshness_factors[idx]

    # 4e. Combine Final Scores: (BaseRelevance * ExposureFactor) + RelatedBonus + ExplorationBonus
    final_scores = (base_relevance_scores * exposure_factors) + related_bonus + exploration_bonus

    # 4f. Candidate Availability Fallback Safeguard
    scored_products = list(zip(product_ids, final_scores))
    scored_products.sort(key=lambda x: x[1], reverse=True)

    # 5. Re-ranking Phase: Intra-List Diversity Filter (Max 4 items per subcategory in Top 10)
    MAX_PER_SUBCATEGORY = 4
    TOP_N_TARGET = 10

    prod_cat_map = {}
    for p in products_data:
        subcat = p.get('subcategory') or p.get('category') or 'general'
        prod_cat_map[p['id']] = subcat.strip().lower()

    selected_ids = []
    deferred_ids = []
    subcat_counts: Dict[str, int] = {}

    for pid, score in scored_products:
        subcat = prod_cat_map.get(pid, 'general')
        count = subcat_counts.get(subcat, 0)
        
        if len(selected_ids) < TOP_N_TARGET:
            if count < MAX_PER_SUBCATEGORY:
                selected_ids.append(pid)
                subcat_counts[subcat] = count + 1
            else:
                # 5th item of same subcategory, defer down to prevent echo chamber
                deferred_ids.append(pid)
        else:
            deferred_ids.append(pid)

    final_recommended_ids = (selected_ids + deferred_ids)[:TOP_N_TARGET]

    # Debug logging for development and verification
    suppressed_count = int(np.sum(exposure_factors < 0.99))
    related_boost_count = int(np.sum(related_bonus > 0.0))
    print(f"[ML Rec] User: {user_id} | Candidates: {len(products_data)} | Recent Views: {len(recent_view_window_list)} | Suppressed: {suppressed_count} | Related Boosted: {related_boost_count}")

    return {"recommended_product_ids": final_recommended_ids}

# ==============================================================================
# Automated NLP Review Moderation Endpoint (Sentiment & Toxicity Filter)
# ==============================================================================

class ReviewAnalysisRequest(BaseModel):
    text: Optional[str] = ""

class ReviewAnalysisResponse(BaseModel):
    is_toxic: bool
    sentiment_score: float
    sentiment_label: str
    compound: float
    flag_reason: Optional[str] = None

@app.post("/nlp/analyze-review", response_model=ReviewAnalysisResponse)
async def analyze_review_endpoint(payload: ReviewAnalysisRequest):
    """
    Evaluates review comment text using VADER Sentiment & Lexical Toxicity Detection.
    Flags malicious reviews, profanity, and severe negative sentiment.
    """
    result = analyze_review_text(payload.text)
    return result

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000)
