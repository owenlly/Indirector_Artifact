#!/bin/bash

mode="$1"
if [ "$mode" == "off" ]; then
    echo -e "Disable ASLR..."
    sudo bash -c "echo 0 > /proc/sys/kernel/randomize_va_space"
elif [ "$mode" == "on" ]; then
    echo -e "Enable ASLR..."
    sudo bash -c "echo 2 > /proc/sys/kernel/randomize_va_space"
else
    echo "Cannot recognize mode..."
fi