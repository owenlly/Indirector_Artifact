# BTB Hit + IBP Hit/Miss in IBP

To reproduce results of Section 3.3 (Table 2) in the paper:
```
Usage: ./run.sh mode=run/asm evict_ibp=true/false [core_id=VALUE] [perf_cts=VALUE]
```

Parsing output example:
```
...
Parsing results:
Indirect branch misprediction rate: 50.36%
```

* BTB Hit + IBP Hit:
    ```
    ./run.sh mode=run evict_ibp=false
    ```
    **Expected output:** ~0% misprediction


* BTB Hit + IBP Miss:
    ```
    ./run.sh mode=run evict_ibp=true
    ```
    **Expected output:** ~50% misprediction
