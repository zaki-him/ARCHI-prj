display_matrix PROC FAR
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    PUSH SI
    PUSH DI
    MOV SI, 0               ; SI = index ligne 
lig:
    CMP SI, ROWS            
    JGE fin_mat
    LEA DX, space2          
    MOV AH, 09h
    INT 21h
    MOV DI, 0               

col:
    CMP DI, COLS            
    JGE fin_lig
    ; Calculer adresse : matrix[SI*COLS + DI]
    MOV AX, SI
    MOV BX, COLS
    MUL BX                  
    ADD AX, DI            
    MOV BX, AX
    MOV AL, matrix[BX]      ; AL = element courant
    CMP AL, '0'
    JB  rouge               ; < '0' -> rouge
    CMP AL, '9'
    JA  rouge               ; > '9' -> rouge
    MOV BL, BLANC           
    JMP aff
rouge:
    MOV BL, ROUGE           
aff:
    ; Afficher le caractere avec couleur 
    MOV AH, 09h
    MOV BH, 00h
    MOV CX, 1
    INT 10h
    ; Avancer le curseur 
    MOV AH, 02h
    MOV DL, AL             ; AL contient le caractere
    INT 21h                ; affiche + avance curseur automatiquement
    ; Afficher espace separateur 
    MOV AH, 02h
    MOV DL, ' '
    INT 21h
    INC DI                  ; colonne suivante
    JMP col
fin_lig:
    ; Nouvelle ligne 
    MOV AH, 02h
    MOV DL, 0Dh            ; met le curseur au d?but de la ligne
    INT 21h
    MOV AH, 02h
    MOV DL, 0Ah            ; descend le curseur dune ligne vers le bas
    INT 21h
    INC SI                 ; ligne suivante
    JMP lig
fin_mat:
    POP DI
    POP SI
    POP DX
    POP CX
    POP BX
    POP AX
    RET
display_matrix ENDP