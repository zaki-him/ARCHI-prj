;════════════════════════════════════════════════════════════════════════════════
; HELLO.ASM - Simple 16-bit Hello World
; Environment: EMU8086 / DOS
;════════════════════════════════════════════════════════════════════════════════

STACK SEGMENT PARA STACK
    DW 64 DUP(?)         ; Small stack for a simple program
STACK ENDS

DATA SEGMENT
    MSG DB 'Hello, World!', 0Dh, 0Ah, '$' ; 0Dh, 0Ah = Carriage Return + Line Feed
DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:STACK

START:
    ; 1. Initialize Data Segment (Crucial step!)
    MOV AX, DATA
    MOV DS, AX

    ; 2. Print the string using DOS Function 09h
    LEA DX, MSG         ; Load address of MSG into DX
    MOV AH, 09h         ; DOS Service 9: Display String
    INT 21h             ; Execute DOS Interrupt

    ; 3. Exit program safely using DOS Function 4Ch
    MOV AX, 4C00h       ; Service 4Ch: Terminate with return code 0
    INT 21h

CODE ENDS
END START