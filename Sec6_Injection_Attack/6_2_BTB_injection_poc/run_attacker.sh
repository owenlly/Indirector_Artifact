#!/bin/bash

PMC_DIR=../../utils/src_pmc

(cd $PMC_DIR && . vars.sh)

# Read coreID from input
read -p "Assign a core-ID for the attacker ( 0 ~ (2*num of P-cores)-1 ): " coreID

# Performance Counters
cts=320,205,206

# Generate linker script
sec_attacker_ibranch_addr=0x100c60c00
sec_inject_target_addr=0x104f00000
link_script_file=script_attacker.ld
ld --verbose > $link_script_file
python3 gen_linker_script.py $link_script_file attacker $sec_inject_target_addr $sec_attacker_ibranch_addr

python3 PHR_maker.py attacker PHR0 184
python3 PHR_maker.py attacker PHR1 384

# Compile the attacker
nasm -f elf64 -o b64_attacker.o -i$PMC_DIR \
  -Dcounters=$cts \
  -Dsec_attacker_ibranch_addr=$sec_attacker_ibranch_addr \
  -Ppoc_attacker.nasm \
  $PMC_DIR/TemplateB64_infinite.nasm
g++ -T $link_script_file -z noexecstack -no-pie -flto -m64 $PMC_DIR/PMCTestA.cpp b64_attacker.o -o x_attacker -lpthread -lrt

# Run the attacker on core No.$coreID
echo "Running the attacker on Core No.$coreID..."
taskset -c $coreID ./x_attacker &