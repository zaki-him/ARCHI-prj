;================================================================
; 2_lessons_on_matrices.asm
; Project Architecture II - L2 ACAD A 2025/2026
;
; Modular program : 2 lessons on a 4x7 data matrix.
;   Lesson 1 (preprocessing) : tasks 1..5
;   Lesson 2 (processing)    : tasks 6..7
;
; Scheduling :
;   INT 1Ch periodic handler (~18.2 Hz, 55 ms) drives a 30-second
;   quantum. Each quantum the main loop runs the next task of the
;   16-step scenario:
;        1 2 3 4 5 1 2 3 4 5 6 7 6 7 6 7
;
; Bonus extension :
;   The 1Ch ISR also polls the keyboard. Pressing SPACE toggles a
;   "paused" flag : when paused the quantum counter freezes, so the
;   user can stop and resume the lesson sequence at will, with no
;   change to the main program structure.
;================================================================

MYSTACK SEGMENT PARA STACK
    DW 256 DUP(?)
MYSTACK ENDS

DATA SEGMENT
    ;---- working matrix and a backup copy used to reset cycles ----
    matrix      DB '9','7','?','2','1','-','2'
                DB '4','M','8','2','6','3','F'
                DB '9','%','?','4','&','6','7'
                DB '0','/','6','2','*','=','8'

    matrix_orig DB '9','7','?','2','1','-','2'
                DB '4','M','8','2','6','3','F'
                DB '9','%','?','4','&','6','7'
                DB '0','/','6','2','*','=','8'

    ROWS  EQU 4
    COLS  EQU 7
    TOTAL EQU 28

    ;---- color attributes used by the modules ----
    BLANC EQU 0Fh
    ROUGE EQU 04h
    VERT  EQU 0Ah
    JAUNE EQU 0Eh

    color           DB 28 DUP(0Fh)
    use_color_array DB 0

    ;----    helpers ----
    SUM       DB ?
    TAB_C     DB 7 DUP(?)
    TAB_ASCII DB '0123456789'
              DB 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
              DB 'abcdefghijklmnopqrstuvwxyz'
              DB ' !"#$&()*+,-./:;<=>?@[]^_`{|}~'

    ;---- 1Ch scheduling state ----
    tick_count   DW 0
    TICKS_QUANTUM EQU 55         ; 18.2 * 3  (TEST: 3 seconds)
    task_ready   DB 1            ; first task fires immediately
    paused       DB 0
    old_1ch_off  DW 0
    old_1ch_seg  DW 0

    ;---- 16-step scenario ----
    scenario   DB 1,2,3,4,5, 1,2,3,4,5, 6,7, 6,7, 6,7
    SCEN_LEN   EQU 16
    scen_index DB 0

    ;---- titles ----
    title_pre  DB 'MATRIX PREPROCESSING','$'
    title_proc DB 'MATRIX PROCESSING','$'

    ;---- task name strings ----
    name_t1 DB '________________Matrix__________________','$'
    name_t2 DB '__________Step 1: Matrix Data Cleaning__________','$'
    name_t3 DB '________Step 2: Matrix Data Normalization________','$'
    name_t4 DB '________Step 3: Matrix Reduction on Rows________','$'
    name_t5 DB '__Step 4: Matrix Reduction on Rows and Columns__','$'
    name_t6 DB '_______Horizontal Reflexion of the Matrix_______','$'
    name_t7 DB '________Vertical Reflexion of the Matrix________','$'

    ;---- date / time ----
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

;================================================================
;  INT 1Ch handler  (preserves all registers it touches)
;================================================================
new_1ch PROC FAR
    PUSH AX
    PUSH DS

    MOV AX, DATA
    MOV DS, AX

    ; --- bonus : any key fires the next task immediately ---
    MOV AH, 01h
    INT 16h                      ; ZF=0 if a key is waiting
    JZ  ich_no_key
    MOV AH, 00h
    INT 16h                      ; consume it
    MOV tick_count, 0
    MOV task_ready, 1
    JMP ich_exit
ich_no_key:

    INC tick_count
    MOV AX, tick_count
    CMP AX, TICKS_QUANTUM
    JB  ich_exit
    MOV tick_count, 0
    MOV task_ready, 1

ich_exit:
    POP DS
    POP AX
    IRET
new_1ch ENDP

;================================================================
;  install / restore vector 1Ch
;================================================================
INSTALL_1CH PROC
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH ES
    PUSH DS
    MOV AH, 35h
    MOV AL, 1Ch
    INT 21h                      ; ES:BX = previous handler
    MOV old_1ch_off, BX
    MOV AX, ES
    MOV old_1ch_seg, AX
    MOV AX, CS
    MOV DS, AX
    MOV DX, OFFSET new_1ch
    MOV AH, 25h
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
    MOV DX, old_1ch_off
    MOV AX, old_1ch_seg
    MOV DS, AX
    MOV AH, 25h
    MOV AL, 1Ch
    INT 21h
    POP DS
    POP DX
    POP AX
    RET
RESTORE_1CH ENDP

;================================================================
;  small helpers
;================================================================
CLEAR_SCREEN PROC
    PUSH AX
    MOV AH, 00h
    MOV AL, 03h
    INT 10h
    POP AX
    RET
CLEAR_SCREEN ENDP

PRINT_STR PROC                       ; in: DX = $-string
    PUSH AX
    MOV AH, 09h
    INT 21h
    POP AX
    RET
PRINT_STR ENDP

GOTO_XY PROC                         ; in: DH=row, DL=col
    PUSH AX
    PUSH BX
    MOV AH, 02h
    MOV BH, 0
    INT 10h
    POP BX
    POP AX
    RET
GOTO_XY ENDP

; PRINT_2DIG : print AL as a 2-digit decimal number
PRINT_2DIG PROC
    PUSH AX
    PUSH BX
    PUSH DX
    XOR AH, AH
    MOV BL, 10
    DIV BL                           ; AL=tens, AH=units
    MOV BL, AH                       ; save units in BL
    ADD AL, '0'
    MOV DL, AL
    MOV AH, 02h
    INT 21h
    MOV DL, BL
    ADD DL, '0'
    MOV AH, 02h
    INT 21h
    POP DX
    POP BX
    POP AX
    RET
PRINT_2DIG ENDP

; PRINT_DEC4 : prints AX as a 4-digit decimal number (year).
;              Splits the digits onto the stack, then emits them.
PRINT_DEC4 PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX
    MOV CX, 4
    MOV BX, 10
pd4_split:
    XOR DX, DX
    DIV BX                           ; AX/10 -> AX=quot, DX=remainder digit
    PUSH DX                          ; save digit (low order first)
    LOOP pd4_split
    MOV CX, 4
pd4_emit:
    POP DX
    ADD DL, '0'
    MOV AH, 02h
    INT 21h
    LOOP pd4_emit
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_DEC4 ENDP

;================================================================
;  PRINT_DATETIME : prints a single line like
;     Monday, March 17, 2026     17:15:02
;================================================================
PRINT_DATETIME PROC
    PUSH AX
    PUSH BX
    PUSH CX
    PUSH DX

    ; --- date : INT 21h AH=2Ah  CX=year, DH=month, DL=day, AL=dow ---
    MOV AH, 2Ah
    INT 21h
    PUSH CX                           ; save year
    PUSH DX                           ; save month/day

    ; day-of-week name
    MOV BL, AL
    MOV AL, DAY_LEN
    MUL BL                            ; AX = AL * BL
    MOV BX, AX
    LEA DX, days_tbl
    ADD DX, BX
    MOV AH, 09h
    INT 21h

    LEA DX, sep
    MOV AH, 09h
    INT 21h

    ; day number
    POP DX                            ; DL=day, DH=month
    PUSH DX
    MOV AL, DL
    CALL PRINT_2DIG

    LEA DX, slash
    MOV AH, 09h
    INT 21h

    ; month
    POP DX
    MOV AL, DH
    CALL PRINT_2DIG

    LEA DX, slash
    MOV AH, 09h
    INT 21h

    ; year
    POP AX                            ; year in AX
    CALL PRINT_DEC4

    ; gap
    LEA DX, sep
    MOV AH, 09h
    INT 21h
    LEA DX, sep
    MOV AH, 09h
    INT 21h

    ; --- time : AH=2Ch  CH=hh, CL=mm, DH=ss ---
    MOV AH, 2Ch
    INT 21h
    PUSH DX
    PUSH CX
    MOV AL, CH
    CALL PRINT_2DIG
    LEA DX, colon
    MOV AH, 09h
    INT 21h
    POP CX
    PUSH CX
    MOV AL, CL
    CALL PRINT_2DIG
    LEA DX, colon
    MOV AH, 09h
    INT 21h
    POP CX
    POP DX
    MOV AL, DH
    CALL PRINT_2DIG

    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_DATETIME ENDP

;================================================================
;  RESET_MATRIX : copies matrix_orig back into matrix
;================================================================
RESET_MATRIX PROC
    PUSH AX
    PUSH CX
    PUSH SI
    PUSH DI
    LEA SI, matrix_orig
    LEA DI, matrix
    MOV CX, TOTAL
rm_loop:
    MOV AL, [SI]
    MOV [DI], AL
    INC SI
    INC DI
    LOOP rm_loop
    POP DI
    POP SI
    POP CX
    POP AX
    RET
RESET_MATRIX ENDP

;================================================================
;  RUN_HEADER : clear screen, print date/time line, title and
;               task name. AL = task number (1..7).
;================================================================
RUN_HEADER PROC
    PUSH AX
    PUSH BX
    PUSH DX

    CALL CLEAR_SCREEN

    ; line 0 : date / time
    MOV DH, 0
    MOV DL, 0
    CALL GOTO_XY
    CALL PRINT_DATETIME

    ; line 2 : title
    MOV DH, 2
    MOV DL, 20
    CALL GOTO_XY
    CMP AL, 6
    JL  rh_pre
    LEA DX, title_proc
    JMP rh_pt
rh_pre:
    LEA DX, title_pre
rh_pt:
    PUSH AX
    MOV AH, 09h
    INT 21h
    POP AX

    ; line 4 : task name
    MOV DH, 4
    MOV DL, 10
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
    MOV AH, 09h
    INT 21h

    ; line 7 : matrix area starts here
    MOV DH, 7
    MOV DL, 20
    CALL GOTO_XY

    POP DX
    POP BX
    POP AX
    RET
RUN_HEADER ENDP

;================================================================
;  RUN_TASK : dispatches task in AL (1..7).
;             Resets the matrix at the start of every lesson-1 cycle
;             (i.e. before each task 1).
;================================================================
RUN_TASK PROC
    PUSH AX
    PUSH BX

    ; reset matrix at the start of every lesson-1 cycle
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

;================================================================
;                              MAIN
;================================================================
MAIN:
    MOV AX, DATA
    MOV DS, AX
    MOV ES, AX

    CALL CLEAR_SCREEN
    CALL INSTALL_1CH

main_loop:
    ; wait until the 1Ch ISR signals "task ready"
wait_quantum:
    CMP task_ready, 1
    JNE wait_quantum

    MOV task_ready, 0

    ; fetch the next task number from the scenario
    MOV BL, scen_index
    XOR BH, BH
    MOV AL, scenario[BX]
    CALL RUN_TASK

    ; advance the scenario index
    INC scen_index
    MOV AL, scen_index
    CMP AL, SCEN_LEN
    JB  main_loop

    ; --- end of scenario ---
    CALL RESTORE_1CH
    LEA DX, msg_end
    MOV AH, 09h
    INT 21h
    MOV AH, 08h
    INT 21h                          ; wait for any key
    MOV AH, 4Ch
    INT 21h

CODE ENDS
END MAIN
