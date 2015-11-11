; Given an array of integers of 10 elements (of 8 bits): 
; 1 - compute the sum for each pair of consecutive values, 
;     putting the result in a 9 elements array;
; 2 - find the minimum value both for the first (A) 
;     and the second (B) array.

DIM_A EQU 10
DIM_B EQU 9

	.MODEL small
	.STACK
	
	.DATA
		VETT_A DB 5, 21, 7, 4, 10, 33, 56, 96, 25, 15
		VETT_B DB DIM_B ?

	.CODE
	.STARTUP
	
	; 1 - Compute the sum for each pair of consecutive values, putting the result in a 9 elements array
						
			XOR AX,AX; initialization of AX to use it as support register for addition
			MOV CX, DIM_B
			XOR DI, DI; initialization of DI, used to point each value in the vector
		
sum_pair_values:	MOV AL, VETT_A[DI]; first value of the pair
			ADD AL, VETT_A[DI+1]; add second value of the pair to the first one
			MOV VETT_B[DI], AL; store the sum of the pair in the second vector
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
						
	.EXIT
END
