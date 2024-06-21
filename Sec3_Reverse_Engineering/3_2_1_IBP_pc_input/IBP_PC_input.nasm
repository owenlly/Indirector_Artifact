%define repeat0  5              ; Number of repetitions of whole test. Default = 8
%define repeat1  1000              ; Repeat count for loop around testcode. Default = no loop
%define repeat2  1              ; Repeat count for repeat macro around testcode. Default = 100
%define noptype  2

%macro testinitc 0              ; Macro to call in each test before reading counters.
    mov dword[PrintCustomPMC], 1
%endmacro

%macro testcode 0               ; A multi-line macro executing any piece of test code.
    rdrand rdx
    and rdx, 1

    call set_PHR_and_jump_0

    %rep 512
     nop
    %endrep

    xor rdx, 1
    call set_PHR_and_jump_0

    %rep 512
     nop
    %endrep
    
    rdrand rdx
    and rdx, 1
    READ_PMC_START
    call set_PHR_and_jump_1
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

%macro SET_PHR 2
    cmp rdx, 1
    %assign i 0
    %rep %1
        je set_phr_eq_%+ %2_%+ i
        %rep 64
         nop
        %endrep
        set_phr_eq_%+ %2_%+ i:
        %rep 64 
         nop
        %endrep
        %assign i i+1
    %endrep

    cmp rdx, 1
    %assign i 0
    %rep %1
        jne set_phr_neq_%+ %2_%+ i
        %rep 64
         nop
        %endrep
        set_phr_neq_%+ %2_%+ i:
        %rep 64 
         nop
        %endrep
        %assign i i+1
    %endrep
%endmacro

%assign j 0
%rep 2
SECTION .sec_set_PHR_%+ j exec
set_PHR_and_jump_%+ j:
    
    SHIFT_PHR 195,j
    SET_PHR 20,j

    lea r10, [indirect_target_0_%+ j]
    lea r9, [indirect_target_1_%+ j]
    cmp rdx, 1
    cmovz r10, r9
    mfence
    call ibranch_%+ j

    %rep 512
     nop
    %endrep
    ret
%assign j j+1
%endrep


SECTION .sec_ibranch_0 exec
ibranch_0:
    jmp r10
    %rep 64 
     nop
    %endrep
indirect_target_0_0:
    %rep 64
     nop
    %endrep
indirect_target_1_0:
    %rep 512 
     nop
    %endrep
    ret

SECTION .sec_ibranch_1 exec
ibranch_1:
    %rep 1<<pc_flip_bit
     nop
    %endrep
    jmp r10
    %rep 64 
     nop
    %endrep
indirect_target_0_1:
    %rep 64
     nop
    %endrep
indirect_target_1_1:
    %rep 512 
     nop
    %endrep
    ret