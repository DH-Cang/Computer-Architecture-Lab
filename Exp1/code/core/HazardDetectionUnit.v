`timescale 1ps/1ps

module HazardDetectionUnit(
    input clk,
    input Branch_ID, rs1use_ID, rs2use_ID,
    input[1:0] hazard_optype_ID,    // idle
    input[4:0] rd_EXE, rd_MEM, rs1_ID, rs2_ID, rs2_EXE,
    output PC_EN_IF, reg_FD_EN, reg_FD_stall, reg_FD_flush,
        reg_DE_EN, reg_DE_flush, reg_EM_EN, reg_EM_flush, reg_MW_EN,
    output forward_ctrl_ls,
    output[1:0] forward_ctrl_A, forward_ctrl_B
);

    assign PC_EN_IF = 'b1;
    assign reg_FD_EN = 'b1;
    assign reg_EM_EN = 'b1;
    assign reg_DE_EN = 'b1;
    assign reg_MW_EN = 'b1;
            //according to the diagram, design the Hazard Detection Unit
    
    optype == 01 // data hazard
    optype == 10 // load-store
    branch_ID == 1 // control

    assign flush = branch_ID
    assign data_hazard = (optype == 01) & () &
    assign ls_hazard = (optype == 10) & () & 

    // rs1 data hazard
    assign forward_ctrl_A = {2{(hazard_optype_ID==2'b01) & rs1use_ID & rs1_ID!=0 & (rs1_ID==rd_EXE)}} & 2'b01 |  // 1
                            {2{(hazard_optype_ID==2'b01) & rs1use_ID & rs1_ID!=0 & (rs1_ID==rd_MEM)}} & 2'b10 |  // 2
                            {2{(hazard_optype_ID==2'b10) & rs1use_ID & rs1_ID!=0 & (rs1_ID==rd_MEM)}} & 2'b11 ;  // 3

    assign forward_ctrl_B = {2{(hazard_optype_ID==2'b01) & rs2use_ID & rs2_ID!=0 & (rs2_ID==rd_EXE)}} & 2'b01 |  // 1
                            {2{(hazard_optype_ID==2'b01) & rs2use_ID & rs2_ID!=0 & (rs2_ID==rd_MEM)}} & 2'b10 |  // 2
                            {2{(hazard_optype_ID==2'b10) & rs2use_ID & rs2_ID!=0 & (rs2_ID==rd_MEM)}} & 2'b11 ;  // 3
endmodule