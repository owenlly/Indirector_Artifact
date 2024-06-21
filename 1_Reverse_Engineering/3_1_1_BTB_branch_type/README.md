# Branch Type in BTB

To reproduce results of Section 3.1.1 in the paper:
```
Usage: ./run.sh mode=run/asm inject_branch=direct/indirect/none measure=data/target_correct/target_malicious [core_id=VALUE] [perf_cts=VALUE]
```

Performance monitor output is in ``./results.out``. An example of ouput is like:
```
Experiment date and time: Thu 20 Jun 2024 08:56:03 PM PDT
Basic options - inject_branch: direct, measure: data, core_id: 0, perf_cts: 320,205,206, output_file: results.out

@   repeat1: 1000

@@   Clock     L2_Miss     BrIndir     BrMispInd

  85455273       2002      21000       1065 
  85071435       2000      21000       1027 
  84965044       2000      21000       1025 
  84746700       2000      21000       1027 
  84713757       2000      21000       1033 

Custom PMCounter results:
    362012       1000          0          0 
    362971       1000          0          0 
    358586       1000          0          0 
    350119       1000          0          0 
    357254       1000          0          0 
```

We have designed a python script to automatically parse the results, which will be shown in the terminal like this:
```
...
Parsing results:
No cache hit detected.
```
* Use aliased direct branch to inject target:

    * measure if data are cached:
        ```
        ./run.sh mode=run inject_branch=direct measure=data
        ```
        **Expected output:** "No cache hit detected."
    * measure if load instruction is cached:
        ```
        ./run.sh mode=run inject_branch=direct measure=target_malicious
        ```
        **Expected output:** "Cache hit detected!"


* Use aliased indirect branch to inject target:
    ```
    ./run.sh mode=run inject_branch=indirect measure=data
    ```
    **Expected output:** "Cache hit detected!"