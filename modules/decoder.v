`include "defines.v"

module decoder (
    input [`WORD_LEN-1:0] instruction,
    output [`OP_CODE_LEN-1:0] opcode,
    output [`FUNCT_LEN-1:0] funct,
    output [`REG_FILE_ADDR_LEN-1:0] rs,
    output [`REG_FILE_ADDR_LEN-1:0] rt,
    output [`REG_FILE_ADDR_LEN-1:0] rd,
    output [`IMM_LEN-1:0] imm,
    output [25:0] daddr,
    output [10:6] shamt
    );
     
    assign rs = instruction[25:21];
    assign rt = instruction[20:16];
    assign rd = instruction[15:11];
    assign funct = instruction[`FUNCT_LEN :0];
    assign opcode = instruction[`WORD_LEN-1:26];
    assign imm = instruction[`IMM_LEN-1:0];
    assign daddr = instruction[25:0];
    assign shamt = instruction[10:6];
    
endmodule