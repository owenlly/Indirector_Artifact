#!/bin/bash

mode="$1"
if [ "$mode" == "off" ]; then
    echo -e "Disable CPU prefetcher..."
    sudo bash -c "wrmsr -a 0x1a4 0xf"
elif [ "$mode" == "on" ]; then
    echo -e "Enable CPU prefetcher..."
    sudo bash -c "wrmsr -a 0x1a4 0x0"
else
    echo "Cannot recognize mode..."
fi