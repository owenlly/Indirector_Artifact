%include "./SET_ATTACKER_PHR0.nasm"
%include "./SET_ATTACKER_PHR1.nasm"
%include "./SET_VICTIM_PHR0.nasm"
%include "./SET_VICTIM_PHR1.nasm"

%define nthreads 1
%define repeat0  repeat0_input              ; Number of repetitions of whole test. Default = 8
%define repeat1  500              ; Repeat count for loop around testcode. Default = no loop
%define repeat2  1              ; Repeat count for repeat macro around testcode. Default = 100
%define noptype  2

%macro testinitc 0              ; Macro to call in each test before reading counters.
    mov dword[PrintCustomPMC], 1
%endmacro

%macro testinit3 0

    %assign i 0
    %rep 2
        retry_random_victim_%+ i:
        rdrand rdx
        jnc retry_random_victim_%+ i
        and rdx, 1
        mov qword[UserData], rdx
        call victim_ibranch
        mfence
        SERIALIZE
        xor qword[UserData], 1
        mfence
        call victim_ibranch
    %assign i i+1
    %endrep

%endmacro

%macro testcode 0               ; A multi-line macro executing any piece of test code.
    
    READ_PMC_START

retry_random_attacker:
    rdrand rdx
    jnc retry_random_attacker
    and rdx, 1
    mov qword[UserData+8], rdx
    mfence

    call attacker_ibranch

    xor qword[UserData+8], 1
    mfence
    SERIALIZE

    call attacker_ibranch

    READ_PMC_END

    %rep 512
     nop
    %endrep
%endmacro

%macro SHIFT_PHR 2
    mov rax, %1
    jmp shift_phr_%+ %2
    align 1<<16
    %rep (1<<16)-64
     nop
    %endrep
    shift_phr_%+ %2:
    %rep 64-8
     nop
    %endrep
    dec rax
    cmp rax, 0
    jg shift_phr_%+ %2
%endmacro

SECTION .sec_attacker_ibranch exec
attacker_ibranch:    
    %assign i 0
    %rep num_locator_branch
        mov rdx, qword[UserData+8]
        lea r10, [attacker_target_0_%+ i]
        lea r9, [attacker_target_1_%+ i]
        cmp rdx, 1
        cmovz r10, r9
        mfence

        cmp rdx, 1
        je attacker_set_PHR1_start_%+ i
        SHIFT_PHR 195,i
        %rep 23
         nop
        %endrep
        SET_ATTACKER_PHR0 i

    attacker_set_PHR1_start_%+ i:
        %assign j i+10
        SHIFT_PHR 195,j
        %rep 23
         nop
        %endrep
        SET_ATTACKER_PHR1 i
    attacker_set_PHR1_end_%+ i:

        align 1<<5
        %rep j<<6
         nop
        %endrep
        jmp r10
        %rep 64 
         nop
        %endrep
    attacker_target_0_%+ i:
        %rep 64
         nop
        %endrep
    attacker_target_1_%+ i:
        %rep 64
         nop
        %endrep
    %assign i i+1
    %endrep
    ret

SECTION .sec_victim_ibranch exec
victim_ibranch:
    mov rdx, qword[UserData]
    lea r10, [victim_target_0]
    lea r9, [victim_target_1]
    cmp rdx, 1
    cmovz r10, r9
    mfence

    cmp rdx, 1
    je victim_set_PHR1_start
    SHIFT_PHR 195,100
    %rep 23
     nop
    %endrep
    SET_VICTIM_PHR0 0

victim_set_PHR1_start:
    SHIFT_PHR 195,101
    %rep 23
     nop
    %endrep
    SET_VICTIM_PHR1 0
victim_set_PHR1_end:

    %rep (50)<<6
     nop
    %endrep
    jmp r10
    %rep 64
     nop
    %endrep
victim_target_0:
    %rep 64
     nop
    %endrep
    ret
victim_target_1:
    %rep 64
     nop
    %endrep
    ret