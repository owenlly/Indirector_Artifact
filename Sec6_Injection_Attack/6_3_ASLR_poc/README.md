# Breaking ASLR and Enable BTB Injection

Resources needed: 1 human-minute + 30 compute-minutes

To reproduce results of Section 6.3 in the paper:
```
Usage: mode=run/asm [core_id=VALUE] [perf_cts=VALUE]
```

In the PoC, we emulate the ASLR by randomizing ``PC[46:12]`` of the victim indirect branch.
The whole process is divided into 3 steps (details described in the paper):
1. Break ``PC[14:12]``
2. Break ``PC[23:15]``
3. Break ``PC[31:24]`` and enable BTB injection

To run it:
```
./run.sh mode=run
```

An example of success from parsing results:
```
Attacker Step 1 - PC[14:12]: 4, BrClear: 2290
Attacker Step 2 - PC[23:15]: 218, BrClear: 17
Attacker Step 3 - PC[31:24]: 52, L2_Miss: 73, BTB injection succeeds!
Attack succeeds! PC[31:12] of victim branch is 0x346D4!
Total compile time: 1051.975 sec
Total exec time: 4.172 sec
```

An example of failure from parsing results:
```
Attacker Step 1 - PC[14:12]: 6, BrClear: 3459
Attacker Step 2 - PC[23:15]: 392, BrClear: 50
Attack fails...
```