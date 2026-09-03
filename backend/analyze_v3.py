import numpy as np
import pandas as pd
import tensorflow as tf

from sklearn.metrics import confusion_matrix
from sklearn.preprocessing import LabelEncoder


# ============================================================
# SETTINGS
# ============================================================

DATA_PATH = "csv_data/FINAL_DATA.csv"
MODEL_PATH = "signlang_v3_model.keras"

ORIGINAL_SAMPLES = 16500
WEBCAM_TEST_PER_CLASS = 50

RANDOM_STATE = 42


# ============================================================
# LOAD DATA
# ============================================================

df = pd.read_csv(DATA_PATH)

X = df.iloc[:, :-1].values.astype(np.float32)
y = df.iloc[:, -1].values


# ============================================================
# GET WEBCAM DATA
# ============================================================

webcam_X = X[ORIGINAL_SAMPLES:]
webcam_y = y[ORIGINAL_SAMPLES:]


# ============================================================
# RECREATE SAME TEST SPLIT
# ============================================================

rng = np.random.RandomState(RANDOM_STATE)

test_indices = []

classes = np.unique(webcam_y)

for cls in classes:

    indices = np.where(webcam_y == cls)[0]

    rng.shuffle(indices)

    test_indices.extend(indices[:WEBCAM_TEST_PER_CLASS])


webcam_test_X = webcam_X[test_indices]
webcam_test_y = webcam_y[test_indices]


# ============================================================
# LABEL ENCODER
# ============================================================

label_encoder = LabelEncoder()

# Fit on ALL labels so the class numbering is correct
label_encoder.fit(y)

true_encoded = label_encoder.transform(webcam_test_y)


# ============================================================
# LOAD MODEL
# ============================================================

print("\nLoading V3 model...")

model = tf.keras.models.load_model(MODEL_PATH)


# ============================================================
# PREDICTIONS
# ============================================================

predictions = model.predict(
    webcam_test_X,
    verbose=0
)

predicted_encoded = np.argmax(predictions, axis=1)


# ============================================================
# CONFUSION MATRIX
# ============================================================

cm = confusion_matrix(
    true_encoded,
    predicted_encoded,
    labels=np.arange(len(label_encoder.classes_))
)


# ============================================================
# TOP CONFUSIONS
# ============================================================

print("\n" + "=" * 70)
print("TOP CONFUSIONS")
print("=" * 70)

confusions = []

for true_idx in range(len(label_encoder.classes_)):

    for pred_idx in range(len(label_encoder.classes_)):

        if true_idx == pred_idx:
            continue

        count = cm[true_idx, pred_idx]

        if count > 0:

            confusions.append(
                (
                    count,
                    label_encoder.classes_[true_idx],
                    label_encoder.classes_[pred_idx]
                )
            )


confusions.sort(reverse=True)


for count, true_label, predicted_label in confusions[:40]:

    print(
        f"{true_label:<20} -> "
        f"{predicted_label:<20} : "
        f"{count}"
    )


# ============================================================
# PER-CLASS ERRORS
# ============================================================

print("\n" + "=" * 70)
print("WORST CLASSES")
print("=" * 70)

for true_idx, label in enumerate(label_encoder.classes_):

    total = cm[true_idx].sum()

    correct = cm[true_idx, true_idx]

    accuracy = correct / total

    print(
        f"{label:<20} "
        f"{accuracy * 100:6.2f}%"
    )


# ============================================================
# DETAILED ANALYSIS OF E
# ============================================================

print("\n" + "=" * 70)
print("WHAT DOES E GET CONFUSED WITH?")
print("=" * 70)

e_idx = np.where(label_encoder.classes_ == "E")[0][0]

for pred_idx in np.argsort(cm[e_idx])[::-1]:

    count = cm[e_idx, pred_idx]

    if count > 0:

        print(
            f"E -> "
            f"{label_encoder.classes_[pred_idx]:<20} "
            f"{count} times"
        )


# ============================================================
# DETAILED ANALYSIS OF D
# ============================================================

print("\n" + "=" * 70)
print("WHAT DOES D GET CONFUSED WITH?")
print("=" * 70)

d_idx = np.where(label_encoder.classes_ == "D")[0][0]

for pred_idx in np.argsort(cm[d_idx])[::-1]:

    count = cm[d_idx, pred_idx]

    if count > 0:

        print(
            f"D -> "
            f"{label_encoder.classes_[pred_idx]:<20} "
            f"{count} times"
        )


print("\nAnalysis complete.")