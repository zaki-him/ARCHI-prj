HORIZ_REFLECT PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH SI
    PUSH DI
 
    ; swap row 1 with row 4
    MOV CX, COLS             ; loop 7 times
    LEA SI, matrix           ; SI -> start of row 1
    LEA DI, matrix
    ADD DI, 3*COLS           ; DI -> start of row 4
 
SWAP_R1_R4:
    MOV AL, [SI]             ; AL = value from row 1
    MOV BL, [DI]             ; BL = value from row 4
    MOV [SI], BL             ; row 1 gets row 4 value
    MOV [DI], AL             ; row 4 gets row 1 value
    INC SI
    INC DI
    LOOP SWAP_R1_R4
 
    ; swap row 2 with row 3
    MOV CX, COLS             ; loop 7 times again
    LEA SI, matrix
    ADD SI, COLS             ; SI -> start of row 2
    LEA DI, matrix
    ADD DI, 2*COLS           ; DI -> start of row 3
 
SWAP_R2_R3:
    MOV AL, [SI]             ; AL = value from row 2
    MOV BL, [DI]             ; BL = value from row 3
    MOV [SI], BL             ; row 2 gets row 3 value
    MOV [DI], AL             ; row 3 gets row 2 value
    INC SI
    INC DI
    LOOP SWAP_R2_R3
 
    POP DI
    POP SI
    POP CX
    POP BX
    POP AX
    RET
HORIZ_REFLECT ENDP
 
 
; ────────────────────────────────────────────────────────────
; ────────────────────────────────────────────────────────────
VERT_REFLECT PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
 
    MOV DX, 0                ; DX = current row offset
 
NEXT_ROW:
    LEA SI, matrix
    ADD SI, DX               ; SI -> first element of row
    LEA DI, matrix
    ADD DI, DX
    ADD DI, COLS-1           ; DI -> last element of row
 
    MOV CX, COLS/2           ; swap 3 times per row
                             ; middle element stays in place
 
SWAP_COLS:
    MOV AL, [SI]             ; AL = left value
    MOV BL, [DI]             ; BL = right value
    MOV [SI], BL             ; left gets right value
    MOV [DI], AL             ; right gets left value
    INC SI                   ; left pointer moves right
    DEC DI                   ; right pointer moves left
    LOOP SWAP_COLS
 
    ADD DX, COLS             ; move to next row
    CMP DX, ROWS*COLS        ; finished all rows?
    JL NEXT_ROW              ; if not go to next row
 
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
VERT_REFLECT ENDP
 