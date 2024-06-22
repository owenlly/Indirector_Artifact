# Indirector: High-Precision Branch Target Injection Attacks Exploiting the Indirect Branch Predictor
**Authors:** Luyi Li*, Hosein Yavarzadeh*, Dean Tullsen (*Equal Contribution)

**Organization:** UC San Diego

To appear at USENIX Security 2024

## Introduction
In this artifact, we introduce Indirector, a collection of reverse engineering tools and branch injection attacks. We provide assembly benchmarks to analyze the Branch Target Buffer (BTB) and Indirect Branch Predictor (IBP) on modern Intel CPUs, and examine the effects of Intel Spectre v2 mitigation techniques.

For attack implementation, we offer *iBranch Locator*, a tool for accurately locating indirect branches within the IBP. Using this tool, we demonstrate two high-precision injection attacks on the IBP and BTB, and a method to break Address Space Layout Randomization (ASLR).

## Platform Requirement
* CPU: Golden/Raptor Cove core (P-core of Intel(R) 12th or 13th gen CPU).

## Necessary Installations
* Install a universal version of the GNU C/C++ compiler with the command: `sudo apt-get install g++-multilib`.
* Install the NASM assembler with the command: `sudo apt-get install nasm`.
* Disable secure boot in the BIOS/UEFI setup menu.

## Install Dependencies
* In the root directory, execute the command: `chmod +x *.sh && ./env_init.sh`.

## Overview
```
Indirector_Artifact/
├── 0_Template                # Basic test to verify installation
├── Sec3_Reverse_Engineering  # Benchmarks for reverse engieering BTB and IBP in Section 3
├── Sec4_Intel_Defense        # Benchmarks for reverse engieering Intel Spectre v2 defenses in Section 4
├── Sec5_iBranch_Locator      # Proof-of-concept for iBranch Locator in Section 5
├── Sec6_Injection_Attack     # Proof-of-concept for cross-process injection and breaking ASLR in Section 6
└── utils                     # MSR drivers, test framework and necessary setup scripts
```

* In each test directory, we have provided scripts to automatically run the benchmark and parse the results.

* There is also a ``README`` file in each test, which shows example usage and expected results in different cases. Please refer to it for execution and further analyses.


## Citation
```
@inproceedings{Li2024Indirector,
  title     = {{Indirector}: High-Precision Branch Target Injection Attacks Exploiting the Indirect Branch Predictor},
  author    = {Luyi Li, Hosein Yavarzadeh and Dean Tullsen},
  booktitle = {33rd {USENIX} Security Symposium ({USENIX} Security 24)},
  year      = {2024}
}
```
