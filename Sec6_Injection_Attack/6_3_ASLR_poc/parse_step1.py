# %%
import pandas as pd
import re

# %%
def parse_pc_14to12(file_path):
    with open(file_path, 'r') as file:
        data = file.read()

    repeat0_match = re.search(r'@   repeat0:\s*(\d+)', data)
    repeat0 = int(repeat0_match.group(1)) if repeat0_match else None
    
    header_line = re.search(r'@@(.+)', data).group(1)
    headers = re.split(r'\s+', header_line.strip())

    sets = re.split(r'@@@-------PC\[14:12\]=(\d+)-------', data)[1:]
    
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
    df['PC[14:12]'] = set_ids
    df['BrClear'] = df['BrClear'].astype(int)
    grouped = df.groupby('PC[14:12]').agg({
        'BrClear': 'mean'
    }).reset_index()
    btb_miss_df = pd.DataFrame(grouped)
    btb_miss_df.columns = ['PC[14:12]', 'BrClear']
    # max_br_clear_index = btb_miss_df['BrClear'].idxmax()
    # pc_14to12 = btb_miss_df.loc[max_br_clear_index, 'PC[14:12]']
    return btb_miss_df

# %%
step1_result_file=f"./results_step1.out"
btb_miss_df = parse_pc_14to12(step1_result_file)
max_row = btb_miss_df.loc[btb_miss_df['BrClear'].idxmax()]
pc_14to12 = max_row['PC[14:12]']
br_clear = max_row['BrClear']
print(int(pc_14to12), int(br_clear), sep=',')