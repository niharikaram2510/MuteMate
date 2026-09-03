import pandas as pd
import numpy as np

from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import classification_report, confusion_matrix

from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout, Input
from tensorflow.keras.utils import to_categorical
from tensorflow.keras.callbacks import EarlyStopping, ReduceLROnPlateau, ModelCheckpoint


# ============================================================
# 1. LOAD DATASET
# ============================================================

data_path = "csv_data/ALL_DATA.csv"

print(f"📂 Loading data from: {data_path}")

data = pd.read_csv(data_path, low_memory=False)

print(f"✅ CSV loaded. Shape: {data.shape}")


# Remove unnamed/index columns
data = data.loc[:, ~data.columns.str.contains("^Unnamed")]

print(f"Remaining columns: {data.shape[1]}")


# ============================================================
# 2. CLEAN DATA
# ============================================================

# Convert feature columns to numeric
feature_columns = [col for col in data.columns if col != "label"]

for col in feature_columns:
    data[col] = pd.to_numeric(data[col], errors="coerce")

# Replace invalid/missing values
data = data.fillna(0)

# Clean labels
label_col = "label"
data[label_col] = data[label_col].astype(str).str.strip()


# ============================================================
# 3. VALID LABELS
# ============================================================

VALID = [
    'A', 'B', 'BYE', 'C', 'D', 'E', 'F', 'G', 'H',
    'HELLO', 'HOW ARE YOU', 'I LOVE YOU', 'I',
    'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
    'S', 'SORRY', 'T', 'THANK YOU', 'U', 'V',
    'W', 'WELCOME', 'X', 'Y', 'Z'
]

data = data[data[label_col].isin(VALID)].copy()

print(f"\nDataset shape after filtering: {data.shape}")


# ============================================================
# 4. FEATURES + LABELS
# ============================================================

X = data.drop(columns=[label_col]).astype("float32")
y = data[label_col]

print("\nClasses:")
print(sorted(y.unique()))
print(f"Total classes: {len(y.unique())}")
print(f"Features per sample: {X.shape[1]}")


# ============================================================
# 5. ENCODE LABELS
# ============================================================

label_encoder = LabelEncoder()

y_encoded = label_encoder.fit_transform(y)

num_classes = len(label_encoder.classes_)

y_onehot = to_categorical(
    y_encoded,
    num_classes=num_classes
)

# Save labels
np.save(
    "label_classes.npy",
    label_encoder.classes_
)

print("\n✅ Label classes saved.")


# ============================================================
# 6. TRAIN / VALIDATION / TEST SPLIT
# ============================================================

# First:
# 80% training
# 20% temporary

X_train, X_temp, y_train, y_temp, y_train_labels, y_temp_labels = train_test_split(
    X,
    y_onehot,
    y_encoded,
    test_size=0.20,
    random_state=42,
    stratify=y_encoded
)

# Then split temporary 50/50:
# 10% validation
# 10% test

X_val, X_test, y_val, y_test = train_test_split(
    X_temp,
    y_temp,
    test_size=0.50,
    random_state=42,
    stratify=y_temp_labels
)

print("\n📊 DATA SPLIT")
print("-------------------------")
print(f"Training:   {X_train.shape[0]}")
print(f"Validation: {X_val.shape[0]}")
print(f"Testing:    {X_test.shape[0]}")


# ============================================================
# 7. BUILD MODEL
# ============================================================

model = Sequential([
    Input(shape=(X_train.shape[1],)),

    Dense(256, activation="relu"),
    Dropout(0.30),

    Dense(128, activation="relu"),
    Dropout(0.30),

    Dense(num_classes, activation="softmax")
])


# ============================================================
# 8. COMPILE
# ============================================================

model.compile(
    optimizer="adam",
    loss="categorical_crossentropy",
    metrics=["accuracy"]
)

model.summary()


# ============================================================
# 9. CALLBACKS
# ============================================================

early_stopping = EarlyStopping(
    monitor="val_loss",
    patience=8,
    restore_best_weights=True,
    verbose=1
)

reduce_lr = ReduceLROnPlateau(
    monitor="val_loss",
    factor=0.5,
    patience=3,
    min_lr=1e-6,
    verbose=1
)

checkpoint = ModelCheckpoint(
    "best_signlang_model.keras",
    monitor="val_accuracy",
    save_best_only=True,
    mode="max",
    verbose=1
)


# ============================================================
# 10. TRAIN
# ============================================================

print("\n🚀 Starting training...\n")

history = model.fit(
    X_train,
    y_train,

    validation_data=(
        X_val,
        y_val
    ),

    epochs=100,
    batch_size=32,

    callbacks=[
        early_stopping,
        reduce_lr,
        checkpoint
    ],

    verbose=1
)


# ============================================================
# 11. LOAD BEST MODEL
# ============================================================

print("\n📦 Loading best model...")

from tensorflow.keras.models import load_model

model = load_model("best_signlang_model.keras")


# ============================================================
# 12. FINAL TEST
# ============================================================

print("\n🧪 Evaluating on completely unseen test data...\n")

test_loss, test_accuracy = model.evaluate(
    X_test,
    y_test,
    verbose=1
)

print("\n================================")
print(f"🎯 TEST ACCURACY: {test_accuracy * 100:.2f}%")
print(f"📉 TEST LOSS:     {test_loss:.4f}")
print("================================")


# ============================================================
# 13. CLASSIFICATION REPORT
# ============================================================

predictions = model.predict(X_test, verbose=0)

predicted_classes = np.argmax(predictions, axis=1)
actual_classes = np.argmax(y_test, axis=1)

print("\n📋 CLASSIFICATION REPORT\n")

print(
    classification_report(
        actual_classes,
        predicted_classes,
        target_names=label_encoder.classes_,
        digits=4
    )
)


# ============================================================
# 14. CONFUSION MATRIX
# ============================================================

cm = confusion_matrix(
    actual_classes,
    predicted_classes
)

print("\n🔎 CONFUSION MATRIX")
print(cm)


# ============================================================
# 15. SAVE FINAL MODEL
# ============================================================

model.save("signlang_v2_model.keras")

print("\n✅ Final model saved as:")
print("   signlang_v2_model.keras")