#!/bin/bash

usage() {
    echo "Usage: $0 mode=run/asm t0_branch_num=VALUE core_assign=cross/same [perf_cts=VALUE]"
}

if [ "$#" -lt 1 ]; then
    usage
    exit 1
fi

#default value
mode="run"s
perf_cts=204,211
t0_branch_num=
core_assign=

for arg in "$@"; do
    key=$(echo $arg | cut -f1 -d=)
    value=$(echo $arg | cut -f2 -d=)

    case $key in
        t0_branch_num)
            t0_branch_num=$value
            ;;
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

if [ -z "$t0_branch_num" ]; then
    echo "Error: The 't0_branch_num' parameter is required."
    usage
    exit 1
fi

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
echo "Basic options - t0_branch_num: $t0_branch_num, perf_cts: $perf_cts, output_file: $output_file" | tee -a $output_file

sec_branch_0_t0_addr=0x100000000
sec_branch_1_t0_addr=0x200000000
sec_branch_t1_addr=0x300000000
link_script_file=script.ld
ld --verbose > $link_script_file
python3 gen_linker_script.py $link_script_file $sec_branch_0_t0_addr $sec_branch_1_t0_addr $sec_branch_t1_addr

PMC_DIR=../../utils/src_pmc
(cd $PMC_DIR && . vars.sh)
g++ -O2 -c -m64 -oa64.o $PMC_DIR/PMCTestA_smt.cpp
nasm -f elf64 -o b64.o -i$PMC_DIR \
    -Dcounters=$perf_cts \
    -Dt0_branch_num=$t0_branch_num \
    -Dsec_branch_0_t0_addr=$sec_branch_0_t0_addr \
    -Dsec_branch_1_t0_addr=$sec_branch_1_t0_addr \
    -Dsec_branch_t1_addr=$sec_branch_t1_addr \
    -Dassign_same=$assign_same \
    -Dassign_cross=$assign_cross \
    -PBTB_core_id_xthread.nasm \
    $PMC_DIR/TemplateB64_smt.nasm
g++ -T $link_script_file -z noexecstack -no-pie -flto -m64 a64.o b64.o -o$x_file -lpthread

if [[ "$mode" == "run" ]]; then
    echo "Performing run mode operations..."
    echo -e "\n@@   Clock     BrRetired     BrClear" >> $output_file
    ./$x_file >> $output_file
    python3 parse.py
else
    echo "Performing asm mode operations..."
    objdump -d ./$x_file > $output_file
fi
