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

; Execution stack
MYSTACK SEGMENT PARA STACK
    DW 256 DUP(?)               ; 256 words for the stack
MYSTACK ENDS

DATA SEGMENT
    ;---- working matrix and backup copy for reset ----
    matrix      DB '9','7','e','2','1','-','2'   ; 4x7 matrix
                DB '4','M','8','2','6','3','F'
                DB '9','%','e','4','&','6','7'
                DB '0','/','6','2','*','=','8'

    matrix_orig DB '9','7','e','2','1','-','2'   ; original backup
                DB '4','M','8','2','6','3','F'
                DB '9','%','e','4','&','6','7'
                DB '0','/','6','2','*','=','8'

    ROWS  EQU 4                 ; number of rows
    COLS  EQU 7                 ; number of columns
    TOTAL EQU 28                ; total size

    ;---- color attributes ----
    BLANC EQU 0Fh               ; white
    ROUGE EQU 04h               ; red
    VERT  EQU 0Ah               ; green
    JAUNE EQU 0Eh               ; yellow

    color           DB 28 DUP(0Fh) ; color per cell
    use_color_array DB 0           ; coloring flag

    ;---- helper variables ----
    SUM       DB ?               ; sum accumulator
    TAB_C     DB 7 DUP(?)        ; column sums
    TAB_ASCII DB '0123456789'    ; XLAT conversion table
              DB 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
              DB 'abcdefghijklmnopqrstuvwxyz'
              DB ' !"#$&()*+,-./:;<=>e@[]^_`{|}~'

    ;---- INT 1Ch scheduler state ----
    tick_count   DW 0             ; tick counter
    TICKS_QUANTUM EQU 55          ; quantum = 3 sec (TEST)
    task_ready   DB 1             ; ready for next task
    paused       DB 0             ; pause flag
    old_1ch_off  DW 0             ; old 1Ch vector offset
    old_1ch_seg  DW 0             ; old 1Ch vector segment

    ;---- 16-step scenario ----
    scenario   DB 1,2,3,4,5, 1,2,3,4,5, 6,7, 6,7, 6,7  ; task order
    SCEN_LEN   EQU 16             ; scenario length
    scen_index DB 0               ; current index

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
;  INT 1Ch handler  (preserves registers)
;================================================================
new_1ch PROC FAR
    PUSH AX
    PUSH DS

    MOV AX, DATA                 ; initialize data segment
    MOV DS, AX

    ; --- check keyboard to launch task immediately ---
    MOV AH, 01h                  ; keyboard status
    INT 16h                      ; ZF=0 if key is waiting
    JZ  ich_no_key
    MOV AH, 00h
    INT 16h                      ; consume the key
    MOV tick_count, 0            ; reset counter
    MOV task_ready, 1            ; signal task ready
    JMP ich_exit
ich_no_key:

    INC tick_count               ; increment counter
    MOV AX, tick_count
    CMP AX, TICKS_QUANTUM        ; quantum reached?
    JB  ich_exit
    MOV tick_count, 0            ; reset
    MOV task_ready, 1            ; launch the task

ich_exit:
    POP DS
    POP AX
    IRET
new_1ch ENDP

;================================================================
;  install/restore the 1Ch interrupt vector
;================================================================
INSTALL_1CH PROC
    PUSH AX
    PUSH BX
    PUSH DX
    PUSH ES
    PUSH DS
    MOV AH, 35h                  ; get old vector
    MOV AL, 1Ch
    INT 21h                      ; ES:BX = old handler
    MOV old_1ch_off, BX          ; save offset
    MOV AX, ES
    MOV old_1ch_seg, AX          ; save segment
    MOV AX, CS                   ; new segment = current code
    MOV DS, AX
    MOV DX, OFFSET new_1ch       ; address of new handler
    MOV AH, 25h                  ; install new vector
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
    MOV DX, old_1ch_off          ; retrieve old offset
    MOV AX, old_1ch_seg          ; retrieve old segment
    MOV DS, AX
    MOV AH, 25h                  ; restore old vector
    MOV AL, 1Ch
    INT 21h
    POP DS
    POP DX
    POP AX
    RET
RESTORE_1CH ENDP

;================================================================
;  small helper functions
;================================================================
CLEAR_SCREEN PROC
    PUSH AX                      ; save AX
    MOV AH, 00h                  ; video mode
    MOV AL, 03h                  ; text 80x25, clear
    INT 10h                      ; BIOS: clear screen
    POP AX
    RET
CLEAR_SCREEN ENDP

PRINT_STR PROC                   ; input: DX = string$
    PUSH AX                      ; save AX
    MOV AH, 09h                  ; DOS: display string
    INT 21h                      ; stops at '$'
    POP AX
    RET
PRINT_STR ENDP

GOTO_XY PROC                     ; input: DH=row, DL=col
    PUSH AX                      ; save AX
    PUSH BX                      ; save BX
    MOV AH, 02h                  ; BIOS: set cursor position
    MOV BH, 0                    ; video page 0
    INT 10h
    POP BX
    POP AX
    RET
GOTO_XY ENDP

; PRINT_2DIG : prints AL as a 2-digit decimal
PRINT_2DIG PROC
    PUSH AX                      ; save registers
    PUSH BX
    PUSH DX
    XOR AH, AH                   ; AX = AL (zero high byte)
    MOV BL, 10                   ; divisor
    DIV BL                       ; AL=tens, AH=units
    MOV BL, AH                   ; save units
    ADD AL, '0'                  ; convert to ASCII
    MOV DL, AL
    MOV AH, 02h                  ; print tens digit
    INT 21h
    MOV DL, BL                   ; units
    ADD DL, '0'                  ; convert to ASCII
    MOV AH, 02h                  ; print units digit
    INT 21h
    POP DX
    POP BX
    POP AX
    RET
PRINT_2DIG ENDP

; PRINT_DEC4 : prints AX as 4 decimal digits (year)
;              Pushes digits on stack, then prints them
PRINT_DEC4 PROC
    PUSH AX                      ; save registers
    PUSH BX
    PUSH CX
    PUSH DX
    MOV CX, 4                    ; 4 digits
    MOV BX, 10                   ; divisor
pd4_split:
    XOR DX, DX                   ; zero DX
    DIV BX                       ; AX/10 -> AX=quotient, DX=digit
    PUSH DX                      ; push digit
    LOOP pd4_split               ; 4 times
    MOV CX, 4                    ; 4 digits to print
pd4_emit:
    POP DX                       ; pop digit
    ADD DL, '0'                  ; convert to ASCII
    MOV AH, 02h                  ; print character
    INT 21h
    LOOP pd4_emit                ; print all
    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_DEC4 ENDP

;================================================================
;  PRINT_DATETIME : prints "Monday, 17/03/2026     17:15:02"
;================================================================
PRINT_DATETIME PROC
    PUSH AX                      ; save registers
    PUSH BX
    PUSH CX
    PUSH DX

    ; --- get date : INT 21h AH=2Ah -> CX=year, DH=month, DL=day, AL=dow ---
    MOV AH, 2Ah
    INT 21h                      ; DOS system call
    PUSH CX                      ; push year
    PUSH DX                      ; push month/day

    ; print day-of-week name
    MOV BL, AL                   ; AL = day index
    MOV AL, DAY_LEN              ; entry size (10)
    MUL BL                       ; offset into days_tbl
    MOV BX, AX
    LEA DX, days_tbl             ; address of days table
    ADD DX, BX                   ; point to the day
    MOV AH, 09h                  ; print string
    INT 21h

    LEA DX, sep                  ; print comma
    MOV AH, 09h
    INT 21h

    ; print day number
    POP DX                       ; DL=day, DH=month
    PUSH DX
    MOV AL, DL                   ; day in AL
    CALL PRINT_2DIG              ; print 2 digits

    LEA DX, slash                ; print "/"
    MOV AH, 09h
    INT 21h

    ; print month
    POP DX
    MOV AL, DH                   ; month in AL
    CALL PRINT_2DIG              ; print 2 digits

    LEA DX, slash                ; print "/"
    MOV AH, 09h
    INT 21h

    ; print year (4 digits)
    POP AX                       ; year in AX
    CALL PRINT_DEC4

    ; spacing
    LEA DX, sep
    MOV AH, 09h
    INT 21h
    LEA DX, sep
    MOV AH, 09h
    INT 21h

    ; --- get time : INT 21h AH=2Ch -> CH=hh, CL=mm, DH=ss ---
    MOV AH, 2Ch
    INT 21h                      ; DOS system call
    PUSH DX                      ; push seconds
    PUSH CX                      ; push minutes
    MOV AL, CH                   ; hours
    CALL PRINT_2DIG              ; print hours

    LEA DX, colon                ; print ":"
    MOV AH, 09h
    INT 21h

    POP CX
    PUSH CX
    MOV AL, CL                   ; minutes
    CALL PRINT_2DIG              ; print minutes

    LEA DX, colon                ; print ":"
    MOV AH, 09h
    INT 21h

    POP CX
    POP DX
    MOV AL, DH                   ; seconds
    CALL PRINT_2DIG              ; print seconds

    POP DX
    POP CX
    POP BX
    POP AX
    RET
PRINT_DATETIME ENDP

;================================================================
;  RESET_MATRIX : restores the original matrix
;================================================================
RESET_MATRIX PROC
    PUSH AX                      ; save registers
    PUSH CX
    PUSH SI
    PUSH DI
    LEA SI, matrix_orig          ; SI -> original copy
    LEA DI, matrix               ; DI -> working matrix
    MOV CX, TOTAL                ; 28 bytes to copy
rm_loop:
    MOV AL, [SI]                 ; load a byte
    MOV [DI], AL                 ; copy to destination
    INC SI                       ; increment source
    INC DI                       ; increment destination
    LOOP rm_loop                 ; loop 28 times
    POP DI
    POP SI
    POP CX
    POP AX
    RET
RESET_MATRIX ENDP

;================================================================
;  RUN_HEADER : clear screen, print date/time/title/task name
;               AL = task number (1..7)
;================================================================
RUN_HEADER PROC
    PUSH AX                      ; save registers
    PUSH BX
    PUSH DX

    CALL CLEAR_SCREEN            ; clear the screen

    ; line 0 : print date/time
    MOV DH, 0                    ; row 0
    MOV DL, 0                    ; column 0
    CALL GOTO_XY                 ; set cursor
    CALL PRINT_DATETIME          ; print date/time

    ; line 2 : print title
    MOV DH, 2                    ; row 2
    MOV DL, 20                   ; column 20
    CALL GOTO_XY
    CMP AL, 6                    ; task >= 6?
    JL  rh_pre                   ; no: preprocessing
    LEA DX, title_proc           ; yes: processing
    JMP rh_pt
rh_pre:
    LEA DX, title_pre            ; preprocessing title
rh_pt:
    PUSH AX
    MOV AH, 09h                  ; print title
    INT 21h
    POP AX

    ; line 4 : print task name
    MOV DH, 4                    ; row 4
    MOV DL, 10                   ; column 10
    CALL GOTO_XY
    CMP AL, 1                    ; which task?
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
    MOV AH, 09h                  ; print the name
    INT 21h

    ; line 7 : matrix starts here
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
