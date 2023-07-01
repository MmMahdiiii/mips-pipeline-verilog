`include "defines.v"

module extender (imm, imm_ext);
  input [15:0] imm;
  output reg [`WORD_LEN-1:0] imm_ext;

  always @(*)
    if (imm[15] == 1)
      imm_ext = {`WORD_NEGATIVE, imm};
    else
      imm_ext = {`WORD_POSITIVE, imm};

endmodule