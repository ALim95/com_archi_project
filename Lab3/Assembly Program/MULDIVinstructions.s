;----------------------------------------------------------------------------------
;--	License terms :
;--	You are free to use this code as long as you
;--		(i) DO NOT post it on any public repository;
;--		(ii) use it only for educational purposes;
;--		(iii) accept the responsibility to ensure that your implementation does not violate any intellectual property of ARM Holdings or other entities.
;--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
;--		(v) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
;--		(vi) retain this notice in this file or any files derived from this.
;----------------------------------------------------------------------------------

	AREA    MYCODE, CODE, READONLY, ALIGN=9 
   	  ENTRY
	  
; ------- <code memory (ROM mapped to Instruction Memory) begins>
; Total number of instructions should not exceed 127 (126 excluding the last line 'halt B halt').
		LDR R1, LEDS        ; R1 stores the address of LEDs
		LDR R3, SEVEN_SEG	; R3 stores the address of seven segment display
		LDR R9, EMPTY_VAL	; Counter for instruction index to be displayed on seven segment
		LDR R10, EMPTY_VAL	; R10 will be used to set the seven segment and LEDs to 0
		LDR  R11, FAIL_VAL  ; R11 will be used to set the LEDs to display the fail values whenever an instruction did not perform as expected
        LDR  R12, TEST_SIGNAL_VAL    ; R12 stores the value which signals the start of a new test
; Start of program

MULtest ; Instruction 1
		ADD R9, #1		; increment index counter by 1
        STR R12, [R1]    ; signals the start of MULtest
		STR R9, [R3]	; displays instruction index on seven segment		
		STR R10, [R3]	; clears the seven segment
		STR R10, [R1]	; clears the LEDs
		LDR R5, MULTEST_MULTIPLICAND ; R5 = 0x8
		STR R5, [R3] ; displays the value of multiplicand (0x8) on the seven segment
		LDR R6, MULTEST_MULTIPLIER ; R6 = 0x4
		STR R6, [R3] ; displays the value of multiplier (0x4) on the seven segment
		MUL R4, R5, R6	; multiply value of R5 with R6 and stores the answer in R4
		STR R4, [R3]	; displays the result of the MUL operation on seven segment
		STR R10, [R3]	; clears the seven segment		
		LDR R6, ExpectedMULVALUE ; loads the expected result into R6
		CMP R4, R6
		BEQ DIVtest	; will skip from 0x50 to 0x5C if expected result matches actual result	

FAIL	; any instruction that did not perform as expected will be running an infinite loop
		STR R11, [R1]		
		B FAIL
		
DIVtest ; Instruction 2
		ADD R9, #1		; increment index counter by 1
        STR R12, [R1]    ; signals the start of DIVtest (using MLA instruction)
		STR R9, [R3]	; displays instruction index on seven segment		
		STR R10, [R3]	; clears the seven segment
		STR R10, [R1]	; clears the LEDs
		LDR R5, DIVTEST_DIVIDEND ; R5 = 0x20
		STR R5, [R3] ; displays the value of dividend (0x20) on the seven segment
		LDR R6, DIVTEST_DIVISOR ; R6 = 0x8
		STR R6, [R3] ; displays the value of divisor (0x8) on the seven segment
		MLA R4, R5, R6, R10	; divides value of R5 with R6 and stores the result/quotient in R4. (R10 is not read in our hardware implementation) 
		STR R4, [R3]	; displays the result of the DIV operation on seven segment
		STR R10, [R3]	; clears the seven segment
		LDR R6, ExpectedDIVVALUE ; loads the expected result into R6
		CMP R4, R6
		BNE FAIL	; will only be executed when actual result does not match expected result	

halt	
		B    halt           ; infinite loop to halt computation. // A program should not "terminate" without an operating system to return control to
							; keep halt	B halt as the last line of your code.
; ------- <\code memory (ROM mapped to Instruction Memory) ends>


	AREA    CONSTANTS, DATA, READONLY, ALIGN=9 
; ------- <constant memory (ROM mapped to Data Memory) begins>
; All constants should be declared in this section. This section is read only (Only LDR, no STR).
; Total number of constants should not exceed 128 (124 excluding the 4 used for peripheral pointers).
; If a variable is accessed multiple times, it is better to store the address in a register and use it rather than load it repeatedly.

;Peripheral pointers
LEDS
		DCD 0x00000C00		; Address of LEDs. //volatile unsigned int * const LEDS = (unsigned int*)0x00000C00;  
DIPS
		DCD 0x00000C04		; Address of DIP switches. //volatile unsigned int * const DIPS = (unsigned int*)0x00000C04;
PBS
		DCD 0x00000C08		; Address of Push Buttons. Used only in Lab 2
UART
		DCD 0x00000C0C		; Address of UART. Used only in Lab 2
SEVEN_SEG
		DCD 0x00000C18		; Address of 7-segment
; Rest of the constants should be declared below.
TEST_SIGNAL_VAL
        DCD  0xAA
EMPTY_VAL
		DCD  0x0
FAIL_VAL
		DCD	 0xFF  
MULTEST_MULTIPLICAND
		DCD 0x8
MULTEST_MULTIPLIER
		DCD 0x4
ExpectedMULVALUE
		DCD 0x20
DIVTEST_DIVIDEND
		DCD 0x20
DIVTEST_DIVISOR
		DCD 0x8
ExpectedDIVVALUE
		DCD 0x4

DELAY_VAL   
		DCD  0x4			; The number of steps of delay // const unsigned int DELAY_VAL = 4;
variable1_addr
		DCD variable1		; address of variable1. Required since we are avoiding pseudo-instructions // unsigned int * const variable1_addr = &variable1;
constant1
		DCD 0xABCD1234		; // const unsigned int constant1 = 0xABCD1234;
string1   
		DCB  "Hello World!!!!",0	; // unsigned char string1[] = "Hello World!"; // assembler will issue a warning if the string size is not a multiple of 4, but the warning is safe to ignore
		
; ------- <constant memory (ROM mapped to Data Memory) ends>	


	AREA   VARIABLES, DATA, READWRITE, ALIGN=9
; ------- <variable memory (RAM mapped to Data Memory) begins>
; All variables should be declared in this section. This section is read-write.
; Total number of variables should not exceed 128. 
; No initialization possible in this region. In other words, you should write to a location before you can read from it (i.e., write to a location using STR before reading using LDR).

variable1
		DCD 0x00000000		;  // unsigned int variable1;
; ------- <variable memory (RAM mapped to Data Memory) ends>	

		END	
		
;const int* x;         // x is a non-constant pointer to constant data
;int const* x;         // x is a non-constant pointer to constant data 
;int*const x;          // x is a constant pointer to non-constant data
		