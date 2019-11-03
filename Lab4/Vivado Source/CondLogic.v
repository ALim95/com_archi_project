`timescale 1ns / 1ps
/*
----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: (c) Shahzor Ahmad and Rajesh Panicker  
-- 
-- Create Date: 09/23/2015 06:49:10 PM
-- Module Name: CondLogic
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool Versions: Vivado 2015.2
-- Description: CondLogic Module
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

module CondLogic(
    input CLK,
    input PCS, // output from decoder.v
    input RegW, // output from decoder.v
    input NoWrite, // output from decoder.v
    input MemW, // output from decoder.v
    input [1:0] FlagW, //output from decoder.v
    input [3:0] Cond, //input from instruction ROM
    input [3:0] ALUFlags, // output from ALU.v
    output PCSrc, // PCSrc = PCS & CondEx
    output RegWrite, // RegWrite = RegW & CondEx
    output MemWrite, // MemWrite = MemW & CondEx
    output C_Flag
    );
    
    reg CondEx ;
    reg N = 0, Z = 0, C = 0, V = 0 ;
    reg [1:0] FlagWrite = 0;
    //<extra signals, if any>
    always@(Cond, N, Z, C, V)
    begin
        case(Cond)
            4'b0000: CondEx <= Z ;                  // EQ  
            4'b0001: CondEx <= ~Z ;                 // NE 
            4'b0010: CondEx <= C ;                  // CS / HS 
            4'b0011: CondEx <= ~C ;                 // CC / LO  
            
            4'b0100: CondEx <= N ;                  // MI  
            4'b0101: CondEx <= ~N ;                 // PL  
            4'b0110: CondEx <= V ;                  // VS  
            4'b0111: CondEx <= ~V ;                 // VC  
            
            4'b1000: CondEx <= (~Z) & C ;           // HI  
            4'b1001: CondEx <= Z | (~C) ;           // LS  
            4'b1010: CondEx <= N ~^ V ;             // GE  
            4'b1011: CondEx <= N ^ V ;              // LT  
            
            4'b1100: CondEx <= (~Z) & (N ~^ V) ;    // GT  
            4'b1101: CondEx <= Z | (N ^ V) ;        // LE  
            4'b1110: CondEx <= 1'b1  ;              // AL 
            4'b1111: CondEx <= 1'bx ;               // unpredictable   
        endcase   
    end
    
    always @ (*) begin
        FlagWrite[0] = FlagW[0] & CondEx;
        FlagWrite[1] = FlagW[1] & CondEx;
    end
    
    
    always @(posedge CLK)
    begin
        case(FlagWrite[1])
            1'b1: begin 
                N <= ALUFlags[3];
                Z <= ALUFlags[2];            
                end
            1'b0: begin
                N <= N;
                Z <= Z;
            end
        endcase
        
        case(FlagWrite[0])
            1'b1: begin 
                C <= ALUFlags[1];
                V <= ALUFlags[0];            
            end
            1'b0: begin
                C <= C;
                V <= V;
            end
        endcase
    end
    
    assign PCSrc = PCS & CondEx;
    assign RegWrite = ~NoWrite & RegW & CondEx;
    assign MemWrite = MemW & CondEx;
    assign C_Flag = C;
        
endmodule













