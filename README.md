# Computer Architecture Project
## Lab 2
Objective
In this lab, you will be implementing the basic ARMv3 processor you had learnt in lectures.

Essentially, it should support the following instructions [HDL simulation as well as hardware]
- LDR, STR with positive immediate offset
- AND, OR, ADD, SUB where Src2 is register or immediate without shifts
- B

Further, improve the processor by adding the following features [HDL simulation as well as hardware]
- CMP and CMN instructions
- LDR, STR to support negative immediate offset
- Src2 for DP instructions support register with immediate shifts (LSL, LSR, ASR, ROR)

## Lab 3
Lab 3 involves 2 compulsory tasks and one open ended task.

### Compulsory Task
1) You will incorporate division (both signed and unsigned) into the MCycle unit given [HDL simulation only].
You can assume that the divisor is never zero.
2) Incorporate MCycle unit into your processor so that it can execute MUL and DIV [HDL simulation as well as hardware].

### Enhancements (Open-ended)
3) You can improve the given signed multiplier implemented in step 1 to score marks for performance enhancement.
- Have implemented a multiplier using Booth's algorithm that halves the number of cycles required, thus improving throughput.

## Lab 4
Lab 4 involves 1 compulsory task and the rest is open-ended.

### Compulsory Task
You will expand the ARM processor to support all the 16 Data Processing instructions a.k.a ALU functions [HDL simulation as well as hardware] (15 marks)

### Enhancements (Open-ended)
Less than half of the weight of Lab 4 is for performance enhancements (10 marks in total). It is open-ended without fixed requirements. You don't have to do everything; one significant improvement which you think is worth 10 marks is good enough.
- Implemented 5-Stage Pipelining with Hazard Control Unit
- This increases performance of the processor, compared to a Single-Cycle Processor.
