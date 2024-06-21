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
    mfence
    
    READ_PMC_START
    %assign k 0
    %rep num_ibranch
        lea r10, [target_0_%+ k]
        lea r9, [target_1_%+ k]
        cmp rdx, 1
        cmovz r10, r9
        mfence
        
        SHIFT_PHR 195,k
        SET_PHR_EVEN k

        %assign j k+100
        SHIFT_PHR 20,j

        %rep 64*k
         nop
        %endrep
        ibranch_%+ k:
        jmp r10
        %rep 64
         nop
        %endrep
        target_0_%+ k:
        %rep 64
         nop
        %endrep
        target_1_%+ k:
        %rep 512
         nop
        %endrep
    %assign k k+1
    %endrep
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

%macro SET_PHR_EVEN 1
    cmp rdx, 1
    %rep 50
     nop
    %endrep
    je set_phr_even_%+ %1
    align 1<<6
    set_phr_even_%+ %1:
    %rep 77H
     nop
    %endrep
%endmacro
