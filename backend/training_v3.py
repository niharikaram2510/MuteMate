import os
import numpy as np
import pandas as pd

from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import classification_report, accuracy_score

import tensorflow as tf
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau, ModelCheckpoint


# ============================================================
# SETTINGS
# ============================================================

DATA_PATH = "csv_data/FINAL_DATA.csv"

ORIGINAL_SAMPLES = 16500
WEBCAM_SAMPLES = 3300

WEBCAM_TEST_PER_CLASS = 50

MODEL_PATH = "signlang_v3_model.keras"
LABEL_PATH = "label_classes_v3.npy"

RANDOM_STATE = 42


# ============================================================
# LOAD DATA
# ============================================================

print("\nLoading FINAL_DATA.csv...")

df = pd.read_csv(DATA_PATH)

X = df.iloc[:, :-1].values.astype(np.float32)
y = df.iloc[:, -1].values

print(f"Total samples: {len(X)}")
print(f"Features: {X.shape[1]}")
print(f"Classes: {len(np.unique(y))}")


# ============================================================
# IDENTIFY ORIGINAL + WEBCAM DATA
# ============================================================

# prepare_webcam_dataset.py placed:
# ORIGINAL_DATA first
# WEBCAM_DATA afterwards

original_X = X[:ORIGINAL_SAMPLES]
original_y = y[:ORIGINAL_SAMPLES]

webcam_X = X[ORIGINAL_SAMPLES:]
webcam_y = y[ORIGINAL_SAMPLES:]

print("\nOriginal dataset:")
print(len(original_X))

print("Webcam dataset:")
print(len(webcam_X))


# ============================================================
# SPLIT WEBCAM DATA
# ============================================================

print("\nSplitting webcam data...")

rng = np.random.RandomState(RANDOM_STATE)

webcam_train_indices = []
webcam_test_indices = []

classes = np.unique(webcam_y)

for cls in classes:

    indices = np.where(webcam_y == cls)[0]

    rng.shuffle(indices)

    test_indices = indices[:WEBCAM_TEST_PER_CLASS]
    train_indices = indices[WEBCAM_TEST_PER_CLASS:]

    webcam_test_indices.extend(test_indices)
    webcam_train_indices.extend(train_indices)


webcam_train_X = webcam_X[webcam_train_indices]
webcam_train_y = webcam_y[webcam_train_indices]

webcam_test_X = webcam_X[webcam_test_indices]
webcam_test_y = webcam_y[webcam_test_indices]


print(f"Webcam training samples: {len(webcam_train_X)}")
print(f"Webcam test samples: {len(webcam_test_X)}")


# ============================================================
# COMBINE ORIGINAL + WEBCAM TRAINING DATA
# ============================================================

train_pool_X = np.concatenate(
    [original_X, webcam_train_X],
    axis=0
)

train_pool_y = np.concatenate(
    [original_y, webcam_train_y],
    axis=0
)


print("\nTraining pool:")
print(len(train_pool_X))


# ============================================================
# LABEL ENCODING
# ============================================================

label_encoder = LabelEncoder()

y_encoded = label_encoder.fit_transform(train_pool_y)

webcam_test_encoded = label_encoder.transform(webcam_test_y)

num_classes = len(label_encoder.classes_)

print(f"\nNumber of classes: {num_classes}")

print("\nClasses:")
for i, label in enumerate(label_encoder.classes_):
    print(i, "->", label)


np.save(LABEL_PATH, label_encoder.classes_)

print(f"\nLabels saved to {LABEL_PATH}")


# ============================================================
# TRAIN / VALIDATION SPLIT
# ============================================================

X_train, X_val, y_train, y_val = train_test_split(
    train_pool_X,
    y_encoded,
    test_size=0.10,
    random_state=RANDOM_STATE,
    stratify=y_encoded
)

print("\nTraining samples:", len(X_train))
print("Validation samples:", len(X_val))
print("Final unseen webcam test:", len(webcam_test_X))


# ============================================================
# BUILD MODEL
# ============================================================

model = Sequential([
    Dense(256, activation="relu", input_shape=(126,)),
    Dropout(0.30),

    Dense(128, activation="relu"),
    Dropout(0.30),

    Dense(num_classes, activation="softmax")
])


model.compile(
    optimizer=tf.keras.optimizers.Adam(learning_rate=0.001),
    loss="sparse_categorical_crossentropy",
    metrics=["accuracy"]
)


model.summary()


# ============================================================
# CALLBACKS
# ============================================================

callbacks = [

    EarlyStopping(
        monitor="val_loss",
        patience=10,
        restore_best_weights=True,
        verbose=1
    ),

    ReduceLROnPlateau(
        monitor="val_loss",
        factor=0.5,
        patience=4,
        min_lr=1e-6,
        verbose=1
    ),

    ModelCheckpoint(
        MODEL_PATH,
        monitor="val_accuracy",
        save_best_only=True,
        verbose=1
    )
]


# ============================================================
# TRAIN
# ============================================================

print("\n" + "=" * 60)
print("STARTING V3 TRAINING")
print("=" * 60)

history = model.fit(
    X_train,
    y_train,
    validation_data=(X_val, y_val),
    epochs=100,
    batch_size=32,
    callbacks=callbacks,
    verbose=1
)


# ============================================================
# LOAD BEST MODEL
# ============================================================

print("\nLoading best V3 model...")

model = tf.keras.models.load_model(MODEL_PATH)


# ============================================================
# FINAL UNSEEN WEBCAM TEST
# ============================================================

print("\n" + "=" * 60)
print("FINAL WEBCAM TEST")
print("=" * 60)

predictions = model.predict(
    webcam_test_X,
    verbose=0
)

predicted_classes = np.argmax(predictions, axis=1)


accuracy = accuracy_score(
    webcam_test_encoded,
    predicted_classes
)

print(f"\nFINAL WEBCAM ACCURACY: {accuracy * 100:.2f}%")


# ============================================================
# CLASSIFICATION REPORT
# ============================================================

print("\nClassification Report:\n")

print(
    classification_report(
        webcam_test_encoded,
        predicted_classes,
        target_names=label_encoder.classes_,
        digits=4,
        zero_division=0
    )
)


# ============================================================
# PER-CLASS ACCURACY
# ============================================================

print("\n" + "=" * 60)
print("PER-CLASS WEBCAM ACCURACY")
print("=" * 60)

for i, label in enumerate(label_encoder.classes_):

    class_indices = np.where(webcam_test_encoded == i)[0]

    class_accuracy = np.mean(
        predicted_classes[class_indices] == i
    )

    print(
        f"{label:<20} : "
        f"{class_accuracy * 100:6.2f}%"
    )


# ============================================================
# DONE
# ============================================================

print("\n" + "=" * 60)
print("V3 TRAINING COMPLETE")
print("=" * 60)

print(f"\nModel saved as: {MODEL_PATH}")
print(f"Labels saved as: {LABEL_PATH}")

print("\nIMPORTANT:")
print("V2 has NOT been overwritten.")
print("V3 was tested using completely unseen webcam samples.")