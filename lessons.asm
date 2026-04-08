
; 2_lessons_sur_les_matrices
; Projet Architecture II - L2 ACAD A 2025/2026
;
; Programme modulaire : 2 lecons sur une matrice de donnees 4x7.
;
;   Lecon 1 (pretraitement) : taches 1 _ 5
;    Lecon 2 (traitement) : taches 6 _ 7
;
; Ordonnancement :
;   Le gestionnaire periodique INT 1Ch (~18,2 Hz, 55 ms) pilote un quantum
;   de 30 secondes. chaque quantum, la boucle principale execute la tache
;   suivante du scenario en 16 etapes :
;
;                1 2 3 4 5 1 2 3 4 5 6 7 6 7 6 7
;
; Extension bonus :
;   L'ISR 1Ch interroge ?galement le clavier. L'appui sur ESPACE bascule
;   un drapeau de pause : lorsque le programme est en pause, le compteur
;   de quantum se fige, permettant ainsi a l'utilisateur d'arreter et de
;   reprendre la sequence de lecons a volonte, sans modifier la structure
;   du programme principal.


; Pile d'execution
MYSTACK SEGMENT PARA STACK
    DW 256 DUP(?)               ; 256 mots pour la pile
MYSTACK ENDS

DATA SEGMENT
;    matrice de travail et copie pour reinitialisation 
    matrix      DB '9','7','e','2','1','-','2'   ; matrice 4x7
                DB '4','M','8','2','6','3','F'
                DB '9','%','e','4','&','6','7'
                DB '0','/','6','2','*','=','8'

    matrix_orig DB '9','7','e','2','1','-','2'   ; sauvegarde originale
                DB '4','M','8','2','6','3','F'
                DB '9','%','e','4','&','6','7'
                DB '0','/','6','2','*','=','8'

    ROWS  EQU 4                 ; nombre de lignes
    COLS  EQU 7                 ; nombre de colonnes
    TOTAL EQU 28                ; taille totale

    ;---- attributs de couleur ----
    BLANC EQU 0Fh               ; blanc
    ROUGE EQU 04h               ; rouge
    VERT  EQU 0Ah               ; vert
    JAUNE EQU 0Eh               ; jaune

    color           DB 28 DUP(0Fh) ; couleur par cellule
    use_color_array DB 0           ; drapeau colorisation

    ;---- variables utilitaires ----
    SUM       DB ?               ; accumulateur de somme
    TAB_C     DB 7 DUP(?)        ; sommes de colonnes
    TAB_ASCII DB '0123456789'    ; table XLAT pour conversion
              DB 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
              DB 'abcdefghijklmnopqrstuvwxyz'
              DB ' !"#$&()*+,-./:;<=>e@[]^_`{|}~'

    ;---- etat ordonnancement INT 1Ch ----
    tick_count   DW 0             ; compteur de tics
    TICKS_QUANTUM EQU 550          ; quantum = 30 sec (TEST)
    task_ready   DB 1             ; pret pour la prochaine tache
    paused       DB 0             ; drapeau pause
    old_1ch_off  DW 0             ; ancien offset vecteur 1Ch
    old_1ch_seg  DW 0             ; ancien segment vecteur 1Ch

    ;---- scenario 16 etapes ----
    scenario   DB 1,2,3,4,5, 1,2,3,4,5, 6,7, 6,7, 6,7  ; ordre des taches
    SCEN_LEN   EQU 16             ; longueur du scenario
    scen_index DB 0               ; indice courant

    ;----les titres ----
    title_pre  DB 'MATRIX PREPROCESSING','$'
    title_proc DB 'MATRIX PROCESSING','$'

    ;----les noms des taches en string ----
    name_t1 DB '________________Matrix__________________','$'
    name_t2 DB '__________Step 1: Matrix Data Cleaning__________','$'
    name_t3 DB '________Step 2: Matrix Data Normalization________','$'
    name_t4 DB '________Step 3: Matrix Reduction on Rows________','$'
    name_t5 DB '__Step 4: Matrix Reduction on Rows and Columns__','$'
    name_t6 DB '_______Horizontal Reflexion of the Matrix_______','$'
    name_t7 DB '________Vertical Reflexion of the Matrix________','$'

    ;---- date / temps ----
    days_tbl   DB 'Sunday   $','Monday   $','Tuesday  $','Wednesday$'
               DB 'Thursday $','Friday   $','Saturday $'
    DAY_LEN    EQU 10

    msg_paused DB 0Dh,0Ah,'   [PAUSED  -  press SPACE to resume]','$'
    msg_end    DB 0Dh,0Ah,0Dh,0Ah,'Program finished. Press a key...','$'
    sep        DB ', ','$'
    space1     DB ' ','$'
    colon      DB ':','$'
    slash      DB '/','$'

DATA ENDS

CODE SEGMENT
    ASSUME CS:CODE, DS:DATA, SS:MYSTACK

INCLUDE task1.asm
INCLUDE tachee2.asm
INCLUDE task3.asm
INCLUDE tache4.asm
INCLUDE task5.asm
INCLUDE task67.asm


;  Gestionnaire INT 1Ch  (preserver les registres)

new_1ch PROC FAR
    PUSH AX
    PUSH DS

    MOV AX, DATA                 ; initialiser segment donnees
    MOV DS, AX

    ; --- verifier clavier pour lancer tache immediatement ---
    MOV AH, 01h                  ; statut clavier
    INT 16h                      ; ZF=0 si touche en attente
    JZ  ich_no_key
    MOV AH, 00h
    INT 16h                      ; consommer la touche
    MOV tick_count, 0            ; reinitialiser le compteur
    MOV task_ready, 1            ; signale que la tache est prete
    JMP ich_exit
ich_no_key:

    INC tick_count               ; incrementer le compteur
    MOV AX, tick_count
    CMP AX, TICKS_QUANTUM        ; quantum atteindre 
    JB  ich_exit
    MOV tick_count, 0            ; reinitialiser
    MOV task_ready, 1            ; lancer la tache

ich_exit:
    POP DS
    POP AX
    IRET
new_1ch ENDP


;  installer/restaurer le vecteur d'interruption 1Ch

INSTALL_1CH PROC
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH ES
    PUSH DS
    MOV AH, 35h                  ; recuperer l' ancien vecteur
    MOV AL, 1Ch
    INT 21h                      ; ES:BX = ancien gestionnaire
    MOV old_1ch_off, BX          ; sauvegarder l' offset
    MOV AX, ES
    MOV old_1ch_seg, AX          ; sauvegarder la segment
    MOV AX, CS                   ; nouveau segment = code courant
    MOV DS, AX
    MOV DX, OFFSET new_1ch       ; adresse du nouveau gestionnaire
    MOV AH, 25h                  ; installer le nouveau vecteur
    MOV AL, 1Ch
    INT 21h
    POP DS
    POP ES
    POP DX
    POP BX  
    POP AX
    RET
INSTALL_1CH ENDP

RESTORE_1CH PROC
    PUSH AX
    PUSH DX
    PUSH DS
    MOV DX, old_1ch_off          ; recuperer l' ancien offset
    MOV AX, old_1ch_seg          ; recuperation d' ancien segment
    MOV DS, AX
    MOV AH, 25h                  ; restauresation d' ancien vecteur
    MOV AL, 1Ch
    INT 21h
    POP DS
    POP DX
    POP AX
    RET
RESTORE_1CH ENDP


;  petites fonctions utilitaires

CLEAR_SCREEN PROC
    PUSH AX                      ; sauvegardement de AX
    MOV AH, 00h                  ; mode video
    MOV AL, 03h                  ; texte 80x25, clair
    INT 10h                      ; BIOS : effacer l' ecran
    POP AX
    RET
CLEAR_SCREEN ENDP

PRINT_STR PROC                   ; entre: DX = chaine $
    PUSH AX                      ; sauvegarder AX
    MOV AH, 09h                  ; DOS : afficher la chaine de caractere
    INT 21h                      ; arret au '$'
    POP AX
    RET
PRINT_STR ENDP

GOTO_XY PROC                     ; entre: DH=ligne, DL=colonne
    PUSH AX                      ; sauvegarder AX
    PUSH BX                      ; sauvegarder BX
    MOV AH, 02h                  ; BIOS : positioner curseur
    MOV BH, 0                    ; page video 0
    INT 10h
    POP BX
    POP AX
    RET
GOTO_XY ENDP

; PRINT_2DIG : affiche AL en decimal 2 chiffres

PRINT_2DIG PROC
    PUSH AX                      ; sauvegarde registres
    PUSH BX
    PUSH DX
    XOR AH, AH                   ; AX = AL (zero le haut)
    MOV BL, 10                   ; diviseur
    DIV BL                       ; AL=dizaines, AH=unites
    MOV BL, AH                   ; sauvegarder unites
    ADD AL, '0'                  ; convertir en ASCII
    MOV DL, AL
    MOV AH, 02h                  ; afficher dizaine
    INT 21h
    MOV DL, BL                   ; unite
    ADD DL, '0'                  ; convertir en ASCII
    MOV AH, 02h                  ; affichege d' unite
    INT 21h
    POP DX
    POP BX
    POP AX
    RET
PRINT_2DIG ENDP

; PRINT_DEC4 : affiche AX en 4 chiffres decimaux (annee)
;              Empilement des chiffres, puis les afficher
PRINT_DEC4 PROC
    PUSH AX                      ; sauvegarder registres
    PUSH BX
    PUSH CX
    PUSH DX
    MOV CX, 4                    ; les 4 chiffres
    MOV BX, 10                   ; diviseur
pd4_split:
    XOR DX, DX                   ; zeroiser DX
    DIV BX                       ; AX/10 -> AX=quotient, DX=chiffre
    PUSH DX                      ; empiler chiffre
    LOOP pd4_split               ; 4 fois
    MOV CX, 4                    ; 4 chiffres sont afficher
pd4_emit:
    POP DX                       ; depiler le chiffre
    ADD DL, '0'                  ; convertion en ASCII
    MOV AH, 02h                  ; afficher le  caractere
    INT 21h
    LOOP pd4_emit                ; afficher tous
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_DEC4 ENDP


;  PRINT_DATETIME : affiche "Lundi, 17/03/2026     17:15:02"

PRINT_DATETIME PROC
    PUSH AX                      ; sauvegarder registres
    PUSH BX
    PUSH CX
    PUSH DX

    ; --- recuperer date : INT 21h AH=2Ah -> CX=annee, DH=mois, DL=jour, AL=jour_semaine ---
    MOV AH, 2Ah
    INT 21h                      ; appel systeme DOS
    PUSH CX                      ; empiler annee
    PUSH DX                      ; empiler mois/jour

    ; afficher nom du jour de la semaine
    MOV BL, AL                   ; AL = index jour
    MOV AL, DAY_LEN              ; taille d'une entree (10)
    MUL BL                       ; offset dans days_tbl
    MOV BX, AX
    LEA DX, days_tbl             ; adresse table jours
    ADD DX, BX                   ; pointer sur le jour
    MOV AH, 09h                  ; affichge du nom de jour
    INT 21h

    LEA DX, sep                  ; afficher une virgule
    MOV AH, 09h
    INT 21h

    ; afficher numero du jour
    POP DX                       ; DL=jour, DH=mois
    PUSH DX
    MOV AL, DL                   ; jour dans AL
    CALL PRINT_2DIG              ; afficher les 2 chiffres

    LEA DX, slash                ; afficher "/"
    MOV AH, 09h
    INT 21h

    ; afficher mois
    POP DX
    MOV AL, DH                   ; mois dans AL
    CALL PRINT_2DIG              ; afficher les 2 chiffres

    LEA DX, slash                ; afficher "/"
    MOV AH, 09h
    INT 21h

    ; afficher annee (4 chiffres)
    POP AX                       ; annee dans AX
    CALL PRINT_DEC4

    ; espacements
    LEA DX, sep
    MOV AH, 09h
    INT 21h
    LEA DX, sep
    MOV AH, 09h
    INT 21h

    ; --- recuperation de l' heure : INT 21h AH=2Ch -> CH=hh, CL=mm, DH=ss ---
    MOV AH, 2Ch
    INT 21h                      ; appel systeme DOS
    PUSH DX                      ; empiler secondes
    PUSH CX                      ; empiler minutes
    MOV AL, CH                   ; heures
    CALL PRINT_2DIG              ; afficher les heures

    LEA DX, colon                ; afficher ":"
    MOV AH, 09h
    INT 21h

    POP CX
    PUSH CX
    MOV AL, CL                   ; minutes
    CALL PRINT_2DIG              ; afficher les minutes

    LEA DX, colon                ; afficher ":"
    MOV AH, 09h
    INT 21h

    POP CX
    POP DX
    MOV AL, DH                   ; secondes
    CALL PRINT_2DIG              ; afficher les secondes

    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_DATETIME ENDP


;  RESET_MATRIX : restaure la matrice originale

RESET_MATRIX PROC
    PUSH AX                      ; sauvegarder registres
    PUSH CX
    PUSH SI
    PUSH DI
    LEA SI, matrix_orig          ; SI = copie originale
    LEA DI, matrix               ; DI = matrice travail
    MOV CX, TOTAL                ; 28 octets a copier
rm_loop:
    MOV AL, [SI]                 ; charger un octet
    MOV [DI], AL                 ; copier a la destination
    INC SI                       ; incrementer source
    INC DI                       ; incrementer destination
    LOOP rm_loop                 ; boucler 28 fois
    POP DI
    POP SI
    POP CX
    POP AX
    RET
RESET_MATRIX ENDP


;  RUN_HEADER : effacer ecran, afficher date/heure/titre/nom tache
;               AL = numero tache (1..7)

RUN_HEADER PROC
    PUSH AX                      ; sauvegarder registres
    PUSH BX
    PUSH DX

    CALL CLEAR_SCREEN            ; effacer l'ecran

    ; ligne 0 : afficher date/heure
    MOV DH, 0                    ; ligne 0
    MOV DL, 0                    ; colonne 0
    CALL GOTO_XY                 ; positionnement du curseur
    CALL PRINT_DATETIME          ; afficher la date/heure

    ; ligne 2 : afficher titre
    MOV DH, 2                    ; ligne 2
    MOV DL, 20                   ; colonne 20
    CALL GOTO_XY
    CMP AL, 6                    ; tache >= 6 
    JL  rh_pre                   ; non : pretraitement
    LEA DX, title_proc           ; oui : traitement
    JMP rh_pt
rh_pre:
    LEA DX, title_pre            ; titre pretraitement
rh_pt:
    PUSH AX
    MOV AH, 09h                  ; afficher le titre
    INT 21h
    POP AX

    ; ligne 4 : afficher le nom de la tache
    MOV DH, 4                    ; ligne 4
    MOV DL, 10                   ; colonne 10
    CALL GOTO_XY
    CMP AL, 1                     
    JNE rh_n2
    LEA DX, name_t1
    JMP rh_print
rh_n2:
    CMP AL, 2
    JNE rh_n3
    LEA DX, name_t2
    JMP rh_print
rh_n3:
    CMP AL, 3
    JNE rh_n4
    LEA DX, name_t3
    JMP rh_print
rh_n4:
    CMP AL, 4
    JNE rh_n5
    LEA DX, name_t4
    JMP rh_print
rh_n5:
    CMP AL, 5
    JNE rh_n6
    LEA DX, name_t5
    JMP rh_print
rh_n6:
    CMP AL, 6
    JNE rh_n7
    LEA DX, name_t6
    JMP rh_print
rh_n7:
    LEA DX, name_t7
rh_print:
    MOV AH, 09h                  ; afficher le nom de la tache
    INT 21h

    ; ligne 7 : la matrice commence ici
    MOV DH, 7
    MOV DL, 20
    CALL GOTO_XY

    POP DX
    POP BX
    POP AX
    RET
RUN_HEADER ENDP


;  RUN_TASK : Les taches 1 ? 7 sont reparties dans le registre AL (1..7).
;             La matrice est reinitialisee avant chaque nouvelle "lesson-1".             

RUN_TASK PROC
    PUSH AX
    PUSH BX

    ; reinitialisation de la matrice chaque debut de lesson 1
    CMP AL, 1
    JNE rt_no_reset
    CALL RESET_MATRIX
    MOV use_color_array, 0
rt_no_reset:

    PUSH AX
    CALL RUN_HEADER
    POP AX

    CMP AL, 1
    JNE rt_t2
    MOV use_color_array, 0
    CALL display_matrix
    JMP rt_done
rt_t2:
    CMP AL, 2
    JNE rt_t3
    CALL CleanMatrix
    MOV use_color_array, 1
    CALL display_matrix
    MOV use_color_array, 0
    JMP rt_done
rt_t3:
    CMP AL, 3
    JNE rt_t4
    CALL tache3
    CALL display_matrix
    JMP rt_done
rt_t4:
    CMP AL, 4
    JNE rt_t5
    CALL TACHE4
    JMP rt_done
rt_t5:
    CMP AL, 5
    JNE rt_t6
    CALL TACHE4
    CALL COLUMN_REDUCTION
    JMP rt_done
rt_t6:
    CMP AL, 6
    JNE rt_t7
    CALL HORIZ_REFLECT
    CALL display_matrix
    JMP rt_done
rt_t7:
    CALL VERT_REFLECT
    CALL display_matrix
rt_done:
    POP BX
    POP AX
    RET
RUN_TASK ENDP


;                       LE       MAIN

MAIN:
    MOV AX, DATA
    MOV DS, AX
    MOV ES, AX

    CALL CLEAR_SCREEN
    CALL INSTALL_1CH

main_loop:
    ; attente jusqu' a ISR signale "tache prete"
wait_quantum:
    CMP task_ready, 1
    JNE wait_quantum

    MOV task_ready, 0

    ; extrait le numero de la tache suivante du scenario.
    MOV BL, scen_index
    XOR BH, BH
    MOV AL, scenario[BX]
    CALL RUN_TASK

    ; avancement de scenario index
    INC scen_index
    MOV AL, scen_index
    CMP AL, SCEN_LEN
    JB  main_loop

    ; --- fin de scenario ---
    CALL RESTORE_1CH
    LEA DX, msg_end
    MOV AH, 09h
    INT 21h
    MOV AH, 08h
    INT 21h                          ; en attente pour une touche sur le clavier
    MOV AH, 4Ch
    INT 21h

CODE ENDS
END MAIN
