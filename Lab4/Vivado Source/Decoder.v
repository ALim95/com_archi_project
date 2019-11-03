`timescale 1ns / 1ps
/*
----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: (c) Shahzor Ahmad and Rajesh Panicker  
-- 
-- Create Date: 09/23/2015 06:49:10 PM
-- Module Name: Decoder
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool Versions: Vivado 2015.2
-- Description: Decoder Module
-- 
-- Dependencies: NIL
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

----------------------------------------------------------------------------------
--	License terms :
--	You are free to use this code as long as you
--		(i) DO NOT post it on any public repository;
--		(ii) use it only for educational purposes;
--		(iii) accept the responsibility to ensure that your implementation does not violate any intellectual property of ARM Holdings or other entities.
--		(iv) accept that the program is provided "as is" without warranty of any kind or assurance regarding its suitability for any particular purpose;
--		(v)	acknowledge that the program was written based on the microarchitecture described in the book Digital Design and Computer Architecture, ARM Edition by Harris and Harris;
--		(vi) send an email to rajesh.panicker@ieee.org briefly mentioning its use (except when used for the course CG3207 at the National University of Singapore);
--		(vii) retain this notice in this file or any files derived from this.
----------------------------------------------------------------------------------
*/

module Decoder(
    input [3:0] Rd, //destination/source register depending on DP/LDR/STR
    input [1:0] Op, // 00 - DP, 01 - Memory, 10 - Branch
    input [5:0] Funct, // I CMD S for DP, I PUBWL for Memory, 1Link for branch
    input [3:0] bit7to4,
    output PCS, // PCS = ((Rd == 15) & RegW) | Branch --> slide 44
    output RegW, // RegW = 1 if it is LDR, DP else 0
    output MemW, // MemW = 1 if it is STR
    output MemtoReg, // MemtoReg = 1 if it is LDR, X if it is STR and 0 if DP/B
    output ALUSrc, // ALUSrc = 0 if DP Reg, else 1
    output [1:0] ImmSrc, // ImmSrc = 00 means zero-extended imm8 which is DP imm, 01 means zero extended imm12 which is LDR/STR, 10 means sign extended imm24 which is branch
    output [1:0] RegSrc, // bit 0 checks if destination is PC which is from Branch, bit 1 checks if register is a source which is from STR
    output NoWrite, // set to 1 if its CMP/CMN
    output reg [3:0] ALUControl, // 00 for anything that is not DP, 00 for ADD, 01 for SUB, 10 for AND, 11 for ORR
    output reg [1:0] FlagW, // FlagW[0] = 1: CV (ALUFlags[1:0] should be saved). FlagW[1] = 1: NZ (ALUFlags[3:2] should be saved). ADDS/SUBS is 11. ANDS/ORRS is 10. without s flag its 00
    output reg Start,
    output reg [1:0] MCycleOp
    );
    
    wire[1:0] ALUOp ; // set to 1x if its dp, 00 if ldr/str with positive offset, 01 if ldr/str with negative offset
    reg [9:0] controls ; // PCS[9], RegW[8], MemW[7], MemtoReg[6], ALUSrc[5], ImmSrc[4:3], RegSrc[2:1], NoWrite[0]
    //<extra signals, if any>
    assign ALUOp[1] = (Op == 2'b00) ? 1'b1 : 1'b0; //If Instruction is a DP Instruction, ALUOp[1] = 1
    assign ALUOp[0] = ((Funct[3] == 1'b0) && (Op == 2'b01)) ? 1'b1 : 1'b0 ; //If Instruction is a Memory Instruction and there is negative immediate offset, AluOp[2] = 1
    always @(*) begin
        case(Op)
            2'b00: begin //DP instruction
                if (Funct[5]) //DP Imm
                    controls[8:1] = 8'b10010000;      //If Funct[5] is 1, there is Immediate Offset, ALUSrc set to 1 to use values from Src2
                else
                    controls[8:1] = 8'b10000000;      //Else if Funct[5] is 0, there is no Immediate Offset, ALUSrc is 0, to use the values from RD2                                
            end
            2'b01: begin //Memory Instruction
                if (Funct[0])
                    controls[8:1] = 8'b10110100;      //If Funct[0] is 1, it is a LDR instruction, RegW = 1, MemToReg = 1, ALUSrc = 1, ImmSrc = 2'b01 for Zero-extended Imm12
                else
                    controls[8:1] = 8'b01010110;      //If Funct[0] is 0, it is a STR instruction, MemW = 1, ALUSrc = 1, ImmSrc = 2'b01 for Zero-extended Imm12, RegSrc = 2'b10 to use the values of Rd
            end
            2'b10: controls[8:1] = 8'b00011001; //For all Branch Instruction, ALUSrc = 1 to use values from imm24, ImmSrc = 2'b10 for Sign-extended Imm24, RegSrc = 2'bX1 to use R15 
            default: controls = 0; //If instruction op code is none of the above, set all controls to 0
        endcase
        
        if (ALUOp[1]) begin //Set the corresponding ALUControl and FlagW values by their specific DP Instruction if ALUOp[1] is 1
            Start = 1'b0;
            MCycleOp = 2'b00;
            
            case(Funct[4:0])
                5'b00000: begin //DP AND/MUL Instr
                    if(bit7to4 == 4'b1001) begin //DP MUL Instr
                        Start = 1;
                        MCycleOp = 2'b01; //2'b01 for Unsigned Multiplication
                        ALUControl = 4'b0000;
                        FlagW = 2'b00;      
                    end
                    else begin
                        ALUControl = 4'b0010; //Denotes AND Instr
                        FlagW = 2'b00; //Dont save any flags
                    end
                end
                 
                5'b00001: begin //DP ANDS Instr
                    ALUControl = 4'b0010; //Denotes AND Instr
                    FlagW = 2'b10; //Only save N and Z flag
                end
                 
                5'b00010: begin //DP EOR/DIV Instr
                    if(bit7to4 == 4'b1001) begin //DP Unsigned DIV Instr
                        ALUControl = 4'b0000;
                        Start = 1;
                        MCycleOp = 2'b11;
                        FlagW = 2'b00;
                    end
                    else begin //DP EOR Instr
                        ALUControl = 4'b0110; //Denotes EOR Instr
                        FlagW = 2'b00; //Dont save any flags    
                    end
                end
                
                5'b00011: begin //DP EORS Instr
                    ALUControl = 4'b0010; //Denotes EOR Instr
                    FlagW = 2'b10; //Only save N and Z Flag
                end
                
                5'b00100: begin //DP SUB Instr
                    ALUControl = 4'b0001; //Denotes SUB Instr
                    FlagW = 2'b00; //Dont save any flags
                end
                 
                5'b00101: begin //DP SUBS Instr
                    ALUControl = 4'b0001; //Denotes SUB Instr
                    FlagW = 2'b11; //Save all N,Z,C and V Flags
                end
                 
                5'b00110: begin //DP RSB Instr
                    ALUControl = 4'b1001; //Denotes RSB Instr
                    FlagW = 2'b00; //Dont save any flags
                end
                
                5'b00111: begin //DP RSBS Instr
                    ALUControl = 4'b1001; //Denotes RSB Instr
                    FlagW = 2'b11; 
                end
                
                5'b01000: begin //DP ADD Instr
                    ALUControl = 4'b0000; //Denotes ADD Instr
                    FlagW = 2'b00; //Dont save any flags
                end
                
                5'b01001: begin //DP ADDS Instr
                    ALUControl = 4'b0000; //Denotes ADD Instr
                    FlagW = 2'b11; //Save all N,Z,C and V Flags
                end
                
                5'b01010: begin //DP ADC Instr
                    ALUControl = 4'b0100; //Denotes ADC Instr
                    FlagW = 2'b00; //Dont save any flags
                end
                 
                5'b01011: begin //DP ADCS Instr
                    ALUControl = 4'b0100; ///Denotes ADC Instr
                    FlagW = 2'b11; //Save all N,Z,C and V flags
                end
                 
                5'b01100: begin //DP SBC Instr
                    ALUControl = 4'b1011; //Denotes SBC Instr
                    FlagW = 2'b00; //Dont save any flags 
                end
                 
                5'b01101: begin //DP SBCS Instr
                    ALUControl = 4'b1011; //Denotes SBC Instr
                    FlagW = 2'b11;
                end
                
                5'b01110: begin //DP RSC Instr
                    ALUControl = 4'b1010; //Denotes RSC Instr
                    FlagW = 2'b00; //Dont save any flags
                end
                
                5'b01111: begin //DP RSCS Instr               
                    ALUControl = 4'b1010; //Denotes RSC Instr
                    FlagW = 2'b11;
                end
                
                5'b10001: begin //DP TST Instr               
                    ALUControl = 4'b1101; //Denotes TST Instr
                    FlagW = 2'b10;
                end
                
                5'b10011: begin //DP TEQ Instr               
                    ALUControl = 4'b1100; //Denotes TEQ Inst
                    FlagW = 2'b10;
                end

                5'b10101: begin //DP CMP Instr
                    ALUControl = 4'b0001; //Denotes SUB Instr
                    FlagW = 2'b11; //Save all N,Z,C and V Flags
                end
                 
                5'b10111: begin //DP CMN Instr
                    ALUControl = 4'b0000; //Denotes ADD Instr
                    FlagW = 2'b11; //Save all N,Z,C and V Flags
                end
                
                5'b11000: begin //DP ORR Instr
                    ALUControl = 4'b0011; //Denotes ORR Instr
                    FlagW = 2'b00; //Dont save any flags
                end
                 
                5'b11001: begin //DP ORRS Instr
                    ALUControl = 4'b0011; //Denotes ORR Instr
                    FlagW = 2'b10; //Only save N and Z flags
                end
                
                5'b11010: begin //DP MOV Instr
                    ALUControl = 4'b0111; //Denotes MOV Instr
                    FlagW = 2'b00; //Do not save any flags
                end
                
                5'b11011: begin //DP MOVS Instr
                    ALUControl = 4'b0111; //Denotes MOV Instr
                    FlagW = 2'b10; //Only save N and Z Flags
                end
                
                5'b11100: begin //DP BIC Instr
                    ALUControl = 4'b0101; //Denotes BIC Instr
                    FlagW = 2'b00; //Do not save nay flags
                end
                
                5'b11101: begin //DP BICS Instr
                    ALUControl = 4'b0101; //Denotes BIC Instr
                    FlagW = 2'b10; //Only save N and Z flag
                end
                
                5'b11110: begin //DP MVN Instr
                    ALUControl = 4'b1000; //Denotes MVN Instr
                    FlagW = 2'b00; //Do not save any flags
                end
                
                5'b11111: begin //DP MVNS Instr
                    ALUControl = 4'b1000; //Denotes MVN Instr
                    FlagW = 2'b10; //Only save N,Z flags
                end
                            
                default: begin //If no such DP Instr, set ALUControl and FlagW to 2'b00
                    ALUControl = 4'b0000; 
                    FlagW = 2'b00;
                end
            endcase
        end
        //For non DP Instructions, ALUControl = ALUOp, so that if there is a Memory Instr with offset, ALUControl will be 2'b00 for positive offset, and 2'b01 for negative offset
        else begin  
            ALUControl = ALUOp;
            FlagW = 2'b00;
            MCycleOp = 2'b00;
            Start = 1'b0;
        end        
        controls[0] = (Funct[4:0] == 5'b10101 || Funct[4:0] == 5'b10111 || Funct[4:0] == 5'b10001 || Funct[4:0] == 5'b10011) ? 1'b1 : 1'b0; //NoWrite if its CMP or CMN then 1 else 0
        controls[9] = (((Rd == 15) & controls[8]) | (Op == 2'b10)) ? 1'b1 : 1'b0; // PCS if its branch or destination is 15 and reg write then 1 else 0
    end
    
    assign PCS = controls[9];
    assign RegW = controls[8];
    assign MemW = controls[7];
    assign MemtoReg = controls[6];
    assign ALUSrc = controls[5];
    assign ImmSrc = controls[4:3];
    assign RegSrc = controls[2:1];
    assign NoWrite = controls[0];
endmodule





