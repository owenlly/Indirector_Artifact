#!/bin/bash

usage() {
    echo "Usage: $0 mode=run/asm core_assign=cross/same [perf_cts=VALUE]"
}

if [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

#default value
mode="run"
core_assign=
perf_cts=320,205,206

for arg in "$@"; do
    key=$(echo $arg | cut -f1 -d=)
    value=$(echo $arg | cut -f2 -d=)

    case $key in
        core_assign)
            if [[ "$value" == "cross" || "$value" == "same" ]]; then
                core_assign=$value
            else
                echo "Error: mode must be one of 'cross' or 'same'."
                usage
                exit 1
            fi
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
        perf_cts)
            perf_cts=$value
            ;;
        *)
            echo "Warning: Ignoring unrecognized option '$key'."
            ;;
    esac
done

if [ -z "$core_assign" ]; then
    echo "Error: The 'core_assign' parameter is required."
    usage
    exit 1
fi

x_file=x_test
if [[ "$mode" == "run" ]]; then
    output_file=results.out
else
    output_file=$x_file.asm
fi

if [[ "$core_assign" == "cross" ]]; then
    assign_same=0
    assign_cross=1
else
    assign_same=1
    assign_cross=0
fi

now="$(date)"
echo "Running in mode: $mode"
echo "Experiment date and time: $now" > $output_file
echo "Basic options - core_assign: $core_assign, perf_cts: $perf_cts, output_file: $output_file" | tee -a $output_file

repeat1_input=1000
PMC_DIR=../../utils/src_pmc
(cd $PMC_DIR && . vars.sh)
nasm -f elf64 -o b64.o -i$PMC_DIR \
    -Dcounters=$perf_cts \
    -Dassign_same=$assign_same \
    -Dassign_cross=$assign_cross \
    -Drepeat1_input=$repeat1_input \
    -PIBP_core_id_xthread.nasm \
    $PMC_DIR/TemplateB64_smt.nasm

if [[ "$core_assign" == "cross" ]]; then
    g++ -O2 -c -m64 -oa64.o $PMC_DIR/PMCTestA_smt.cpp
else
    g++ -O2 -c -m64 -oa64.o $PMC_DIR/PMCTestA_fixed_core.cpp
fi

g++ -no-pie -flto -m64 a64.o b64.o -o$x_file -lpthread -lrt

if [[ "$mode" == "run" ]]; then
    echo "Performing run mode operations..."
    echo -e "\n@   repeat1: $repeat1_input" >> $output_file
    echo -e "\n@@   Clock     L2_Miss     BrIndir     BrMispInd" >> $output_file
    ./$x_file >> $output_file
    python3 parse.py
else
    echo "Performing asm mode operations..."
    objdump -d ./$x_file > $output_file
fi
