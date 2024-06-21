#!/bin/bash

ROOT_DIR=$(pwd)

(cd "$ROOT_DIR/utils/src_driver" && sudo make install)

(cd "$ROOT_DIR/utils/src_pmc" && ./init64.sh)

(cd "$ROOT_DIR/utils/script" && ./set_performance.sh performance && ./set_prefetcher.sh off)