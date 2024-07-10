import time
import sys

def main():
    try:
        person = sys.argv[1].lower()
        if person not in ['victim', 'attacker']:
            raise ValueError("First argument must be 'victim' or 'attacker'")
        phr_mode = sys.argv[2].upper()
        if phr_mode not in ['PHR0', 'PHR1']:
            raise ValueError("Second argument must be 'PHR0' or 'PHR1'")
        input_number = int(sys.argv[3])
    except (IndexError, ValueError) as e:
        print("Usage: python script.py [victim/attacker] [PHR0/PHR1] [integer]")
        print(f"Error: {e}")
        return

    if (person == "attacker"):
        BRANCH_NUM = 65
        base = 16
    if (person == "victim"):
        BRANCH_NUM = 65
        base = 52
    phr_value = [0] * BRANCH_NUM
    
    for i in range(11):
        phr_value[base + i] = (input_number >> i) & 1
    
    if (phr_mode == "PHR0"):
        end = 0
    else:
        end = -1
    
    filename = f"SET_{person.upper()}_{phr_mode}.nasm"
    
    with open(filename, 'w') as file:
        file.write(f"%macro SET_{person.upper()}_{phr_mode} 1\n\n")
        file.write(f"\tjmp {person}_{phr_mode}_doublet{BRANCH_NUM-1}_%+ %1\n")
        for i in range(BRANCH_NUM-1, end, -1):
            file.write(f"\talign 1<<16\n")
            file.write(f"\t%rep {16 + (3 - phr_value[i])}\n")
            file.write(f"\t nop\n")
            file.write(f"\t%endrep\n")
            file.write(f"\t{person}_{phr_mode}_doublet{i}_%+ %1:\n")
            
            if (i > 0):
                if phr_value[i] == 3:
                    file.write(f"\t%rep 8\n")
                    file.write(f"\t nop\n")
                    file.write(f"\t%endrep\n")
                else:
                    file.write(f"\talign 1<<3\n")
                
                if (i == 1) and (phr_mode == "PHR0"):
                    if (person == "victim"):
                        file.write(f"\tjmp {person}_set_PHR1_end\n\n")
                    else:
                        file.write(f"\tjmp {person}_set_PHR1_end_%+ i\n\n")
                else:
                    file.write(f"\tjmp {person}_{phr_mode}_doublet{i-1}_%+ %1\n\n")
        
        file.write(f"%endmacro")

if __name__ == "__main__":
    main()
