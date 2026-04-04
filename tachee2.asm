; --- Process: Replace non-digits with '0' and set color to Red (04h) ---
CleanMatrix PROC
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI

    MOV SI, OFFSET matrix
    MOV DI, OFFSET color
    MOV CX, TOTAL

Next_Element:
    MOV AL, [SI]
    CMP AL, '0'
    JB Is_Not_Digit
    CMP AL, '9'
    JA Is_Not_Digit
    JMP Continue_Clean

Is_Not_Digit:
    MOV BYTE PTR [SI], '0'
    MOV BYTE PTR [DI], 04h          ; Red attribute

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
    MOV CX, TOTAL
    MOV DL, 0                       ; Column counter
    MOV DH, 0                       ; Row tracker (for cursor)

Display_Loop:
    ; 1. Set Cursor Position (Required for INT 10h AH=09h)
    MOV AH, 02h
    MOV BH, 00
    ; DH and DL are managed below
    INT 10h

    ; 2. Print Character with Attribute
    MOV AL, [SI]                    ; Character to print
    MOV BL, [DI]                    ; Color attribute
    MOV AH, 09h
    MOV BH, 00
    PUSH CX                         ; Save total loop counter
    MOV CX, 1                       ; Repeat count for INT 10h
    INT 10h
    POP CX                          ; Restore total loop counter

    ; 3. Increment Pointers and Column
    INC SI
    INC DI
    INC DL                          ; Move cursor column right

    ; Check if we need a new line
    CMP DL, COLS
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
