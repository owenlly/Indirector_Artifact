# Hash Function of IBP

We designed a tool for automatically verifying the correctness of IBP index and tag hash function in Figure 8 and 9.

Based on the input of victim PHR and ``PC[15:6]``, the tool will find a possible PHR value and a corresponding ``PC[15:6]`` for the attacker to create IBP aliasing with the victim.

To run the tool, use:
```
python3 ./aliasing_search.py
```

Example usage:
```
Input the victim PHR bits you want to flip (0~387), separated by commas:
28, 39, 54, 123, 156
Input the victim PC[15:6] in binary: 
1001100000

Attacker PHR bits can be set at position: 28, 36, 42
Attacker PC[15:6] can be: 1011110011
Running injection test...

Parsing results:
Cache Hit Rate: 17.44%
Injection success!
```
