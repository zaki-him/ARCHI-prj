TACHE4 PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    LEA SI, matrix
    MOV CX, ROWS              ; 4 rows
ROW_LOOP:
    PUSH CX
    MOV CX, COLS              ; 7 cols
    XOR BL, BL                ; Reset row sum
COL_LOOP:
    MOV AL, [SI]
    PUSH AX                   ; Save char for printing
    SUB AL, '0'               ; Convert to number
    ADD BL, AL                ; Accumulate numeric sum
    POP AX                    ; Restore char for printing
    ; --- Print element in WHITE using INT 10h AH=09h ---
    PUSH BX                   ; Save sum (BL will be used for color)
    PUSH CX                   ; Save col counter (CX used by INT 10h)
    MOV AH, 09h
    MOV BH, 0                 ; Page 0
    MOV BL, 07h               ; WHITE attribute
    MOV CX, 1                 ; Print 1 time
    INT 10h                   ; Print element with color
    ; --- Advance cursor right using INT 10h AH=03h + AH=02h ---
    MOV AH, 03h
    MOV BH, 0
    INT 10h                   ; Read cursor ? DH=row, DL=col
    INC DL                    ; Move one column right
    MOV AH, 02h
    MOV BH, 0
    INT 10h                   ; Set new cursor position
    ; --- Print space ---
    MOV AH, 09h
    MOV AL, ' '
    MOV BH, 0
    MOV BL, 07h               ; WHITE
    MOV CX, 1
    INT 10h
    ; Advance cursor again after space
    MOV AH, 03h
    MOV BH, 0
    INT 10h
    INC DL
    MOV AH, 02h
    MOV BH, 0
    INT 10h
    POP CX                    ; Restore col counter
    POP BX                    ; Restore sum
    INC SI
    LOOP COL_LOOP             ; Next column
    ; --- Print row sum in GREEN ---
    ADD BL, '0'               ; Convert sum to ASCII
    MOV AL, BL                ; Save char before BL overwritten
    PUSH CX
    MOV AH, 09h
    MOV BH, 0
    MOV BL, 0Ah               ; GREEN attribute
    MOV CX, 1
    INT 10h                   ; Print green sum digit
    ; Advance cursor after sum
    MOV AH, 03h
    MOV BH, 0
    INT 10h
    INC DL
    MOV AH, 02h
    MOV BH, 0
    INT 10h
    POP CX
    ; --- Move to next line using INT 10h AH=03h + AH=02h ---
    MOV AH, 03h
    MOV BH, 0
    INT 10h                   ; Read current cursor ? DH=row, DL=col
    INC DH                    ; Next row
    MOV DL, 0                 ; Reset to column 0
    MOV AH, 02h
    MOV BH, 0
    INT 10h                   ; Set cursor to start of next row
    POP CX
    LOOP ROW_LOOP
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
TACHE4 ENDP
