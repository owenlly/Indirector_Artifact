#!/bin/bash

usage() {
    echo "Usage: $0 mode=run/asm evict_ibp=true/false [inject_btb=true/false] [core_id=VALUE] [perf_cts=VALUE]"
}

if [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

#default value
mode="run"
core_id=0
perf_cts=320,205,206
evict_ibp=
inject_btb=true

for arg in "$@"; do
    key=$(echo $arg | cut -f1 -d=)
    value=$(echo $arg | cut -f2 -d=)

    case $key in
        evict_ibp)
            if [[ "$value" == "true" || "$value" == "false" ]]; then
                evict_ibp=$value
            else
                echo "Error: evict_ibp must be one of 'true' or 'false'."
                usage
                exit 1
            fi
            ;;
        inject_btb)
            if [[ "$value" == "true" || "$value" == "false" ]]; then
                inject_btb=$value
            else
                echo "Error: inject_btb must be one of 'true' or 'false'."
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


if [[ "$inject_btb" == "true" ]]; then
    input_inject_btb=1
else
    input_inject_btb=0
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
echo "Basic options - evict_ibp: $evict_ibp, inject_btb: $inject_btb, core_id: $core_id, perf_cts: $perf_cts, output_file: $output_file" | tee -a $output_file

# Generate linker script
sec_victim_ibranch_addr=0x8000000
sec_malicious_gadget_addr=0x4f00000
sec_attacker_ibranch_addr=0x100850c00
sec_inject_target_addr=0x104f00000
link_script_file=script.ld
ld --verbose > $link_script_file
python3 gen_linker_script.py $link_script_file $sec_victim_ibranch_addr $sec_malicious_gadget_addr $sec_attacker_ibranch_addr $sec_inject_target_addr 

python3 PHR_maker.py victim PHR0 184
python3 PHR_maker.py victim PHR1 384
python3 PHR_maker.py attacker PHR0 184
python3 PHR_maker.py attacker PHR1 384
PMC_DIR=../../utils/src_pmc
secret=4
index=4
repeat1_input=1000
(cd $PMC_DIR && . vars.sh)
g++ -O2 -c -m64 -oa64.o $PMC_DIR/PMCTestA.cpp
nasm -f elf64 -o b64.o -i$PMC_DIR \
    -Dcounters=$perf_cts \
    -Devict_ibp=$input_evict_ibp \
    -Dinject_btb=$input_inject_btb \
    -Dsec_attacker_ibranch_addr=$sec_attacker_ibranch_addr \
    -Dindex=$index \
    -Dsecret=$secret \
    -Drepeat1_input=$repeat1_input \
    -Ppoc_BTB_injection.nasm \
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
