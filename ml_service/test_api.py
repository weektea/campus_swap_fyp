import requests
import glob
import random
import os

def test_api():
    dataset_dir = "dataset/user_corrections"
    images = glob.glob(os.path.join(dataset_dir, "**", "*.jpg"), recursive=True)
    images.extend(glob.glob(os.path.join(dataset_dir, "**", "*.png"), recursive=True))
    images.extend(glob.glob(os.path.join(dataset_dir, "**", "*.jpeg"), recursive=True))
    
    if not images:
        print("No images found in dataset.")
        return
        
    print(f"Total images found: {len(images)}")
    samples = random.sample(images, min(20, len(images)))
    
    correct = 0
    for idx, img in enumerate(samples):
        true_class = os.path.basename(os.path.dirname(img))
        true_cat, true_sub = true_class.split("___")
        
        with open(img, 'rb') as f:
            try:
                r = requests.post("http://localhost:5000/predict/image", files={"file": f}, timeout=5)
                res = r.json()
                pred_cat = res.get("category")
                pred_sub = res.get("sub_category")
                conf = res.get("confidence", 0.0)
                
                is_correct = (pred_cat == true_cat and pred_sub == true_sub)
                status = "OK" if is_correct else "FAIL"
                if is_correct:
                    correct += 1
                    
                print(f"Sample {idx+1}: {os.path.basename(img)}")
                print(f"  True: {true_cat} -> {true_sub}")
                print(f"  Pred: {pred_cat} -> {pred_sub} ({conf*100:.1f}%) | [{status}]")
                print("-" * 50)
            except Exception as e:
                print(f"Error calling API for {img}: {e}")
                
    print(f"API Accuracy: {correct}/{len(samples)} ({correct/len(samples)*100:.1f}%)")

if __name__ == "__main__":
    test_api()
