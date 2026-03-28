import csv
import json
import numpy as np
import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout
import os

csv_path = r"c:\Users\ASUS\StudioProjects\campus_swap\ml\price_data.csv"
model_path = r"c:\Users\ASUS\StudioProjects\campus_swap\ml\price_model.keras"
vocab_path = r"c:\Users\ASUS\StudioProjects\campus_swap\ml\price_vocab.json"

def main():
    print("Loading price data...")
    categories = set()
    data = []
    
    with open(csv_path, 'r', encoding='utf-8') as f:
        reader = csv.DictReader(f)
        for row in reader:
            cat = row['Category'].strip().lower()
            if cat == 'books & stationery' or cat == 'books':
                cat = 'books'
            
            cond_str = row['Condition']
            price_str = row['Market_Price_RM']
            
            try:
                cond = float(cond_str)
                price = float(price_str)
            except:
                continue
                
            categories.add(cat)
            data.append({'cat': cat, 'cond': cond, 'price': price})
            
    cat_list = sorted(list(categories))
    cat_to_idx = {c: i for i, c in enumerate(cat_list)}
    
    # Save vocab
    with open(vocab_path, 'w') as f:
        json.dump(cat_list, f)
        
    print(f"Categories found: {cat_list}")
    
    # Prepare features
    # Feature vector: [one_hot_category_vector..., condition / 10.0]
    X = []
    Y = []
    
    cat_dim = len(cat_list)
    for d in data:
        vec = [0.0] * cat_dim
        if d['cat'] in cat_to_idx:
            vec[cat_to_idx[d['cat']]] = 1.0
        
        # Condition normalized 0 to 1
        vec.append(d['cond'] / 10.0)
        
        X.append(vec)
        Y.append(d['price'])
        
    X = np.array(X, dtype=np.float32)
    Y = np.array(Y, dtype=np.float32)
    
    print(f"Data shape: {X.shape}, {Y.shape}")
    
    # Simple Neural Network for Regression
    model = Sequential([
        Dense(64, activation='relu', input_shape=(X.shape[1],)),
        Dense(32, activation='relu'),
        Dense(16, activation='relu'),
        Dense(1) # Predict price directly
    ])
    
    model.compile(optimizer='adam', loss='mae', metrics=['mae'])
    
    print("Training model...")
    model.fit(X, Y, epochs=300, batch_size=8, verbose=0)
    
    loss, mae = model.evaluate(X, Y, verbose=0)
    print(f"Training Complete. MAE: {mae:.2f} RM")
    
    model.save(model_path)
    print(f"Saved model to {model_path}")

if __name__ == '__main__':
    main()
