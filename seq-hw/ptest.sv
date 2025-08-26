`include "spec.sv"

module ptest();
    reg clk;
    reg rst;
    reg[15:0] mem[1023:0];
    reg pin_in`WORD;
    reg pin_out`WORD;
    wire`WORD pc;
    wire[15:0] ins = mem[pc[9:0]];
    
    processor proc(clk,rst,pc,ins,pin_in,pin_out);
    
    reg n_File_ID;
    initial begin
        pin_in = '{`BITNESS{{1'h0}}};
        pin_in[0] = 1;
        
        mem = '{1024{{16'h0}}};
        mem[0] = 'h206F;
        mem[1] = 'h206F;
        mem[2] = 'h6F20;
        
        clk = 0;
        rst = 1;
        #5;
        rst = 0;
        forever begin
            clk = 0;
            $display("PC = %d",pc);
            #10;
            clk = 1;
            #10;
            if(pin_out[1]) break;
        end
    end
endmodule
