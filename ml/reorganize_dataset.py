import os
import shutil
from pathlib import Path

# Base paths
base_dir = r"c:\Users\ASUS\StudioProjects\campus_swap\Classification_Images"
output_dir = r"c:\Users\ASUS\StudioProjects\campus_swap\ml\dataset"

# Target Categories for the APP
TARGET_CATEGORIES = ['Books', 'Electronics', 'Clothing', 'Furniture', 'Stationery', 'Bicycles', 'Others']

def create_dirs():
    if os.path.exists(output_dir):
        shutil.rmtree(output_dir)
    for cat in TARGET_CATEGORIES:
        os.makedirs(os.path.join(output_dir, cat), exist_ok=True)

def copy_images(src_dir, mapping):
    if not os.path.exists(src_dir):
        return
    for item in os.listdir(src_dir):
        item_path = os.path.join(src_dir, item)
        if os.path.isdir(item_path):
            target_cat = mapping.get(item)
            if target_cat:
                for img in os.listdir(item_path):
                    if img.lower().endswith(('.png', '.jpg', '.jpeg')):
                        shutil.copy2(os.path.join(item_path, img), os.path.join(output_dir, target_cat, f"{item}_{img}"))

def process_loose_images(src_dir):
    if not os.path.exists(src_dir):
        return
    for img in os.listdir(src_dir):
        if not img.lower().endswith(('.png', '.jpg', '.jpeg')): continue
        
        target_cat = 'Others'
        if 'earphones' in img or 'wrist_watch' in img:
            target_cat = 'Electronics'
        elif 'pen' in img.lower():
            target_cat = 'Stationery'
        elif 'sneakers' in img:
            target_cat = 'Clothing'
            
        shutil.copy2(os.path.join(src_dir, img), os.path.join(output_dir, target_cat, img))

def main():
    print("Initializing directories...")
    create_dirs()
    
    # 1. Marketplace item classification
    mapping_1 = {
        'Books': 'Books',
        'Laptops': 'Electronics',
        'Clothing': 'Clothing',
        'Shoes': 'Clothing',
        'Cosmetics': 'Others'
    }
    copy_images(os.path.join(base_dir, 'Marketplace item classification'), mapping_1)
    
    # 2. ecommerce products
    mapping_2 = {
        'jeans': 'Clothing',
        'tshirt': 'Clothing',
        'sofa': 'Furniture',
        'tv': 'Electronics'
    }
    copy_images(os.path.join(base_dir, 'ecommerce products'), mapping_2)
    
    # 3. val
    mapping_3 = {
        'book': 'Books',
        'chair': 'Furniture',
        'laptop': 'Electronics',
        'table': 'Furniture'
    }
    copy_images(os.path.join(base_dir, 'val'), mapping_3)
    
    # 4. Loose images
    process_loose_images(os.path.join(base_dir, 'images'))
    
    # Summary
    print("\nDataset Reorganization Complete!")
    for cat in TARGET_CATEGORIES:
        count = len(os.listdir(os.path.join(output_dir, cat)))
        print(f"{cat}: {count} images")

if __name__ == "__main__":
    main()
