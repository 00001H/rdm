`include "commons.sv"

module test_mem(input wire`WORD addr, output wire[7:0] read);
    logic[7:0] m[8191:0];
    wire[12:0] real_addr = addr[12:0];
    assign read = m[real_addr];
endmodule
