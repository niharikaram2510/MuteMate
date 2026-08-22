import os
import pandas as pd

csv_folder = "csv_data"
output_file = os.path.join(csv_folder, "ALL_DATA.csv")

all_dfs = []

for file_name in sorted(os.listdir(csv_folder)):

    if not file_name.endswith(".csv"):
        continue

    if file_name == "ALL_DATA.csv":
        continue

    print("Reading", file_name)

    df = pd.read_csv(os.path.join(csv_folder, file_name), low_memory=False)

    # rename last column to label
    cols = list(df.columns)
    cols[-1] = "label"
    df.columns = cols

    # remove spaces around labels
    df["label"] = df["label"].astype(str).str.strip()

    all_dfs.append(df)

combined = pd.concat(all_dfs, ignore_index=True)

combined.to_csv(output_file, index=False)

print("\nDone.")
print(combined.shape)
print(combined["label"].value_counts())