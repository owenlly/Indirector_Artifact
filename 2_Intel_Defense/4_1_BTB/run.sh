#!/bin/bash

usage() {
    echo "Usage: $0 mode=run/asm defense=IBRS/STIBP/IBPB [num_dbranch=VALUE] [num_cbranch=VALUE] [num_ibranch=VALUE] [core_id=VALUE] [perf_cts=VALUE]"
}

if [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

#default value
mode="run"
core_id=0
perf_cts=211,205,206
defense=
num_dbranch=4
num_cbranch=5
num_ibranch=6

for arg in "$@"; do
    key=$(echo $arg | cut -f1 -d=)
    value=$(echo $arg | cut -f2 -d=)

    case $key in
        defense)
            if [[ "$value" == "IBRS" || "$value" == "STIBP" || "$value" == "IBPB" ]]; then
                defense=$value
            else
                echo "Error: mode must be one of 'IBRS', 'STIBP', or 'IBPB'."
                usage
                exit 1
            fi
            ;;
        num_dbranch)
            num_dbranch=$value
            ;;
        num_cbranch)
            num_cbranch=$value
            ;;
        num_ibranch)
            num_ibranch=$value
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

if [ -z "$defense" ]; then
    echo "Error: The 'defense' parameter is required."
    usage
    exit 1
fi

x_file=x_test
if [[ "$mode" == "run" ]]; then
    output_file=results.out
else
    output_file=$x_file.asm
fi

if [[ "$defense" == "IBRS" ]]; then
    ibrs=1
    stibp=0
    ibpb=0
elif [[ "$defense" == "STIBP" ]]; then
    ibrs=0
    stibp=1
    ibpb=0
else
    ibrs=0
    stibp=0
    ibpb=1
fi

now="$(date)"
echo "Running in mode: $mode"
echo "Experiment date and time: $now" > $output_file
echo "Basic options - defense: $defense, num_dbranch: $num_dbranch, num_cbranch: $num_cbranch, num_ibranch: $num_ibranch, core_id: $core_id, perf_cts: $perf_cts, output_file: $output_file" | tee -a $output_file

repeat1_input=1000
PMC_DIR=../../utils/src_pmc
(cd $PMC_DIR && . vars.sh)
g++ -O2 -c -m64 -oa64.o $PMC_DIR/PMCTestA.cpp
nasm -f elf64 -o b64.o -i$PMC_DIR \
    -Dcounters=$perf_cts \
    -Dibrs=$ibrs \
    -Dstibp=$stibp \
    -Dibpb=$ibpb \
    -Dnum_dbranch=$num_dbranch \
    -Dnum_cbranch=$num_cbranch \
    -Dnum_ibranch=$num_ibranch \
    -Dcore_id=$core_id \
    -Drepeat1_input=$repeat1_input \
    -Pdefense_test_BTB.nasm \
    $PMC_DIR/TemplateB64.nasm
g++ -no-pie -flto -m64 a64.o b64.o -o$x_file -lpthread

if [[ "$mode" == "run" ]]; then
    echo "Performing run mode operations..."
    echo -e "\n@   repeat1: $repeat1_input" >> $output_file
    echo -e "\n@@   Clock     BrClear     BrIndir     BrMispInd" >> $output_file
    taskset -c $core_id ./$x_file >> $output_file
    python3 parse.py
else
    echo "Performing asm mode operations..."
    objdump -d ./$x_file > $output_file
fi
