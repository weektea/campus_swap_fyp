import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image
import os

# Define Sub-Categories mapping
SUB_CATEGORIES = {
    'Books': ['Textbooks', 'Novels', 'Comics', 'Reference', 'Others'],
    'Electronics': ['Laptops', 'Smartphones', 'Accessories', 'Audio', 'Others'],
    'Fashion': ['Clothing', 'Shoes', 'Bags', 'Accessories'],
    'Furniture': ['Chairs', 'Tables', 'Storage', 'Others'],
    'Stationery': ['Writing', 'Paper', 'Art Supplies', 'Others'],
    'Sports': ['Equipment', 'Apparel', 'Bicycles', 'Others'],
    'Others': ['Miscellaneous']
}

# Flatten into a strict list of 27 classes for the CNN to predict directly
FLAT_CLASSES = sorted([f"{cat}___{sub}" for cat, subs in SUB_CATEGORIES.items() for sub in subs])

MODEL_PATH = "custom_model.pth"

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
            model.load_state_dict(torch.load(MODEL_PATH, map_location=device))
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
        return True
    except Exception as e:
        print(f"Fine-tuning error: {e}")
        return False
