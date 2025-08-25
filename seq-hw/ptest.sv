`include "spec.sv"

module ptest();
    reg clk;
    reg[15:0] mem[1023:0];
    reg pin_in`WORD;
    reg pin_out`WORD;
    wire`WORD pc;
    wire[15:0] ins = mem[pc[9:0]];
    
    processor proc(pc,clk,ins,pin_in,pin_out);
    initial begin
        for(int i=0;i<`BITNESS;++i) begin
            pin_in[i] = 1;
        end
        mem = '{1024{{16'h0}}};
        mem[0] = 'h006F;
        mem[1] = 'h6F00;
        forever begin
            clk = 0;
            $display("PC = %d",pc);
            #10;
            clk = 1;
            #10;
            if(pin_out[0]) break;
        end
    end
endmodule
