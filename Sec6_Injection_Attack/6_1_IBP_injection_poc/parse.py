
import pandas as pd

def clean_df(df):
    df = df.fillna(-1)
    df = df.replace(r'[^0-9]+',-1)
    df = df.replace('',-1)
    df = df.replace(' ',-1)
    df = df.replace('\n',-1)
    return df

data = pd.read_csv("results.out", sep='\s+')
data = clean_df(data)
data["Clock"] = pd.to_numeric(data["Clock"],errors='coerce')
data["L2_Miss"] = pd.to_numeric(data["L2_Miss"],errors='coerce')
data["BrIndir"] = pd.to_numeric(data["BrIndir"],errors='coerce')
data["BrMispInd"] = pd.to_numeric(data["BrMispInd"],errors='coerce')

min_l2_miss_value = data["L2_Miss"].min()
min_l2_miss_indices = data.index[data["L2_Miss"] == min_l2_miss_value].tolist()

if len(min_l2_miss_indices) == 1:
    index = min_l2_miss_indices[0]
    print(f"IBP injection attack is successful! The secret value is {index}!")
else:
    print("IBP injection attack fails...")