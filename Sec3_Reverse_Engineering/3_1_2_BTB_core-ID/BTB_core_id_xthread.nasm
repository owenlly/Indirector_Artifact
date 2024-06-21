%define nthreads 2
%define repeat0  5           ; Number of repetitions of whole test. Default = 8
%define repeat1  1000              ; Repeat count for loop around testcode. Default = no loop
%define repeat2  1              ; Repeat count for repeat macro around testcode. Default = 100
%define noptype  2

%define t1_repeat1 1000
%define t1_repeat2 1

%macro testinitc 0              ; Macro to call in each test before reading counters.
    mov dword[PrintCustomPMC], 1
%endmacro

%macro testcode 0               ; A multi-line macro executing any piece of test code.
acquire_spinlock_t0:
    mov   eax, 1
    xchg  eax, dword[thread_lock]
    test  eax, eax
    jnz   acquire_spinlock_t0

    mfence
    SERIALIZE
    mov rax, sec_branch_0_t0_addr
    call rax

    %rep assign_same
        mfence
        SERIALIZE
        mov rax, sec_branch_1_t0_addr
        call rax
    %endrep

    READ_PMC_START
    %assign i 0
    %rep t0_branch_num
        align 1<<15 ; align all the branches to the same BTB index
        nop
        align 1<<7
        nop
        align 1<<5
        jmp t0_target_%+ i
        %rep 32 ; control the target distance
         nop
        %endrep
        t0_target_%+ i:
        %rep 32
         nop
        %endrep
        SERIALIZE
        %assign i i+1
    %endrep
    READ_PMC_END

release_spinlock_t0:
    mfence
    SERIALIZE
    dec dword[thread_lock]

    %rep 64
     nop
    %endrep
%endmacro

%macro t1_testcode 0
acquire_spinlock_t1:
    mov   eax, 1
    xchg  eax, dword[thread_lock]
    test  eax, eax
    jnz   acquire_spinlock_t1

    %rep assign_cross
        mfence
        SERIALIZE
        mov rax, sec_branch_t1_addr
        call rax
    %endrep

release_spinlock_t1:
    mfence
    SERIALIZE
    dec dword[thread_lock]

    %rep 64
     nop
    %endrep
%endmacro


SECTION .sec_branch_0_t0 exec
branch_0_t0:
    align 1<<15
    nop
    align 1<<7
    nop
    align 1<<5
    nop
    jmp t0_aliased_target_0
    %rep 31
     nop
    %endrep
    t0_aliased_target_0:
    %rep 512
     nop
    %endrep
    ret

SECTION .sec_branch_1_t0 exec
branch_1_t0:
    align 1<<15
    nop
    align 1<<7
    nop
    align 1<<5
    nop
    jmp t0_aliased_target_1
    %rep 64
     nop
    %endrep
    t0_aliased_target_1:
    %rep 512
     nop
    %endrep
    ret

SECTION .sec_branch_t1 exec
branch_t1:
    align 1<<15
    nop
    align 1<<7
    nop
    align 1<<5
    nop
    jmp t1_aliased_target
    %rep 128
     nop
    %endrep
    t1_aliased_target:
    %rep 512
     nop
    %endrep
    ret
