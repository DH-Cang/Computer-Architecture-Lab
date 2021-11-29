`timescale 1ns / 1ps

module FU_jump(
	input clk, EN, JALR,
	input[2:0] cmp_ctrl,
	input[31:0] rs1_data, rs2_data, imm, PC,
	output[31:0] PC_jump, PC_wb,
	output cmp_res, finish
);

    reg state;
    assign finish = state == 1'b1;
	initial begin
        state = 0;
    end

	reg JALR_reg;
	reg[2:0] cmp_ctrl_reg;
	reg[31:0] rs1_data_reg, rs2_data_reg, imm_reg, PC_reg;

	//to fill sth.in  
	always@(posedge clk) begin
		if(EN & ~state) begin
			JALR_reg <= JALR;
			cmp_ctrl_reg <= cmp_ctrl;
			rs1_data_reg <= rs1_data;
			rs2_data_reg <= rs2_data;
			imm_reg <= imm;
			PC_reg <= PC;
			state <= 1;
		end 
		else begin
			state <= 0;
		end
	end

	add_32 adder_pc_jump(JALR_reg ? rs1_data_reg : PC_reg, imm_reg, PC_jump);
	add_32 adder_pc_wb(PC_reg, 'd4, PC_wb);
	cmp_32 cmp(rs1_data_reg, rs2_data_reg, cmp_ctrl_reg, cmp_res);



endmodule