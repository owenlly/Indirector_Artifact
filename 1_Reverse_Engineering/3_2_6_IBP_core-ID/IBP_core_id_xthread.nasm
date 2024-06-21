%define nthreads 2
%define repeat0  5              ; Number of repetitions of whole test. Default = 8
%define repeat1  repeat1_input         ; Repeat count for loop around testcode. Default = no loop
%define repeat2  1              ; Repeat count for repeat macro around testcode. Default = 100
%define noptype  2

%define t1_repeat1 1000
%define t1_repeat2 1

%macro testinitc 0              ; Macro to call in each test before reading counters.
    mov dword[PrintCustomPMC], 1
%endmacro

%if assign_same==1
%macro testinit3 0
    rdrand rdx
    and rdx, 1
    mov qword[UserData+16], rdx
    mfence
    SERIALIZE
    call start_attacker_ibranch
    mfence
    SERIALIZE
    xor qword[UserData+16], 1
    call start_attacker_ibranch
    mfence
    SERIALIZE
%endmacro
%endif

%if assign_cross==1
%macro t1_testinit3 0
acquire_spinlock_t1:
    mov   eax, 1
    xchg  eax, dword[thread_lock]
    test  eax, eax
    jnz   acquire_spinlock_t1

    rdrand rdx
    and rdx, 1
    mov qword[UserData+16], rdx
    mfence
    SERIALIZE
    call start_attacker_ibranch
    mfence
    SERIALIZE
    xor qword[UserData+16], 1
    call start_attacker_ibranch

release_spinlock_t1:
    mfence
    SERIALIZE
    dec dword[thread_lock]
%endmacro
%endif

%macro testcode 0               ; A multi-line macro executing any piece of test code.
acquire_spinlock_t0:
    mov   eax, 1
    xchg  eax, dword[thread_lock]
    test  eax, eax
    jnz   acquire_spinlock_t0
    
    clflush [UserData+2048]
    mfence
    SERIALIZE
    
    rdrand rdx
    and rdx, 1
    mov qword[UserData+8], rdx
    call start_victim_ibranch
    
    mfence
    SERIALIZE

    READ_PMC_START
    mov r11, qword[UserData+2048]
    READ_PMC_END

release_spinlock_t0:
    mfence
    SERIALIZE
    dec dword[thread_lock]

    %rep 512
     nop
    %endrep
%endmacro

%if assign_cross==1
%macro t1_testcode 0
%endmacro
%endif

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

SECTION .sec_victim_ibranch exec
start_victim_ibranch:
    mov rdx, qword[UserData+8]
    lea r10, [victim_target_0]
    lea r9, [victim_target_1]
    cmp rdx, 1
    cmovz r10, r9
    mov qword[UserData], r10
    clflush [UserData]
    mfence

    SHIFT_PHR 195,0
    SET_PHR 50,0
    SHIFT_PHR 1,1

    %rep 64
     nop
    %endrep
victim_ibranch:
    jmp [UserData]
    %rep 512
     nop
    %endrep
victim_target_0:
    %rep 512
     nop
    %endrep
    ret
victim_target_1:
    %rep 512
     nop
    %endrep
    ret

SECTION .sec_attacker_ibranch exec
start_attacker_ibranch:
    mov rdx, qword[UserData+16]
    lea r10, [attacker_target_0]
    lea r9, [attacker_target_1]
    cmp rdx, 1
    cmovz r10, r9
    mfence

    SHIFT_PHR 195,2
    SET_PHR 50,2
    SHIFT_PHR 1,3

    %rep 64
     nop
    %endrep
attacker_ibranch:
    jmp r10
    %rep 512
     nop
    %endrep
attacker_target_0:
    mov r11, qword[UserData+2048]
    %rep 512-8
     nop
    %endrep
    ret
attacker_target_1:
    mov r11, qword[UserData+2048]
    %rep 512
     nop
    %endrep
    ret