# BTB Miss + IBP Hit/Miss in IBP

To reproduce results of Section 3.3 (Table 2) in the paper:
```
Usage: ./run.sh mode=run/asm evict_ibp=true/false measure=branch/data/next_inst [core_id=VALUE] [perf_cts=VALUE]
```

* ``measure=branch`` to measure the misprediction of the indirect branch

* ``measure=data`` to measure if the load instruction right after the indirect branch is executed

* ``measure=next_inst`` to measure if the load instruction right after the indirect branch is brought to instruction cache


Parsing output example:
```
...
Parsing results:
Indirect branch misprediction rate: 97.06%
...
Parsing results:
Cache Hit Rate: 0.00%
No cache hit detected.
```

* BTB Miss + IBP Hit/Miss:
    ```
    ./run.sh mode=run evict_ibp=true/false measure=branch
    ```
    **Expected output:** >90% misprediction

    ```
    ./run.sh mode=run evict_ibp=true/false measure=data
    ```
    **Expected output:** "No cache hit detected."

    ```
    ./run.sh mode=run evict_ibp=true/false measure=next_inst
    ```
    **Expected output:** "Cache hit detected!"