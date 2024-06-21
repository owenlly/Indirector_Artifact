# Intel Defense Impacts on BTB

To reproduce results of Section 4 (Table 3) in the paper:
```
Usage: sudo ./run.sh mode=run/asm defense=IBRS/STIBP/IBPB [num_dbranch=VALUE] [num_cbranch=VALUE] [num_ibranch=VALUE] [core_id=VALUE] [perf_cts=VALUE]
```

Run the command with sudo!!

Parsing output example:
```
...
Parsing results:
Number of BTB Miss: 10
```

On Raptor Cove, IBRS, STIBP and IBPB only flush all the BTB entries for indirect branches. Therefore, the number of BTB misses will be only related to the value of ``num_ibranch``. 

```
sudo ./run.sh mode=run defense=IBRS/STIBP/IBPB num_ibranch=6
```
**Expected output:** 6 BTB misses

```
sudo ./run.sh mode=run defense=IBRS/STIBP/IBPB num_ibranch=6 num_dbranch=3 num_cbranch=4
```
**Expected output:** 6 BTB misse