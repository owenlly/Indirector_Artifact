%define repeat0  5              ; Number of repetitions of whole test. Default = 8
%define repeat1  1000              ; Repeat count for loop around testcode. Default = no loop
%define repeat2  1              ; Repeat count for repeat macro around testcode. Default = 100
%define noptype  2

%macro testinitc 0
    mov dword[PrintCustomPMC], 1
%endmacro

%macro testcode 0               ; A multi-line macro executing any piece of test code.
    
    READ_PMC_START
    jmp template
    %rep 64
     nop
    %endrep
template:
    %rep 64
     nop
    %endrep
    READ_PMC_END

    %rep 512
     nop
    %endrep
%endmacro
