import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image
import os

import requests

FLAT_CLASSES = []

def fetch_categories_from_api():
    global FLAT_CLASSES
    try:
        print("Fetching categories from Node.js API...")
        response = requests.get('http://localhost:3000/api/categories', timeout=5)
        if response.status_code == 200:
            categories = response.json()
            classes = []
            for cat in categories:
                cat_name = cat.get('name')
                for sub in cat.get('subcategories', []):
                    classes.append(f"{cat_name}___{sub.get('name')}")
            if classes:
                FLAT_CLASSES = sorted(classes)
                print(f"Dynamically loaded {len(FLAT_CLASSES)} categories from DB.")
                return
    except Exception as e:
        print(f"Warning: Could not fetch categories from API ({e}).")
    
    print("Attempting to load categories from dataset folder...")
    try:
        current_dir = os.path.dirname(os.path.abspath(__file__))
        dataset_root = os.path.join(current_dir, "dataset", "user_corrections")
        if os.path.exists(dataset_root):
            classes = [d for d in os.listdir(dataset_root) if os.path.isdir(os.path.join(dataset_root, d)) and "___" in d]
            if classes:
                FLAT_CLASSES = sorted(classes)
                print(f"Loaded {len(FLAT_CLASSES)} categories from dataset directory.")
                return
    except Exception as ex:
        print(f"Warning: Could not scan dataset folders ({ex}).")
        
    print("Using fallback category list.")
    FLAT_CLASSES = ["Others___Miscellaneous"]

fetch_categories_from_api()

# Use absolute path to ensure custom_model.pth is loaded regardless of working directory
MODEL_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "custom_model.pth")

# Image transformations
data_transforms = transforms.Compose([
    transforms.Resize((224, 224)),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
])

device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")

def get_model():
    # Load MobileNetV2
    model = models.mobilenet_v2(weights=models.MobileNet_V2_Weights.IMAGENET1K_V1)
    
    # Freeze early layers for faster training (Continuous Learning)
    for param in model.features[:-4].parameters():
        param.requires_grad = False
        
    # Replace the classifier head
    num_ftrs = model.classifier[1].in_features
    model.classifier[1] = nn.Linear(num_ftrs, len(FLAT_CLASSES))
    
    # Load custom trained weights if they exist
    if os.path.exists(MODEL_PATH):
        try:
            state_dict = torch.load(MODEL_PATH, map_location=device)
            # Check if the number of classes matches the saved model's output layer
            if 'classifier.1.weight' in state_dict and state_dict['classifier.1.weight'].shape[0] != len(FLAT_CLASSES):
                print(f"Model output size mismatch. Expected {len(FLAT_CLASSES)} classes but weights have {state_dict['classifier.1.weight'].shape[0]}. Reinitializing classifier head.")
                # Load only matching layers
                model_dict = model.state_dict()
                state_dict = {k: v for k, v in state_dict.items() if k in model_dict and v.shape == model_dict[k].shape}
                model_dict.update(state_dict)
                model.load_state_dict(model_dict)
            else:
                model.load_state_dict(state_dict)
                print(f"Loaded existing model from {MODEL_PATH}")
        except Exception as e:
            print(f"Error loading model: {e}")
            
    return model.to(device)

model = get_model()
model.eval()

def predict_image(image_path: str):
    try:
        image = Image.open(image_path).convert('RGB')
        img_tensor = data_transforms(image).unsqueeze(0).to(device)
        
        with torch.no_grad():
            outputs = model(img_tensor)
            probabilities = torch.nn.functional.softmax(outputs[0], dim=0)
            
            # Get Top 1 Prediction
            confidence, predicted = torch.max(probabilities, 0)
            
            flat_class = FLAT_CLASSES[predicted.item()]
            category, sub_category = flat_class.split('___')
            
            return {
                "category": category,
                "sub_category": sub_category,
                "confidence": confidence.item()
            }
    except Exception as e:
        print(f"Prediction error: {e}")
        return {"category": "Others", "sub_category": "Others", "confidence": 0.0}

def fine_tune_model(dataset_dir: str):
    from torch.utils.data import Dataset, DataLoader
    import torch.optim as optim
    from PIL import Image
    import glob
    
    print(f"Starting Fine-Tuning on {dataset_dir}...")
    
    class CustomImageDataset(Dataset):
        def __init__(self, root_dir, transform=None):
            self.root_dir = root_dir
            self.transform = transform
            self.image_paths = []
            self.labels = []
            
            for idx, flat_class in enumerate(FLAT_CLASSES):
                cat_dir = os.path.join(root_dir, flat_class)
                if os.path.exists(cat_dir):
                    for ext in ('*.jpg', '*.jpeg', '*.png', '*.webp'):
                        for file_path in glob.glob(os.path.join(cat_dir, ext)):
                            self.image_paths.append(file_path)
                            self.labels.append(idx)
                            
        def __len__(self):
            return len(self.image_paths)
            
        def __getitem__(self, idx):
            img_path = self.image_paths[idx]
            image = Image.open(img_path).convert('RGB')
            if self.transform:
                image = self.transform(image)
            label = self.labels[idx]
            return image, label

    try:
        # Load Dataset
        dataset = CustomImageDataset(dataset_dir, transform=data_transforms)
        
        if len(dataset) == 0:
            print("No images found for training.")
            return False
            
        print(f"Found {len(dataset)} images for training.")
        
        dataloader = DataLoader(dataset, batch_size=16, shuffle=True)
        
        criterion = nn.CrossEntropyLoss()
        # Only optimize the classifier and last few feature layers
        optimizer = optim.Adam(filter(lambda p: p.requires_grad, model.parameters()), lr=0.001)
        
        model.train()
        
        epochs = 3 # Small number of epochs for quick continuous learning
        for epoch in range(epochs):
            running_loss = 0.0
            for inputs, labels in dataloader:
                inputs = inputs.to(device)
                labels = labels.to(device)
                
                optimizer.zero_grad()
                
                outputs = model(inputs)
                loss = criterion(outputs, labels)
                loss.backward()
                optimizer.step()
                
                running_loss += loss.item() * inputs.size(0)
                
            epoch_loss = running_loss / len(dataset)
            print(f"Epoch {epoch+1}/{epochs} Loss: {epoch_loss:.4f}")
            
        # Save the fine-tuned model
        torch.save(model.state_dict(), MODEL_PATH)
        print("Model fine-tuning complete and saved!")
        
        # Switch back to eval mode
        model.eval()

        # Evaluate model to generate True MLOps metrics
        print("Evaluating model to generate True MLOps metrics...")
        import time
        from sklearn.metrics import accuracy_score, precision_score, recall_score
        import json
        from datetime import datetime

        all_preds = []
        all_labels = []
        start_time = time.time()
        
        with torch.no_grad():
            for inputs, labels in dataloader:
                inputs = inputs.to(device)
                outputs = model(inputs)
                _, preds = torch.max(outputs, 1)
                all_preds.extend(preds.cpu().numpy())
                all_labels.extend(labels.numpy())
                
        inference_time_ms = int(((time.time() - start_time) / len(dataset)) * 1000)
        
        acc = accuracy_score(all_labels, all_preds) * 100
        prec = precision_score(all_labels, all_preds, average='weighted', zero_division=0) * 100
        rec = recall_score(all_labels, all_preds, average='weighted', zero_division=0) * 100
        
        metrics_file = os.path.join(dataset_dir, "metrics_history.json")
        history = []
        if os.path.exists(metrics_file):
            try:
                with open(metrics_file, 'r') as f:
                    history = json.load(f)
            except:
                pass
                
        version_num = len(history) + 1
        new_metric = {
            "version": f"v1.0.{version_num}",
            "accuracy": f"{round(acc, 1)}%",
            "precision": f"{round(prec, 1)}%",
            "recall": f"{round(rec, 1)}%",
            "latency": f"{inference_time_ms}ms",
            "dataset_size": len(dataset),
            "classes": f"{len(FLAT_CLASSES)} Sub-Categories"
        }
        history.append(new_metric)
        
        with open(metrics_file, 'w') as f:
            json.dump(history, f, indent=4)
        
        print(f"Metrics saved: {new_metric}")

        return True
    except Exception as e:
        print(f"Fine-tuning error: {e}")
        return False
