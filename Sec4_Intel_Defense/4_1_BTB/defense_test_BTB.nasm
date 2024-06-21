%define repeat0  5              ; Number of repetitions of whole test. Default = 8
%define repeat1  repeat1_input              ; Repeat count for loop around testcode. Default = no loop
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
    
    call start_test_branch

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

    READ_PMC_START
    call start_test_branch
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

section .sec_test_branch exec
start_test_branch:
    %assign i 0
    %rep num_dbranch
        jmp d_target%+ i
        %rep 64
         nop
        %endrep
        d_target%+ i:
        %rep 64
         nop
        %endrep
    %assign i i+1
    %endrep

    %assign i 0
    %rep num_cbranch
        mov rax, 1
        cmp rax, 1
        je c_target%+ i
        %rep 64
         nop
        %endrep
        c_target%+ i:
        %rep 64
         nop
        %endrep
    %assign i i+1
    %endrep

    %assign i 0
    %rep num_ibranch
        lea r10, [i_target_%+ i]
        jmp r10
        %rep 64
         nop
        %endrep
        i_target_%+ i:
        %rep 64
         nop
        %endrep
    %assign i i+1
    %endrep

    ret