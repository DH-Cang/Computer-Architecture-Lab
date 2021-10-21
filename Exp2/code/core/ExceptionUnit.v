`timescale 1ns / 1ps

module ExceptionUnit(
    input clk, rst,
    input csr_rw_in,            // whether a r/w intruction
    input[1:0] csr_wsc_mode_in, // 01: rw  10: rs  11: rc
    input csr_w_imm_mux,        // csr instructions with immediate
    input[11:0] csr_rw_addr_in, // address of the csr
    input[31:0] csr_w_data_reg, // data to write into a csr
    input[4:0] csr_w_data_imm,  // unextended zimm
    output[31:0] csr_r_data_out,// data to write into a register

    input interrupt,
    input illegal_inst,
    input l_access_fault,
    input s_access_fault,
    input ecall_m,

    input mret,

    input[31:0] epc_cur,    // PC of WB
    input[31:0] epc_next,   // next PC that would not be flushed
    output [31:0] PC_redirect,   // PC to fetch in IF
    output redirect_mux,    // select PC for IF

    output reg reg_FD_flush, reg_DE_flush, reg_EM_flush, reg_MW_flush, 
    output reg RegWrite_cancel
);

    reg[11:0] csr_raddr, csr_waddr;
    reg[31:0] csr_wdata;
    reg csr_w;
    reg[1:0] csr_wsc;

    wire[31:0] mstatus;

    CSRRegs csr(.clk(clk),.rst(rst),.csr_w(csr_w),.raddr(csr_raddr),.waddr(csr_waddr),
        .wdata(csr_wdata),.rdata(csr_r_data_out),.mstatus(mstatus),.csr_wsc_mode(csr_wsc));

    //According to the diagram, design the Exception Unit
    parameter idle = 0;
    parameter mepc = 1;
    parameter mcause = 2;
    reg[1:0] state; 
    reg[31:0] _mepc; 
    reg[5:0] _cause; 
    assign exception = illegal_inst | l_access_fault | s_access_fault; 
    // PC
    assign PC_redirect = ((state == mepc || mret) && ~rst) ? csr_r_data_out : 0; 
    assign redirect_mux = ((state == mepc || mret) && ~rst) ? 1 : 0; 
    always @(posedge clk or posedge rst) begin
        if(rst)begin
            state <= idle; 
            reg_FD_flush <= 0;
            reg_DE_flush <= 0;
            reg_EM_flush <= 0;
            reg_MW_flush <= 0;
            RegWrite_cancel <= 0; 
            csr_w <= 0;  
            _mepc <= 0; 
            csr_wdata <= 0; 
            csr_waddr <= 0; 
            csr_raddr <= 0; 
            _cause <= 0; 
            csr_wsc <= 0; 
        end
        else if(state == idle && (exception | ecall_m))begin
            // an exception
            state <= mepc;
            csr_w <= 1;  
            _mepc <= epc_cur;
            // set mstatus
            csr_wdata <= {mstatus[31:8], mstatus[3], mstatus[6:4], 1'b0, mstatus[2:0]}; 
            csr_waddr <= 12'h300; 
            csr_raddr <= 0; 
            if(ecall_m)begin
                _cause <= 11; 
            end
            else if(illegal_inst)begin
                _cause <= 2; 
            end
            else if (l_access_fault)begin
                _cause <= 5; 
            end
            else if (s_access_fault)begin
                _cause <= 7; 
            end
            reg_FD_flush <= 1; 
            reg_DE_flush <= 1; 
            reg_EM_flush <= 1; 
            reg_MW_flush <= 1; 
            RegWrite_cancel <= 1; 
            csr_wsc <= 1; 
        end
        else if(state == mepc)begin
            state <= mcause; 
            csr_w <= 1; 
            _mepc <= _mepc;
            // write mepc
            csr_wdata <= _mepc; 
            csr_waddr <= 12'h341; 
            // read mtvec
            csr_raddr <= 12'h305; 
            // change PC
            /* maybe questions here */ 
            _cause <= _cause; 
            reg_FD_flush <= 0; 
            reg_DE_flush <= 0; 
            reg_EM_flush <= 0; 
            reg_MW_flush <= 0; 
            RegWrite_cancel <= 0; 
            csr_wsc <= 1; 
        end
        else if(state == mcause)begin
            state <= idle; 
            csr_w <= 1; 
            // write mcause
            _mepc <= 0; 
            csr_wdata <= _cause; 
            csr_waddr <= 12'h342; 
            csr_raddr <= 0; 
            reg_FD_flush <= 0; 
            reg_DE_flush <= 0; 
            reg_EM_flush <= 0; 
            reg_MW_flush <= 0;
            RegWrite_cancel <= 0; 
            csr_wsc <= 1; 
        end
        else if(mret)begin
            state <= idle; 
            csr_w <= 1; 
            _mepc <= 0; 
            // write mstatus
            csr_wdata <= {mstatus[31:8], 1'b1, mstatus[6:4], mstatus[7], mstatus[2:0]}; 
            csr_waddr <= 12'h300; 
            // read mepc
            csr_raddr <= 12'h341; 
            /* maybe questions here */ 
            reg_FD_flush <= 0; 
            reg_DE_flush <= 0; 
            reg_EM_flush <= 0; 
            reg_MW_flush <= 0;
            RegWrite_cancel <= 0; 
            csr_wsc <= 1; 
        end
        else begin
            // normal
            state <= idle; 
            csr_w <= csr_rw_in & csr_w_data_imm!=5'b00000; 
            _mepc <= 0; 
            csr_wdata <= csr_w_imm_mux ? csr_w_data_imm : csr_w_data_reg; 
            csr_waddr <= csr_rw_addr_in; 
            csr_raddr <= csr_rw_addr_in; 
            reg_FD_flush <= 0; 
            reg_DE_flush <= 0; 
            reg_EM_flush <= 0; 
            reg_MW_flush <= 0;
            RegWrite_cancel <= 0; 
            csr_wsc <= csr_wsc_mode_in;  
        end
    end

endmodule