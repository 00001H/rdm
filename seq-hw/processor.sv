`include "commons.sv"

module processor(input wire clk, input wire rst, output logic`WORD pc, input wire[15:0] instruction, input wire pin_in`WORD, output logic pin_out`WORD, input wire[31:0] imm);
    wire`WORD module_reads`PER_RSP;
    wire module_read_mask`PER_RSP;
    wire module_write_mask`PER_RSP;
    wor`WORD read;
    wire`WORD write;
    wire`WORD next_pc = pc+1;
    logic`WORD bm;
    logic`WORD bms;
    logic`WORD lp;
    logic`WORD lc;
    
    wire i0 = instruction[7];
    wire[6:0] S = instruction[6:0];
    rbswitch read_switch(S,module_read_mask);
    
    wire i1 = instruction[15];
    wire[6:0] D = instruction[14:8];
    rbswitch write_switch(D,module_write_mask);
    
    wire zreg = (!i0)&&i1&&(S==D);
    wire`WORD wmask = zreg?`BITNESS'b1:bms;
    
    wire`WORD bmaskfroms = (`BITNESS'b1 << S[5:0])-1;
    wire`WORD calbm = (S[6]?~bmaskfroms:bmaskfroms);
    wire`WORD new_bm = i0?calbm:write;
    
    assign module_reads[`SP_PC] = next_pc;
    assign module_reads[`SP_BM] = bm;
    assign module_reads[`SP_BMS] = bms;
    assign module_reads[`SP_LP] = lp;
    assign module_reads[`SP_LC] = lc;
    for(genvar i=0;i<`BITNESS;++i)
        assign module_reads[`SP_EP][i] = pin_in[i];
        
    wire`WORD writemask = (module_write_mask[`SP_BM]||module_write_mask[`SP_BMS])?`BITNESS'b1:bms;
    
    dreg data(clk,rst,S[4:0],module_reads[`SP_D],module_write_mask[`SP_D],D[4:0],write,writemask);
    areg arith(clk,rst,S[3:0],module_reads[`SP_A],module_write_mask[`SP_A],i1,D[3:0],write,writemask);
    breg bitwise(clk,rst,S[3:0],module_reads[`SP_B],module_write_mask[`SP_B],i1,D[3:0],write,writemask);
    
    for(genvar i=0;i<`NRSPACES;++i)
        assign read = {`BITNESS{{module_read_mask[i]}}}&module_reads[i];
    
    assign write = zreg?0:read;

    always @(posedge clk or posedge rst) begin
        if(rst) begin
            pc <= 0;
            bm <= 0;
            bms <= 0;
            lp <= 0;
            lc <= 0;
        end else begin
            if(module_write_mask[`SP_LC] && write != 0)
                pc <= lp;
            else if(module_write_mask[`SP_PC])
                pc <= masked(pc,write,wmask);
            else
                pc <= next_pc;
            if(module_write_mask[`SP_EP]) begin
                for(integer i=0;i<`BITNESS;++i)
                    if(wmask[i])
                        pin_out[i] <= write[i];
            end
            if(module_write_mask[`SP_BM]) begin
                bm <= new_bm;
                bms <= new_bm;
                // $display("Writing to bm. X = %d, Y = %d and the new value is %d.",i0,i1,new_bm);
            end else if(module_write_mask[`SP_BMS]) begin
                bms <= new_bm;
                // $display("Writing to bms. X = %d, Y = %d and the new value is %d.",i0,i1,new_bm);
            end else
                bms <= bm;
            if(module_write_mask[`SP_LP])
                lp <= masked(lp,write,wmask);
            if(module_write_mask[`SP_LC])
                lc <= masked(lc,i1 ? lc + write : write,wmask);
        end
    end
endmodule
