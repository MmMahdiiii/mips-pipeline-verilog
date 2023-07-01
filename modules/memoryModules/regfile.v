`include "defines.v"

module regfile (
    input         clk  ,
    input  [ 4:0] addr1,
    input  [ 4:0] addr2,
    output [31:0] data1,
    output [31:0] data2,
    input         write,
    input  [ 4:0] dest,
    input  [31:0] wdata
);


    reg [`WORD_LEN-1:0] regMem [31:0];
    integer i;

    initial begin
        for (i = 0; i < 32; i = i + 1) begin
            regMem[i] = i;
        end
    end

    always @ (negedge clk) begin
      if (write) regMem[dest] <= wdata;
      regMem[0] <= 0;
    end

    assign data1 = (regMem[addr1]);
    assign data2 = (regMem[addr2]);
endmodule // regFile