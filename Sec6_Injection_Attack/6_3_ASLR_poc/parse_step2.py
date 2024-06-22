# %%
import pandas as pd
import re

# %%
def parse_pc_23to15(file_path):
    with open(file_path, 'r') as file:
        data = file.read()

    repeat0_match = re.search(r'@   repeat0:\s*(\d+)', data)
    repeat0 = int(repeat0_match.group(1)) if repeat0_match else None
    
    header_line = re.search(r'@@(.+)', data).group(1)
    headers = re.split(r'\s+', header_line.strip())

    sets = re.split(r'@@@-------PC\[23:15\]=(\d+)-------', data)[1:]
    
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
    df['PC[23:15]'] = set_ids
    df['BrClear'] = df['BrClear'].astype(int)
    grouped = df.groupby('PC[23:15]').agg({
        'BrClear': 'min'
    }).reset_index()
    btb_miss_df = pd.DataFrame(grouped)
    btb_miss_df.columns = ['PC[23:15]', 'BrClear']

    # min_br_clear_index = btb_miss_df['BrClear'].idxmin()
    # pc_23to15 = btb_miss_df.loc[min_br_clear_index, 'PC[23:15]']
    return btb_miss_df

# %%
step2_result_file=f"./results_step2.out"
btb_miss_df = parse_pc_23to15(step2_result_file)
pc_23to15 = btb_miss_df.iloc[-1]['PC[23:15]']
br_clear = btb_miss_df.iloc[-1]['BrClear']
print(int(pc_23to15), int(br_clear), sep=',')

