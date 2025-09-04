`include "commons.sv"

module cpu(input wire clk, input wire rst, output wire`WORD m_addr, input wire[7:0] m_read, input wire pin_in`WORD, output wire pin_out`WORD,
`ifndef SYNTHESIS
output wire`WORD pc // for debug purposes
`endif
);
`ifdef SYNTHESIS
    wire`WORD pc;
`endif
    wire ready;
    wire[15:0] ins;
    wire[31:0] imm;
    instruction_fetcher fetcher(pc,!clk /* fetch memory on falling edge */,rst,m_addr,m_read,ready,ins,imm);

    wire p_clk = clk && ready;
    processor proc(p_clk,rst,pc,ins,pin_in,pin_out,imm);
endmodule
