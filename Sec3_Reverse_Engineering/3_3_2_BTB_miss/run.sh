#!/bin/bash

usage() {
    echo "Usage: $0 mode=run/asm evict_ibp=true/false measure=branch/data/next_inst [core_id=VALUE] [perf_cts=VALUE]"
}

if [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

#default value
mode="run"
core_id=0
perf_cts=320,205,206
measure=
evict_ibp=

for arg in "$@"; do
    key=$(echo $arg | cut -f1 -d=)
    value=$(echo $arg | cut -f2 -d=)

    case $key in
        measure)
            if [[ "$value" == "branch" || "$value" == "data" || "$value" == "next_inst" ]]; then
                measure=$value
            else
                echo "Error: mode must be one of 'branch', 'data', or 'next_inst'."
                usage
                exit 1
            fi
            ;;
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

if [ -z "$measure" ]; then
    echo "Error: The 'measure' parameter is required."
    usage
    exit 1
fi

x_file=x_test
if [[ "$mode" == "run" ]]; then
    output_file=results.out
else
    output_file=$x_file.asm
fi

if [[ "$measure" == "branch" ]]; then
    measure_ibranch=1
    measure_data=0
    measure_inst=0
elif [[ "$measure" == "data" ]]; then
    measure_ibranch=0
    measure_data=1
    measure_inst=0
else
    measure_ibranch=0
    measure_data=0
    measure_inst=1
fi

if [[ "$evict_ibp" == "true" ]]; then
    input_evict_ibp=1
else
    input_evict_ibp=0
fi

now="$(date)"
echo "Running in mode: $mode"
echo "Experiment date and time: $now" > $output_file
echo "Basic options - evict_ibp: $evict_ibp, measure: $measure, core_id: $core_id, perf_cts: $perf_cts, output_file: $output_file" | tee -a $output_file

PMC_DIR=../../utils/src_pmc
repeat1_input=1000
(cd $PMC_DIR && . vars.sh)
g++ -O2 -c -m64 -oa64.o $PMC_DIR/PMCTestA.cpp
nasm -f elf64 -o b64.o -i$PMC_DIR \
    -Dcounters=$perf_cts \
    -Dinput_evict_ibp=$input_evict_ibp \
    -Dmeasure_ibranch=$measure_ibranch \
    -Dmeasure_data=$measure_data \
    -Dmeasure_inst=$measure_inst \
    -Drepeat1_input=$repeat1_input \
    -PBTB_miss.nasm \
    $PMC_DIR/TemplateB64.nasm
g++ -no-pie -flto -m64 a64.o b64.o -o$x_file -lpthread

if [[ "$mode" == "run" ]]; then
    echo "Performing run mode operations..."
    echo -e "\n@   repeat1: $repeat1_input" >> $output_file
    echo -e "\n@@   Clock     L2_Miss     BrIndir     BrMispInd" >> $output_file
    taskset -c $core_id ./$x_file >> $output_file
    python3 parse.py
else
    echo "Performing asm mode operations..."
    objdump -d ./$x_file > $output_file
fi
