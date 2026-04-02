STACK SEGMENT PARA STACK
DW 100 DUP(?)
STACK ENDS

DATA SEGMENT
matrix DB '9','7','?','2'
DB '4','M','8','2'
DB '9','u','?','4'
DB '0','/','6','2'
DB '1','-','2','3'
DB 'A','5','B','6'
DB '7','8','9','C'

rows EQU 4
cols EQU 7
total EQU 28

color DB 28 DUP(07h) ; Default light gray
DATA ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA, SS:STACK

Start:
MOV AX, DATA
MOV DS, AX

CALL CleanMatrix
CALL DisplayMatrix

MOV AH, 4CH
INT 21H

; --- Process: Replace non-digits with '0' and set color to Red (04h) ---
CleanMatrix PROC
PUSH AX
PUSH CX
PUSH SI
PUSH DI

MOV SI, OFFSET matrix
MOV DI, OFFSET color
MOV CX, total

Next_Element:
MOV AL, [SI]
CMP AL, '0'
JB Is_Not_Digit
CMP AL, '9'
JA Is_Not_Digit
JMP Continue_Clean

Is_Not_Digit:
MOV BYTE PTR [SI], '0'
MOV BYTE PTR [DI], 04h ; Red attribute

Continue_Clean:
INC SI
INC DI
LOOP Next_Element

POP DI
POP SI
POP CX
POP AX
RET
CleanMatrix ENDP

; --- Process: Display Matrix using stored colors ---
DisplayMatrix PROC
PUSH AX
PUSH BX
PUSH CX
PUSH DX
PUSH SI
PUSH DI

MOV SI, OFFSET matrix
MOV DI, OFFSET color
MOV CX, total
MOV DL, 0 ; Column counter
MOV DH, 0 ; Row tracker (for cursor)

Display_Loop:
; 1. Set Cursor Position (Required for INT 10h AH=09h)
MOV AH, 02h
MOV BH, 00
; DH and DL are managed below
INT 10h

; 2. Print Character with Attribute
MOV AL, [SI] ; Character to print
MOV BL, [DI] ; Color attribute
MOV AH, 09h
MOV BH, 00
PUSH CX ; Save total loop counter
MOV CX, 1 ; Repeat count for INT 10h
INT 10h
POP CX ; Restore total loop counter

; 3. Increment Pointers and Column
INC SI
INC DI
INC DL ; Move cursor column right

; Check if we need a new line
CMP DL, cols
JNE Continue_Display

; Reset column, increment row
MOV DL, 0
INC DH

Continue_Display:
LOOP Display_Loop

POP DI
POP SI
POP DX
POP CX
POP BX
POP AX
RET
DisplayMatrix ENDP

CODE ENDS
END Start
