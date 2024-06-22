#!/bin/bash

usage() {
    echo "Usage: $0 mode=run/asm num_ibranch=VALUE [core_id=VALUE] [perf_cts=VALUE]"
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

for arg in "$@"; do
    key=$(echo $arg | cut -f1 -d=)
    value=$(echo $arg | cut -f2 -d=)

    case $key in
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

if [ -z "$num_ibranch" ]; then
    echo "Error: The 'num_ibranch' parameter is required."
    usage
    exit 1
fi

x_file=x_test
if [[ "$mode" == "run" ]]; then
    output_file=results.out
else
    output_file=$x_file.asm
fi

now="$(date)"
echo "Running in mode: $mode"
echo "Experiment date and time: $now" > $output_file
echo "Basic options - num_ibranch: $num_ibranch, core_id: $core_id, perf_cts: $perf_cts, output_file: $output_file" | tee -a $output_file

PMC_DIR=../../utils/src_pmc
(cd $PMC_DIR && . vars.sh)
g++ -O2 -c -m64 -oa64.o $PMC_DIR/PMCTestA.cpp
nasm -f elf64 -o b64.o -i$PMC_DIR \
    -Dcounters=$perf_cts \
    -Dnum_ibranch=$num_ibranch \
    -PIBP_associativity_lite.nasm \
    $PMC_DIR/TemplateB64.nasm
g++ -no-pie -flto -m64 a64.o b64.o -o$x_file -lpthread

if [[ "$mode" == "run" ]]; then
    echo "Performing run mode operations..."
    echo -e "\n@@   Clock     BrIndir     BrMispInd" >> $output_file
    taskset -c $core_id ./$x_file >> $output_file
else
    echo "Performing asm mode operations..."
    objdump -d ./$x_file > $output_file
fi

