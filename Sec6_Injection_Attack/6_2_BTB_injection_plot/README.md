# BTB Injection

Resources needed: 1 human-minute + 1 compute-minute

To reproduce results of Figure 13 in the paper:
```
Usage: ./run.sh mode=run/asm evict_ibp=true/false [inject_btb=true/false] [core_id=VALUE] [perf_cts=VALUE]
```

Parsing output example:
```
...
Parsing results:
Cache Hit Rate: 7.56%
Injection success!
```

* IBP Eviction + BTB Injection:
    ```
    ./run.sh mode=run evict_ibp=true inject_btb=true
    ```
    **Expected output:** "Injection success!"

* Only BTB Injection:
    ```
    ./run.sh mode=run evict_ibp=false inject_btb=true
    ```
    **Expected output:** "Injection fail."

* Only IBP Eviction:
    ```
    ./run.sh mode=run evict_ibp=true inject_btb=false
    ```
    **Expected output:** "Injection fail."