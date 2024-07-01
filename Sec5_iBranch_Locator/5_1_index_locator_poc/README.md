# iBranch Index Locator

Resources needed: 1 human-minute + 2 compute-minutes

To reproduce results of Figure 11 in the paper:
```
Usage: ./run_index_locator_poc.sh mode=run/compile [begin_set=VALUE] [end_set=VALUE] [core_id=VALUE] [perf_cts=VALUE]
```

We provide a simplied method to quickly reproduce the spikes in Figure 11, by only scanning part of the IBP sets.

In our example, the victim indirect branch is in IBP set #184 and #384.

For example, to verify the spike at #184, you need to first compile with the command:
```
./run_index_locator_poc.sh mode=compile begin_set=180 end_set=189
```

After compilation, run with:
```
./run_index_locator_poc.sh mode=run begin_set=180 end_set=189
```

An example of parsing results:
```
Parsing results:
Misprediction in IBP set 180: 30.36%
Misprediction in IBP set 181: 29.59%
Misprediction in IBP set 182: 28.72%
Misprediction in IBP set 183: 29.79%
Misprediction in IBP set 184: 47.11% // Much higher than others
Misprediction in IBP set 185: 29.68%
Misprediction in IBP set 186: 29.17%
Misprediction in IBP set 187: 28.25%
Misprediction in IBP set 188: 28.34%
Misprediction in IBP set 189: 23.71%
```

To verify the spike at #384 is similar.