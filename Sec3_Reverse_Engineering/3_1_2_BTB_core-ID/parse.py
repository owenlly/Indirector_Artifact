import pandas as pd
import re

def parse_results(file_path):
    with open(file_path, 'r') as file:
        data = file.read()

    header_line = re.search(r'@@(.+)', data).group(1)
    headers = re.split(r'\s+', header_line.strip())
    
    results_start = data.find("Custom PMCounter results:")
    results_data = data[results_start:].split('\n')[1:]
    
    results = []
    for line in results_data:
        if line.strip():
            results.append(re.split(r'\s+', line.strip()))
    
    df = pd.DataFrame(results, columns=headers)
    
    return df

file_path = 'results.out'
df = parse_results(file_path)

df['BrMissRate'] = (df['BrClear'].astype(int) / df['BrRetired'].astype(int)) * 100
print(f"\nParsing results:")
print(f"Branch misprediction rate of t0 test branches: {df['BrMissRate'].mean():.2f}%")


