#!/bin/bash

mode="$1"
if [ "$mode" == "off" ]; then
    echo -e "Disable CPU SMT..."
    sudo bash -c "echo off > /sys/devices/system/cpu/smt/control"
elif [ "$mode" == "on" ]; then
    echo -e "Enable CPU SMT..."
    sudo bash -c "echo on > /sys/devices/system/cpu/smt/control"
else
    echo "Cannot recognize mode..."
fi