// Wire widths
`define WORD_LEN 32
`define REG_FILE_ADDR_LEN 5
`define ALU_OPR_LEN 4
`define IMM_LEN 16
`define OP_CODE_LEN 6
`define FUNCT_LEN 6

// Memory constants
`define DATA_MEM_SIZE 64
`define INSTR_MEM_SIZE 64
`define DATA_MEM_ADDR_LEN 6
`define INSTR_MEM_ADDR_LEN 6

// To be used inside controller.v
`define OP_R_TYPE 6'b000000


// ------------I-Type----------------
// Arithmetic Instructions
`define OP_ADD_I 6'b001000
`define OP_ADD_I_U 6'b001001
`define OP_AND_I 6'b001100
`define OP_OR_I 6'b001101

// Data Transfer Instructions
`define OP_LW 6'b100011     
`define OP_SW 6'b101011
`define OP_LUI 6'b001111

// Conditional Branch Instructions
`define OP_BEQ 6'b000100
`define OP_BNE 6'b000101

// Comparison Instructions
`define OP_SLT_I 6'b001010


// ------------J-Type----------------
`define OP_J_TYPE 6'b000010  //what is this exactly??

// Unconditional Jump Instructions
`define OP_J 6'b000010
`define OP_JAL 6'b000011


// To be used in side ALU
`define ALU_NO_OPERATION 4'b0000 // for NOP, BEZ, BNQ, JMP
`define ALU_ADD 4'b0001 //1
`define ALU_SUB 4'b0010 //2
`define ALU_SLL 4'b0011 //3
`define ALU_AND 4'b0100 //4
`define ALU_OR 4'b0101  //5
`define ALU_SRL 4'b0110 //6
`define ALU_LUI 4'b0111 //7
`define ALU_SLT 4'b1000 //8
`define ALU_JAL 4'b1001 //9
`define ALU_XOR 4'b1010 //10
`define ALU_NOR 4'b1011 //11
`define ALU_ADD_U 4'b1100 //12
`define ALU_SUB_U 4'b1101 //13
`define ALU_SLT_U 4'b1110 //14


// ------------R-Type FT----------------
// Arithmetic Instructions
`define FT_ADD 6'b100000
`define FT_SUB 6'b100010
`define FT_ADD_U   6'b100001
`define FT_SUB_U 6'b100011

// Logical Instructions
`define FT_AND 6'b100100
`define FT_OR 6'b100101
`define FT_SLL 6'b000000
`define FT_SRL 6'b000010

// Comparison Instructions  
`define FT_SLT 6'b101010
`define FT_SLT_U 6'b101011

// Unconditional Jump Instructions
`define FT_JR 6'b001000

// Jump and Link Register
`define FT_JALR 6'b001001

`define FT_XOR 6'b100110
`define FT_NOR 6'b100111


// To be used in conditionChecker
`define COND_JUMP 2'b10
`define COND_BEQ 2'b11
`define COND_NOTHING 2'b00

//IMMEDIATE EXTENSION
`define WORD_NEGATIVE 16'b1111111111111111
`define WORD_POSITIVE 16'b0000000000000000
