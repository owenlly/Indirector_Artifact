import sys
import random

if len(sys.argv) != 6:
    print("Usage: python modify_link_script.py <link_script_file> <sec_set_PHR_0_addr> <sec_set_PHR_1_addr> <sec_ibranch_0_addr> <sec_ibranch_1_addr>")
    sys.exit(1)

link_script_file = sys.argv[1]
sec_set_PHR_0_addr = sys.argv[2]
sec_set_PHR_1_addr = sys.argv[3]
sec_ibranch_0_addr = sys.argv[4]
sec_ibranch_1_addr = sys.argv[5]

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
            f"  . = {sec_set_PHR_0_addr};\n",
            "  .sec_set_PHR_0 : { *(.sec_set_PHR_0) }\n",
            "\n",
            f"  . = {sec_set_PHR_1_addr};\n",
            "  .sec_set_PHR_1 : { *(.sec_set_PHR_1) }\n",
            "\n",
            f"  . = {sec_ibranch_0_addr};\n",
            "  .sec_ibranch_0 : { *(.sec_ibranch_0) }\n",
            "\n",
            f"  . = {sec_ibranch_1_addr};\n",
            "  .sec_ibranch_1 : { *(.sec_ibranch_1) }\n"
        ]
        content = content[:last_brace_index] + insert_lines + content[last_brace_index:]

    with open(link_script_file, 'w') as file:
        file.writelines(content)
    
else:
    print("Error: The format of the link script file does not meet the expected pattern.")
