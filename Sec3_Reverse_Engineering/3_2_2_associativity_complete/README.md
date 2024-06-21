# TAGE-like Structure of IBP

To reproduce results of Section 3.2.2 in the paper:
```
Usage: ./run.sh mode=run/asm num_ibranch=VALUE phr_flip_bit=VALUE [core_id=VALUE] [perf_cts=VALUE]
```

To directly reproduce Figure 6:
```
python3 plot.py
```

Example output:
```
Testing associativity with flipped PHR[0]...
Associativity is 6.0!
Testing associativity with flipped PHR[1]...
Associativity is 6.0!
Testing associativity with flipped PHR[2]...
Associativity is 6.0!
...
Testing associativity with flipped PHR[387]...
Associativity is 2.0!
Testing associativity with flipped PHR[388]...
Associativity is 0.0!
Figure 6 is generated! (see fig_associativity_complete.pdf)
```