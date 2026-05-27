import os
import shutil

SOURCE_DIR = "Classification_Images/Marketplace item classification"
TARGET_DIR = "ml_service/dataset/user_corrections"

MAPPING = {
    "Books": "Books___Textbooks",
    "Clothing": "Fashion___Clothing",
    "Shoes": "Fashion___Shoes",
    "Laptops": "Electronics___Laptops",
    "Cosmetics": "Others___Miscellaneous" 
}

def setup_dataset():
    if not os.path.exists(SOURCE_DIR):
        print(f"Source dir {SOURCE_DIR} not found.")
        return

    for src_cat, target_cat in MAPPING.items():
        src_path = os.path.join(SOURCE_DIR, src_cat)
        target_path = os.path.join(TARGET_DIR, target_cat)
        
        os.makedirs(target_path, exist_ok=True)
        
        if os.path.exists(src_path):
            files = os.listdir(src_path)
            copied = 0
            for f in files:
                if f.lower().endswith(('.png', '.jpg', '.jpeg')):
                    shutil.copy2(os.path.join(src_path, f), os.path.join(target_path, f"{src_cat}_{f}"))
                    copied += 1
            print(f"Copied {copied} images from {src_cat} to {target_cat}")

if __name__ == "__main__":
    setup_dataset()
