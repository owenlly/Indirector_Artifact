# Core-ID in IBP

Resources needed: 1 human-minute + 1 compute-minute

To reproduce results of Section 3.2.6 in the paper:
```
Usage: ./run.sh mode=run/asm core_assign=cross/same [perf_cts=VALUE]
```

Parsing output example:
```
...
Parsing results:
Cache Hit Rate: 99.98%
Injection success!
```

* Assign two aliased indirect branches on the same SMT core:
    ```
    ./run.sh mode=run core_assign=same
    ```
    **Expected output:** "Injection success!"


* Assign two aliased indirect branches on two different SMT cores:
    ```
    ./run.sh mode=run core_assign=cross
    ```
    **Expected output:** "Injection fail."
