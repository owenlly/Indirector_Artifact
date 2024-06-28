#!/bin/bash

usage() {
    echo "Usage: $0 mode=run/asm inject_branch=direct/indirect/none measure=data/target_correct/target_malicious [core_id=VALUE] [perf_cts=VALUE]"
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
inject_branch=

for arg in "$@"; do
    key=$(echo $arg | cut -f1 -d=)
    value=$(echo $arg | cut -f2 -d=)

    case $key in
        inject_branch)
            if [[ "$value" == "direct" || "$value" == "indirect" || "$value" == "none" ]]; then
                inject_branch=$value
            else
                echo "Error: inject_branch must be one of 'direct', 'indirect' or 'none'."
                usage
                exit 1
            fi
            ;;
        measure)
            if [[ "$value" == "data" || "$value" == "target_correct" || "$value" == "target_malicious" ]]; then
                measure=$value
            else
                echo "Error: mode must be one of 'data', 'target_correct', or 'target_malicious'."
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

if [ -z "$inject_branch" ]; then
    echo "Error: The 'inject_branch' parameter is required."
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

if [[ "$measure" == "data" ]]; then
    measure_data=1
    measure_target_correct=0
    measure_target_malicious=0
elif [[ "$measure" == "target_correct" ]]; then
    measure_data=0
    measure_target_correct=1
    measure_target_malicious=0
else
    measure_data=0
    measure_target_correct=0
    measure_target_malicious=1
fi

if [[ "$inject_branch" == "direct" ]]; then
    use_dbranch=1
    use_ibranch=0
elif [[ "$inject_branch" == "indirect" ]]; then
    use_dbranch=0
    use_ibranch=1
else
    use_dbranch=0
    use_ibranch=0
fi

now="$(date)"
echo "Running in mode: $mode"
echo "Experiment date and time: $now" > $output_file
echo "Basic options - inject_branch: $inject_branch, measure: $measure, core_id: $core_id, perf_cts: $perf_cts, output_file: $output_file" | tee -a $output_file

sec_victim_ibranch_addr=0x1000000
sec_attacker_dbranch_addr=0x101000000
sec_attacker_ibranch_addr=0x201000000
link_script_file=script.ld
ld --verbose > $link_script_file
python3 gen_linker_script.py $link_script_file $sec_victim_ibranch_addr $sec_attacker_dbranch_addr $sec_attacker_ibranch_addr

PMC_DIR=../../utils/src_pmc
repeat1_input=1000
(cd $PMC_DIR && . vars.sh)
g++ -O2 -c -m64 -oa64.o $PMC_DIR/PMCTestA.cpp
nasm -f elf64 -o b64.o -i$PMC_DIR \
    -Dcounters=$perf_cts \
    -Dmeasure_data=$measure_data \
    -Dmeasure_target_correct=$measure_target_correct \
    -Dmeasure_target_malicious=$measure_target_malicious \
    -Dsec_attacker_dbranch_addr=$sec_attacker_dbranch_addr \
    -Dsec_attacker_ibranch_addr=$sec_attacker_ibranch_addr \
    -Duse_dbranch=$use_dbranch \
    -Duse_ibranch=$use_ibranch \
    -Drepeat1_input=$repeat1_input \
    -PBTB_branch_type.nasm \
    $PMC_DIR/TemplateB64.nasm
g++ -T $link_script_file -z noexecstack -no-pie -flto -m64 a64.o b64.o -o$x_file -lpthread

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
