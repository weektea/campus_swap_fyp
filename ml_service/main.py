from fastapi import FastAPI, File, UploadFile, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
import shutil
import os
import uuid
import threading
from model_vision import predict_image, fine_tune_model, FLAT_CLASSES

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
    category: str
    sub_category: str
    confidence: float

class FeedbackResponse(BaseModel):
    message: str
    saved_path: str

@app.post("/predict/image", response_model=PredictResponse)
async def predict(file: UploadFile = File(...)):
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

@app.post("/train/image-model")
async def train_model():
    # Run fine-tuning in a background thread to not block the API
    def train_task():
        success = fine_tune_model(DATASET_DIR)
        if success:
            print("Background training completed successfully.")
        else:
            print("Background training failed.")
            
    thread = threading.Thread(target=train_task)
    thread.start()
    
    return {"message": "Model training started in the background."}

@app.get("/admin/ml-metrics")
async def get_ml_metrics():
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
    category: str
    condition: str

class PriceSuggestionResponse(BaseModel):
    estimated_price: float
    currency: str
    note: str

class DescriptionRequest(BaseModel):
    title: str
    category: str
    condition: str
    type: str

class DescriptionResponse(BaseModel):
    description: str

@app.post("/predict-price", response_model=PriceSuggestionResponse)
async def predict_price(req: PriceSuggestionRequest):
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

class DescriptionRequest(BaseModel):
    title: str
    category: str
    condition: str
    type: str
    price: float = None
    location: str = None

class DescriptionResponse(BaseModel):
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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000)
