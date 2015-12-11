DIM         EQU 50
K           EQU 1

            .MODEL small
            .STACK
            
            .DATA

FIRST_ROW   DB  DIM+2 DUP(?)
SECOND_ROW  DB  DIM+2 DUP(?)
THIRD_ROW   DB  DIM+2 DUP(?)
FOURTH_ROW  DB  DIM+2 DUP(?)

ROWS        DW  4   DUP(?)
DIMS        DW  4   DUP(?)

CHARS_TMP   DB  52  DUP(?)
CHARS_TOT   DB  52  DUP(?)    

MSG_CNT     DB  0Dh, 0AH, "The characters that appear a number of times = half the max", 0Dh, 0AH, "$"
MSG_MAX     DB  0Dh, 0AH, "The character that appears more times in all rows is:", 0Dh, 0AH, "$"

K_TMP       DW  ?  

ALPH        DB  "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
DIM_ALPH    DB  ?   
MSG_CAESAR  DB  0Dh, 0Ah, "Here the transformed text:", 0Dh, 0Ah, "$"  
                 
            .CODE
            .STARTUP

;-----------------------------------------------------------------
;----------Main---------------------------------------------------
;-----------------------------------------------------------------
            
            ; compute a table with the addresses for each row

            XOR BX,BX   ; initialize BX
            
            LEA BX, FIRST_ROW   ; store rows addresses in an array
            MOV ROWS, BX
            
            LEA BX, SECOND_ROW
            MOV ROWS+2, BX
            
            LEA BX, THIRD_ROW
            MOV ROWS+4, BX
            
            LEA BX, FOURTH_ROW
            MOV ROWS+6, BX
            
            ; fill the row arrays taking the chars in input
            
            MOV CX, 4   ; initialize CX for counting 4 rows
            XOR DI, DI  ; initialize DI as array index

read_rows:  XOR SI, SI  ; initialize SI for storing return value
            MOV BX, ROWS[DI]    ; the address of the current row to read
            PUSH SI
            PUSH BX
            CALL read_row       ; read row DI
            POP SI
            POP SI
            MOV DIMS[DI], SI    ; store the number of chars in row DI
            ADD DI,2
            LOOP read_rows   
            
            ; initialize the CHARS_TMP array
             
            MOV CX, 52
            XOR DI, DI
clear_vett: MOV CHARS_TMP[DI], 0
            INC DI
            LOOP clear_vett
            
            ; find the chars which appear half times the char appearing the most
            
            MOV CX, 4   ; initialize CX for counting 4 rows
            XOR DI, DI  ; initialize DI as array index
count_chars:MOV BX, ROWS[DI]    ; the address of the current row to read
            MOV SI, DIMS[DI]
            PUSH SI
            PUSH BX
            CALL search_char
            POP SI
            POP SI
            ADD DI,2
            LOOP count_chars
            
            ; find the char with the most occurrences
            ; considering all the four rows 
            
            LEA BX, CHARS_TOT
            XOR SI, SI
            PUSH SI
            PUSH BX
            CALL find_max   ; compute the maximum times of char occurences
            POP SI          ; store the char appearing the most
            POP DI          ; store the maximum occurence 
            
            ; print the character that appears more times
            
            LEA DX, MSG_MAX
            MOV AH, 09H
            INT 21H   
            
            CMP SI, 26
            JB small_caps   ; yes, its' a small caps char
            MOV DX, SI      ; no, it's a big caps char
            SUB DX, 26
            ADD DL, 'A'
            MOV AH, 2
            INT 21H 
small_caps: MOV DX, SI
            ADD DL, 'a'
            MOV AH, 2
            INT 21H  
            
            ; print CR and LF
            MOV DX, 13
            MOV AH, 2
            INT 21H           
            MOV DX, 10
            MOV AH, 2
            INT 21H
            
            ; Print the text after Caesar cipher transformation 
            ; after each row the current value of K is incremented
            ; by AX, where AX is the number of the current row
            
            LEA DX, MSG_CAESAR
            MOV AH, 09H
            INT 21H
            
            MOV CX, 4   ; initialize CX for counting 4 rows
            XOR AX, AX  ; initialize AX for using as adder for K
            XOR DI, DI  ; initialize DI as array index
            MOV SI, K   ; store into SI the k constant of Caesar cipher method
caesar_row: MOV BX, ROWS[DI]    ; the address of the current row to read
            PUSH DIMS[DI]       ; push the number of character in the current row
            PUSH SI             ; push the value of K
            PUSH BX             ; push the address of the current row
            CALL transform      ; transform row according to Caesar cipher
            POP SI
            POP SI
            ADD DI,2
            INC AX
            ADD SI,AX
            LOOP caesar_row                        
            
            JMP end_program	    ; end the program

;-----------------------------------------------------------------
;----------Procedure for reading a row of text--------------------
;-----------------------------------------------------------------

read_row    PROC        ;read one row of text

            PUSH BP
            MOV BP,SP   ; store the current value for SP
            
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            PUSH DI
            
            MOV BX, BP+4
            
            MOV CX, DIM
            XOR DI, DI  ; initialize DI as array iterator
            MOV AH, 1   ; predisposition for using the 21 interrupt
read_char:  INT 21H     ; read a char and display it
            MOV [BX][DI], AL   ; store the char
            INC DI
            DEC CX
            CMP DI, 20
            JB read_char
            CMP AL, 13  ; check if it is return character
            JZ read_end ; if it is, jump to the end of procedure
            CMP CX, 0   ; otherwhise go on looping
            JNZ read_char
            
            MOV [BX][DI],13    ; store the CR char, if need it
            INC DI
            MOV DL, 13         ; print the CR char
            MOV AH, 2
            INT 21H
read_end:   MOV [BX][DI],10    ; store the LF char
            INC DI
            MOV DL, 10         ; print the LF char
            MOV AH, 2
            INT 21H
            MOV [BP+6], DI     ; store the number of read chars
            
            POP DI
            POP DX
            POP CX
            POP BX
            POP AX
            POP BP
            
            RET

read_row    ENDP
           
           
;-----------------------------------------------------------------
;----------Procedure for counting characters----------------------
;-----------------------------------------------------------------

search_char PROC        ; read one row of text

            PUSH BP
            MOV BP,SP   ; store the current value for SP
            
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            PUSH SI
            PUSH DI
            
            MOV BX, BP+4; store the address of the row
            MOV CX, BP+6; store the number of chars in the row 
            XOR DI, DI  ; initialize DI as array iterator
find_char:  MOV AL, [BX][DI]            
            CMP AL, 'z' ; AL > 'z' ?
            JA next_loop; yes, next loop please
            CMP AL, 'a' ; no, AL < 'a' ?  
            JB test_big ; yes, verify if it's in big caps
            SUB AL, 'a' ; no, it's a small caps char  
            XOR AH, AH 
            MOV BP, AX 
            ADD DS:CHARS_TMP[BP],1 ; increment the counter for the current char
            ADD DS:CHARS_TOT[BP],1 ; increment the total counter for the current char  
            JMP next_loop
test_big:   CMP AL, 'Z' ; AL > 'Z' ?
            JA next_loop; yes, next loop please                          
            CMP AL, 'A' ; no, AL < 'A' ?  
            JB next_loop; yes, next loop please
            SUB AL, 'A' ; no, it's a big caps char 
            XOR AH, AH  
            MOV BP, AX   
            ADD DS:CHARS_TMP[BP+26],1 ; increment the counter for the current char
            ADD DS:CHARS_TOT[BP+26],1 ; increment the total counter for the current char
next_loop:  INC DI
            LOOP find_char            
            
            ; find the char with the most occurrences
            LEA BX, CHARS_TMP
            XOR SI, SI
            PUSH SI
            PUSH BX
            CALL find_max   ; compute the maximum times of char occurences
            POP SI
            POP SI          ; store the maximum occurence
            MOV BX, SI      ; store the maximum occurrence in BX,
                            ; in order to use BL later, 
                            ; since max fits into 8 bits 
            SHR BX, 1       ; the half of the maximum,
                            ; to be compared with all occurrences
            
            ; print character that appears a number of times 
            ; equal to half the maximum times
            
            LEA DX, MSG_CNT
            MOV AH, 09H
            INT 21H
            
            ; first analyse small caps 
            
            MOV CX, 26
            XOR DI, DI
test_num_s: CMP BL, CHARS_TMP[DI]; is it equal to max/2?
            JNE new_test_s       ; no, next iteration please 
            MOV DX, DI
            ADD DL, 'a'
            MOV AH, 2
            INT 21H
            MOV DX, " "
            MOV AH, 2
            INT 21H
new_test_s: INC DI
            LOOP test_num_s 
            
            ; then analyse big caps 
            
            MOV CX, 26
            MOV DI, 26
test_num_b: CMP BL, CHARS_TMP[DI]; is it equal to max/2?
            JNE new_test_b       ; no, next iteration please 
            MOV DX, DI
            SUB DX, 26
            ADD DL, 'A'
            MOV AH, 2
            INT 21H
            MOV DX, " "
            MOV AH, 2
            INT 21H
new_test_b: INC DI
            LOOP test_num_b           
            
            ; empty the CHARS_TMP array for using it in next calls 
            MOV CX, 52
            XOR DI, DI
clear_arr:  MOV CHARS_TMP[DI], 0
            INC DI
            LOOP clear_arr                        
                            
            POP DI
            POP SI
            POP DX
            POP CX
            POP BX
            POP AX
            POP BP          
            
            RET
            
search_char ENDP 

;-----------------------------------------------------------------
;----------Procedure for finding the char appearing the most------
;-----------------------------------------------------------------

find_max    PROC    
            
            PUSH BP
            MOV BP,SP   ; store the current value for SP
            
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            PUSH SI
            PUSH DI 
            
            MOV BX, [BP+4]  ; store the address of the array 
            MOV CX, 52
            XOR DI, DI      ; initialize DI as array iterator
            XOR AL, AL      ; initialize AL as current maximum 
loop_arr:   CMP [BX][DI], AL; AL is maximum?
            JA new_max      ; no, store new max
            JMP next_iter   ; yes, next iteration please        
new_max:    MOV AL, [BX][DI]; store new max
            MOV DX, DI        
next_iter:  INC DI
            LOOP loop_arr 
            
            XOR AH, AH
            MOV [BP+4],DX
            MOV [BP+6],AX 
            
            POP DI
            POP SI
            POP DX
            POP CX
            POP BX 
            POP AX
            POP BP
            
            RET          
            
find_max    ENDP    

;-----------------------------------------------------------------
;----------Procedure for printing the transformed text------------
;-----------------------------------------------------------------
   
   
transform   PROC
    
            PUSH BP
            MOV BP,SP   ; store the current value for SP
            
            PUSH AX
            PUSH BX
            PUSH CX
            PUSH DX
            PUSH SI
            PUSH DI
            
            MOV BX, BP+4    ; store the address of the row into BX
            MOV SI, BP+6 ; store the value of K into K_TMP
            MOV K_TMP, SI 
            MOV DIM_ALPH, 52    ; store the dimension of ALPH array 
                                ; used for transforming each character
                                ; according to the Caesar cypher
            MOV CX, BP+8; store the number of characters in the current row
            XOR DI, DI  ; initialize DI as array iterator
            XOR AX, AX  ; initialize AX for storing   
            XOR DX, DX  ; initialize DX for later use
loop_cipher:MOV AL, [BX][DI]            
            CMP AL, 'z' ; AL > 'z' ?
            JA no_cipher; yes, no cypher
            CMP AL, 'a' ; no, AL < 'a' ?  
            JB test_char ; yes, verify if it's in big caps
            SUB AL, 'a' ; no, it's a small caps char  
            XOR AH, AH   
            JMP yes_cipher  ; prepare char for printing
test_char:  CMP AL, 'Z' ; AL > 'Z' ?
            JA no_cipher; yes, no cypher                          
            CMP AL, 'A' ; no, AL < 'A' ?  
            JB no_cipher; yes, no cypher
            SUB AL, 'A' ; no, it's a big caps char 
            XOR AH, AH 
            ADD AX, 26 
yes_cipher: ADD AX, K_TMP
            DIV DIM_ALPH   ; divide the current char by the dimension of ALPH array 
            MOV DL, AH     ; and use the remainder (modulus operatio for accessing
            CMP DL, 26     ; the right cell of the array) 
            JB small_c     ; DL < 26 ? yes, it's a small caps character
            SUB DL, 26     ; no, it's a big caps character
            ADD DL, 'A'    ; find the corresponding char
            JMP next_cipher           
small_c:    ADD DL, 'a'    ; find the corresponding char
            JMP next_cipher           
no_cipher:  MOV DL, AL     ; copy the char in DL for printing            
next_cipher:MOV AH, 2      ; preparing for printing the char
            INT 21H        ; print the char
            INC DI
            LOOP loop_cipher 
            
            POP DI
            POP SI
            POP DX
            POP CX
            POP BX 
            POP AX
            POP BP
            
            RET
            
transform   ENDP
            
end_program: 
    
.EXIT
END
