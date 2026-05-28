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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=5000)
