#!/bin/bash

ROOT_DIR=$(pwd)

sudo modprobe msr

(cd "$ROOT_DIR/utils/src_driver" && sudo make install)

(cd "$ROOT_DIR/utils/src_pmc" && ./init64.sh)

(cd "$ROOT_DIR/utils/script" && ./set_performance.sh performance && ./set_prefetcher.sh off && ./set_smt.sh on && ./set_aslr.sh off)

KERNELDIR=/lib/modules/`uname -r`
echo "Kernel module MSRdrv is permanently installed in $KERNELDIR/extra! Use ./utils/src_driver/uninstall.sh to uninstall it."