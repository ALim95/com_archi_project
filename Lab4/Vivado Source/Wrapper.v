`timescale 1ns / 1ps
/*
----------------------------------------------------------------------------------
-- Company: NUS
-- Engineer: (c) Thao Nguyen and Rajesh Panicker
-- 
-- Create Date:   21:06:18 24/09/2015
-- Design Name: 	Wrapper (ARM Wrapper)
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool versions: Vivado 2015.2
-- Description: Wrapper for ARM processor. Not meant to be synthesized directly.
--
-- Revision 0.02
-- Additional Comments: See the notes below. The interface (entity) as well as implementation (architecture) can be modified
----------------------------------------------------------------------------------
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post it on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept the responsibility to ensure that your implementation does not violate any intellectual property of ARM Holdings or other entities.
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
--		(vi) retain this notice in this file or any files derived from this.
----------------------------------------------------------------------------------
*/

//>>>>>>>>>>>> ******* FOR SIMULATION. DO NOT SYNTHESIZE THIS DIRECTLY (This is use as a component in TOP.vhd for Synthesis) ******* <<<<<<<<<<<<

module Wrapper
#(
	parameter N_LEDs_OUT      = 8,   // Number of LEDs displaying Result. LED(15 downto 15-N_LEDs_OUT+1). 8 by default
	parameter N_DIPs = 16,           // Number of DIPs. 16 by default
	parameter N_PBs  = 4             // Number of PushButtons. 4 by default
		                             // Note that BTNC is used as PAUSE
)
(
	input  [N_DIPs-1:0] DIP, 		 		// DIP switch inputs. Not debounced. Mapped to 0x00000C04. 
	                                        // Only the least significant 16 bits read from this location are valid. 
	input  [N_PBs-1:0] PB,  				// PB switch inputs. Not debounced.	Mapped to 0x00000C08. 
	                                        // Only the least significant 4 bits read from this location are valid. Order (3 downto 0) -> BTNU, BTNL, BTNR, BTND.
	output reg [N_LEDs_OUT-1:0] LED_OUT, 	// LED(15 downto 8) mapped to 0x00000C00. Only the least significant 8 bits written to this location are used.
	output [6:0] LED_PC, 					// LED(6 downto 0) showing PC(8 downto 2).
	output reg [31:0] SEVENSEGHEX, 			// 7 Seg LED Display. Mapped to 0x00000C18. The 32-bit value will appear as 8 Hex digits on the display.
	output reg [7:0] CONSOLE_OUT,           // CONSOLE (UART) Output. Mapped to 0x00000C0C. The least significant 8 bits written to this location are sent to PC via UART.
											// Check if CONSOLE_OUT_ready (0x00000C14) is set before writing to this location (especially if your CLK_DIV_BITS is small).
											// Consecutive STRs to this location not permitted (there should be at least 1 instruction gap between STRs to this location).
	input	CONSOLE_OUT_ready,				// An indication to the wrapper/processor that it is ok to write to the CONSOLE_OUT (UART hardware).
	                                        //  This bit should be set in the testbench to indicate that it is ok to write a new character to CONSOLE_OUT from your program.
	                                        //  It can be read from the address 0x00000C14.
	output reg CONSOLE_OUT_valid,           // An indication to the UART hardware that the processor has written a new data byte to be transmitted.
	input  [7:0] CONSOLE_IN,                // CONSOLE (UART) Input. Mapped to 0x00000C0C. The least significant 8 bits read from this location is the character received from PC via UART.
	                                        // Check if CONSOLE_IN_valid flag (0x00000C10)is set before reading from this location.
											// Consecutive LDRs from this location not permitted (needs at least 1 instruction spacing between LDRs).
											// Also, note that there is no Tx FIFO implemented. DO NOT send characters from PC at a rate faster than 
											//  your processor (program) can read them. This means sending only 1 char every few seconds if your CLK_DIV_BITS is 26.
											// 	This is not a problem if your processor runs at a high speed.
	input  	CONSOLE_IN_valid,               // An indication to the wrapper/processor that there is a new data byte waiting to be read from the UART hardware.
	                                        // This bit should be set in the testbench to indicate a new character (Else, the processor will only read in 0x00).
											//  It can be read from the address 0x00000C10.
	output reg CONSOLE_IN_ack,              // An indication to the UART hardware that the processor has read the newly received data byte.
	                                        // The testbench should clear CONSOLE_IN_valid when this is set.
	input  RESET,							// Active high. Implemented in TOP as not(CPU_RESET) or Internal_reset (CPU_RESET is red push button and is active low).
	input  CLK								// Divided Clock from TOP.
);                                             

//----------------------------------------------------------------
// ARM signals
//----------------------------------------------------------------
wire[31:0] PC ;
wire[31:0] Instr ;
reg[31:0] ReadData ;
wire MemWrite ;
wire[31:0] ALUResult ;
wire[31:0] WriteData ;

//----------------------------------------------------------------
// Address Decode signals
//---------------------------------------------------------------
wire dec_DATA_CONST, dec_DATA_VAR, dec_LED, dec_DIP, dec_CONSOLE, dec_PB, dec_7SEG, dec_CONSOLE_IN_valid, dec_CONSOLE_OUT_ready;  // 'enable' signals from data memory address decoding

//----------------------------------------------------------------
// Memory declaration
//-----------------------------------------------------------------
reg [31:0] INSTR_MEM		[0:127]; // instruction memory
reg [31:0] DATA_CONST_MEM	[0:127]; // data (constant) memory
reg [31:0] DATA_VAR_MEM     [0:127]; // data (variable) memory



//----------------------------------------------------------------
// Instruction Memory
//----------------------------------------------------------------
initial begin
			INSTR_MEM[0] = 32'hE59F11F8; 
			INSTR_MEM[1] = 32'hE59F3204; 
			INSTR_MEM[2] = 32'hE59F9208; 
			INSTR_MEM[3] = 32'hE59FA204; 
			INSTR_MEM[4] = 32'hE59FB204; 
			INSTR_MEM[5] = 32'hE59FC1F8; 
			INSTR_MEM[6] = 32'hE2899001; 
			INSTR_MEM[7] = 32'hE581C000; 
			INSTR_MEM[8] = 32'hE5839000; 
			INSTR_MEM[9] = 32'hE583A000; 
			INSTR_MEM[10] = 32'hE581A000; 
			INSTR_MEM[11] = 32'hE59F51F8; 
			INSTR_MEM[12] = 32'hE2955001; 
			INSTR_MEM[13] = 32'hE59F51F4; 
			INSTR_MEM[14] = 32'hE5835000; 
			INSTR_MEM[15] = 32'hE59F61F0; 
			INSTR_MEM[16] = 32'hE5836000; 
			INSTR_MEM[17] = 32'hE0A55006; 
			INSTR_MEM[18] = 32'hE5835000; 
			INSTR_MEM[19] = 32'hE583A000; 
			INSTR_MEM[20] = 32'hE59F61E0; 
			INSTR_MEM[21] = 32'hE1550006; 
			INSTR_MEM[22] = 32'h0A000001; 
			INSTR_MEM[23] = 32'hE581B000; 
			INSTR_MEM[24] = 32'hEAFFFFFD; 
			INSTR_MEM[25] = 32'hE2899001; 
			INSTR_MEM[26] = 32'hE581C000; 
			INSTR_MEM[27] = 32'hE5839000; 
			INSTR_MEM[28] = 32'hE583A000; 
			INSTR_MEM[29] = 32'hE581A000; 
			INSTR_MEM[30] = 32'hE59F51BC; 
			INSTR_MEM[31] = 32'hE5835000; 
			INSTR_MEM[32] = 32'hE59F61B8; 
			INSTR_MEM[33] = 32'hE5836000; 
			INSTR_MEM[34] = 32'hE1C55006; 
			INSTR_MEM[35] = 32'hE5835000; 
			INSTR_MEM[36] = 32'hE583A000; 
			INSTR_MEM[37] = 32'hE59F61A8; 
			INSTR_MEM[38] = 32'hE1550006; 
			INSTR_MEM[39] = 32'h1AFFFFEE; 
			INSTR_MEM[40] = 32'hE2899001; 
			INSTR_MEM[41] = 32'hE581C000; 
			INSTR_MEM[42] = 32'hE5839000; 
			INSTR_MEM[43] = 32'hE583A000; 
			INSTR_MEM[44] = 32'hE581A000; 
			INSTR_MEM[45] = 32'hE59F518C; 
			INSTR_MEM[46] = 32'hE5835000; 
			INSTR_MEM[47] = 32'hE59F6188; 
			INSTR_MEM[48] = 32'hE5836000; 
			INSTR_MEM[49] = 32'hE0255006; 
			INSTR_MEM[50] = 32'hE5835000; 
			INSTR_MEM[51] = 32'hE583A000; 
			INSTR_MEM[52] = 32'hE59F6178; 
			INSTR_MEM[53] = 32'hE1550006; 
			INSTR_MEM[54] = 32'h1AFFFFDF; 
			INSTR_MEM[55] = 32'hE2899001; 
			INSTR_MEM[56] = 32'hE581C000; 
			INSTR_MEM[57] = 32'hE5839000; 
			INSTR_MEM[58] = 32'hE583A000; 
			INSTR_MEM[59] = 32'hE581A000; 
			INSTR_MEM[60] = 32'hE59F611C; 
			INSTR_MEM[61] = 32'hE5836000; 
			INSTR_MEM[62] = 32'hE3A050AA; 
			INSTR_MEM[63] = 32'hE583A000; 
			INSTR_MEM[64] = 32'hE5835000; 
			INSTR_MEM[65] = 32'hE583A000; 
			INSTR_MEM[66] = 32'hE1550006; 
			INSTR_MEM[67] = 32'h1AFFFFD2; 
			INSTR_MEM[68] = 32'hE2899001; 
			INSTR_MEM[69] = 32'hE581C000; 
			INSTR_MEM[70] = 32'hE5839000; 
			INSTR_MEM[71] = 32'hE583A000; 
			INSTR_MEM[72] = 32'hE581A000; 
			INSTR_MEM[73] = 32'hE59F60E8; 
			INSTR_MEM[74] = 32'hE5836000; 
			INSTR_MEM[75] = 32'hE3E050AA; 
			INSTR_MEM[76] = 32'hE5835000; 
			INSTR_MEM[77] = 32'hE583A000; 
			INSTR_MEM[78] = 32'hE59F6114; 
			INSTR_MEM[79] = 32'hE1550006; 
			INSTR_MEM[80] = 32'h1AFFFFC5; 
			INSTR_MEM[81] = 32'hEAFFFFFE;
end

//----------------------------------------------------------------
// Data (Constant) Memory
//----------------------------------------------------------------
initial begin
			DATA_CONST_MEM[0] = 32'h00000C00; 
			DATA_CONST_MEM[1] = 32'h00000C04; 
			DATA_CONST_MEM[2] = 32'h00000C08; 
			DATA_CONST_MEM[3] = 32'h00000C0C; 
			DATA_CONST_MEM[4] = 32'h00000C18; 
			DATA_CONST_MEM[5] = 32'h000000AA; 
			DATA_CONST_MEM[6] = 32'h00000000; 
			DATA_CONST_MEM[7] = 32'h000000FF; 
			DATA_CONST_MEM[8] = 32'h00000001; 
			DATA_CONST_MEM[9] = 32'h00000002; 
			DATA_CONST_MEM[10] = 32'h0000000A; 
			DATA_CONST_MEM[11] = 32'hFFFFFFFF; 
			DATA_CONST_MEM[12] = 32'h00000008; 
			DATA_CONST_MEM[13] = 32'h00000007; 
			DATA_CONST_MEM[14] = 32'h00000010; 
			DATA_CONST_MEM[15] = 32'hAAAAAAAA; 
			DATA_CONST_MEM[16] = 32'hFFFF0000; 
			DATA_CONST_MEM[17] = 32'h0000AAAA; 
			DATA_CONST_MEM[18] = 32'h00AAAAFF; 
			DATA_CONST_MEM[19] = 32'h55555555; 
			DATA_CONST_MEM[20] = 32'h55FFFFAA; 
			DATA_CONST_MEM[21] = 32'hFFFFFF55; 
			DATA_CONST_MEM[22] = 32'h8A8A8B35; 
			DATA_CONST_MEM[23] = 32'h00000008; 
			DATA_CONST_MEM[24] = 32'h00000004; 
			DATA_CONST_MEM[25] = 32'h00000800; 
			DATA_CONST_MEM[26] = 32'hABCD1234; 
			DATA_CONST_MEM[27] = 32'h6C6C6548; 
			DATA_CONST_MEM[28] = 32'h6F57206F; 
			DATA_CONST_MEM[29] = 32'h21646C72; 
			DATA_CONST_MEM[30] = 32'h00212121;
end


//----------------------------------------------------------------
// Data (Variable) Memory
//----------------------------------------------------------------
initial begin
end

//----------------------------------------------------------------
// Debug LEDs
//----------------------------------------------------------------
assign LED_PC = PC[15-N_LEDs_OUT+1 : 2]; // debug showing PC

//----------------------------------------------------------------
// ARM port map
//----------------------------------------------------------------
ARM ARM1(
	CLK,
	RESET,
	Instr,
	ReadData,
	MemWrite,
	PC,
	ALUResult,
	WriteData
);

//----------------------------------------------------------------
// Data memory address decoding
//----------------------------------------------------------------
assign dec_DATA_CONST		= (ALUResult >= 32'h00000200 && ALUResult <= 32'h000003FC) ? 1'b1 : 1'b0;
assign dec_DATA_VAR			= (ALUResult >= 32'h00000800 && ALUResult <= 32'h000009FC) ? 1'b1 : 1'b0;
assign dec_LED				= (ALUResult == 32'h00000C00) ? 1'b1 : 1'b0;
assign dec_DIP				= (ALUResult == 32'h00000C04) ? 1'b1 : 1'b0;
assign dec_PB 		   		= (ALUResult == 32'h00000C08) ? 1'b1 : 1'b0;
assign dec_CONSOLE	   		= (ALUResult == 32'h00000C0C) ? 1'b1 : 1'b0;
assign dec_CONSOLE_IN_valid	= (ALUResult == 32'h00000C10) ? 1'b1 : 1'b0;
assign dec_CONSOLE_OUT_ready= (ALUResult == 32'h00000C14) ? 1'b1 : 1'b0;
assign dec_7SEG	    		= (ALUResult == 32'h00000C18) ? 1'b1 : 1'b0;

//----------------------------------------------------------------
// Data memory read
//----------------------------------------------------------------
always@( * ) begin
if (dec_DIP)
	ReadData <= { {31-N_DIPs+1{1'b0}}, DIP } ; 
else if (dec_PB)
	ReadData <= { {31-N_PBs+1{1'b0}}, PB } ; 
else if (dec_DATA_VAR)
	ReadData <= DATA_VAR_MEM[ALUResult[8:2]] ; 
else if (dec_DATA_CONST)
	ReadData <= DATA_CONST_MEM[ALUResult[8:2]] ; 
else if (dec_CONSOLE && CONSOLE_IN_valid)
	ReadData <= {24'b0, CONSOLE_IN};
else if (dec_CONSOLE_IN_valid)
	ReadData <= {31'b0, CONSOLE_IN_valid};	
else if (dec_CONSOLE_OUT_ready)
	ReadData <= {31'b0, CONSOLE_OUT_ready};		
else
	ReadData <= 32'h0 ; 
end
			
//----------------------------------------------------------------
// Instruction memory read
//----------------------------------------------------------------
assign Instr = ( (PC >= 32'h00000000) & (PC <= 32'h000001FC) ) ? // To check if address is in the valid range, assuming 128 word memory. Also helps minimize warnings
                 INSTR_MEM[PC[8:2]] : 32'h00000000 ; 

//----------------------------------------------------------------
// Console read / write
//----------------------------------------------------------------
always @(posedge CLK) begin
	CONSOLE_OUT_valid <= 1'b0;
	CONSOLE_IN_ack <= 1'b0;
	if (MemWrite && dec_CONSOLE && CONSOLE_OUT_ready)
	begin
		CONSOLE_OUT <= WriteData[7:0];
		CONSOLE_OUT_valid <= 1'b1;
	end
	if (!MemWrite && dec_CONSOLE && CONSOLE_IN_valid)
		CONSOLE_IN_ack <= 1'b1;
end
// Possible spurious CONSOLE_IN_ack and a lost character since we don't have a MemRead signal. Make sure ALUResult is never 0xC0C other than when accessing UART.
// Also, the character received from PC in the CLK cycle immediately following a character read by the processor is lost. This is not that much of a problem in practice though.

//----------------------------------------------------------------
// Data Memory-mapped LED write
//----------------------------------------------------------------
always@(posedge CLK) begin
    if(RESET)
        LED_OUT <= 0 ;
    else if( MemWrite & dec_LED ) 
        LED_OUT <= WriteData[N_LEDs_OUT-1 : 0] ;
end

//----------------------------------------------------------------
// SevenSeg LED Display write
//----------------------------------------------------------------
always @(posedge CLK) begin
	if (RESET)
		SEVENSEGHEX <= 'b0;
	else if (MemWrite && dec_7SEG)
		SEVENSEGHEX <= WriteData;
end

//----------------------------------------------------------------
// Data Memory write
//----------------------------------------------------------------
always@(posedge CLK) begin
    if( MemWrite & dec_DATA_VAR ) 
        DATA_VAR_MEM[ALUResult[8:2]] <= WriteData ;
end

endmodule