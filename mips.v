`include "defines.v"
`include "modules/extender.v"
`include "modules/alu.v"
`include "modules/decoder.v"
`include "modules/controllers/controller.v"
`include "modules/memoryModules/regfile.v"

//jump, zero, branch az koja barmigarde be fetch? memory or write back?

module mips_core (clk, rst, iaddr, idata, daddr, dwr, ddout, ddin);
	input  clk;
	input  rst;
	output [`WORD_LEN-1:0]  iaddr;
	input  [`WORD_LEN-1:0] idata;
	output [`WORD_LEN-1:0]  daddr;
	output [`WORD_LEN-1:0] ddout;
	input  [`WORD_LEN-1:0] ddin;
	output        dwr;
	
	// ----------------------------------------  pipeline registers ----------------------------------------

	// wires 
	wire branch, jump, is_eq, jmp_src, jal;
	wire [25:0] address;
	wire [`WORD_LEN-1:0] imm_ext;
	wire [`REG_FILE_ADDR_LEN-1:0] rs;
	wire [`REG_FILE_ADDR_LEN-1:0] rt;
	wire [`REG_FILE_ADDR_LEN-1:0] rd;
	wire [15:0] imm;
	wire [`OP_CODE_LEN-1:0] opcode;
	wire [`FUNCT_LEN-1:0] funct;
	wire reg_write, mem_to_reg, mem_write, reg_dst, alu_src;
	wire [`ALU_OPR_LEN-1:0] alu_op;
	wire [4:0] shamt;
	
	wire [`WORD_LEN-1:0] data1, data2;
	reg [`REG_FILE_ADDR_LEN-1:0] write_reg;
	wire [`WORD_LEN-1:0] result;

	wire [`WORD_LEN-1:0] src_a;
	wire [`WORD_LEN-1:0] src_b;
	wire [`ALU_OPR_LEN-1:0] alucontrol;
	wire zero;
	wire [`WORD_LEN-1:0] alu_out;
	
	
	// pc reg
	reg [`WORD_LEN-1:0] pc, pc_next;

	// fetch phase pipeline registers
	reg [`WORD_LEN-1:0] instruction_pipeline_reg_fetch;
	reg [`WORD_LEN-1:0] pc_plus_pipeline_reg_fetch;

	
	// decode phase pipeline registers
	reg [`REG_FILE_ADDR_LEN-1:0] rs_pipeline_reg_decode;
	reg [`REG_FILE_ADDR_LEN-1:0] rt_pipeline_reg_decode;
	reg [`REG_FILE_ADDR_LEN-1:0] rd_pipeline_reg_decode;
	reg [`WORD_LEN-1:0] data1_pipeline_reg_decode;
	reg [`WORD_LEN-1:0] data2_pipeline_reg_decode;
	reg [`WORD_LEN-1:0] imm_ext_pipeline_reg_decode;
	reg [`ALU_OPR_LEN-1:0] alu_op_pipeline_reg_decode;
	reg [4:0] shamt_pipeline_reg_decode;
	reg [4:0] write_reg_pipeline_reg_decode;
	reg reg_write_pipeline_reg_decode;
	reg mem_to_reg_pipeline_reg_decode;
	reg mem_write_pipeline_reg_decode;
	reg alu_src_pipeline_reg_decode;
	

	// execute phase pipeline registers
	reg [`WORD_LEN-1:0] data2_pipeline_reg_execute;
	reg [4:0] write_reg_pipeline_reg_execute;
	reg reg_write_pipeline_reg_execute;
	reg mem_to_reg_pipeline_reg_execute;
	reg mem_write_pipeline_reg_execute;
	reg [`WORD_LEN-1:0] alu_out_pipeline_reg_execute;
	
	// memory phase pipeline registers
	reg reg_write_pipeline_reg_memory;
	reg mem_to_reg_pipeline_reg_memory;
	reg [4:0] write_reg_pipeline_reg_memory;
	reg [`WORD_LEN-1:0] alu_out_pipeline_reg_memory;
	reg [`WORD_LEN-1:0] readdata_pipeline_reg_memory;

	reg lw_stall, branchstall;
	reg [1:0] ForwardAE, ForwardBE;

	reg taken;

	wire  flush_execute, stall_decode, stall_fetch;
	assign flush_execute = lw_stall | branchstall;
	assign stall_decode = lw_stall | branchstall;
	assign stall_fetch = lw_stall | branchstall;

	wire [`WORD_LEN-1:0] real_data1, real_data2;
	wire ForwardAD, ForwardBD;

	// ----------------------------------------  stall logic ----------------------------------------

	always @(branch or reg_write_pipeline_reg_decode or write_reg_pipeline_reg_decode or rs or 
	 		mem_to_reg_pipeline_reg_decode or rt or write_reg_pipeline_reg_execute or 
			mem_to_reg_pipeline_reg_execute or jump or jmp_src) begin
				
		branchstall = 0;
		if (branch) begin
			if (reg_write_pipeline_reg_decode && 
				((write_reg_pipeline_reg_decode == rs) || (write_reg_pipeline_reg_decode == rt))) begin
				branchstall = 1;
			end 
			else begin
				if (mem_to_reg_pipeline_reg_execute && 
					((write_reg_pipeline_reg_execute == rs) || (write_reg_pipeline_reg_execute == rt)))
					branchstall = 1;
			end
			end else if (jump && jmp_src) begin 
			if (reg_write_pipeline_reg_decode && (write_reg_pipeline_reg_decode == rs)) begin
				branchstall = 1;
			end 
			else begin
				if (mem_to_reg_pipeline_reg_execute && (write_reg_pipeline_reg_execute == rs))
					branchstall = 1;
			end
		end
	end 


	always @(rs or rt or rt_pipeline_reg_decode or mem_to_reg_pipeline_reg_decode or rst) begin
		lw_stall <= 1'b0;
		
		if ((rs == rt_pipeline_reg_decode) || (rt == rt_pipeline_reg_decode)) begin
			if (mem_to_reg_pipeline_reg_decode) begin
				lw_stall <= 1'b1;
			end
		end

		if (rst)
			lw_stall <= 1'b0;
	end 

	// ---------------------------------------------- forwarding logic ----------------------------------------------

	always @(rs_pipeline_reg_decode or rt_pipeline_reg_decode or
			 write_reg_pipeline_reg_execute or write_reg_pipeline_reg_memory or
			 reg_write_pipeline_reg_execute or reg_write_pipeline_reg_memory or rst) begin

		// forwarding
		if ((rs_pipeline_reg_decode != 0) &&
		    (rs_pipeline_reg_decode == write_reg_pipeline_reg_execute) &&
			reg_write_pipeline_reg_execute) begin
			ForwardAE <= 2'b10;
		end
		else if ((rs_pipeline_reg_decode != 0) &&
				 (rs_pipeline_reg_decode == write_reg_pipeline_reg_memory) &&
				 reg_write_pipeline_reg_memory) begin
			ForwardAE <= 2'b01;
		end
		else begin
			ForwardAE <= 2'b00;
		end

		// forwarding
		if ((rt_pipeline_reg_decode != 0) &&
			(rt_pipeline_reg_decode == write_reg_pipeline_reg_execute) &&
			reg_write_pipeline_reg_execute) begin
			ForwardBE <= 2'b10;
		end
		else if ((rt_pipeline_reg_decode != 0) &&
				 (rt_pipeline_reg_decode == write_reg_pipeline_reg_memory) &&
				 reg_write_pipeline_reg_memory) begin
			ForwardBE <= 2'b01;
		end
		else begin
			ForwardBE <= 2'b00;
		end

		if (rst) begin 
			ForwardBE <= 2'b00;
			ForwardAE <= 2'b00;
		end 

	end 

	assign ForwardAD = (rs != 0) && (rs == write_reg_pipeline_reg_execute) && reg_write_pipeline_reg_execute;
	assign ForwardBD = (rt != 0) && (rt == write_reg_pipeline_reg_execute) && reg_write_pipeline_reg_execute;



// -------------------------------------pipeline-------------------------------------

	always @(posedge clk) begin

		// fetch 
		if (!stall_decode) begin 
			if (taken) begin
				instruction_pipeline_reg_fetch <= 0;
				pc_plus_pipeline_reg_fetch <= 0;
			end
			else begin
			instruction_pipeline_reg_fetch <= idata;
			pc_plus_pipeline_reg_fetch <= pc + 1;
			end
		end 



		// decode
		if (!flush_execute) begin
			rs_pipeline_reg_decode <= rs;
			rt_pipeline_reg_decode <= rt;
			rd_pipeline_reg_decode <= rd;
			shamt_pipeline_reg_decode <= shamt;
			data1_pipeline_reg_decode <= (jal)? pc_plus_pipeline_reg_fetch : data1;
			data2_pipeline_reg_decode <= data2;
			imm_ext_pipeline_reg_decode <= imm_ext;
			alu_op_pipeline_reg_decode <= alu_op;
			write_reg_pipeline_reg_decode <= write_reg;
			reg_write_pipeline_reg_decode <= reg_write;
			mem_to_reg_pipeline_reg_decode <= mem_to_reg;
			mem_write_pipeline_reg_decode <= mem_write;
			alu_src_pipeline_reg_decode <= alu_src;
		end 
		else begin
			rs_pipeline_reg_decode <= 0;
			rt_pipeline_reg_decode <= 0;
			rd_pipeline_reg_decode <= 0;
			data1_pipeline_reg_decode <= 0;
			data2_pipeline_reg_decode <= 0;
			shamt_pipeline_reg_decode <= 0;
			imm_ext_pipeline_reg_decode <= 0;
			alu_op_pipeline_reg_decode <= 0;
			write_reg_pipeline_reg_decode <= 0;
			reg_write_pipeline_reg_decode <= 0;
			mem_to_reg_pipeline_reg_decode <= 0;
			mem_write_pipeline_reg_decode <= 0;
			alu_src_pipeline_reg_decode <= 0;
		end

		// execute
		data2_pipeline_reg_execute <= data2_pipeline_reg_decode;
		write_reg_pipeline_reg_execute <= write_reg_pipeline_reg_decode;
		reg_write_pipeline_reg_execute <= reg_write_pipeline_reg_decode;
		mem_to_reg_pipeline_reg_execute <= mem_to_reg_pipeline_reg_decode;
		mem_write_pipeline_reg_execute <= mem_write_pipeline_reg_decode;
		alu_out_pipeline_reg_execute <= alu_out;

		// memory
		reg_write_pipeline_reg_memory <= reg_write_pipeline_reg_execute;
		mem_to_reg_pipeline_reg_memory <= mem_to_reg_pipeline_reg_execute;
		write_reg_pipeline_reg_memory <= write_reg_pipeline_reg_execute;
		alu_out_pipeline_reg_memory <= alu_out_pipeline_reg_execute;
		readdata_pipeline_reg_memory <= ddin;

		if (rst)
		begin
			// pc reg
			pc <= 0;

			// fetch
			instruction_pipeline_reg_fetch <= 0;
			pc_plus_pipeline_reg_fetch <= 0;

			// decode
			data1_pipeline_reg_decode <= 0;
			data2_pipeline_reg_decode <= 0;
			imm_ext_pipeline_reg_decode <= 0;
			alu_op_pipeline_reg_decode <= 0;
			shamt_pipeline_reg_decode <= 0;
			write_reg_pipeline_reg_decode <= 0;
			reg_write_pipeline_reg_decode <= 0;
			mem_to_reg_pipeline_reg_decode <= 0;
			mem_write_pipeline_reg_decode <= 0;
			alu_src_pipeline_reg_decode <= 0;

			// execute
			data2_pipeline_reg_execute <= 0;
			write_reg_pipeline_reg_execute <= 0;
			reg_write_pipeline_reg_execute <= 0;
			mem_to_reg_pipeline_reg_execute <= 0;
			mem_write_pipeline_reg_execute <= 0;
			alu_out_pipeline_reg_execute <= 0;

			// memory
			reg_write_pipeline_reg_memory <= 0;
			mem_to_reg_pipeline_reg_memory <= 0;
			write_reg_pipeline_reg_memory <= 0;
			alu_out_pipeline_reg_memory <= 0;
			readdata_pipeline_reg_memory <= 0;
		end
	end


	// ---------------------------------------- Fetch ----------------------------------------

	always @(posedge clk, posedge rst)
	begin
		if(rst)
			pc <= 0;
		else if (!stall_fetch)
			pc <= pc_next;
	end

	// Fetch
	assign iaddr = pc;

	// ---------------------------------------- Decode ----------------------------------------
	decoder decoder1(
		instruction_pipeline_reg_fetch,
		opcode,
		funct,
		rs,
		rt,
		rd,
		imm,
		address,
		shamt
	);

	// controler
	controller controller(
		.opcode(opcode),
		.funct(funct),
		.branch(branch),
		.jump(jump),
		.alu_op(alu_op),
		.mem_to_reg(mem_to_reg),
		.mem_write(mem_write),
		.reg_dst(reg_dst), 
		.reg_write(reg_write),
		.alu_src(alu_src),
		.is_eq(is_eq),
		.jmp_src(jmp_src),
		.jal(jal)
	);

	always @(jal or reg_dst or rd or rt)begin
		if (jal)begin
			write_reg = 5'b11111;
		end
		else if (reg_dst)begin
			write_reg = rd;
		end
		else begin
			write_reg = rt;
		end
	end 

	// register file
	regfile regfile (
	.clk  (clk         ),
	.write(reg_write_pipeline_reg_memory),
	.addr1(rs          ),	
	.addr2(rt          ),
	.dest (write_reg_pipeline_reg_memory), 
	.wdata(result      ),
	.data1(data1	   ),
	.data2(data2	   )
	);


	assign real_data1 = (ForwardAD)? alu_out_pipeline_reg_execute : data1;
	assign real_data2 = (ForwardBD)? alu_out_pipeline_reg_execute : data2;

	always @(jump or branch or pc or imm_ext or address or real_data2 or
	 		 pc_plus_pipeline_reg_fetch or is_eq or jmp_src or rst or real_data1)
	begin

		taken = 1'b1;

		if(jump) begin
			if (jmp_src)
				pc_next = real_data1;
			else
				pc_next = {pc_plus_pipeline_reg_fetch[31:13], address[12:0]};
		end else if(branch && ((is_eq && real_data1 == real_data2) || (!is_eq && real_data1 != real_data2))) begin 
				pc_next = pc_plus_pipeline_reg_fetch + imm_ext;
		end 
		else begin
			pc_next = pc + 1;
			taken = 1'b0;
		end 

		if(rst)
			taken = 1'b0;

	end


	//extender
	extender extender (
		.imm(imm),
		.imm_ext(imm_ext)
	);
	// ---------------------------------------- Execute ----------------------------------------
	// setting values
	wire [31:0] val1, val2;
	wire [4:0] shamtE;

	assign shamtE = shamt_pipeline_reg_decode;
	assign val1 = (ForwardAE[1])? alu_out_pipeline_reg_execute : (ForwardAE[0])? result : data1_pipeline_reg_decode;
	assign val2 = (ForwardBE[1])? alu_out_pipeline_reg_execute : (ForwardBE[0])? result : data2_pipeline_reg_decode;
	
	assign src_a = val1;
	assign src_b = alu_src_pipeline_reg_decode ? imm_ext_pipeline_reg_decode : val2;

	assign alucontrol = alu_op_pipeline_reg_decode;


	//alu
	alu alu (
		.val1     (src_a     ),
		.val2     (src_b     ),
		.opration (alucontrol),
		.zero     (zero      ),
		.aluOut   (alu_out   ),
		.shamt	  (shamtE    )
	);
	// ---------------------------------------- Memory ----------------------------------------
	// data memory
	assign daddr = alu_out_pipeline_reg_execute; 					  			//ina ro nnveshtam!
	assign ddout = data2_pipeline_reg_execute;									//ina ro nnveshtam!
	assign dwr   = mem_write_pipeline_reg_execute;

	// ---------------------------------------- Write Back ----------------------------------------
	// write back
	assign result = mem_to_reg_pipeline_reg_memory ? readdata_pipeline_reg_memory : alu_out_pipeline_reg_memory;



endmodule 