# Basic Test

To make sure the installation is successful, run with:
```
./run.sh mode=run
```

The correct output in ``results.out`` will be:
```
Basic options - core_id: 0, perf_cts: 204, output_file: results.out
@@   Clock     BrRetired

    465718       2000 
    464655       2000 
    464754       2000 
    464761       2000 
    468457       2000 

Custom PMCounter results:
     90122       1000 
     89805       1000 
     89812       1000 
     89789       1000 
     89779       1000 
```

"BrRetired" column under "Custom PMCounter results" shows that each test iterates the direct branch for 1000 times.