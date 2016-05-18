; Given an array of integers of 10 elements (of 8 bits): 
; 1 - compute the sum for each pair of consecutive values, 
;     putting the result in a 9 elements array;
; 2 - find the minimum value both for the first (A) 
;     and the second (B) array;
; 3 - compute all possible products among first 9 values of first array 
;     and all 9 values of second array, putting results in a matrix 
;     of 9x9 values (words).
; 4 - Find the maximum value among values of the so computed matrix. 
;     Is there overflow?
;
; > While adding up pairs of values, an overflow could occur.
;   In this case, the program ends after printing out a message.
;   During the multiplication, it's not possible to have overflow.

DIM_A EQU 10
DIM_B EQU 9
DIM_M EQU 81

	.MODEL small
	.STACK
	
	.DATA
		VETT_A DB 5, 21, 7, 4, 10, 33, 56, 96, 25, 15
		VETT_B DB DIM_B DUP(?)
		MIN_A DB ?
		MIN_B DB ?
		OPD_A DW ?
		MATR DW DIM_M DUP(?)
		MAX DW ?
		OVERFLOW_MSG DB " Overflow occurred adding up the pairs of values, please check VETT_A", 13, 10, '$'
		
	.CODE
	.STARTUP
	
	; 1 - Compute the sum for each pair of consecutive values, putting the result in a 9 elements array
						
			XOR AX,AX; initialization of AX to use it as support register for addition
			MOV CX, DIM_B
			XOR DI, DI; initialization of DI, used to point each value in the vector
		
sum_pair_values:	MOV AL, VETT_A[DI]; first value of the pair
			ADD AL, VETT_A[DI+1]; add second value of the pair to the first one
			JNC no_overflow; if there isn't overflow (CF=0), continue
			JMP handle_overflow; otherwise, exit the loop and handle it 
no_overflow:		MOV VETT_B[DI], AL; store the sum of the pair in the second vector
			INC DI
			DEC CX
			CMP CX,0
			JNZ sum_pair_values; jump to the next pair of consecutive values
			
	; 2 - Find the minimum value both for the first (A) and the second (B) array.
	
			; 2a - Find the minimum value for VETT_A
			XOR AX,AX; initialization of AX, used for storing the actual minimum
			MOV CX, DIM_A
			XOR DI, DI;
		                
		        MOV AL, 0FFH; initialize AL with maximum value writable on 8 bits
		                
search_minimum_a: 	CMP AL, VETT_A[DI]; compare with the current minimum		
			JB current_is_minimum_a; if AL<VETT_A[DI]
			MOV AL, VETT_A[DI]; AL>VETT_A[DI], store the new minimum
current_is_minimum_a: 	INC DI
			DEC CX
			CMP CX,0
			JNZ search_minimum_a 
			
			MOV MIN_A, AL;store the minimum

                  	; 2b - Find the minimum value for VETT_B
			XOR AX,AX; initialization of AX, used for storing the actual minimum
			MOV CX, DIM_B
			XOR DI, DI; 
			
			MOV AL, 0FFH; initialize AL with maximum value writable on 8 bits
		
search_minimum_b: 	CMP AL, VETT_B[DI]; compare with the current minimum		
			JB current_is_minimum_b; if AL<VETT_B[DI]
			MOV AL, VETT_B[DI]; AL>VETT_B[DI], store the new minimum
current_is_minimum_b: 	INC DI
			DEC CX
			CMP CX,0
			JNZ search_minimum_b
			
			MOV MIN_B, AL;store the minimum
			
	; 3 - Compute all possible products among first 9 values of first array and all 9 values of second array, 
	;     putting results in a matrix of 9x9 values (words)
	
			XOR AX,AX; initialitation, used as support register for multiplications 
			XOR BX,BX; initialitation, used as index for VETT_A
						
multiply_outer_loop:	MOV AL, VETT_A[BX]; first operand of multiplication
			MOV OPD_A, AX; save the operand to be multiplied by each element of VETT_B
			XOR SI, SI; initialitation, used as index for VETT_B
			XOR DI, DI; initialitation, used as col index for matrix
			MOV CX, DIM_B
						
multiply_inner_loop:	MUL VETT_B[SI]; VETT_A[BX]*VETT_B[SI]
			PUSH AX; save the result
			
			XOR AX,AX; initialitation, used to compute the row index of matrix
			MOV AL, 18; 18 = number of columns * 2, because dealing with words.
			MUL BX; BX*number of columns*2(byte)
			MOV BP, AX; store the row index in BP
			
			POP AX; restore the result of multiplication
			MOV DS:MATR[BP][DI], AX; store the product in MATR[i*2*nCols][2*j]
			
			MOV AX, OPD_A; restore the first operand of multiplication, i.e. VETT_A[BX]
			
			INC SI
			ADD DI, 2
			DEC CX
			
			CMP CX, 0
			JNZ multiply_inner_loop
			; end inner loop
					
			INC BX
			
			CMP BX, DIM_B
			JB multiply_outer_loop
	
	; 4 - Find the maximum value among values of the so computed matrix. Is there overflow?
	
			XOR AX,AX; initialization of AX, used for storing the actual maximum
			MOV CX, DIM_M
			XOR DI, DI;
									
search_maximum: 	CMP AX, MATR[DI]; compare with the current maximum		
			JA current_is_maximum; if AX>MATR[DI]
			MOV AX, MATR[DI]; AX<MATR[DI], store the new maximum
current_is_maximum: 	ADD DI, 2
			DEC CX
			CMP CX,0
			JNZ search_maximum 
			
			MOV MAX, AX;store the maximum
			
			JMP end_program

handle_overflow:	LEA DX, OVERFLOW_MSG; store in DX the offset of message 
	                MOV AH, 09H; predisposition of AH for printing characters
	                INT 21H; print the message
	                
end_program: 
						
	.EXIT
END
