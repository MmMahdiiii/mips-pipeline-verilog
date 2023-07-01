module imem (addr, dout);
	input  [5:0] addr;
	output wire [31:0] dout; 
  	reg [31:0] rb [0:63]; // 64 rows of 32-bits

	initial begin	
			$readmemb("seq2.bin", rb);
	end 

	assign dout = rb[addr];
endmodule