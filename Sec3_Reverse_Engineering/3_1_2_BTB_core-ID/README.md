# Core-ID in BTB

Resources needed: 1 human-minute + 1 compute-minute

To reproduce results of Section 3.1.2 in the paper:
```
Usage: ./run.sh mode=run/asm t0_branch_num=VALUE core_assign=cross/same [perf_cts=VALUE]
```

Parsing output example:
```
...
Parsing results:
Branch misprediction rate of t0 test branches: 0.08%
```

* Assign two aliased branches on the same SMT core:
    ```
    ./run.sh mode=run t0_branch_num=11 core_assign=same
    ```
    **Expected output:** ~0% misprediction on t0 test branches
  
    There are 11 available ways in the BTB set. Two aliased branches share the BTB entry.


* Assign two aliased branches on two different SMT cores:
    ```
    ./run.sh mode=run t0_branch_num=10 core_assign=cross
    ```
    **Expected output:** ~0% misprediction on t0 test branches
    
    ```
    ./run.sh mode=run t0_branch_num=11 core_assign=cross
    ```
    **Expected output:** >10% misprediction on t0 test branches
  
    There are 10 available ways in the BTB set. Two aliased branches use separate BTB entries within the same set.
