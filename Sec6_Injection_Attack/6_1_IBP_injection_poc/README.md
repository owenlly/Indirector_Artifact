# Run Cross-process Injection Attacks
* Go to the attack directories: `6_1_IBP_injection_poc` (or `6_2_BTB_injection_poc`).
* Execute the command: `make`.
* Follow the instructions to assign the core ID for both attacker and victim processes.
* A success example when both processes run on the same SMT core:

    ```
    xyz@xyz-home:~/IBP_attack_poc/poc_code/injection_BTB$ make
    Assign a core-ID for the attacker ( 0 ~ (2*num of P-cores)-1 ): 0
    Running the attacker on Core No.0...
    Assign a core-ID for the victim ( 0 ~ (2*num of P-cores)-1 ): 0
    Input a secret for the victim (0 ~ 9): 4
    Running the victim on Core No.0...
    BTB injection attack successes! The secret value is 4!
    ```

* The attack fails when they run on different cores:
    ```
    xyz@xyz-home:~/IBP_attack_poc/poc_code/injection_BTB$ make
    Assign a core-ID for the attacker ( 0 ~ (2*num of P-cores)-1 ): 0
    Running the attacker on Core No.0...
    Assign a core-ID for the victim ( 0 ~ (2*num of P-cores)-1 ): 1
    Input a secret for the victim (0 ~ 9): 4
    Running the victim on Core No.1...
    BTB injection attack fails...
    ```