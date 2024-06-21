import pandas as pd
import re

def parse_associativity(file_path):
    with open(file_path, 'r') as file:
        data = file.read()

    repeat0_match = re.search(r'@   repeat0:\s*(\d+)', data)
    repeat0 = int(repeat0_match.group(1)) if repeat0_match else None
    
    header_line = re.search(r'@@(.+)', data).group(1)
    headers = re.split(r'\s+', header_line.strip())

    starts = [m.end() for m in re.finditer("Custom PMCounter results:", data)]

    all_results = []

    for start in starts:
        results_data = data[start:].split('\n')[1:1 + repeat0]
        results = []
        for line in results_data:
            if line.strip():
                results.append(re.split(r'\s+', line.strip()))

        if results:
            all_results.extend(results)

    df = pd.DataFrame(all_results, columns=headers)
    df['BrMissRate'] = (df['BrMispInd'].astype(int) / df['BrIndir'].astype(int)) * 100
    df['NumIndBr'] = df['BrIndir'].astype(int) / 2000
    df['BrMispInd'] = df['BrMispInd'].astype(int)
    grouped = df.groupby('NumIndBr').agg({
        'BrMissRate': 'mean',
        'BrMispInd': 'mean'
    }).reset_index()
    asso_df = pd.DataFrame(grouped)
    asso_df.columns = ['NumIndBr', 'BrMissRate', 'BrMispInd']
    first_high_miss_rate = asso_df[(asso_df['BrMissRate'] > 10) & (asso_df['BrMispInd'] > 400)].head(1)
    associativity = first_high_miss_rate['NumIndBr'].iloc[0] - 1
    return asso_df, associativity

import subprocess

script_name = './run.sh'
data = []

for i in range(0, 400):
    command = f"{script_name} mode=run num_ibranch=10 phr_flip_bit={i}"
    try:
        print(f"Testing associativity with flipped PHR[{i}]...")
        subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        result_file_path = f'./results/results_{i}.out'
        asso_df, associativity = parse_associativity(result_file_path)
        if associativity is not None:
            print(f"Associativity is {associativity}!")
            data.append({'phr_flip_bit': i, 'associativity': associativity})
    except subprocess.CalledProcessError as e:
        print(f"Error running script with pc_flip_bit={i}: {e.stderr}")
    
df = pd.DataFrame(data)

import matplotlib.pyplot as plt
import seaborn as sns

plt.figure(figsize=(7.5,1))
plt.rcParams['font.family'] = 'serif'
# Setting up the axes and labels
plt.xlabel('Location of the Flipped PHR Bit', fontsize = 14)
plt.ylabel('Associativity', fontsize = 14)
plt.ylim(-1, 7)
plt.xlim(-5, 405)
custom_yticks = [0, 2, 4, 6]
plt.yticks(custom_yticks)

custom_xticks = [0, 68, 132, 388]
plt.xticks(custom_xticks)

data_point = [df['associativity'][custom_xticks[1]], df['associativity'][custom_xticks[2]], df['associativity'][custom_xticks[3]]]
plt.plot([custom_xticks[1], custom_xticks[1]], [-5, data_point[0]], color='red', linestyle='--', linewidth=1)
plt.plot([custom_xticks[2], custom_xticks[2]], [-5, data_point[1]], color='red', linestyle='--', linewidth=1)
plt.plot([custom_xticks[3], custom_xticks[3]], [-5, data_point[2]], color='red', linestyle='--', linewidth=1)
plt.plot([-5, 70], [data_point[0], data_point[0]], color='red', linestyle='--', linewidth=1)
plt.plot([-5, 134], [data_point[1], data_point[1]], color='red', linestyle='--', linewidth=1)
plt.plot([-5, 390], [data_point[2], data_point[2]], color='red', linestyle='--', linewidth=1)

plt.plot(df['phr_flip_bit'], df['associativity'], linestyle='-', color='green')
plt.gca().get_yaxis().get_label().set_position((0, 0.3))
# plt.show()
fig_file_path='fig_associativity_complete.pdf'
print(f"Figure 6 is generated! (see {fig_file_path})")
plt.savefig(fig_file_path, bbox_inches='tight')


