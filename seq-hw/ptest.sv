`include "commons.sv"

module ptest();
    logic clk;
    logic rst;
    logic[15:0] mem[0:1023];
    logic pin_in`WORD;
    logic pin_out`WORD;
    wire`WORD pc;
    wire[15:0] ins = mem[pc[9:0]];
    
    processor proc(clk,rst,pc,ins,pin_in,pin_out);
    
    logic[31:0] test_prog_handle;
    initial begin
        pin_in = '{`BITNESS{{1'h0}}};
        pin_in[0] = 1;
        
        test_prog_handle = $fopen("seq-hw/hwtest.bin","rb");
        $fread(mem,test_prog_handle,0,1024); // reads in big endian
        for(integer i=0;i<1024;++i)
            {mem[i][7:0],mem[i][15:8]} = {mem[i][15:8],mem[i][7:0]}; // byteswap
        
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
            if(pc > 15) begin
                $display("Execution fell off the end of program :(");
                $display("terminating");
                break;
            end
            $display("pins: %d %d %d %d",pin_out[0],pin_out[1],pin_out[2],pin_out[3]);
            if(pin_out[1]) break;
        end
    end
endmodule
