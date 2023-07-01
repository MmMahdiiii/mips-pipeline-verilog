`include "defines.v"


module controller (opcode, funct, branch, jump, alu_op, mem_to_reg, mem_write, reg_dst, reg_write, alu_src, is_eq, jmp_src, jal);
    input [`OP_CODE_LEN-1:0] opcode;
    input [`FUNCT_LEN-1:0] funct;
    output reg branch, jump ,reg_write, mem_to_reg, mem_write, reg_dst, alu_src, is_eq,jmp_src, jal;
    output reg [`ALU_OPR_LEN-1:0] alu_op;
    always @ ( * ) begin
        jal <= 0;
        is_eq <= 0;
        reg_write <= 0;
        mem_to_reg <= 0;
        mem_write <= 0;
        reg_dst <= 0;
        alu_src <= 0;
        alu_op <= 0;
        branch <= 0;
        jump <= 0;
        jmp_src <= 0;
        if (opcode == `OP_R_TYPE) begin
            reg_write <= 1'b1;
            reg_dst <= 1'b1;
            jmp_src <= 1'b1;
            alu_op <= `ALU_NO_OPERATION;
            case (funct)
                `FT_ADD: begin alu_op <= `ALU_ADD; end
                `FT_SUB: begin alu_op <= `ALU_SUB; end
                `FT_AND: begin alu_op <= `ALU_AND; end
                `FT_OR: begin alu_op <= `ALU_OR; end
                `FT_SLT: begin alu_op <= `ALU_SLT; end
                `FT_SLT_U: begin alu_op <= `ALU_SLT_U; end
                `FT_ADD_U: begin alu_op <= `ALU_ADD_U; end
                `FT_SUB_U: begin alu_op <= `ALU_SUB_U; end
                `FT_SLL: begin alu_op <= `ALU_SLL; end
                `FT_SRL: begin alu_op <= `ALU_SRL; end
                `FT_XOR: begin alu_op <= `ALU_XOR; end
                `FT_NOR: begin alu_op <= `ALU_NOR; end
                `FT_JR: begin jump <= 1'b1; end
                `FT_JALR: begin jump <= 1'b1; jal <= 1'b1; alu_op <= `ALU_JAL; end
                default: begin alu_op <= `ALU_NO_OPERATION; end
            endcase
        end else if (opcode == `OP_BNE) begin 
            branch <= 1'b1;
            alu_op <= `ALU_SUB;
            is_eq <= 1'b0;
        end else if (opcode == `OP_LW) begin
            reg_write <= 1'b1;
            mem_to_reg <= 1'b1;
            alu_src <= 1'b1;
            alu_op <= `ALU_ADD;
        end else if (opcode == `OP_SW) begin
            mem_write <= 1'b1;
            alu_src <= 1'b1;
            alu_op <= `ALU_ADD;
        end else if (opcode == `OP_ADD_I) begin
            reg_write <= 1'b1;
            alu_src <= 1'b1;
            alu_op <= `ALU_ADD;
        end else if(opcode == `OP_ADD_I_U) begin
            reg_write <= 1'b1;
            alu_src <= 1'b1;
            alu_op <= `ALU_ADD_U;
        end else if (opcode == `OP_SLT_I) begin
            reg_write <= 1'b1;
            alu_src <= 1'b1;
            alu_op <= `ALU_SLT;
        end else if (opcode == `OP_AND_I) begin
            reg_write <= 1'b1;
            alu_src <= 1'b1;
            alu_op <= `ALU_AND;
        end else if (opcode == `OP_OR_I) begin
            reg_write <= 1'b1;
            alu_src <= 1'b1;
            alu_op <= `ALU_OR;
        end else if (opcode == `OP_LUI) begin
            reg_write <= 1'b1;
            alu_src <= 1'b1;
            alu_op <= `ALU_LUI;
        end else if (opcode == `OP_BEQ) begin
            branch <= 1'b1;
            alu_op <= `ALU_SUB;
            is_eq <= 1'b1;
        end else if (opcode == `OP_J) begin
            jump <= 1'b1;
        end else if (opcode == `OP_JAL) begin
            jump <= 1'b1;
            jal <= 1'b1;
            alu_op <= `ALU_JAL;
            reg_write <= 1'b1;
        end else begin
            reg_write <= 1'b0;
            mem_to_reg <= 1'b0;
            mem_write <= 1'b0;
            reg_dst <= 1'b0;
            alu_src <= 1'b0;
            alu_op <= 1'b0;
            branch <= 1'b0;
            jump <= 1'b0;
            is_eq <= 1'b0;
        end
    end
endmodule
