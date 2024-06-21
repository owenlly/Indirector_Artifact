%define repeat0  5              ; Number of repetitions of whole test. Default = 8
%define repeat1  1000              ; Repeat count for loop around testcode. Default = no loop
%define repeat2  1              ; Repeat count for repeat macro around testcode. Default = 100
%define noptype  2

%macro testinitc 0              ; Macro to call in each test before reading counters.
    mov dword[PrintCustomPMC], 1

open_msr_file:
    mov rdi, msr_file
    mov rsi, open_flag
    mov rax, syscall_open
    syscall                
    mov [UserData], rax ; file desriptor
    mfence
    SERIALIZE
%endmacro

%macro testafter3 0 
close_msr_file:
    mov rdi, [UserData]
    mov rax, syscall_close
    syscall
    mfence
    SERIALIZE
%endmacro

%macro testcode 0               ; A multi-line macro executing any piece of test code.
    
    rdrand rdx
    and rdx, 1
    mov qword[UserData+8], rdx
    mfence
    SERIALIZE
    call start_test_ibranch
    mfence
    SERIALIZE
    xor qword[UserData+8], 1
    call start_test_ibranch
    mfence
    SERIALIZE

    %if ibrs==1
        COMMAND_IBRS 1
    %endif

    %if stibp==1
        COMMAND_STIBP 1
    %endif

    %if ibpb==1
        COMMAND_IBPB 1
    %endif

    mfence
    SERIALIZE

    ; initialize BTB
    rdrand rdx
    and rdx, 1
    mov qword[UserData+8], rdx
    %rep 4
        mfence
        SERIALIZE
        call start_test_ibranch
    %endrep

    READ_PMC_START
    xor qword[UserData+8], 1 ; flip input
    call start_test_ibranch
    READ_PMC_END

    %rep 512
     nop
    %endrep

%endmacro

%macro COMMAND_IBPB 1
    mov dword[syscall_input], %1
    mov rdi, [UserData]    ; First argument: file descriptor
    mov rsi, syscall_input          ; Second argument: pointer to data
    mov rdx, 8             ; Third argument: count (number of bytes to write)
    mov r10, 73            ; Fourth argument: offset
    mov rax, syscall_pwrite
    syscall
%endmacro

%macro COMMAND_IBRS 1
    mov dword[syscall_input], %1
    mov rdi, [UserData]    ; First argument: file descriptor
    mov rsi, syscall_input          ; Second argument: pointer to data
    mov rdx, 8             ; Third argument: count (number of bytes to write)
    mov r10, 72            ; Fourth argument: offset
    mov rax, syscall_pwrite
    syscall
%endmacro

%macro COMMAND_STIBP 1
    mov dword[syscall_input], %1 ; 2 to set, 0 to unset
    mov rdi, [UserData]    ; First argument: file descriptor
    mov rsi, syscall_input          ; Second argument: pointer to data
    mov rdx, 8             ; Third argument: count (number of bytes to write)
    mov r10, 72            ; Fourth argument: offset
    mov rax, syscall_pwrite
    syscall
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

section .sec_test_ibranch exec
start_test_ibranch:
    mov rdx, qword[UserData+8]
    lea r10, [i_target_0]
    lea r9, [i_target_1]
    cmp rdx, 1
    cmovz r10, r9
    mfence

    SHIFT_PHR 195,0
    SET_PHR 50,0
    SHIFT_PHR 1,1

    %rep 64
     nop
    %endrep
test_ibranch:
    jmp r10
    %rep 512
     nop
    %endrep
i_target_0:
    %rep 512
     nop
    %endrep
    ret
i_target_1:
    %rep 512
     nop
    %endrep
    ret