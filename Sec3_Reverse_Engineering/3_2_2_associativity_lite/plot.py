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
    df['BrMissRate'] = (df['BrMispInd'].astype(int) / df['BrIndir'].astype(int)) * 100
    
    miss_rate = df['BrMissRate'].mean()
    
    return miss_rate

import subprocess

result_file_path = 'results.out'
script_name = './run.sh'
data = []

for i in range(1,11):
    command = f"{script_name} mode=run num_ibranch={i}"
    try:
        print(f"{i} indirect branches with same PHR...")
        subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        miss_rate = parse_results(result_file_path)
        if miss_rate is not None:
            data.append({'num_ibranch': i, 'miss_rate': miss_rate})
    except subprocess.CalledProcessError as e:
        print(f"Error running script with pc_flip_bit={i}: {e.stderr}")
    
df = pd.DataFrame(data)

import matplotlib.pyplot as plt
import seaborn as sns

plt.figure(figsize=(7,1.2))
plt.rcParams['font.family'] = 'serif'
# Setting up the axes and labels
plt.xlabel('Number of the Indirect Branches', fontsize = 14)
plt.ylabel('Miss Rate (%)', fontsize = 14)
plt.ylim(-10, 70)
plt.xlim(0, 11)
custom_yticks = [0, 20, 40, 60]
plt.yticks(custom_yticks)

custom_xticks = [1, 6, 7, 10]
plt.xticks(custom_xticks)

plt.plot([6, 6], [-10, df['miss_rate'][5]], color='red', linestyle='--', linewidth=1)
plt.plot([7, 7], [-10, df['miss_rate'][6]], color='red', linestyle='--', linewidth=1)
plt.axhline(y=0, color='grey', linestyle='--', linewidth=0.6)

plt.plot(df['num_ibranch'].to_numpy(), df['miss_rate'].to_numpy(), linestyle='-', color='green')
plt.gca().get_yaxis().get_label().set_position((0, 0.3))

fig_file_path='fig_associativity_lite.pdf'
print(f"Figure 5 is generated! (see {fig_file_path})")
plt.savefig(fig_file_path, bbox_inches='tight')


