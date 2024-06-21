#!/bin/bash

usage() {
    echo "Usage: $0 mode=run/asm evict_ibp=true/false [core_id=VALUE] [perf_cts=VALUE]"
}

if [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

#default value
mode="run"
core_id=0
perf_cts=205,206
evict_ibp=

for arg in "$@"; do
    key=$(echo $arg | cut -f1 -d=)
    value=$(echo $arg | cut -f2 -d=)

    case $key in
        evict_ibp)
            if [[ "$value" == "true" || "$value" == "false" ]]; then
                evict_ibp=$value
            else
                echo "Error: mode must be one of 'true' or 'false'."
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

if [ -z "$evict_ibp" ]; then
    echo "Error: The 'evict_ibp' parameter is required."
    usage
    exit 1
fi

if [[ "$evict_ibp" == "true" ]]; then
    input_evict_ibp=1
else
    input_evict_ibp=0
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
echo "Basic options - evict_ibp: $evict_ibp, core_id: $core_id, perf_cts: $perf_cts, output_file: $output_file" | tee -a $output_file

PMC_DIR=../../utils/src_pmc
(cd $PMC_DIR && . vars.sh)
g++ -O2 -c -m64 -oa64.o $PMC_DIR/PMCTestA.cpp
nasm -f elf64 -o b64.o -i$PMC_DIR \
    -Dcounters=$perf_cts \
    -Devict_ibp=$input_evict_ibp \
    -PBTB_hit.nasm \
    $PMC_DIR/TemplateB64.nasm
g++ -no-pie -flto -m64 a64.o b64.o -o$x_file -lpthread

if [[ "$mode" == "run" ]]; then
    echo "Performing run mode operations..."
    echo -e "\n@@   Clock     BrIndir     BrMispInd" >> $output_file
    taskset -c $core_id ./$x_file >> $output_file
    python3 parse.py
else
    echo "Performing asm mode operations..."
    objdump -d ./$x_file > $output_file
fi
