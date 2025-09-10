`include "commons.sv"

module ptest();
    logic clk;
    logic rst;
    logic pin_in`WORD;
    logic pin_out`WORD;
    wire`WORD pc;
    
    wire`WORD m_addr;
    wire[7:0] m_write;
    wire[7:0] m_read;
    test_mem memory(m_addr,m_read);
    cpu proc(clk,rst,m_addr,m_read,pin_in,pin_out,pc);
    
    logic[31:0] test_prog_handle;
    logic[31:0] outf_handle;
    initial begin
        force m_write = 0;
        pin_in = '{`BITNESS{{1'h0}}};
        pin_in[0] = 1;
        
        test_prog_handle = $fopen("seq-hw/hwtest.bin","rb");
        outf_handle = $fopen("seq-hw/out.txt","w");
        $fread(memory.m,test_prog_handle,0,1024);
        $fclose(test_prog_handle);
        
        clk = 0;
        rst = 1;
        #5;
        rst = 0;
        forever begin
            $display("Falling edge. PC = %d",pc[5:0]);
            // $display("Memory bus content: %d @ addr %d",m_read,m_addr);
            clk = 0;
            #10;
            // $display("Rising edge. PC = %d",pc);
            clk = 1;
            #10;
            if(pc > 50) begin
                $display("Execution fell off the end of program :(");
                $display("terminating");
                break;
            end
            // $display("pins: %d %d %d %d",pin_out[0],pin_out[1],pin_out[2],pin_out[3]);
            if(pin_out[1]) break;
            if(pin_out[0]) begin
                logic[7:0] pch;
                for(integer i=0;i<8;++i) pch[i] = pin_out[i+2];
                $display("%c",pch);
                $fwrite(outf_handle,"%c",pch);
            end
        end
        $fclose(outf_handle);
    end
endmodule
