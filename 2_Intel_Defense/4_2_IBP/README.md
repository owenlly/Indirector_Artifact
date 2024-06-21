# Intel Defense Impacts on IBP

To reproduce results of Section 4 (Table 3) in the paper:
```
Usage: sudo ./run.sh mode=run/asm defense=IBRS/STIBP/IBPB [core_id=VALUE] [perf_cts=VALUE]
```

Run the command with sudo!!

Parsing output example:
```
...
Parsing results:
Indirect branch misprediction rate: 100.00%
```

On Raptor Cove, IBRS and STIBP do not flush the IBP, while IBPB flushes the IBP. 

```
sudo ./run.sh defense=IBPB
```
**Expected output:** ~100% misprediction

```
sudo ./run.sh mode=run defense=IBRS/STIBP
```
**Expected output:** ~0% misprediction