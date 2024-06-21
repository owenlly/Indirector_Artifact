%include "./SET_ATTACKER_PHR.nasm"
%include "./SET_VICTIM_PHR.nasm"

%define nthreads 1
%define repeat0  5              ; Number of repetitions of whole test. Default = 8
%define repeat1  repeat1_input              ; Repeat count for loop around testcode. Default = no loop
%define repeat2  1              ; Repeat count for repeat macro around testcode. Default = 100
%define noptype  2

%macro testinitc 0              ; Macro to call in each test before reading counters.
    mov dword[PrintCustomPMC], 1
%endmacro

%macro testinit3 0

    %assign i 0
    %rep 3
        retry_random_attacker_%+ i:
        rdrand rdx
        jnc retry_random_attacker_%+ i
        and rdx, 1
        mov qword[UserData+16], rdx
        call attacker_ibranch
        mfence
        SERIALIZE
        xor qword[UserData+16], 1
        mfence
        call attacker_ibranch
    %assign i i+1
    %endrep

%endmacro

%macro testcode 0               ; A multi-line macro executing any piece of test code.

    clflush [UserData+2048]

    ; READ_PMC_START
retry_random_victim:
    rdrand rdx
    jnc retry_random_victim
    and rdx, 1
    mov qword[UserData], rdx
    mfence
    call victim_ibranch
    ; READ_PMC_END

    READ_PMC_START
    mov r11, qword[UserData+2048]
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
    mov rdx, qword[UserData+16]
    lea r10, [attacker_target_0]
    lea r9, [attacker_target_1]
    cmp rdx, 1
    cmovz r10, r9
    mfence

    cmp rdx, 0
    je attacker_set_PHR_end
    SHIFT_PHR 195, 3
    %rep 23
     nop
    %endrep
    SET_ATTACKER_PHR 0
    align 1<<16
    nop
    align 1<<5
attacker_set_PHR_end:
    
    xor rax, rax
    cpuid

    %rep (attacker_pc15to6)<<6
     nop
    %endrep
    jmp r10
    %rep 64
     nop
    %endrep
attacker_target_0:
    %rep 64
     nop
    %endrep
    ret
attacker_target_1:
    mov r11, qword[UserData+2048]
    %rep 64
     nop
    %endrep
    ret

SECTION .sec_victim_ibranch exec
victim_ibranch:
    mov rdx, qword[UserData]
    lea r10, [victim_target_0]
    lea r9, [victim_target_1]
    cmp rdx, 1
    cmovz r10, r9
    mov qword[UserData+512], r10
    clflush [UserData+512]
    mfence

    cmp rdx, 0
    je victim_set_PHR_end
    SHIFT_PHR 195, 1
    %rep 23
     nop
    %endrep
    SET_VICTIM_PHR 0
    align 1<<16
victim_set_PHR_end:

    xor rax, rax
    cpuid

    %rep (victim_pc15to6)<<6
     nop
    %endrep
    jmp [UserData+512]
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