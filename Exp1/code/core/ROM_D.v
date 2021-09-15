`timescale 1ns / 1ps

module ROM_D(
    input[6:0] a,
    output[31:0] spo
);

    reg[31:0] inst_data[0:127];


    initial	begin
        $readmemh("D:/2021WinterMaterial/Architecture/Computer-Architecture-Lab/Exp1/code/core/rom.hex", inst_data); 
    end

    assign spo = inst_data[a];

endmodule