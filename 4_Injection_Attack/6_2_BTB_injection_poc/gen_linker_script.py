import sys
import random

# if len(sys.argv) != 4:
#     print("Usage: python modify_link_script.py <link_script_file> <victim/attacker> <sec_addr_0> <sec_addr_1>")
#     sys.exit(1)

link_script_file = sys.argv[1]
person = sys.argv[2].lower()
sec_addr_0 = sys.argv[3]
if (person == "attacker"):
    sec_addr_1 = sys.argv[4]

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
        if (person == "attacker"):
            insert_lines = [
                f"  . = {sec_addr_0};\n",
                "  .sec_inject_target : { *(.sec_inject_target) }\n"
                "\n",
                f"  . = {sec_addr_1};\n",
                "  .sec_attacker_ibranch : { *(.sec_attacker_ibranch) }\n",
            ]
        elif (person == "victim"):
            insert_lines = [
                f"  . = {sec_addr_0};\n",
                "  .sec_malicious_gadget : { *(.sec_malicious_gadget) }\n"
            ]  
        content = content[:last_brace_index] + insert_lines + content[last_brace_index:]

    with open(link_script_file, 'w') as file:
        file.writelines(content)
    
else:
    print("Error: The format of the link script file does not meet the expected pattern.")
