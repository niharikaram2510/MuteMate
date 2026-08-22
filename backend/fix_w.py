import pandas as pd

df = pd.read_csv("csv_data/W.csv", low_memory=False)

# force last column to always be W
df.iloc[:, -1] = "W"

df.to_csv("csv_data/W.csv", index=False)

print("Done.")
print(df.iloc[:, -5:])