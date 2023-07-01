`include "defines.v"

module alu (val1, val2, opration, aluOut, zero, shamt);
    input [`WORD_LEN-1:0] val1, val2;
    input [`ALU_OPR_LEN-1:0] opration;
    input [4:0] shamt;
    output reg [`WORD_LEN-1:0] aluOut;
    output zero;

    assign zero = (aluOut == 0);

    always @ ( * ) begin
    case (opration)
        `ALU_ADD: aluOut <= val1 + val2;
        `ALU_SUB: aluOut <= val1 - val2;
        `ALU_AND: aluOut <= val1 & val2;
        `ALU_OR:  aluOut <= val1 | val2;
        `ALU_SLT: aluOut <= (val1 < val2) ? 1 : 0;
        `ALU_SLT_U: aluOut <= ($unsigned(val1) < $unsigned(val2)) ? 1 : 0;
        `ALU_SLL: aluOut <= val2 << shamt;
        `ALU_SRL: aluOut <= val2 >> shamt;
        `ALU_LUI: aluOut <= val2 << 16;
        `ALU_XOR: aluOut <= val1 ^ val2;
        `ALU_NOR: aluOut <= ~(val1 | val2);
        `ALU_JAL: aluOut <= val1;
        `ALU_ADD_U: aluOut <= $unsigned(val1) + $unsigned(val2);
        `ALU_SUB_U: aluOut <= $unsigned(val1) - $unsigned(val2);
        `ALU_NO_OPERATION: aluOut <= 0;
        default: aluOut <= 0;
    endcase
    end
endmodule // ALU
