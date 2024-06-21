#!/bin/bash

mode="$1"
if [ "$mode" == "performance" ]; then
    echo "Turn on CPU performance mode..."
    for cpu in $(find /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor); do
        sudo bash -c "echo 'performance' > $cpu"
    done
elif [ "$mode" == "powersave" ]; then
    echo "Turn on CPU powersave mode..."
    for cpu in $(find /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor); do
        sudo bash -c "echo 'powersave' > $cpu"
    done
else
    echo "Cannot recognize mode..."
fi