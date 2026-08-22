import os
import pandas as pd

for file in sorted(os.listdir("csv_data")):

    if not file.endswith(".csv"):
        continue

    if file == "ALL_DATA.csv":
        continue

    df = pd.read_csv(os.path.join("csv_data", file), low_memory=False)

    last = df.iloc[:, -1].astype(str)

    bad = last[
        ~last.str.fullmatch(r"[A-Z ]+")
    ]

    if len(bad):
        print(file)
        print(bad)
        print("-"*40)