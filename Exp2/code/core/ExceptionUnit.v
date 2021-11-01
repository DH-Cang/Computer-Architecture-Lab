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

    output reg_FD_flush, reg_DE_flush, reg_EM_flush, reg_MW_flush, 
    output RegWrite_cancel
);


    //According to the diagram, design the Exception Unit
    parameter idle = 0;
    parameter mepc = 1;
    parameter mcause = 2;
    reg[1:0] state; 
    reg[31:0] _mepc; 
    reg[5:0] _cause; 
    wire[31:0] mstatus;
    
    assign exception = illegal_inst | l_access_fault | s_access_fault; 
    assign _interrupt = (interrupt & mstatus[3]); 
    // PC
    assign PC_redirect = ((state == mepc || mret) && ~rst) ? csr_r_data_out : 0; 
    assign redirect_mux = ((state == mepc || mret) && ~rst) ? 1 : 0; 


    wire[11:0] csr_raddr =  {12{state == idle && mret}} & 12'h341 | //mepc read
                            {12{state == mepc}} & 12'h305 | // mtvec read
                            {12{state == idle && !mret}} & csr_rw_addr_in;  // normal

    wire[11:0] csr_waddr =  {12{state == idle && (exception | ecall_m | mret)}} & 12'h300           |    // write mstatus
                            {12{state == mepc}} & 12'h341                                           |       // write mepc
                            {12{state == mcause}} & 12'h342                                         |       // write mcause
                            {12{state == idle && !(exception | ecall_m | mret)}} & csr_rw_addr_in   ;   // normal

    wire[31:0] csr_wdata =  {32{state == idle && (exception | ecall_m)}} & {mstatus[31:8], mstatus[3], mstatus[6:4], 1'b0, mstatus[2:0]} |
                            {32{state == idle && (mret)}} & {mstatus[31:8], 1'b1, mstatus[6:4], mstatus[7], mstatus[2:0]}           |
                            {32{state == mepc}} & _mepc |
                            {32{state == mcause}} & _cause |
                            {32{state == idle && !(exception | ecall_m | mret)}} & (csr_w_imm_mux ? {27'b0, csr_w_data_imm} : csr_w_data_reg)    ;

    wire csr_w = {(state == idle && (exception | ecall_m | mret)) || state == mepc || state == mcause}      | 
                    {state == idle && !(exception | ecall_m | mret)} & csr_rw_in & csr_w_data_imm!=5'b00000 ;

    wire[1:0] csr_wsc = {2{state == idle && !(exception | ecall_m | mret)}} & csr_wsc_mode_in           |
                        {(state == idle && (exception | ecall_m | mret)) || state == mepc || state == mcause};


    assign reg_FD_flush = state == idle & (exception | ecall_m | _interrupt) | state == mepc ? 1 : mret ? 1 : 0; 
    assign reg_DE_flush = state == idle & (exception | ecall_m | _interrupt) | state == mepc ? 1 : mret ? 1 : 0; 
    assign reg_EM_flush = state == idle & (exception | ecall_m | _interrupt) | state == mepc ? 1 : mret ? 1 : 0; 
    assign reg_MW_flush = state == idle & (exception | ecall_m) | state == mepc; 
    assign RegWrite_cancel = state == idle & (exception | ecall_m) | state == mepc; 


    always @(posedge clk or posedge rst) begin
        if(rst)begin
            state <= idle;  
            _mepc <= 0; 
            _cause <= 0; 
        end
        else if(state == idle && (exception | ecall_m | _interrupt)) begin
            state <= mepc; 
            _mepc <= epc_cur; 
            if(ecall_m)
                _cause <= 11;
            else if(illegal_inst)
                _cause <= 2;
            else if (l_access_fault)
                _cause <= 5; 
            else if (s_access_fault)
                _cause <= 7; 
            else if (_interrupt)
                _cause <= 32'h80000000; 
        end
        else if(state == mepc) begin
            state <= mcause; 
            _mepc <= _mepc; 
            _cause <= _cause; 
        end
        else if(state == mcause) begin
            state <= idle; 
            _mepc <= 0; 
            _cause <= _cause; 
        end
        else if(state == idle && mret) begin
            state <= idle; 
            _mepc <= 0; 
            _cause <= _cause; 
        end
        else begin
            state <= idle; 
            _mepc <= 0; 
            _cause <= _cause; 
        end
    end

    CSRRegs csr(.clk(clk),.rst(rst),.csr_w(csr_w),.raddr(csr_raddr),.waddr(csr_waddr),
    .wdata(csr_wdata),.rdata(csr_r_data_out),.mstatus(mstatus),.csr_wsc_mode(csr_wsc));


endmodule