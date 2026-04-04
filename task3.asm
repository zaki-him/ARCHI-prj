tache3 PROC

    MOV SI, 0           ; on comence au premier element (indice 0)
    MOV CX, 28          ; compteur = 4 lignes * 7 colones = 28 elements

parcours:
    MOV AL, matrix[SI]  ; on charge l element courant dans AL
    CMP AL, 5           ; on compare avec 5
    JL trouver          ; si AL < 5 on saute vers trouver

    MOV matrix[SI], 1   ; on ecrit 1 a la place
    JMP etiq

trouver:
    MOV matrix[SI], 0   ; on ecrit 0 a la place

etiq:
    INC SI              ; on passe a l element suivant
    LOOP parcours       ; on boucle sur parcour

    RET

tache3 ENDP