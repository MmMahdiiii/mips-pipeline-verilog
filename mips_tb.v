`timescale 1 ns/10 ps  // time-unit = 1 ns, precision = 10 ps
`include "defines.v"
`include "mips.v"
`include "modules/memoryModules/imem.v"
`include "modules/memoryModules/dmem.v"
module mips_core_tb;
	
    wire [31:0] imem_data ;
	wire [31:0] imem_addr ;
	wire [31:0] dmem_rdata;
	wire        dmem_we   ;// write enable
	wire [31:0] dmem_addr ;
	wire [31:0] dmem_wdata;
	reg rst;
	reg clk;
	integer i;

    imem IM (
	.addr(imem_addr[5:0]),
	.dout(imem_data)
	);

	mips_core mips_core (
	.clk(clk),
	.rst(rst),
	.idata(imem_data),
	.iaddr(imem_addr),
	.ddin(dmem_rdata),
	.dwr(dmem_we),
	.daddr(dmem_addr),
	.ddout(dmem_wdata)
	);
	
	dmem dmem_inst(
	.clk(clk),
	.wr(dmem_we),
	.addr (dmem_addr[`DATA_MEM_ADDR_LEN-1:0]),
	.din(dmem_wdata),
	.dout (dmem_rdata)
	);

		initial
		begin
			rst = 1'b1;
			#100
			rst = 1'b0;
		end

		initial
		begin
			clk = 1'b0;
			for(i=0;i<100;i=i+1)
			begin	
				#50 
				clk = 1'b1;
				#50
				clk = 1'b0;
			end
		end
endmodule