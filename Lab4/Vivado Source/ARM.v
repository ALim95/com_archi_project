`timescale 1ns / 1ps
/*
----------------------------------------------------------------------------------
-- Company: NUS	
-- Engineer: (c) Shahzor Ahmad and Rajesh Panicker  
-- 
-- Create Date: 09/23/2015 06:49:10 PM
-- Module Name: ARM
-- Project Name: CG3207 Project
-- Target Devices: Nexys 4 (Artix 7 100T)
-- Tool Versions: Vivado 2015.2
-- Description: ARM Module
-- 
-- Dependencies: NIL
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: The interface SHOULD NOT be modified. The implementation can be modified
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

//-- R15 is not stored
//-- Save waveform file and add it to the project
//-- Reset and launch simulation if you add interal signals to the waveform window

module ARM(
    input CLK,
    input RESET,
    //input Interrupt,  // for optional future use
    input [31:0] InstrF,
    input [31:0] ReadDataM,
    output reg MemWriteM,
    output [31:0] PCF,
    output reg [31:0] ALUResultM,
    output [31:0] WriteDataM
    );
    
    // Decode stage
    reg [31:0] InstrD;
    
    // Execute stage        
    reg MemtoRegE;
    reg [3:0] WA3E;
    reg [31:0] ExtImmE;
    reg StartE;
    wire [31:0] WriteDataE;
    
    // Memory stage
    reg PCSrcM;
    reg RegWriteM;
    reg MemtoRegM;
    reg [31:0] WriteDataEM;
    reg [3:0] WA3M;
    reg [31:0] ALUOutM; 
    
    // Writeback stage
    reg PCSrcW;
    reg RegWriteW;
    reg MemtoRegW;
    reg [31:0] ReadDataW;
    reg [31:0] ALUOutW;
    reg [3:0] WA3W;
    reg StartW;
        
    // RegFile signals
    //wire CLK ;
    wire WE3 ;
    wire [3:0] A1 ;
    wire [3:0] A2 ;
    wire [3:0] A3 ;
    wire [31:0] WD3 ;
    wire [31:0] R15 ;
    wire [31:0] RD1 ;
    wire [31:0] RD2 ;
    
    // Extend Module signals
    wire [1:0] ImmSrc ;
    wire [23:0] InstrImm ;
    wire [31:0] ExtImm ;
    
    // Decoder signals
    wire [3:0] Rd ;
    wire [3:0] MCycleRd;
    wire [1:0] Op ;
    wire [5:0] Funct ;
    wire [3:0] bit7to4;
    wire PCSD ;
    wire RegWD ;
    wire MemWD ;
    wire MemtoRegD ;
    wire ALUSrcD ;
    wire [1:0] ImmSrcD ;
    wire [1:0] RegSrcD ;
    wire StartD;
    wire [1:0] MCycleOpD;
    wire NoWriteD ;
    wire [3:0] ALUControlD ;
    wire [1:0] FlagWD ;
    
    // CondLogic signals
    //wire CLK ;
    reg PCSE ;
    reg RegWE ;
    reg NoWriteE ;
    reg MemWE ;
    reg [1:0] FlagWE ;
    reg [3:0] CondE ;
    reg ALUSrcE;
    //wire [3:0] ALUFlags,
    wire PCSrcE ;
    wire RegWriteE ; 
    wire MemWriteE;
    wire C_FlagE;
       
    // Shifter signals
    reg [1:0] Sh ;
    reg [4:0] Shamt5 ;
    wire [31:0] ShIn ;
    wire [31:0] ShOut ;
    
    // ALU signals
    wire [31:0] Src_AE ;
    wire [31:0] Src_BE ;
    wire [31:0] Src_ME ;
    reg [3:0] ALUControlE ;
    wire [31:0] ALUResultE ;
    wire [3:0] ALUFlags ;
    
    // ProgramCounter signals
    //wire CLK ;
    //wire RESET ;
    wire WE_PC ;    
    wire [31:0] PC_IN ;
    //wire [31:0] PC ; 
        
    // MCycle signals    
    wire BusyE;
    wire [31:0] MResult1E;
    wire [31:0] MResult2E;
    reg [1:0] MCycleOpE;
    reg [31:0] RD1E;
    reg [31:0] RD2E;
    
    // signal for hazard control
    reg [3:0] RA1E;
    reg [3:0] RA2E;
    reg [3:0] RA2M;
    wire StallF;
    wire StallD;
    wire StallE;
    wire StallM;
    wire StallW;
    wire FlushD;
    wire FlushE;
    wire [1:0] ForwardAE;
    wire [1:0] ForwardBE;
    wire ForwardM;
        
    // Other internal signals here
    wire [31:0] PCPlus4F ;
    wire [31:0] PCPlus8D ;
    wire [31:0] ResultW ;
    
    // from Fetch to Decode Stage
    always @ (posedge CLK) begin
        if (!StallD) begin
            InstrD <= InstrF;
        end
        if (FlushD || RESET) begin
            InstrD <= 0;
        end
    end
    
    // from Decode to Execute Stage
    always @ (posedge CLK) begin
        if (FlushE || RESET) begin
            PCSE <= 0;
            RegWE <= 0;
            MemWE <= 0;
            FlagWE <= 0;
            MemtoRegE <= 0;
        end else if (!StallE) begin
            PCSE <= PCSD;
            RegWE <= RegWD;
            MemWE <= MemWD;
            FlagWE <= FlagWD;
            ALUControlE <= ALUControlD;
            MemtoRegE <= MemtoRegD;               
            ALUSrcE <= ALUSrcD;
            CondE <= InstrD[31:28];
            WA3E <= (StartD == 1'b1) ? InstrD[19:16] : InstrD[15:12];
            NoWriteE <= NoWriteD;
            
            // for mcycle
            MCycleOpE <= MCycleOpD;
            StartE <= StartD;
            RD1E <= RD1;
            RD2E <= RD2;             
            
            // for shifter
            Shamt5 <= InstrD[11:7];
            Sh <= InstrD[6:5];
            
            // for ALU                    
            ExtImmE <= ExtImm;
            
            // for hazard control
            RA1E <= A1;
            RA2E <= A2;
        end        
    end
    
    // from Execute to Memory Stage
    always @ (posedge CLK) begin
        if (RESET) begin
            RegWriteM <= 0;
            MemWriteM <= 0;
            MemtoRegM <= 0;
        end else if (!StallM) begin
            MemtoRegM <= MemtoRegE;
            PCSrcM <= PCSrcE;
            RegWriteM <= RegWriteE;        
            MemtoRegM <= MemtoRegE;
            ALUResultM <= (StartE == 1) ? MResult1E : ALUResultE;
            ALUOutM <= (StartE == 1) ? MResult1E : ALUResultE;
            MemWriteM <= MemWriteE;
            WriteDataEM <= WriteDataE;            
            WA3M <= WA3E;                           
            
            // for hazard control
            RA2M <= RA2E;   
        end
    end
    
    // from Memory to Writeback Stage
    always @ (posedge CLK) begin
        if (RESET) begin
            RegWriteW <= 0;
            MemtoRegW <= 0;
        end else if (!StallW) begin
            MemtoRegW <= MemtoRegM;
            PCSrcW <= PCSrcM;
            RegWriteW <= RegWriteM;
            MemtoRegW <= MemtoRegM;
            ReadDataW <= ReadDataM;
            ALUOutW <= ALUOutM;
            WA3W <= WA3M;            
        end
    end            
    
    // datapath connections here
    assign WE_PC = BusyE || StallF ; // Will need to control it for multi-cycle operations (Multiplication, Division) and/or Pipelining with hazard hardware.
    assign Op = InstrD[27:26];    
    assign Funct = InstrD[25:20];
    assign Rd = InstrD[15:12];    
    assign MCycleRd = InstrD[19:16];
    assign InstrImm = InstrD[23:0];
    assign bit7to4 = InstrD[7:4];
    assign A1 = (RegSrcD[0] == 1'b1) ? 4'b1111 : (StartD == 1'b1) ? InstrD[11:8] : InstrD[19:16]; //If DIV/MUL, A1=Operand2(Rs)
    assign A2 = (RegSrcD[1] == 1'b1) ?  InstrD[15:12] : InstrD[3:0]; //If DIV/MUL, A2=Operand1(Rm)
    assign A3 = WA3W;
    assign WE3 = RegWriteW;
    assign WD3 = ResultW;
    assign R15 = PCPlus8D;        
    
    assign Src_AE = (ForwardAE == 2'b00) ? RD1E : (ForwardAE == 2'b01) ? ResultW : (ForwardAE == 2'b10) ? ALUOutM : 0;    
    assign Src_BE = (ALUSrcE == 1'b1) ? ExtImmE : ShOut;
    assign Src_ME = (ForwardBE == 2'b00) ? RD2E : (ForwardBE == 2'b01) ? ResultW : (ForwardBE == 2'b10) ? ALUOutM : 0;
    assign ShIn = (ForwardBE == 2'b00) ? RD2E : (ForwardBE == 2'b01) ? ResultW: 
                    (ForwardBE == 2'b10) ? ALUOutM : 0;        
    assign WriteDataE = ShOut;   
    assign WriteDataM = (MemWriteM == 1'b1) ? ((ForwardM == 1'b0) ? WriteDataEM : ResultW) : 0;

    // initialise all signals / regs to zeros
    initial begin
        InstrD = 0;
        MemtoRegE = 0;
        WA3E = 0;
        ExtImmE = 0;
        StartE = 0;
        
        // Memory stage
        PCSrcM = 0;
        RegWriteM = 0;
        MemtoRegM = 0;
        WA3M = 0;
        ALUOutM = 0;     
        
        // Writeback stage
        PCSrcW = 0;
        RegWriteW = 0;
        MemtoRegW = 0;
        ReadDataW = 0;
        ALUOutW = 0;
        WA3W = 0;
        StartW = 0;         
        
        // CondLogic signals
        //wire CLK ;
        PCSE = 0;
        RegWE = 0;
        NoWriteE = 0;
        MemWE = 0;
        FlagWE = 0;
        CondE = 0;
        ALUSrcE = 0;        
           
        // Shifter signals
        Sh = 0;
        Shamt5 = 0;
        
        // ALU signals
        ALUControlE = 0;
            
        // MCycle signals
        MCycleOpE = 0;
        RD1E = 0;
        RD2E = 0;
        
        // hazard control signals
        RA1E = 0;
        RA2E = 0;
        RA2M = 0;
    end                
    
// Instantiate Decoder
    Decoder Decoder1(
                    Rd,
                    Op,
                    Funct,
                    bit7to4,
                    PCSD,
                    RegWD,
                    MemWD,
                    MemtoRegD,
                    ALUSrcD,
                    ImmSrcD,
                    RegSrcD,
                    NoWriteD,
                    ALUControlD,
                    FlagWD,
                    StartD,
                    MCycleOpD
                );    

    

    // Instantiate CondLogic
    CondLogic CondLogic1(
                    CLK,
                    PCSE,
                    RegWE,
                    NoWriteE,
                    MemWE,
                    FlagWE,
                    CondE,
                    ALUFlags,
                    PCSrcE,
                    RegWriteE,
                    MemWriteE,
                    C_FlagE
                );                          

    // Instantiate CondLogic
    HazardUnit HazardUnit1(
                    A1,
                    A2,
                    RA1E,
                    RA2E,
                    WA3E,
                    MemtoRegE,
                    PCSrcE,
                    WA3M,
                    RegWriteM,
                    RA2M,
                    MemWD,
                    MemWriteM,
                    MemtoRegW,
                    WA3W,
                    RegWriteW,
                    RegWriteE,
                    BusyE,
                    StallF,
                    StallD,
                    StallE,
                    StallM,
                    StallW,
                    FlushD,
                    FlushE,
                    ForwardM,          
                    ForwardAE,
                    ForwardBE
                );    
        
        
    // Instantiate RegFile
    RegFile RegFile1( 
                    CLK,
                    WE3,
                    A1,
                    A2,
                    A3,
                    WD3,
                    R15,
                    RD1,
                    RD2     
                );
                
     // Instantiate Extend Module
    Extend Extend1(
                    ImmSrcD,
                    InstrImm,
                    ExtImm
                );
                                                                
    // Instantiate Shifter        
    Shifter Shifter1(
                    Sh,
                    Shamt5,
                    ShIn,
                    ShOut
                );                                           
    
    // Instantiate ALU        
    ALU ALU1(
                    Src_AE,
                    Src_BE,
                    ALUControlE,
                    C_FlagE,
                    ALUResultE,
                    ALUFlags
                ); 
    
    assign ResultW = (MemtoRegW == 1'b1) ? ReadDataW : ALUOutW;           
    assign PCPlus4F = PCF + 4;
    assign PCPlus8D = PCPlus4F;                               
    assign PC_IN = (PCSrcE == 1'b1) ? ALUResultE : PCPlus4F;
    // Instantiate ProgramCounter    
    ProgramCounter ProgramCounter1(
                    CLK,
                    RESET,
                    WE_PC,    
                    PC_IN,
                    PCF  
                );    

    MCycle MCycle1(
                    CLK,
                    RESET,
                    StartE,
                    MCycleOpE,
                    Src_ME,
                    Src_AE,
                    MResult1E,
                    MResult2E,
                    BusyE
                );                               
                            
endmodule








