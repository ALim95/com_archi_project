There are 2 separate ARM programmes written, DPinstructions, and Memory_CMPCMN_instructions
as the total number of instructions exceeded the 128 word limit of a program due to extra instructions
being used for the displaying of values on the 7-segment display and to make the outcome of each instruction
occur clearly.

Before every instruction test, the LEDs will display 1010 1010 and the seven segment will display the instruction index of the instruction
to be tested.


MEMORY_CMPCMN INSTRUCTIONS PROGRAM

We have 4 instructions to be tested, which are, 1.CMP, 2.CMN, 3.LDR/STR w positive offset, 4. LDR w negative offset

Instruction 1: CMPtest, we use Rd value of 1, Rn value of 2. Expected result will be NZCV = 1000 and BLT will be executed,
causing PC to jump from 0x4C to 0x58.

Instruction 2: CMNtest, we use Rd value of -10, Rn value of 10. Expected NZCV = 0110 and BEQ will be executed,
causing PC to jump from 0x84 to 0x8C.

Instruction 3: LDR/STR w positive offfset, we use LDR Rd, [Rn, #4], where Rn is 0xC00 (addr of LEDs), to Rd.
This is supposed to LDR the value in memory address 0xC04 (DIPS), which is set by the switches, to Rd.
Next we use STR Rd, [Rn, #24], to store the loaded value into memory address of (R1 + 0x18) which is seven segment

Instruction 4: LDR w negative offset, we use LDR Rd, [Rn, #-4], where Rn is 0xC08, to Rd.
This loads value in memory address 0xC04 (DIPS), to Rd. Then, we store Rd's value into the memory address of seven segment


DP INSTRUCTIONS PROGRAM

We have 6 instructions to be tested, which are:
Instruction 1: ANDimmtest - (AND Rd, Rn, #0xAB)	Rn: 0xF5F5F5F5	Rm: NA
Expected result (OxA1) is displayed on seven segment

Instruction 2: ORRegtest - (ORR Rd, Rn, Rm)		Rn: 0xF5F5F5F5	Rm:0x7CA2
Expected result (OxFDF7) is displayed on seven segment

Instruction 3: ADDLSRtest -	(ADD Rd, Rn, Rm, LSR #3)	Rn: 0xAA	Rm: 0xABABABAB
Expected result (Ox1575761F) is displayed on seven segment

Instruction 4: ADDSASRtest - (ADDS Rd, Rn, Rm, ASR #3)	Rn: 0xAA	Rm: 0xABABABAB
Expected result (OxF575761F) is displayed on seven segment
NZCV set to 1000

Instruction 5: SUBRORtest -	(SUB Rd, Rn, Rm, ROR #3)	Rn: 0xAA	Rm: 0xABABABAB	
Expected result (0x8A8A8B35) is displayed on seven segment

Instruction 6: ANDSLSLtest -(ANDS Rd, Rn, Rm, LSL #3)	Rn: 0xAA	Rm: 0xABABABAB	
Expected result (0x8) is displayed on seven segment
NZ set to 00
CV remains the same	


VIVADO SIMULATION
To check that CMP or CMN does not write back to register Rd, we used the simulation in vivado. First we go to the PC of CMP and check
the current value in Rd, then go the next PC to check if Rd value is being written with the result.

Also, to check if the NZCV flags are set, we used the simulation in vivado to check at the particular instructions (ANDSLSL, ADDS) where the flags are updated at the next instruction after an instruction that updates the flags.






