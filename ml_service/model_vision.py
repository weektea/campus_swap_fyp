import torch
import torch.nn as nn
from torchvision import models, transforms
from PIL import Image
import os
import requests
import json
import threading

FLAT_CLASSES = []

BACKEND_API_URL = os.getenv('BACKEND_API_URL', 'http://localhost:3000/api')

def fetch_categories_from_api():
    """
    Fetches the hierarchical product categories and subcategories from the backend database API,
    flattens them into a combined format (Category___SubCategory), and updates the global FLAT_CLASSES list.
    If the API is unavailable, it attempts to load categories from the local dataset folder names,
    falling back to a default category if both checks fail.

    Returns:
        None

    Raises:
        None (catches exceptions internally and prints warnings)
    """
    global FLAT_CLASSES
    try:
        print("Fetching categories from Node.js API...")
        response = requests.get(f"{BACKEND_API_URL}/categories", timeout=5)
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

# Populate FLAT_CLASSES initially from DB/files
fetch_categories_from_api()

# Paths
MODEL_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "custom_model.pth")
CLASSES_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "custom_model_classes.json")

# Image transformations for live inference and evaluation
eval_transforms = transforms.Compose([
    transforms.Resize((256, 256)),
    transforms.CenterCrop(224),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
])

# Robust Data Augmentation transforms for shadow training (handles angles, lighting, scaling & background variations)
train_transforms = transforms.Compose([
    transforms.RandomResizedCrop(224, scale=(0.65, 1.0)),
    transforms.RandomHorizontalFlip(p=0.5),
    transforms.RandomRotation(degrees=15),
    transforms.ColorJitter(brightness=0.25, contrast=0.25, saturation=0.2, hue=0.05),
    transforms.ToTensor(),
    transforms.Normalize([0.485, 0.456, 0.406], [0.229, 0.224, 0.225])
])

data_transforms = eval_transforms

device = torch.device("cuda:0" if torch.cuda.is_available() else "cpu")

class LiveModelContainer:
    """
    A thread-safe container that holds the loaded PyTorch model and its class mapping.
    Allows atomic swapping of model instances when a new model has been trained.
    """
    def __init__(self):
        """
        Initializes the LiveModelContainer with empty weights, class map, and an RLock.
        """
        self.model = None
        self.classes = []
        self.lock = threading.RLock() # Reentrant lock for strict safety

    def load_model(self, model_path: str, classes_path: str) -> bool:
        """
        Reconstructs the model architecture, loads weights from the specified path,
        and atomically swaps the active model under a reentrant lock.

        Args:
            model_path (str): The absolute or relative path to the custom PyTorch weights file (.pth).
            classes_path (str): The path to the sidecar JSON file containing the list of output classes.

        Returns:
            bool: True if the model reloaded successfully, False otherwise.

        Raises:
            FileNotFoundError: If the model weights or class files are missing from disk.
            Exception: If PyTorch fails to load the state dict or parsing JSON fails.
        """
        with self.lock:
            print(f"[ML-HOT-SWAP] Hot Swap initiated. Loading weights from {model_path}...")
            if not os.path.exists(model_path) or not os.path.exists(classes_path):
                print(f"[ML-HOT-SWAP] Error: Model weights or classes file not found on disk.")
                return False
                
            try:
                with open(classes_path, 'r') as f:
                    loaded_classes = json.load(f)
                
                # Reconstruct Mobilenet V2 architecture
                model = models.mobilenet_v2()
                num_ftrs = model.classifier[1].in_features
                model.classifier[1] = nn.Linear(num_ftrs, len(loaded_classes))
                
                state_dict = torch.load(model_path, map_location=device)
                model.load_state_dict(state_dict)
                model.to(device)
                model.eval()
                
                # Atomic swap under lock
                self.model = model
                self.classes = loaded_classes
                print(f"[ML-HOT-SWAP] Model reloaded successfully with {len(loaded_classes)} classes. Discarding old model instance.")
                return True
            except Exception as e:
                print(f"[ML-HOT-SWAP] Error during model reload: {e}")
                return False

# Initialize the live model container instance
live_model_container = LiveModelContainer()

# Determine initial classes list to construct/recover sidecar classes file
initial_classes = []
if os.path.exists(CLASSES_PATH):
    try:
        with open(CLASSES_PATH, 'r') as f:
            initial_classes = json.load(f)
    except Exception as e:
        print(f"Error reading classes JSON sidecar: {e}")

if not initial_classes:
    # Auto-recovery: If weights exist, read its output dimension
    if os.path.exists(MODEL_PATH):
        try:
            state_dict = torch.load(MODEL_PATH, map_location=device)
            if 'classifier.1.weight' in state_dict:
                n_classes = state_dict['classifier.1.weight'].shape[0]
                if len(FLAT_CLASSES) >= n_classes:
                    initial_classes = FLAT_CLASSES[:n_classes]
                else:
                    initial_classes = FLAT_CLASSES + [f"Others___Class{i}" for i in range(len(FLAT_CLASSES), n_classes)]
                # Save sidecar file
                with open(CLASSES_PATH, 'w') as f:
                    json.dump(initial_classes, f, indent=4)
                print(f"Auto-recovered missing classes JSON with {n_classes} classes.")
            else:
                initial_classes = list(FLAT_CLASSES)
        except Exception as e:
            print(f"Error during class recovery: {e}")
            initial_classes = list(FLAT_CLASSES)
    else:
        initial_classes = list(FLAT_CLASSES)

# Try loading the model initially
if os.path.exists(MODEL_PATH):
    # Save the initial classes sidecar if it was recovered
    if not os.path.exists(CLASSES_PATH):
        with open(CLASSES_PATH, 'w') as f:
            json.dump(initial_classes, f, indent=4)
    live_model_container.load_model(MODEL_PATH, CLASSES_PATH)
else:
    print(f"No custom model found at {MODEL_PATH}. Hot Swapper waiting for first training run.")

def predict_image(image_path: str):
    """
    Inferences the model to predict the category and subcategory of a given image file.
    Runs under the thread-safety lock of the live model container.

    Args:
        image_path (str): The absolute filesystem path to the target image file.

    Returns:
        dict: A dictionary containing 'category', 'sub_category', and 'confidence'.
              Defaults to "Others", "Others", 0.0 if loading or inference fails.

    Raises:
        None (catches exceptions internally and returns fallback dictionary)
    """
    # Enforce strict thread-safety during inference per Code Safety requirement
    with live_model_container.lock:
        try:
            current_model = live_model_container.model
            current_classes = live_model_container.classes

            if current_model is None or not current_classes:
                print("[ML-INFERENCE] Error: Live model or classes not loaded in container.")
                return {"category": "Others", "sub_category": "Others", "confidence": 0.0}

            image = Image.open(image_path).convert('RGB')
            img_tensor = data_transforms(image).unsqueeze(0).to(device)
            
            with torch.no_grad():
                outputs = current_model(img_tensor)
                probabilities = torch.nn.functional.softmax(outputs[0], dim=0)
                
                # Get Top 1 Prediction
                confidence, predicted = torch.max(probabilities, 0)
                
                flat_class = current_classes[predicted.item()]
                category, sub_category = flat_class.split('___')
                
                return {
                    "category": category,
                    "sub_category": sub_category,
                    "confidence": confidence.item()
                }
        except Exception as e:
            print(f"[ML-INFERENCE] Prediction error: {e}")
            return {"category": "Others", "sub_category": "Others", "confidence": 0.0}

def fine_tune_model(dataset_dir: str, target_classes: list = None) -> bool:
    """
    Fine-tunes a MobileNet V2 shadow model using corrective feedback dataset, calculates metrics,
    and updates model weights/classes JSON sidecar using atomic renaming.

    Args:
        dataset_dir (str): The path containing subdirectories named Category___SubCategory with feedback images.
        target_classes (list, optional): Explicit target list of categories. If None, defaults to FLAT_CLASSES.

    Returns:
        bool: True if training, evaluation, and weights swap completed successfully, False otherwise.

    Raises:
        None (catches exceptions internally and cleans up temp files)
    """
    from torch.utils.data import Dataset, DataLoader
    import torch.optim as optim
    import glob
    import time
    from sklearn.metrics import accuracy_score, precision_score, recall_score
    
    classes_to_train = target_classes if target_classes is not None else FLAT_CLASSES
    print(f"[ML-SHADOW-TRAINING] Starting Shadow Training for {len(classes_to_train)} subcategories...")
    
    class CustomImageDataset(Dataset):
        """
        A custom PyTorch Dataset implementation for parsing and loading user feedback
        corrective images grouped by category subfolders.
        """
        def __init__(self, root_dir: str, transform=None):
            """
            Initializes the dataset, loading image filepaths and mapping them to class indexes.

            Args:
                root_dir (str): The root directory containing category directories.
                transform (callable, optional): The transform pipeline (e.g. data_transforms).
            """
            self.root_dir = root_dir
            self.transform = transform
            self.image_paths = []
            self.labels = []
            
            for idx, flat_class in enumerate(classes_to_train):
                cat_dir = os.path.join(root_dir, flat_class)
                if os.path.exists(cat_dir):
                    for ext in ('*.jpg', '*.jpeg', '*.png', '*.webp'):
                        for file_path in glob.glob(os.path.join(cat_dir, ext)):
                            self.image_paths.append(file_path)
                            self.labels.append(idx)
                            
        def __len__(self) -> int:
            """
            Returns the total number of images found.

            Returns:
                int: Total number of images.
            """
            return len(self.image_paths)
            
        def __getitem__(self, idx: int):
            """
            Loads, transforms, and returns a single (image_tensor, label_index) pair.

            Args:
                idx (int): The index of the target sample.

            Returns:
                tuple: (transformed_image_tensor, label_index).
            """
            img_path = self.image_paths[idx]
            image = Image.open(img_path).convert('RGB')
            if self.transform:
                image = self.transform(image)
            label = self.labels[idx]
            return image, label

    try:
        dataset = CustomImageDataset(dataset_dir, transform=train_transforms)
        eval_dataset = CustomImageDataset(dataset_dir, transform=eval_transforms)
        if len(dataset) == 0:
            print("[ML-SHADOW-TRAINING] Error: No images found for training.")
            return False
            
        print(f"[ML-SHADOW-TRAINING] Found {len(dataset)} images for training with Data Augmentation.")
        dataloader = DataLoader(dataset, batch_size=16, shuffle=True)
        eval_dataloader = DataLoader(eval_dataset, batch_size=16, shuffle=False)
        
        # Instantiate a separate "Shadow Model" instance to isolate training from live inference
        shadow_model = models.mobilenet_v2(weights=models.MobileNet_V2_Weights.IMAGENET1K_V1)
        
        # Unfreeze features block -4 to end for fine-tuning
        for param in shadow_model.features[:-4].parameters():
            param.requires_grad = False
            
        num_ftrs = shadow_model.classifier[1].in_features
        shadow_model.classifier[1] = nn.Linear(num_ftrs, len(classes_to_train))
        
        # Load backbone weights from current model if available
        if os.path.exists(MODEL_PATH):
            try:
                state_dict = torch.load(MODEL_PATH, map_location=device)
                model_dict = shadow_model.state_dict()
                # Load only layers with matching shapes
                matching_state = {k: v for k, v in state_dict.items() if k in model_dict and v.shape == model_dict[k].shape}
                model_dict.update(matching_state)
                shadow_model.load_state_dict(model_dict)
                print("[ML-SHADOW-TRAINING] Loaded matching backbone weights from live model.")
            except Exception as e:
                print(f"[ML-SHADOW-TRAINING] Warning: Could not load backbone weights ({e}). Fine-tuning from ImageNet weights.")
                
        shadow_model.to(device)
        criterion = nn.CrossEntropyLoss()
        optimizer = optim.Adam(filter(lambda p: p.requires_grad, shadow_model.parameters()), lr=0.0008)
        
        shadow_model.train()
        epochs = 5
        for epoch in range(epochs):
            running_loss = 0.0
            for inputs, labels in dataloader:
                inputs = inputs.to(device)
                labels = labels.to(device)
                
                optimizer.zero_grad()
                outputs = shadow_model(inputs)
                loss = criterion(outputs, labels)
                loss.backward()
                optimizer.step()
                
                running_loss += loss.item() * inputs.size(0)
                
            epoch_loss = running_loss / len(dataset)
            print(f"[ML-SHADOW-TRAINING] Epoch {epoch+1}/{epochs} Loss: {epoch_loss:.4f}")
            
        shadow_model.eval()
        
        # Evaluate metrics using eval_dataloader (clean evaluation)
        all_preds = []
        all_labels = []
        start_time = time.time()
        with torch.no_grad():
            for inputs, labels in eval_dataloader:
                inputs = inputs.to(device)
                outputs = shadow_model(inputs)
                _, preds = torch.max(outputs, 1)
                all_preds.extend(preds.cpu().numpy())
                all_labels.extend(labels.numpy())
                
        inference_time_ms = int(((time.time() - start_time) / len(dataset)) * 1000)
        acc = accuracy_score(all_labels, all_preds) * 100
        prec = precision_score(all_labels, all_preds, average='weighted', zero_division=0) * 100
        rec = recall_score(all_labels, all_preds, average='weighted', zero_division=0) * 100
        
        # Save MLOps metrics
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
            "classes": f"{len(classes_to_train)} Sub-Categories"
        }
        history.append(new_metric)
        with open(metrics_file, 'w') as f:
            json.dump(history, f, indent=4)
            
        # Write to temporary files first to protect against partial reads during Hot Swap
        temp_model_path = MODEL_PATH + ".tmp"
        temp_classes_path = CLASSES_PATH + ".tmp"
        
        torch.save(shadow_model.state_dict(), temp_model_path)
        with open(temp_classes_path, 'w') as f:
            json.dump(classes_to_train, f, indent=4)
            
        # Atomic file rename swap on disk
        if os.path.exists(temp_model_path) and os.path.exists(temp_classes_path):
            if os.path.exists(MODEL_PATH):
                os.remove(MODEL_PATH)
            os.rename(temp_model_path, MODEL_PATH)
            
            if os.path.exists(CLASSES_PATH):
                os.remove(CLASSES_PATH)
            os.rename(temp_classes_path, CLASSES_PATH)
            
        print(f"[ML-SHADOW-TRAINING] Shadow Model weights and classes JSON saved. Metrics: {new_metric}")
        return True
    except Exception as e:
        print(f"[ML-SHADOW-TRAINING] Error during Shadow Training: {e}")
        # Clean up temp files if they exist
        for path in (MODEL_PATH + ".tmp", CLASSES_PATH + ".tmp"):
            if os.path.exists(path):
                os.remove(path)
        return False
