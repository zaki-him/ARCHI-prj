COLUMN_REDUCTION PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    XOR DI, DI              ; SETTING DESTINATION INDEX REG TO 0
    MOV CX, COLS
    LEA BX, TAB_ASCII       ; ACCESS TO A REDUCED ASCII TABLE TO CONVERT RESULTS
TAB:
    MOV SI, DI              ; SI AND DI ARE POINTING TO THE SAME 1:J ELEMENT EVERY
    MOV SUM, 0
    MOV DX, ROWS            ; USING DX AS A COUNTER
SUMM:
    MOV AL, matrix[SI]
    SUB AL, '0'             ; CONVERT CHAR TO NUMBER
    ADD SUM, AL
    ADD SI, COLS            ; EVERY ELEMENT IN THE SAME COLUMN-DIFFERENT ROW ARE PLACED
    DEC DX
    CMP DX, 0
    JNZ SUMM
    MOV AL, SUM
    XLAT                    ; CONVERSION NEEDED INSTRUCTION
    MOV TAB_C[DI], AL
    INC DI
    LOOP TAB
    ; PRINT STEP
    MOV CX, COLS            ; COUNTER: Num OF CHARS
    LEA SI, TAB_C           ; ACCESS TO CHAR ARRAY
    ADD SI, COLS            ; MOVE SI TO ONE PAST THE END
    DEC SI                  ; MOVE SI TO THE LAST ELEMENT
PRINT:
    MOV AL, [SI]            ; LOAD CURRENT ELEMENT
    ; --- Print element in YELLOW using INT 10h AH=09h ---
    PUSH BX                 ; SAVE BX (COLOR WILL OVERWRITE BL)
    PUSH CX                 ; SAVE LOOP COUNTER (CX USED BY INT 10h)
    MOV AH, 09H             ; FUNCTION Num
    MOV BH, 0               ; PAGE Num
    MOV BL, 0EH             ; COLOR: YELLOW
    MOV CX, 1               ; PRINT 1 TIME
    INT 10H
    ; --- Advance cursor right ---
    MOV AH, 03H
    MOV BH, 0
    INT 10H                 ; READ CURSOR -> DH=ROW, DL=COL
    INC DL                  ; MOVE ONE COLUMN RIGHT
    MOV AH, 02H
    MOV BH, 0
    INT 10H                 ; SET NEW CURSOR POSITION
    ; --- Print space ---
    MOV AH, 09H
    MOV AL, ' '
    MOV BH, 0
    MOV BL, 07H             ; WHITE
    MOV CX, 1
    INT 10H
    ; --- Advance cursor again after space ---
    MOV AH, 03H
    MOV BH, 0
    INT 10H
    INC DL
    MOV AH, 02H
    MOV BH, 0
    INT 10H
    POP CX                  ; RESTORE LOOP COUNTER
    POP BX                  ; RESTORE BX
    DEC SI                  ; MOVE BACKWARDS THROUGH THE ARRAY
    LOOP PRINT
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
COLUMN_REDUCTION ENDP