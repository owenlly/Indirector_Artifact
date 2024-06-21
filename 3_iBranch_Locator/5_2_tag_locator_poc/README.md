# iBranch Index Locator

To reproduce results of Figure 12 in the paper:
```
Usage: mode=run/compile [begin_pc=VALUE] [end_pc=VALUE] [core_id=VALUE] [perf_cts=VALUE]
```

We provide a simplied method to quickly reproduce the spikes in Figure 12, by only scanning part of the IBP tags.

For example, to verify the spike at #218H(536), you need to first compile with the command:
```
./run_tag_locator_poc.sh mode=compile begin_pc=530 end_pc=539
```

After compilation, run with:
```
./run_tag_locator_poc.sh mode=run begin_pc=530 end_pc=539
```

An example of parsing results:
```
Parsing results:
Misprediction of IBP tag 530: 54.00%
Misprediction of IBP tag 531: 55.83%
Misprediction of IBP tag 532: 49.33%
Misprediction of IBP tag 533: 49.67%
Misprediction of IBP tag 534: 50.33%
Misprediction of IBP tag 535: 49.83%
Misprediction of IBP tag 536: 73.67% // Much higher than others
Misprediction of IBP tag 537: 54.17%
Misprediction of IBP tag 538: 52.17%
Misprediction of IBP tag 539: 51.00%
Misprediction of IBP tag 1554: 49.00%
Misprediction of IBP tag 1555: 51.33%
Misprediction of IBP tag 1556: 50.67%
Misprediction of IBP tag 1557: 49.00%
Misprediction of IBP tag 1558: 53.83%
Misprediction of IBP tag 1559: 54.83%
Misprediction of IBP tag 1560: 47.50%
Misprediction of IBP tag 1561: 52.00%
Misprediction of IBP tag 1562: 49.67%
Misprediction of IBP tag 1563: 50.17%
```

To verify the spike at #357H(855) is similar.