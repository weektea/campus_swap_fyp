import os
import tensorflow as tf
from tensorflow.keras.applications.mobilenet_v2 import MobileNetV2, preprocess_input
from tensorflow.keras.layers import Dense, GlobalAveragePooling2D
from tensorflow.keras.models import Model
from tensorflow.keras.optimizers import Adam
from tensorflow.keras.preprocessing import image_dataset_from_directory

data_dir = r"c:\Users\ASUS\StudioProjects\campus_swap\ml\dataset"
model_save_path = r"c:\Users\ASUS\StudioProjects\campus_swap\ml\campus_swap_model.keras"

IMG_SIZE = (224, 224)
BATCH_SIZE = 32

def main():
    print("Loading dataset...")
    train_dataset = image_dataset_from_directory(
        data_dir,
        validation_split=0.2,
        subset="training",
        seed=123,
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        label_mode='categorical'
    )

    validation_dataset = image_dataset_from_directory(
        data_dir,
        validation_split=0.2,
        subset="validation",
        seed=123,
        image_size=IMG_SIZE,
        batch_size=BATCH_SIZE,
        label_mode='categorical'
    )
    
    class_names = train_dataset.class_names
    print(f"Classes: {class_names}")

    # MobileNetV2 pre-processing
    # We should map dataset -> [-1, 1] using preprocess_input
    def preprocess(image, label):
        return preprocess_input(image), label
        
    train_dataset = train_dataset.map(preprocess).prefetch(buffer_size=tf.data.AUTOTUNE)
    validation_dataset = validation_dataset.map(preprocess).prefetch(buffer_size=tf.data.AUTOTUNE)

    # Base Model
    base_model = MobileNetV2(input_shape=(224, 224, 3), include_top=False, weights='imagenet')
    base_model.trainable = False  # Freeze base model

    x = base_model.output
    x = GlobalAveragePooling2D()(x)
    x = Dense(128, activation='relu')(x)
    predictions = Dense(len(class_names), activation='softmax')(x)

    model = Model(inputs=base_model.input, outputs=predictions)

    model.compile(optimizer=Adam(learning_rate=0.001), loss='categorical_crossentropy', metrics=['accuracy'])

    print("Training model... (This will take a minute or two)")
    model.fit(train_dataset, validation_data=validation_dataset, epochs=3)

    print(f"Saving model to {model_save_path}")
    model.save(model_save_path)
    
    # Save the class names to a text file
    with open(r"c:\Users\ASUS\StudioProjects\campus_swap\ml\class_names.txt", "w") as f:
        for c in class_names:
            f.write(f"{c}\n")
            
    print("Done! Model and class names saved.")

if __name__ == "__main__":
    main()
