#!/bin/bash

usage() {
    echo "Usage: $0 mode=run/compile [begin_pc=VALUE] [end_pc=VALUE] [core_id=VALUE] [perf_cts=VALUE]"
}

if [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

#default value
mode="run"
core_id=0
perf_cts=205,206
begin_pc=0
end_pc=1023

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
        begin_pc)
            begin_pc=$value
            ;;
        end_pc)
            end_pc=$value
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
victim_set0=184 #pc 855
victim_set1=384 #pc 536
repeat0_input=3
output_file=results.out
(cd $PMC_DIR && . vars.sh)
g++ -O2 -c -m64 -oa64_tag_locator.o $PMC_DIR/PMCTestA_poc.cpp

if [[ "$mode" == "run" ]]; then
    echo "Performing run mode operations..." 
    echo -e "\n@   repeat0: $repeat0_input" > $output_file
    echo -e "\n@@   Clock     BrIndir     BrMispInd" >> $output_file
    for (( i=0; i<2; ++i ))
    do
        for (( j=$begin_pc; j<=$end_pc; ++j ))
        do  
            index=$(($i * 1024 + $j))
            echo -e "@@@-------Tag #$index-------\n" >> $output_file
            taskset -c $core_id ./x_files/x_tag_locator_$index >> $output_file
        done
    done
    python3 parse.py
elif [[ "$mode" == "compile" ]]; then
    mkdir -p ./x_files
    python3 PHR_maker.py victim PHR0 $victim_set0
    python3 PHR_maker.py victim PHR1 $victim_set1
    for (( i=0; i<2; ++i ))
    do
        if [[ $i -eq 1 ]]; then
            flipped_set0=$(($victim_set0 ^ 1026))
            flipped_set1=$(($victim_set1 ^ 1026))
            python3 PHR_maker.py attacker PHR0 $flipped_set0
            python3 PHR_maker.py attacker PHR1 $flipped_set1
        else
            python3 PHR_maker.py attacker PHR0 $victim_set0
            python3 PHR_maker.py attacker PHR1 $victim_set1
        fi
        for (( pc_15_to_6=$begin_pc; pc_15_to_6<=$end_pc; ++pc_15_to_6 ))
        do  
            index=$(($i * 1024 + pc_15_to_6))
            echo -e "compiling scanning for tag $index..."
            nasm -f elf64 -o b64_tag_locator.o -i$PMC_DIR \
                -Dcounters=$perf_cts \
                -Drepeat0_input=$repeat0_input \
                -Dpc_15_to_6=$pc_15_to_6 \
                -Ptag_locator_poc.nasm \
                $PMC_DIR/TemplateB64.nasm
            g++ -no-pie -flto -m64 a64_tag_locator.o b64_tag_locator.o \
                -o ./x_files/x_tag_locator_$index -lpthread
        done
    done
fi