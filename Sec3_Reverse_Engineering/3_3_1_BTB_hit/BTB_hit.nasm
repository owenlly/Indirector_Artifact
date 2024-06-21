%define repeat0  5              ; Number of repetitions of whole test. Default = 8
%define repeat1  1000              ; Repeat count for loop around testcode. Default = no loop
%define repeat2  1              ; Repeat count for repeat macro around testcode. Default = 100
%define noptype  2

%macro testinitc 0              ; Macro to call in each test before reading counters.
    mov dword[PrintCustomPMC], 1
%endmacro

%macro testinit3 0
    rdrand rdx
    and rdx, 1
    mov qword[UserData+8], rdx
    mfence
    SERIALIZE
    call start_test_ibranch

    xor qword[UserData+8], 1
    mfence
    SERIALIZE
    call start_test_ibranch
    mfence
    SERIALIZE
%endmacro

%macro testcode 0               ; A multi-line macro executing any piece of test code.
    
    %rep 5 * evict_ibp
        rdrand rdx
        and rdx, 1
        mov qword[UserData+16], rdx
        mfence
        SERIALIZE
        call start_eviction_ibranch

        xor qword[UserData+16], 1
        mfence
        SERIALIZE
        call start_eviction_ibranch
    %endrep

    mfence
    SERIALIZE

    rdrand rdx
    and rdx, 1
    mov qword[UserData+8], rdx
    mfence
    SERIALIZE
    READ_PMC_START
    call start_test_ibranch
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

SECTION .sec_test_ibranch exec
start_test_ibranch:
    mov rdx, qword[UserData+8]
    lea r10, [test_target_0]
    lea r9, [test_target_1]
    cmp rdx, 1
    cmovz r10, r9
    mfence

    SHIFT_PHR 195,0
    SET_PHR 50,0
    SHIFT_PHR 1,1

    align 1<<16
    %rep 64*77
     nop
    %endrep
test_ibranch:
    jmp r10
    %rep 512
     nop
    %endrep
test_target_0:
    %rep 512
     nop
    %endrep
    ret
test_target_1:
    %rep 512
     nop
    %endrep
    ret


SECTION .sec_eviction_ibranch exec
start_eviction_ibranch:
    %assign k 2
    %rep 6
        mov rdx, qword[UserData+16]
        lea r10, [eviction_target_0_%+ k]
        lea r9, [eviction_target_1_%+ k]
        cmp rdx, 1
        cmovz r10, r9
        mfence

        SHIFT_PHR 195,k
        SET_PHR 50,k
        %assign j k+100
        SHIFT_PHR 1,j
        
        %rep 64*k
         nop
        %endrep
    eviction_ibranch_%+ k:
        jmp r10
        %rep 512
         nop
        %endrep
    eviction_target_0_%+ k:
        %rep 512
         nop
        %endrep
    eviction_target_1_%+ k:
        %rep 512
         nop
        %endrep
    %assign k k+1
    %endrep
    ret