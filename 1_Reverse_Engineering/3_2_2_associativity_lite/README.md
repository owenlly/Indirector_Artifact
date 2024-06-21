# Associativity structure of IBP

To reproduce results of Section 3.2.2 in the paper:
```
Usage: ./run.sh mode=run/asm num_ibranch=VALUE [core_id=VALUE] [perf_cts=VALUE]
```

To directly reproduce Figure 5:
```
python3 plot.py
```

Example output:
```
1 indirect branches with same PHR...
2 indirect branches with same PHR...
3 indirect branches with same PHR...
4 indirect branches with same PHR...
5 indirect branches with same PHR...
6 indirect branches with same PHR...
7 indirect branches with same PHR...
8 indirect branches with same PHR...
9 indirect branches with same PHR...
10 indirect branches with same PHR...
Figure 5 is generated! (see fig_associativity_lite.pdf)
```