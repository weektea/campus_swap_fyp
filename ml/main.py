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

# Load Pre-trained Model (MobileNetV2)
# We load it globally so it's ready for requests
print("Loading MobileNetV2 model...")
model = MobileNetV2(weights='imagenet')
print("Model loaded.")

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
        
        # Resize to 224x224 for MobileNetV2
        img = img.resize((224, 224))
        
        # Preprocess
        img_array = keras_image.img_to_array(img)
        img_array = np.expand_dims(img_array, axis=0)
        img_array = preprocess_input(img_array)
        
        # Predict
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
            "top_3": [{"label": x[1], "confidence": float(x[2])} for x in decoded]
        }
    except Exception as e:
        print(f"Error processing image: {e}")
        raise HTTPException(status_code=500, detail=str(e))

class PriceRequest(BaseModel):
    category: str
    condition: str

@app.post("/predict-price")
def predict_price(request: PriceRequest):
    # Heuristic Logic (Simulating a regression model)
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
    
    # Add some randomness to simulate AI variance
    variance = np.random.uniform(0.9, 1.1)
    final_price = round(estimated_price * variance, 2)
    
    return {"estimated_price": final_price, "currency": "RM"}


class DescriptionRequest(BaseModel):
    title: str
    category: str
    condition: str

@app.post("/generate-description")
def generate_description(request: DescriptionRequest):
    templates = [
        f"Selling my {request.condition} {request.title}. It is perfect for {request.category} lovers.",
        f"Check out this {request.title}! Condition is {request.condition}. Great deal.",
        f"{request.category} item available: {request.title}. {request.condition} condition. DM for details."
    ]
    # Pick one randomly
    import random
    selected = random.choice(templates)
    return {"description": selected}


@app.post("/recommend", response_model=PredictionResponse)
def get_recommendations(request: RecommendationRequest):
    # Mock Logic for now
    return {
        "product_ids": ["prod_1", "prod_2", "prod_5"],
        "confidence": 0.85
    }

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
