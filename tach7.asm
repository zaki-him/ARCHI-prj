
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
 
