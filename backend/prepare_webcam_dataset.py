import os
import glob
import numpy as np
import pandas as pd


# ============================================================
# PATHS
# ============================================================

ORIGINAL_DATASET = "csv_data/ALL_DATA.csv"
WEBCAM_DIR = "webcam_training_data"
OUTPUT_DATASET = "csv_data/FINAL_DATA.csv"

EXPECTED_FEATURES = 126

VALID_LABELS = [
    'A', 'B', 'BYE', 'C', 'D', 'E', 'F', 'G', 'H',
    'HELLO', 'HOW ARE YOU', 'I', 'I LOVE YOU',
    'J', 'K', 'L', 'M', 'N', 'O', 'P', 'Q', 'R',
    'S', 'SORRY', 'T', 'THANK YOU', 'U', 'V',
    'W', 'WELCOME', 'X', 'Y', 'Z'
]


# ============================================================
# 1. LOAD ORIGINAL DATASET
# ============================================================

print("\n📂 Loading original dataset...")

original = pd.read_csv(
    ORIGINAL_DATASET,
    low_memory=False
)

original = original.loc[
    :,
    ~original.columns.str.contains("^Unnamed")
]

original["label"] = (
    original["label"]
    .astype(str)
    .str.strip()
)

original = original[
    original["label"].isin(VALID_LABELS)
].copy()

print(f"✅ Original samples: {len(original)}")
print(f"✅ Original features: {len(original.columns) - 1}")


# ============================================================
# 2. VERIFY ORIGINAL DATASET
# ============================================================

original_features = original.drop(
    columns=["label"]
)

if original_features.shape[1] != EXPECTED_FEATURES:
    raise ValueError(
        f"❌ Original dataset has "
        f"{original_features.shape[1]} features. "
        f"Expected {EXPECTED_FEATURES}."
    )

original_features = original_features.apply(
    pd.to_numeric,
    errors="coerce"
)

if original_features.isna().any().any():
    print("⚠️ NaN values found in original dataset. Filling with 0.")
    original_features = original_features.fillna(0)

original.iloc[:, :-1] = original_features


# ============================================================
# 3. LOAD WEBCAM DATA
# ============================================================

print("\n📸 Loading webcam samples...")

webcam_rows = []

for label in VALID_LABELS:

    label_dir = os.path.join(
        WEBCAM_DIR,
        label
    )

    files = sorted(
        glob.glob(
            os.path.join(label_dir, "*.npy")
        )
    )

    print(
        f"{label:<15} : {len(files)} samples"
    )

    if len(files) != 100:
        raise ValueError(
            f"❌ {label} has {len(files)} samples. "
            f"Expected exactly 100."
        )

    for file_path in files:

        features = np.load(file_path)

        features = np.asarray(
            features,
            dtype=np.float32
        ).flatten()

        if len(features) != EXPECTED_FEATURES:
            raise ValueError(
                f"❌ {file_path} has "
                f"{len(features)} features. "
                f"Expected {EXPECTED_FEATURES}."
            )

        if not np.isfinite(features).all():
            raise ValueError(
                f"❌ Invalid values found in {file_path}"
            )

        row = list(features) + [label]

        webcam_rows.append(row)


# ============================================================
# 4. CREATE WEBCAM DATAFRAME
# ============================================================

feature_names = [
    f"feature_{i}"
    for i in range(EXPECTED_FEATURES)
]

columns = feature_names + ["label"]

webcam = pd.DataFrame(
    webcam_rows,
    columns=columns
)

print(
    f"\n✅ Webcam samples loaded: {len(webcam)}"
)


# ============================================================
# 5. ALIGN ORIGINAL COLUMN NAMES
# ============================================================

original_columns = list(
    original.columns
)

original_feature_names = [
    col for col in original_columns
    if col != "label"
]

webcam.columns = (
    original_feature_names + ["label"]
)


# ============================================================
# 6. COMBINE DATASETS
# ============================================================

print("\n🔗 Combining datasets...")

final_data = pd.concat(
    [
        original,
        webcam
    ],
    ignore_index=True
)


# ============================================================
# 7. FINAL VALIDATION
# ============================================================

print("\n🔍 Final dataset validation...")

if final_data.shape[1] != 127:
    raise ValueError(
        f"❌ Final dataset has "
        f"{final_data.shape[1]} columns. "
        f"Expected 127."
    )

if final_data.shape[0] != 19800:
    raise ValueError(
        f"❌ Final dataset has "
        f"{final_data.shape[0]} rows. "
        f"Expected 19,800."
    )

if set(final_data["label"].unique()) != set(VALID_LABELS):
    raise ValueError(
        "❌ Label mismatch detected."
    )

final_features = final_data.drop(
    columns=["label"]
)

final_features = final_features.apply(
    pd.to_numeric,
    errors="coerce"
)

if final_features.isna().any().any():
    raise ValueError(
        "❌ Final dataset contains NaN values."
    )

if not np.isfinite(
    final_features.to_numpy()
).all():
    raise ValueError(
        "❌ Final dataset contains invalid values."
    )


# ============================================================
# 8. PRINT CLASS COUNTS
# ============================================================

print("\n📊 FINAL CLASS COUNTS")
print("=" * 35)

counts = final_data["label"].value_counts()

for label in VALID_LABELS:
    print(
        f"{label:<15} : {counts[label]}"
    )


# ============================================================
# 9. SAVE
# ============================================================

final_data.to_csv(
    OUTPUT_DATASET,
    index=False
)

print("\n" + "=" * 50)
print("🎉 DATASET PREPARATION COMPLETE")
print("=" * 50)

print(f"📦 Total samples: {len(final_data)}")
print(f"📐 Features: {len(final_features.columns)}")
print(f"🏷️ Classes: {final_data['label'].nunique()}")

print(f"\n💾 Saved to:")
print(OUTPUT_DATASET)

print("\n✅ Original ALL_DATA.csv was NOT modified.")