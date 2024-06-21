# Breaking ASLR and Enable BTB Injection

To reproduce results of Section 6.3 in the paper:
```
Usage: mode=run/asm [core_id=VALUE] [perf_cts=VALUE]
```

In the PoC, we emulate the ASLR by randomizing ``PC[46:12]`` of the victim indirect branch.
The whole process is divided into 3 steps (detail descriptions are in the paper):
1. Break ``PC[14:12]``
2. Break ``PC[23:15]``
3. Break ``PC[31:24]`` and enable BTB injection

To run it:
```
./run.sh mode=run
```

An example of success from parsing results:
```
Attacker Step 1 - PC[14:12]: 5, BrClear: 2407
Attacker Step 2 - PC[23:15]: 86, BrClear: 34
Attacker Step 3 - PC[31:24]: 34, L2_Miss: 83
```

