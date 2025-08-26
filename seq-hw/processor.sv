`include "spec.sv"

module processor(input clk, input rst, output reg`WORD pc, input[15:0] instruction, input pin_in`WORD, output reg pin_out`WORD);
    wire`WORD module_reads`PER_RSP;
    wire module_read_mask`PER_RSP;
    wire module_write_mask`PER_RSP;
    wor`WORD read;
    wire`WORD write;
    wire`WORD next_pc = pc+1;
    
    wire i0 = instruction[7];
    wire[6:0] S = instruction[6:0];
    rbswitch read_switch(S,module_read_mask);
    
    wire i1 = instruction[15];
    wire[6:0] D = instruction[14:8];
    rbswitch write_switch(D,module_write_mask);
    
    assign module_reads[7] = next_pc;
    for(genvar i=0;i<`BITNESS;++i)
        assign module_reads[13][i] = pin_in[i];
    
    dreg data(clk,rst,S[4:0],module_reads[0],module_write_mask[0],D[4:0],write);
    areg arith(clk,rst,S[3:0],module_reads[1],module_write_mask[1],i1,D[3:0],write);
    breg bitwise(clk,rst,S[3:0],module_reads[2],module_write_mask[2],i1,D[3:0],write);
    
    for(genvar i=0;i<`NRSPACES;++i)
        assign read = {`BITNESS{{module_read_mask[i]}}}&module_reads[i];
    
    assign write = ((!i0)&&i1&&(S==D))?0:read;

    always @(posedge clk) begin
        if(module_write_mask[7])
            pc <= write;
        else
            pc <= next_pc;
        if(module_write_mask[13]) begin
            for(integer i=0;i<`BITNESS;++i)
                pin_out[i] <= write[i];
        end
    end
endmodule
