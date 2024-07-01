# Indirector: High-Precision Branch Target Injection Attacks Exploiting the Indirect Branch Predictor
**Authors:** Luyi Li*, Hosein Yavarzadeh*, Dean Tullsen (*Equal Contribution)

**Organization:** UC San Diego

**Webpage:** https://indirector.cpusec.org

To appear at USENIX Security 2024

## Introduction
In this artifact, we introduce Indirector, a collection of reverse engineering tools and branch injection attacks. We provide assembly benchmarks to analyze the Branch Target Buffer (BTB) and Indirect Branch Predictor (IBP) on modern Intel CPUs, and examine the effects of Intel Spectre v2 mitigation techniques.

For attack implementation, we offer *iBranch Locator*, a tool for accurately locating indirect branches within the IBP. Using this tool, we demonstrate two high-precision injection attacks on the IBP and BTB, and a method to break Address Space Layout Randomization (ASLR).

## Platform Requirement
* CPU: Golden/Raptor Cove core (P-core of Intel(R) 12th or 13th gen CPU).
* OS: Ubuntu-based Linux system.

**The environments we used in our paper are:**
* i9-12900 running Ubuntu 22.04.4 LTS with Linux kernel 5.10.209
* i7-13700K running Ubuntu 20.04.6 LTS with Linux kernel 5.15.89
* i9-13900KS running Ubuntu 22.04.4 LTS with Linux kernel 6.5.0-35-generic

## Necessary Installations
* Install a universal version of the GNU C/C++ compiler: `sudo apt-get install g++-multilib`.
* Install the NASM assembler: `sudo apt-get install nasm`.
* Install the msr-tools: `sudo apt-get install msr-tools`
* Disable secure boot in the BIOS/UEFI setup menu.

## Install Dependencies
* In the root directory, execute the command: `chmod +x *.sh && ./env_init.sh`.

## Overview
```
Indirector_Artifact/
├── 0_Template                # Basic test to verify installation
├── Sec3_Reverse_Engineering  # Benchmarks for reverse engieering BTB and IBP in Section 3 (~ 10 human-minutes + 70 compute-minutes)
├── Sec4_Intel_Defense        # Benchmarks for reverse engieering Intel Spectre v2 defenses in Section 4 (~ 2 human-minutes + 2 compute-minutes)
├── Sec5_iBranch_Locator      # Proof-of-concept for iBranch Locator in Section 5 (~ 3 human-minutes + 5 compute-minutes)
├── Sec6_Injection_Attack     # Proof-of-concept for cross-process injection and breaking ASLR in Section 6 (~ 3 human-minutes + 35 compute-minutes)
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
## Acknowldgement
This repository is built upon Anger Fog's excellent [test programs for measuring performance counters](https://agner.org/optimize/#testp).
