#!/bin/bash

usage() {
    echo "Usage: $0 mode=run/compile [num_locator_branch=VALUE] [begin_set=VALUE] [end_set=VALUE] [core_id=VALUE] [perf_cts=VALUE]"
}

if [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

#default value
mode="run"
core_id=0
perf_cts=205,206
begin_set=0
end_set=511
num_locator_branch=1

for arg in "$@"; do
    key=$(echo $arg | cut -f1 -d=)
    value=$(echo $arg | cut -f2 -d=)
    case $key in
        mode)
            if [[ "$value" == "run" || "$value" == "compile" ]]; then
                mode=$value
            else
                echo "Error: mode must be one of 'run' or 'compile'."
                usage
                exit 1
            fi
            ;;
        num_locator_branch)
            num_locator_branch=$value
            ;;
        begin_set)
            begin_set=$value
            ;;
        end_set)
            end_set=$value
            ;;
        core_id)
            core_id=$value
            ;;
        perf_cts)
            perf_cts=$value
            ;;
        output_file)
            output_file=$value
            ;;
        *)
            echo "Warning: Ignoring unrecognized option '$key'."
            ;;
    esac
done

PMC_DIR=../../utils/src_pmc
repeat0_input=3
output_file=results.out
(cd $PMC_DIR && . vars.sh)
g++ -O2 -c -m64 -oa64_index_locator.o $PMC_DIR/PMCTestA_poc.cpp

if [[ "$mode" == "run" ]]; then
    total_exec_time=0
    echo "Performing run mode operations..." 
    echo -e "\n@   repeat0: $repeat0_input" > $output_file
    echo -e "\n@@   Clock     BrIndir     BrMispInd" >> $output_file
    for (( i=$begin_set; i<=$end_set; ++i ))
    do  
        echo -e "@@@-------IBP set #$i-------\n" >> $output_file
        start_time=$(date +%s%N)
        taskset -c $core_id ./x_files/x_index_locator_$i >> $output_file
        end_time=$(date +%s%N)
        elapsed=$((end_time - start_time))
        elapsed_sec=$(echo "scale=3; $elapsed / 1000000000" | bc)
        total_exec_time=$(echo "scale=3; $total_exec_time + $elapsed_sec" | bc)
    done
    python3 parse.py
    echo "Total exec time: $total_exec_time sec"
elif [[ "$mode" == "compile" ]]; then
    mkdir -p ./x_files
    python3 PHR_maker.py victim PHR0 184
    python3 PHR_maker.py victim PHR1 384
    for (( i=$begin_set; i<=$end_set; ++i ))
    do  
        echo -e "compiling scanning for IBP set #$i..."
        if [[ $i == 0 ]]; then  
            python3 PHR_maker.py attacker PHR0 1
        else
            python3 PHR_maker.py attacker PHR0 0
        fi
        python3 PHR_maker.py attacker PHR1 $i
        nasm -f elf64 -o b64_index_locator.o -i$PMC_DIR \
            -Dcounters=$perf_cts \
            -Drepeat0_input=$repeat0_input \
            -Dnum_locator_branch=$num_locator_branch \
            -Pindex_locator_poc.nasm \
            $PMC_DIR/TemplateB64.nasm
        g++ -no-pie -flto -m64 a64_index_locator.o b64_index_locator.o \
            -o ./x_files/x_index_locator_$i -lpthread -lrt
    done
fi