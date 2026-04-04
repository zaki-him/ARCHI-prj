COLUMN_REDUCTION PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    
    XOR DI, DI                      ; SETTING DESTINATION INDEX REG TO 0
    MOV CX, COL
    
    LEA BX, TAB_ASCII               ; Access to ASCII table for conversion

TAB:
    MOV SI, DI                      ; SI and DI point to same 1:J element
    MOV SUM, 0
    MOV DX, ROW                     ; Using DX as counter

SUMM:
    MOV AL, matrix[SI]              ; Get element from matrix
    ADD SUM, AL                     ; Accumulate sum
    ADD SI, COL                     ; Move to next row, same column
    DEC DX
    CMP DX, 0
    JNZ SUMM
    
    MOV AL, SUM
    XLAT                            ; Convert byte to ASCII
    MOV TAB_C[DI], AL
    INC DI
    
    LOOP TAB

    ; Print column sums in YELLOW
    MOV CX, COL                     ; Counter: Num OF CHARS
    MOV SI, OFFSET TAB_C            ; Access to char
    
PRINT:
    LODSB                           ; Load next byte in SI to AL
    MOV AH, 09H                     ; Function Num
    MOV BH, 0                       ; PAGE Num
    MOV BL, 0EH                    ; COLOR: YELLOW
    MOV CX, 1
    INT 10H
    LOOP PRINT

    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
COLUMN_REDUCTION ENDP
