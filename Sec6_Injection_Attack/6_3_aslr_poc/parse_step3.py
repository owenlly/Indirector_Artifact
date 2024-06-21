# %%
import pandas as pd
import re

# %%
def parse_pc_31to24(file_path):
    with open(file_path, 'r') as file:
        data = file.read()

    repeat0_match = re.search(r'@   repeat0:\s*(\d+)', data)
    repeat0 = int(repeat0_match.group(1)) if repeat0_match else None
    
    header_line = re.search(r'@@(.+)', data).group(1)
    headers = re.split(r'\s+', header_line.strip())

    sets = re.split(r'@@@-------PC\[31:24\]=(\d+)-------', data)[1:]

    results = []
    set_ids = []
    
    for i in range(0, len(sets), 2):
        set_id = int(sets[i])
        set_data = sets[i + 1]
        set_lines = set_data.strip().split('\n')[0:repeat0]
        for line in set_lines:
            if line.strip():
                results.append(re.split(r'\s+', line.strip()))
                set_ids.append(set_id)

    df = pd.DataFrame(results, columns=headers)
    df['PC[31:24]'] = set_ids
    df['L2_Miss'] = df['L2_Miss'].astype(int)
    grouped = df.groupby('PC[31:24]').agg({
        'L2_Miss': 'min'
    }).reset_index()
    l2_miss_df = pd.DataFrame(grouped)
    l2_miss_df.columns = ['PC[31:24]', 'L2_Miss']
    # min_br_clear_index = l2_miss_df['L2_Miss'].idxmin()
    # pc_31to24 = l2_miss_df.loc[min_br_clear_index, 'PC[31:24]']
    return l2_miss_df

# %%
step3_result_file=f"./results_step3.out"
l2_miss_df = parse_pc_31to24(step3_result_file)
pc_31to24 = l2_miss_df.iloc[-1]['PC[31:24]']
l2_miss = l2_miss_df.iloc[-1]['L2_Miss']
print(int(pc_31to24), int(l2_miss), sep=',')


