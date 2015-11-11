; Given an array of integers of 10 elements (of 8 bits), 
; compute the sum for each pair of consecutive values, 
; putting the result in a 9 elements array.

DIM_A EQU 10
DIM_B EQU 9

	.MODEL small
	.STACK
	
	.DATA
		VETT_A DB 5, 21, 7, 4, 10, 33, 56, 96, 25, 15
		VETT_B DB DIM_B ?

	.CODE
	.STARTUP
						
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
	.EXIT
END
