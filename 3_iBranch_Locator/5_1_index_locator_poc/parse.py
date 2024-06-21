import pandas as pd
import re

def parse_results(file_path):
    with open(file_path, 'r') as file:
        data = file.read()

    repeat0_match = re.search(r'@   repeat0:\s*(\d+)', data)
    repeat0 = int(repeat0_match.group(1)) if repeat0_match else None
    
    header_line = re.search(r'@@(.+)', data).group(1)
    headers = re.split(r'\s+', header_line.strip())

    sets = re.split(r'@@@-------IBP set #(\d+)-------', data)[1:]

    results = []
    set_ids = []
    
    for i in range(0, len(sets), 2):
        set_id = int(sets[i])
        set_data = sets[i + 1]
        set_lines = set_data.strip().split('\n')[1:repeat0]

        for line in set_lines:
            if line.strip():
                results.append(re.split(r'\s+', line.strip()))
                set_ids.append(set_id)

    df = pd.DataFrame(results, columns=headers)
    df['SetID'] = set_ids
    df['BrMissRate'] = (df['BrMispInd'].astype(int) / df['BrIndir'].astype(int)) * 100
    grouped = df.groupby('SetID').agg({
        'BrMissRate': 'mean'
    }).reset_index()
    miss_rate_df = pd.DataFrame(grouped)
    miss_rate_df.columns = ['SetID', 'BrMissRate']
    return miss_rate_df

df = parse_results("results.out")
print(f"\nParsing results:")
for index, row in df.iterrows():
    print(f'Misprediction in IBP set {int(row["SetID"])}: {row["BrMissRate"]:.2f}%')


