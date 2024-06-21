#!/bin/bash

PMC_DIR=../../utils/src_pmc

(cd $PMC_DIR && . vars.sh)

# Read coreID from input
read -p "Assign a core-ID for the victim ( 0 ~ (2*num of P-cores)-1 ): " coreID

# Read secret from input
read -p "Input a secret for the victim (0 ~ 9): " secret

# Performance Counters
cts=320,205,206

# Generate linker script
sec_malicious_gadget_addr=0x4f00000
link_script_file=script_victim.ld
ld --verbose > $link_script_file
python3 gen_linker_script.py $link_script_file victim $sec_malicious_gadget_addr

python3 PHR_maker.py victim PHR0 184
python3 PHR_maker.py victim PHR1 384

# Generate output file
output_file=results.out
echo -e "     Clock      L2_Miss     BrIndir     BrMispInd" > $output_file

# Reload different memory locations
echo "Running the victim on Core No.$coreID..."
max=10
for (( i=0; i<$max; ++i ))
do
  # Compile the victim
  nasm -f elf64 -o b64_victim.o -i$PMC_DIR \
    -Dcounters=$cts \
    -Dsecret=$secret \
    -Dindex=$i \
    -Ppoc_victim.nasm \
    $PMC_DIR/TemplateB64.nasm

  g++ -T $link_script_file -no-pie -flto -m64 $PMC_DIR/PMCTestA_poc.cpp b64_victim.o -o x_victim -lpthread -lrt

  # Run the victim on core No.$coreID
  taskset -c $coreID ./x_victim >> $output_file
done

python3 parse.py

if pgrep -f x_attacker > /dev/null; then
  pkill -f x_attacker
fi