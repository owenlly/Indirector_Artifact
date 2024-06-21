import sys
import random

if len(sys.argv) != 5:
    print("Usage: python modify_link_script.py <link_script_file> <PC[31:24]> <PC[23:15]> <sec_victim_ibranch_addr>")
    sys.exit(1)

link_script_file = sys.argv[1]
pc_31to24 = sys.argv[2]
pc_23to15 = sys.argv[3]
sec_victim_ibranch_addr = sys.argv[4]

sec_aliased_dbranch_addr = (1 << 28) | (int(pc_23to15) << 15)
sec_attacker_ibranch_addr = (1 << 32) | (int(pc_31to24) << 24) | (int(pc_23to15) << 15)

with open(link_script_file, 'r') as file:
    lines = file.readlines()

start_index = None
end_index = None
for i, line in enumerate(lines):
    if '====' in line.strip():
        if start_index is None:
            start_index = i + 1
        else:
            end_index = i

if start_index is not None and end_index is not None:
    content = lines[start_index:end_index]

    last_brace_index = None
    for i in range(len(content) - 1, -1, -1):
        if '}' in content[i]:
            last_brace_index = i
            break

    if last_brace_index is not None:
        insert_lines = [
            f"  . = {hex(sec_aliased_dbranch_addr)};\n",
            "  .sec_aliased_dbranch : { *(.sec_aliased_dbranch) }\n"
            "\n",
            f"  . = {hex(sec_attacker_ibranch_addr)};\n",
            "  .sec_attacker_ibranch : { *(.sec_attacker_ibranch) }\n"
            "\n",
            f"  . = {sec_victim_ibranch_addr};\n",
            "  .sec_victim_ibranch : { *(.sec_victim_ibranch) }\n"
        ] 
        content = content[:last_brace_index] + insert_lines + content[last_brace_index:]

    with open(link_script_file, 'w') as file:
        file.writelines(content)
    
else:
    print("Error: The format of the link script file does not meet the expected pattern.")
