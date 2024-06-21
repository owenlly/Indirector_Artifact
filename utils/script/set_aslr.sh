#!/bin/bash

mode="$1"
if [ "$mode" == "off" ]; then
    echo -e "Disable ASLR..."
    echo 0 | sudo tee /proc/sys/kernel/randomize_va_space
elif [ "$mode" == "on" ]; then
    echo -e "Enable ASLR..."
    echo 2 | sudo tee /proc/sys/kernel/randomize_va_space
else
    echo "Cannot recognize mode..."
fi