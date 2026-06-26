import os
import sys

# Add current directory to path just in case
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from model_vision import fine_tune_model, FLAT_CLASSES

def main():
    print("==================================================")
    print("Campus Swap ML Offline Model Training")
    print("==================================================")
    print(f"Number of target subcategories: {len(FLAT_CLASSES)}")
    print("Subcategories:")
    for idx, cls in enumerate(FLAT_CLASSES):
        print(f"  {idx + 1}. {cls}")
    print("==================================================")
    
    dataset_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "dataset", "user_corrections")
    
    print(f"Dataset path: {dataset_dir}")
    if not os.path.exists(dataset_dir):
        print(f"Error: Dataset directory not found at {dataset_dir}")
        return
        
    print("Starting training process...")
    success = fine_tune_model(dataset_dir)
    
    if success:
        print("\n==================================================")
        print("Training completed successfully!")
        print("Updated weights saved to custom_model.pth.")
        metrics_file = os.path.join(dataset_dir, "metrics_history.json")
        if os.path.exists(metrics_file):
            import json
            try:
                with open(metrics_file, "r") as f:
                    history = json.load(f)
                    if history:
                        print("Latest metrics:")
                        latest = history[-1]
                        for k, v in latest.items():
                            print(f"  {k}: {v}")
            except Exception as e:
                print(f"Could not read metrics: {e}")
        print("==================================================")
    else:
        print("\n==================================================")
        print("Training failed. Please check logs.")
        print("==================================================")

if __name__ == "__main__":
    main()
