`include "spec.sv"

module processor(input wire clk, input wire rst, output logic`WORD pc, input wire[15:0] instruction, input wire pin_in`WORD, output logic pin_out`WORD);
    wire`WORD module_reads`PER_RSP;
    wire module_read_mask`PER_RSP;
    wire module_write_mask`PER_RSP;
    wor`WORD read;
    wire`WORD write;
    wire`WORD next_pc = pc+1;
    logic`WORD bm;
    logic`WORD bms;
    /*
    std::uint64_t gen_bits(std::uint8_t x){
        std::uint64_t y = (static_cast<std::uint64_t>(1) << (x&63)) - 1;
        if(x&64){
            return ~y;
        }else{
            return y;
        }
    }
    */
    
    wire i0 = instruction[7];
    wire[6:0] S = instruction[6:0];
    rbswitch read_switch(S,module_read_mask);
    
    wire i1 = instruction[15];
    wire[6:0] D = instruction[14:8];
    rbswitch write_switch(D,module_write_mask);
    
    wire`WORD bmaskfroms = (`BITNESS'b1 << S[5:0])-1;
    wire`WORD calbm = (S[6]?~bmaskfroms:bmaskfroms);
    
    assign module_reads[`SP_PC] = next_pc;
    for(genvar i=0;i<`BITNESS;++i)
        assign module_reads[`SP_EP][i] = pin_in[i];
    
    dreg data(clk,rst,S[4:0],module_reads[`SP_D],module_write_mask[`SP_D],D[4:0],write);
    areg arith(clk,rst,S[3:0],module_reads[`SP_A],module_write_mask[`SP_A],i1,D[3:0],write);
    breg bitwise(clk,rst,S[3:0],module_reads[`SP_B],module_write_mask[`SP_B],i1,D[3:0],write);
    
    for(genvar i=0;i<`NRSPACES;++i)
        assign read = {`BITNESS{{module_read_mask[i]}}}&module_reads[i];
    
    assign write = ((!i0)&&i1&&(S==D))?0:((module_write_mask[`SP_BM]||module_write_mask[`SP_BMS])?read:(read&bms));

    always @(posedge clk) begin
        if(module_write_mask[`SP_PC])
            pc <= write;
        else
            pc <= next_pc;
        if(module_write_mask[`SP_EP]) begin
            for(integer i=0;i<`BITNESS;++i)
                pin_out[i] <= write[i];
        end
        if(module_write_mask[`SP_BM]) begin
            bm <= i0?calbm:write;
            bms <= i0?calbm:write;
            // $display("Writing to bm. X = %d, Y = %d and the new value is %d.",i0,i1,i0?calbm:write);
        end
        else bms <= (module_write_mask[`SP_BMS] ? (i0?calbm:write) : bm);
    end
endmodule
