#!/bin/bash

# kill all the attacker processes
if pgrep -f x_attacker > /dev/null; then
  pkill -f x_attacker
fi
