`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/23/2018 01:26:55 PM
// Design Name: 
// Module Name: HazardUnit
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module HazardUnit(
    input [3:0] RA1D,
    input [3:0] RA2D,
    input [3:0] RA1E,
    input [3:0] RA2E,
    input [3:0] WA3E,
    input MemtoRegE,
    input PCSrcE,
    input [3:0] WA3M,
    input RegWriteM,
    input [3:0] RA2M,
    input MemWD,
    input MemWriteM,
    input MemtoRegW,
    input [3:0] WA3W,
    input RegWriteW,
    input RegWriteE,
    input BusyE,
    output StallF,
    output StallD,
    output StallE,
    output StallM,
    output StallW,
    output FlushD,
    output FlushE,
    output ForwardM,
    output [1:0] ForwardAE,
    output [1:0] ForwardBE
    );
    
    wire Match_1E_M;
    wire Match_2E_M;
    wire Match_1E_W;
    wire Match_2E_W;
    wire Match_12D_E;
    wire ldrstall;
    
    assign Match_1E_M = (RA1E == WA3M);
    assign Match_2E_M = (RA2E == WA3M);
    assign Match_1E_W = (RA1E == WA3W);
    assign Match_2E_W = (RA2E == WA3W);
    assign Match_12D_E = (RA1D == WA3E) || ((RA2D == WA3E) & ~MemWD);
    assign ldrstall = (Match_12D_E & MemtoRegE & RegWriteE);
    
    assign StallF = BusyE || ldrstall;
    assign StallD = BusyE || ldrstall;
    assign StallE = BusyE;
    assign StallM = BusyE;
    assign StallW = BusyE;
    
    assign FlushD = PCSrcE;
    assign FlushE = (ldrstall || PCSrcE);
    
    assign ForwardAE = (Match_1E_M & RegWriteM) ? 2'b10: (Match_1E_W & RegWriteW) ? 2'b01 : 2'b00;
    assign ForwardBE = (Match_2E_M & RegWriteM) ? 2'b10: (Match_2E_W & RegWriteW) ? 2'b01 : 2'b00;
    assign ForwardM = (RA2M == WA3W) & MemWriteM & MemtoRegW & RegWriteW;            
    
endmodule
