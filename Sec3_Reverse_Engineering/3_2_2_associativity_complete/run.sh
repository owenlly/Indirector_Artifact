#!/bin/bash

usage() {
    echo "Usage: $0 mode=run/asm num_ibranch=VALUE phr_flip_bit=VALUE [core_id=VALUE] [perf_cts=VALUE]"
}

if [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

#default value
mode="run"
core_id=0
perf_cts=205,206
num_ibranch=
phr_flip_bit=

for arg in "$@"; do
    key=$(echo $arg | cut -f1 -d=)
    value=$(echo $arg | cut -f2 -d=)

    case $key in
        num_ibranch)
            num_ibranch=$value
            ;;
        phr_flip_bit)
            phr_flip_bit=$value
            ;;
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

if [ -z "$num_ibranch" ]; then
    echo "Error: The 'num_ibranch' parameter is required."
    usage
    exit 1
fi

if [ -z "$phr_flip_bit" ]; then
    echo "Error: The 'phr_flip_bit' parameter is required."
    usage
    exit 1
fi

x_file=x_test
if [[ "$mode" == "run" ]]; then
    output_file=results.out
else
    output_file=$x_file.asm
fi

if [ $((phr_flip_bit % 2)) -eq 0 ]; then
    is_even=1
else
    is_even=0
fi

if [ $phr_flip_bit -lt 16 ]; then
    is_lower_bit=1
else
    is_lower_bit=0
fi

if [ $phr_flip_bit -eq 0 ] || [ $phr_flip_bit -eq 1 ]; then
    is_lowest=1
else
    is_lowest=0
fi

now="$(date)"
echo "Running in mode: $mode"

PMC_DIR=../../utils/src_pmc
repeat0_input=5
(cd $PMC_DIR && . vars.sh)
g++ -O2 -c -m64 -oa64.o $PMC_DIR/PMCTestA.cpp

if [[ "$mode" == "run" ]]; then
    echo "Performing run mode operations..."
    mkdir -p ./results
    output_file=./results/results_$phr_flip_bit.out
    echo -e "\n@   repeat0: $repeat0_input" > $output_file
    echo -e "\n@@   Clock     BrIndir     BrMispInd" >> $output_file
    for (( i=1; i<=$num_ibranch; ++i ))
    do  
        # echo -e "\n---------- Start: Test No. $i ----------" >> results.csv
        # echo -e "Number of branches with same PHR: $i\n" >> results.csv
        # echo -e "   Clock     BrIndir     BrMispInd" >> $output_file
        nasm -f elf64 -o b64.o -i$PMC_DIR \
            -Dcounters=$perf_cts \
            -Dnum_ibranch=$i \
            -Dphr_shift_len=$((phr_flip_bit / 2)) \
            -Dis_lower_bit=$is_lower_bit \
            -Dis_lowest=$is_lowest \
            -Dis_even=$is_even \
            -PIBP_associativity_complete.nasm \
            -Drepeat0_input=$repeat0_input \
            $PMC_DIR/TemplateB64.nasm
        g++ -no-pie -flto -m64 a64.o b64.o -o$x_file -lpthread
        taskset -c $core_id ./$x_file >> $output_file
        # echo -e "---------- End: Test No. $i ----------" >> results.csv
    done
else
    echo "Performing asm mode operations..."
    nasm -f elf64 -o b64.o -i$PMC_DIR \
        -Dcounters=$perf_cts \
        -Dnum_ibranch=$num_ibranch \
        -Dphr_flip_bit=$phr_flip_bit \
        -Dis_lower_bit=$is_lower_bit \
        -Dis_lowest=$is_lowest \
        -Dis_even=$is_even \
        -Dis_odd=$is_odd \
        -Drepeat0_input=$repeat0_input \
        -PIBP_associativity_complete.nasm \
        $PMC_DIR/TemplateB64.nasm
    g++ -no-pie -flto -m64 a64.o b64.o -o$x_file -lpthread
    objdump -d ./$x_file > $output_file
fi

