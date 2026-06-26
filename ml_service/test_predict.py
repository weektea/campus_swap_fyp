import os
import sys
import glob
import random

# Add current directory to path just in case
sys.path.append(os.path.dirname(os.path.abspath(__file__)))

from model_vision import predict_image

def main():
    print("==================================================")
    print("Campus Swap ML Prediction Tester")
    print("==================================================")
    
    if len(sys.argv) > 1:
        image_path = sys.argv[1]
        if not os.path.exists(image_path):
            print(f"Error: File '{image_path}' does not exist.")
            return
        
        print(f"Predicting for file: {image_path}")
        res = predict_image(image_path)
        print("Prediction Result:")
        print(f"  Category:     {res.get('category')}")
        print(f"  Subcategory:  {res.get('sub_category')}")
        print(f"  Confidence:   {res.get('confidence') * 100:.2f}%")
    else:
        print("No image path provided. Running random validation demo...")
        dataset_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), "dataset", "user_corrections")
        if not os.path.exists(dataset_dir):
            print(f"Dataset path not found at {dataset_dir}. Cannot run demo.")
            return
            
        # Find all images in dataset subdirectories
        image_paths = []
        image_to_true_class = {}
        
        for subdir in os.listdir(dataset_dir):
            subpath = os.path.join(dataset_dir, subdir)
            if os.path.isdir(subpath) and "___" in subdir:
                for ext in ('*.jpg', '*.jpeg', '*.png', '*.webp'):
                    for file_path in glob.glob(os.path.join(subpath, ext)):
                        image_paths.append(file_path)
                        image_to_true_class[file_path] = subdir
                        
        if not image_paths:
            print("No images found in the dataset to test.")
            return
            
        print(f"Found {len(image_paths)} total images in dataset.")
        # Pick 5 random images
        samples = random.sample(image_paths, min(5, len(image_paths)))
        print(f"Selected {len(samples)} random samples for prediction evaluation:\n")
        
        correct = 0
        for i, sample in enumerate(samples):
            true_class = image_to_true_class[sample]
            true_cat, true_sub = true_class.split("___")
            
            print(f"Sample {i + 1}: {os.path.basename(sample)}")
            print(f"  True Label:  {true_cat} -> {true_sub}")
            
            res = predict_image(sample)
            pred_cat, pred_sub = res.get('category'), res.get('sub_category')
            conf = res.get('confidence')
            
            print(f"  Predicted:   {pred_cat} -> {pred_sub} ({conf * 100:.2f}%)")
            
            is_correct = (pred_cat == true_cat and pred_sub == true_sub)
            if is_correct:
                print("  Status:      [CORRECT] OK")
                correct += 1
            else:
                print("  Status:      [INCORRECT] FAIL")
            print("-" * 50)
            
        print(f"Demo accuracy: {correct}/{len(samples)} ({correct / len(samples) * 100:.1f}%)")
    print("==================================================")

if __name__ == "__main__":
    main()
