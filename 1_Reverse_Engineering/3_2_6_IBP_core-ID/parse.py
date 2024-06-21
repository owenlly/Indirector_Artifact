import pandas as pd
import re

def parse_results(file_path):
    with open(file_path, 'r') as file:
        data = file.read()

    repeat1_match = re.search(r'@   repeat1:\s*(\d+)', data)
    repeat1 = int(repeat1_match.group(1)) if repeat1_match else None

    header_line = re.search(r'@@(.+)', data).group(1)
    headers = re.split(r'\s+', header_line.strip())
    
    results_start = data.find("Custom PMCounter results:")
    results_data = data[results_start:].split('\n')[1:]
    
    results = []
    for line in results_data:
        if line.strip():
            results.append(re.split(r'\s+', line.strip()))
    
    df = pd.DataFrame(results, columns=headers)
    
    return df, repeat1

file_path = 'results.out'
df, repeat1 = parse_results(file_path)

df['L2_Miss'] = df['L2_Miss'].astype(int)
df['Cache_Miss'] = (df['L2_Miss'] / repeat1) * 100
cache_hit_rate = 100 - df['Cache_Miss'].mean()
print(f"\nParsing results:")
print(f"Cache Hit Rate: {cache_hit_rate:.2f}%")
if cache_hit_rate > 2:
    print("Injection success!")
else:
    print("Injection fail.")