# training_isl_final.py
import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split
from sklearn.preprocessing import LabelEncoder
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Dense, Dropout
from tensorflow.keras.utils import to_categorical

# ----------------------------
# Load and clean dataset
# ----------------------------
data_path = "csv_data/ALL_DATA.csv"
print(f"📂 Loading data from: {data_path}")

data = pd.read_csv(data_path, low_memory=False)
print(f"✅ CSV loaded. Shape: {data.shape}")

# Remove unnamed or index columns if present
data = data.loc[:, ~data.columns.str.contains('^Unnamed')]
print(f"Remaining columns: {data.shape[1]}")

# Convert all feature columns to numeric safely
for col in data.columns[:-1]:
    data[col] = pd.to_numeric(data[col], errors='coerce')

# Replace invalid or missing values with 0 (instead of dropping them)
data = data.fillna(0)

label_col = "label"

# remove spaces
data[label_col] = data[label_col].astype(str).str.strip()

# keep only the 33 valid labels
VALID = [
    'A','B','BYE','C','D','E','F','G','H',
    'HELLO','HOW ARE YOU','I LOVE YOU','I',
    'J','K','L','M','N','O','P','Q','R',
    'S','SORRY','T','THANK YOU','U','V',
    'W','WELCOME','X','Y','Z'
]

data = data[data[label_col].isin(VALID)]

X = data.drop(columns=["label"]).astype("float32")
y = data["label"]

print("Dataset shape:", X.shape)
print("Classes:", sorted(y.unique()))
print("Total classes:", len(y.unique()))

# ----------------------------
# Encode labels
# ----------------------------
label_encoder = LabelEncoder()
y_encoded = label_encoder.fit_transform(y)
num_classes = len(label_encoder.classes_)
y_onehot = to_categorical(y_encoded, num_classes)

# Save class labels for realtime detection
np.save("label_classes.npy", label_encoder.classes_)
print("✅ Label classes saved as 'label_classes.npy'")

# ----------------------------
# Split data
# ----------------------------
X_train, X_test, y_train, y_test = train_test_split(
    X, y_onehot, test_size=0.2, random_state=42, stratify=y_encoded
)

print(f"📊 Training set: {X_train.shape}, Testing set: {X_test.shape}")

# ----------------------------
# Build and compile the model
# ----------------------------
model = Sequential([
    Dense(256, activation='relu', input_shape=(X_train.shape[1],)),
    Dropout(0.3),
    Dense(128, activation='relu'),
    Dropout(0.3),
    Dense(num_classes, activation='softmax')
])

model.compile(
    loss='categorical_crossentropy',
    optimizer='adam',
    metrics=['accuracy']
)

model.summary()

# ----------------------------
# Train the model
# ----------------------------
history = model.fit(
    X_train, y_train,
    validation_data=(X_test, y_test),
    epochs=50,
    batch_size=32,
    verbose=1
)

# ----------------------------
# Save model
# ----------------------------
model.save("signlang_v2_model.keras")
print("✅ Model saved as 'signlang_v2_model.keras'")
