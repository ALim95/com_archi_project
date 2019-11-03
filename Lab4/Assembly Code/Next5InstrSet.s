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

RSBtest ; Instruction 1
		ADD R9, #1		; increment index counter by 1
        STR R12, [R1]    ; signals the start of RSBtest with no shifts
		STR R9, [R3]	; displays instruction index on seven segment		
		STR R10, [R3]	; clears the seven segment
		STR R10, [R1]	; clears the LEDs
		LDR R5, RSBTEST_FIRSTNUM ; R5 = 0x8
		STR R5, [R3] ; displays the value of first number to RSB on the seven segment
		LDR R6, RSBTEST_SECONDNUM ; R6 = 0x7
		STR R6, [R3] ; displays the value of second number to RSB on the seven segment
		RSB R5, R5, R6 ; performs the RSB instruction
		STR R5, [R3]	; displays the result of the RSB operation on seven segment
		STR R10, [R3]	; clears the seven segment		
		LDR R6, FULL_VAL ; loads the expected result into R6
		CMP R5, R6
		BEQ RSCtest	; will skip from 0x58 to 0x64 if expected result matches actual result	

FAIL	; any instruction that did not perform as expected will be running an infinite loop
		STR R11, [R1]		
		B FAIL
		
RSCtest 
		ADD R9, #1		; increment index counter by 1
        STR R12, [R1]    ; signals the start of RSCtest with no shifts
		STR R9, [R3]	; displays instruction index on seven segment		
		STR R10, [R3]	; clears the seven segment
		STR R10, [R1]	; clears the LEDs
        LDR R5, EMPTY_VAL ; R5 = 0x0
		ADDS R5, R5, #1 ; set C flag to 0
		LDR R5, RSBTEST_FIRSTNUM ; R5 = 0x8
		STR R5, [R3] ; displays the value of first number to RSC on the seven segment
		LDR R6, RSBTEST_SECONDNUM ; R6 = 0x7
		STR R6, [R3] ; displays the value of second number to RSC on the seven segment
		RSC R5, R5, R6 ; performs the RSC instruction
		STR R5, [R3]	; displays the result of the RSC operation on seven segment
		STR R10, [R3]	; clears the seven segment		
		LDR R6, ExpectedRSCval ; loads the expected result into R6
		CMP R5, R6
		BNE FAIL	; will skip from 0x98 to 0xA0 if expected result matches actual result	

SBCtest
		ADD R9, #1		; increment index counter by 1
        STR R12, [R1]    ; signals the start of SBCtest with no shifts
		STR R9, [R3]	; displays instruction index on seven segment		
		STR R10, [R3]	; clears the seven segment
		STR R10, [R1]	; clears the LEDs
        LDR R5, EMPTY_VAL ; R5 = 0x0
		ADDS R5, R5, #1 ; set C flag to 0
		LDR R5, RSBTEST_FIRSTNUM ; R5 = 0x8
		STR R5, [R3] ; displays the value of first number to SBC on the seven segment
		LDR R6, RSBTEST_SECONDNUM ; R6 = 0x7
		STR R6, [R3] ; displays the value of second number to SBC on the seven segment
		SBC R5, R5, R6 ; performs the SBC instruction
		STR R5, [R3]	; displays the result of the SBC operation on seven segment
		STR R10, [R3]	; clears the seven segment		
		LDR R6, EMPTY_VAL ; loads the expected result into R6
		CMP R5, R6
		BNE FAIL	; will skip from 0xD4 to 0xDC if expected result matches actual result	

TEQtest
		ADD R9, #1		; increment index counter by 1
        STR R12, [R1]    ; signals the start of TEQtest with no shifts
		STR R9, [R3]	; displays instruction index on seven segment		
		STR R10, [R3]	; clears the seven segment
		STR R10, [R1]	; clears the LEDs
        LDR R5, TEQ_FIRSTVAL ; R5 = 0xAAAAAAAA
        STR R5, [R3] ; displays the value of first number to TEQ on the seven segment
		LDR R6, TEQ_SECONDVAL ; R6 = 0x55555555
		STR R6, [R3] ; displays the value of second number to TEQ on the seven segment
		TEQ R5, R6 ; performs the TEQ instruction
		STR R10, [R3]	; clears the seven segment		
		BPL FAIL	; will skip from 0x10C to 0x114 if expected result matches actual result	

TSTtest
		ADD R9, #1		; increment index counter by 1
        STR R12, [R1]    ; signals the start of TSTtest with no shifts
		STR R9, [R3]	; displays instruction index on seven segment		
		STR R10, [R3]	; clears the seven segment
		STR R10, [R1]	; clears the LEDs
        LDR R5, TEQ_FIRSTVAL ; R5 = 0xAAAAAAAA
		STR R5, [R3] ; displays the value of first number to TST on the seven segment
		LDR R6, TEQ_SECONDVAL ; R6 = 0x55555555
		STR R6, [R3] ; displays the value of second number to TST on the seven segment
		TST R5, R6 ; performs the TST instruction
		STR R10, [R3]	; clears the seven segment		
		BNE FAIL	; will skip from 0x13C to 0x144 if expected result matches actual result	
		
		
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
FULL_VAL
		DCD 0xFFFFFFFF
RSBTEST_FIRSTNUM
		DCD 0x8
RSBTEST_SECONDNUM
		DCD 0x7
TEQ_FIRSTVAL
        DCD 0xAAAAAAAA
TEQ_SECONDVAL
        DCD 0x55555555
ExpectedRSCval
        DCD 0xFFFFFFFE
		
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
		