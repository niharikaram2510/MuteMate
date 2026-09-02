import pandas as pd
import numpy as np

from tensorflow.keras.models import load_model
from tensorflow.keras.utils import to_categorical

from sklearn.preprocessing import LabelEncoder
from sklearn.model_selection import train_test_split
from sklearn.metrics import accuracy_score, classification_report, confusion_matrix

import seaborn as sns
import matplotlib.pyplot as plt


MODEL_PATH = "signlang_v2_model.keras"
DATA_PATH = "csv_data/ALL_DATA.csv"


print("📂 Loading model and dataset...")

# --------------------------------------------------
# LOAD MODEL
# --------------------------------------------------

model = load_model(MODEL_PATH, compile=False)

model.compile(
    optimizer="adam",
    loss="categorical_crossentropy",
    metrics=["accuracy"]
)


# --------------------------------------------------
# LOAD DATASET
# --------------------------------------------------

data = pd.read_csv(DATA_PATH, low_memory=False)

data = data.loc[:, ~data.columns.str.contains('^Unnamed')]

label_col = data.columns[-1]

for col in data.columns[:-1]:
    data[col] = pd.to_numeric(data[col], errors="coerce")

data = data.fillna(0)

data[label_col] = data[label_col].astype(str).str.strip()


X = data.drop(columns=[label_col]).astype("float32")
y = data[label_col]


print(f"✅ Dataset shape: {X.shape}")
print(f"✅ Total classes: {y.nunique()}")


# --------------------------------------------------
# ENCODE LABELS
# --------------------------------------------------

encoder = LabelEncoder()

y_encoded = encoder.fit_transform(y)

y_onehot = to_categorical(y_encoded)


# --------------------------------------------------
# SAME TRAIN/TEST SPLIT USED DURING TRAINING
# --------------------------------------------------

X_train, X_test, y_train, y_test = train_test_split(
    X,
    y_onehot,
    test_size=0.2,
    random_state=42,
    stratify=y_encoded
)


print(f"📚 Training samples: {len(X_train)}")
print(f"🧪 Test samples: {len(X_test)}")


# --------------------------------------------------
# EVALUATE ONLY ON UNSEEN TEST DATA
# --------------------------------------------------

print("\n🧠 Evaluating on unseen test data...")

loss, accuracy = model.evaluate(
    X_test,
    y_test,
    verbose=1
)

print(f"\n🎯 HOLDOUT TEST ACCURACY: {accuracy * 100:.2f}%")


# --------------------------------------------------
# PREDICTIONS
# --------------------------------------------------

predictions = model.predict(X_test, verbose=1)

y_pred = np.argmax(predictions, axis=1)
y_true = np.argmax(y_test, axis=1)


# --------------------------------------------------
# CLASSIFICATION REPORT
# --------------------------------------------------

print("\n📊 Classification Report:")

print(
    classification_report(
        y_true,
        y_pred,
        target_names=encoder.classes_
    )
)


# --------------------------------------------------
# CONFUSION MATRIX
# --------------------------------------------------

cm = confusion_matrix(y_true, y_pred)

plt.figure(figsize=(18, 14))

sns.heatmap(
    cm,
    annot=True,
    fmt="d",
    xticklabels=encoder.classes_,
    yticklabels=encoder.classes_
)

plt.title("Confusion Matrix - Unseen Test Data")
plt.xlabel("Predicted Label")
plt.ylabel("True Label")

plt.tight_layout()
plt.show()