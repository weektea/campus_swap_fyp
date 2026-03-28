import io
import numpy as np
import tensorflow as tf
from tensorflow.keras.applications.mobilenet_v2 import MobileNetV2, preprocess_input, decode_predictions
from tensorflow.keras.preprocessing import image as keras_image
from PIL import Image
from fastapi import FastAPI, UploadFile, File, HTTPException
from pydantic import BaseModel
from typing import List
import uvicorn

app = FastAPI(title="Campus Swap ML Service", version="1.0.0")

# Load Pre-trained Model (MobileNetV2) fallback and Custom Model
import os
print("Loading Models...")
custom_model_path = r"c:\Users\ASUS\StudioProjects\campus_swap\ml\campus_swap_model.keras"
classes_path = r"c:\Users\ASUS\StudioProjects\campus_swap\ml\class_names.txt"

custom_model = None
custom_classes = []

if os.path.exists(custom_model_path) and os.path.exists(classes_path):
    print("Loading Custom Fine-Tuned Model...")
    custom_model = tf.keras.models.load_model(custom_model_path)
    with open(classes_path, "r") as f:
        custom_classes = [line.strip() for line in f.readlines()]
else:
    print("Custom model not found. Backing up to generic MobileNetV2.")

print("Loading Generic MobileNetV2 model...")
model = MobileNetV2(weights='imagenet')
print("Models loaded.")

price_model_path = r"c:\Users\ASUS\StudioProjects\campus_swap\ml\price_model.keras"
price_vocab_path = r"c:\Users\ASUS\StudioProjects\campus_swap\ml\price_vocab.json"
custom_price_model = None
price_vocab = []

if os.path.exists(price_model_path) and os.path.exists(price_vocab_path):
    print("Loading Custom Price Prediction Model...")
    custom_price_model = tf.keras.models.load_model(price_model_path)
    import json
    with open(price_vocab_path, "r") as f:
        price_vocab = json.load(f)

class RecommendationRequest(BaseModel):
    user_id: str
    recent_interactions: List[str]

class PredictionResponse(BaseModel):
    product_ids: List[str]
    confidence: float

@app.get("/")
def read_root():
    return {"message": "Campus Swap ML Service is running"}

def map_imagenet_to_category(label: str) -> str:
    """
    Maps ImageNet labels to Campus Swap categories.
    This is a naive mapping for demonstration.
    """
    label = label.lower()
    if any(x in label for x in ['phone', 'laptop', 'computer', 'screen', 'keyboard', 'mouse', 'calculator']):
        return 'Electronics'
    if any(x in label for x in ['book', 'paper', 'notebook']):
        return 'Books'
    if any(x in label for x in ['chair', 'table', 'desk', 'lamp', 'sofa']):
        return 'Furniture'
    if any(x in label for x in ['shirt', 'jean', 'shoe', 'dress', 'hat']):
        return 'Fashion'
    if any(x in label for x in ['ball', 'racket', 'bike', 'helmet']):
        return 'Sports'
    return 'Others'

@app.post("/classify-image")
async def classify_image(file: UploadFile = File(...)):
    try:
        # Read image
        contents = await file.read()
        img = Image.open(io.BytesIO(contents)).convert('RGB')
        
        # Resize to 224x224 for models
        img = img.resize((224, 224))
        
        # Preprocess
        img_array = keras_image.img_to_array(img)
        img_array = np.expand_dims(img_array, axis=0)
        img_array = preprocess_input(img_array)
        
        if custom_model is not None:
            # Predict using Custom Model
            predictions = custom_model.predict(img_array)[0]
            
            # Get top 3
            top_indices = predictions.argsort()[-3:][::-1]
            top_prediction_idx = top_indices[0]
            
            category = custom_classes[top_prediction_idx]
            confidence = float(predictions[top_prediction_idx])
            
            return {
                "filename": file.filename,
                "raw_label": category,
                "category": category,
                "confidence": confidence,
                "top_3": [{"label": custom_classes[idx], "confidence": float(predictions[idx])} for idx in top_indices],
                "model_used": "Custom_FineTuned_MobileNetV2"
            }
        else:
            # Predict using generic model
            predictions = model.predict(img_array)
            decoded = decode_predictions(predictions, top=3)[0]
            
            # Get top prediction
            top_prediction = decoded[0]
            label = top_prediction[1]
            confidence = float(top_prediction[2])
            
            # Map to our categories
            category = map_imagenet_to_category(label)
            
            return {
                "filename": file.filename,
                "raw_label": label,
                "category": category,
                "confidence": confidence,
                "top_3": [{"label": x[1], "confidence": float(x[2])} for x in decoded],
                "model_used": "Generic_MobileNetV2_with_Mapping"
            }
    except Exception as e:
        print(f"Error processing image: {e}")
        raise HTTPException(status_code=500, detail=str(e))

class PriceRequest(BaseModel):
    category: str
    condition: str

@app.post("/predict-price")
def predict_price(request: PriceRequest):
    if custom_price_model is not None and len(price_vocab) > 0:
        cat = request.category.strip().lower()
        if cat == 'books & stationery' or 'books' in cat:
            cat = 'books'
        
        # Map string conditions to out 1-10 numerical scale
        cond_map = {'New': 10.0, 'Like New': 9.0, 'Good': 8.0, 'Fair': 6.0, 'Poor': 4.0}
        cond_val = cond_map.get(request.condition, 8.0)
        
        vec = [0.0] * len(price_vocab)
        if cat in price_vocab:
            vec[price_vocab.index(cat)] = 1.0
            
        vec.append(cond_val / 10.0)
        X = np.array([vec], dtype=np.float32)
        
        pred = custom_price_model.predict(X, verbose=0)
        final_price = round(float(pred[0][0]), 2)
        if final_price < 0: final_price = 5.0 # Basic minimum floor if prediction fails
        
        # Adding a bit of variance as per real market behaviors
        variance = np.random.uniform(0.95, 1.05)
        final_price = round(final_price * variance, 2)
        
        return {"estimated_price": final_price, "currency": "RM", "model_used": "Custom_NN_Regression"}

    # Heuristic Logic Fallback (Simulating a regression model)
    base_price = 50.0
    
    if request.category == 'Electronics':
        base_price = 300.0
    elif request.category == 'Furniture':
        base_price = 150.0
    elif request.category == 'Books':
        base_price = 35.0
    elif request.category == 'Fashion':
        base_price = 60.0
    elif request.category == 'Sports':
        base_price = 80.0
        
    # Condition Multiplier
    multiplier = 1.0
    if request.condition == 'New': multiplier = 1.2
    elif request.condition == 'Like New': multiplier = 1.0
    elif request.condition == 'Good': multiplier = 0.8
    elif request.condition == 'Fair': multiplier = 0.5
    elif request.condition == 'Poor': multiplier = 0.3
    
    estimated_price = base_price * multiplier
    
    final_price = round(estimated_price * np.random.uniform(0.9, 1.1), 2)
    
    return {"estimated_price": final_price, "currency": "RM", "model_used": "Fallback_Heuristic"}


class DescriptionRequest(BaseModel):
    title: str
    category: str
    condition: str
    type: str = 'Sale'

@app.post("/generate-description")
def generate_description(request: DescriptionRequest):
    import random
    
    title = request.title.strip().title()
    cat = request.category.strip().lower()
    cond = request.condition.strip()
    list_type = request.type.strip().lower()

    # 1. Opening
    if list_type == 'rent':
        openings = [
            f"Looking to rent out my {title}.",
            f"Available for rent: a {title} in {cond} condition.",
            f"Renting out my {title} for a reasonable rate.",
            f"Need a {title} but don't want to buy? Rent mine!"
        ]
    else:
        openings = [
            f"Looking to let go of this {title}.",
            f"Selling my {title}.",
            f"Available for grab: a {title} in {cond} condition.",
            f"Time to find a new home for this {title}."
        ]
    desc = random.choice(openings) + " "

    # 2. Condition specifics
    if cond == 'New':
        desc += "It's completely brand new and has never been used. "
    elif cond == 'Like New':
        desc += "Barely used, looks and functions just like new. "
    elif cond == 'Good':
        desc += "Has been used carefully. Still in great working condition. "
    elif cond == 'Fair':
        desc += "Shows noticeable signs of wear and tear, but still gets the job done. "
    elif cond == 'Poor':
        desc += "Definitely well-loved with heavy wear. Priced accordingly to clear it out. "
    else:
        desc += f"Condition is {cond}. "

    # 3. Item specifics based on Title / Category keywords
    title_lower = title.lower()
    
    # Kitchen / Cooking / Small Appliances
    if any(k in title_lower for k in ['fridge', 'microwave', 'toaster', 'dispenser', 'fryer', 'stove', 'kettle', 'pot', 'pan', 'jug', 'cup', 'plate', 'bowl', 'mug', 'oven']):
        desc += "Perfect appliance or tool to make your dorm / rental house life much more convenient! Works smoothly. "
    # Dorm Decor / Storage / Basic Furniture
    elif any(k in title_lower for k in ['desk', 'chair', 'table', 'mattress', 'bed', 'mirror', 'wardrobe', 'drawer', 'hanger', 'rack', 'box', 'bucket', 'sofa', 'stool', 'trolley', 'brush']):
        desc += "Great addition for your room. Saves you from spending big bucks on a brand-new piece! "
    # Tech / Electronics
    elif any(k in title_lower for k in ['laptop', 'computer', 'monitor', 'keyboard', 'mouse', 'tablet', 'calculator', 'earphone', 'cable', 'dryer', 'vacuum', 'ipad']):
        desc += "Tested and fully functional. Save your money and buy second-hand tech for your studies. "
    # Fashion / Wearables / Bags
    elif any(k in title_lower for k in ['shirt', 'jacket', 'sneaker', 'shoe', 'clothing', 'apron', 'glove', 'backpack', 'bag', 'wallet', 'watch']):
        desc += "Looks fantastic in person. Clean, well-maintained and ready to be used. "
    # Sports / Leisure
    elif any(k in title_lower for k in ['racket', 'dumbbell', 'mat', 'bicycle', 'instrument', 'guitar', 'sport']):
        desc += "Great equipment to keep yourself active and entertained during campus life! "
    # Fallbacks 
    elif 'book' in cat or 'stationery' in cat:
        desc += "Pages are intact. Perfect for anyone taking this related course next semester. "

    # 4. Closing / Call to Action
    if list_type == 'rent':
        closings = [
            "Rental duration and price can be discussed. DM me!",
            "Hit me up if you want to rent this!"
        ]
    else:
        closings = [
            "Feel free to DM me if you have any questions!",
            "Price is slightly negotiable for serious buyers. PM me!",
            "First come, first served. Message me for meetup details."
        ]
    desc += random.choice(closings)

    return {"description": desc.strip()}


@app.post("/recommend", response_model=PredictionResponse)
def get_recommendations(request: RecommendationRequest):
    # Mock Logic for now
    return {
        "product_ids": ["prod_1", "prod_2", "prod_5"],
        "confidence": 0.85
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
