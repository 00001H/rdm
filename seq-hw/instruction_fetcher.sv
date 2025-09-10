`include "commons.sv"

module instruction_fetcher(input wire`WORD pc,input wire clk, input wire rst, output wire`WORD fetch_addr, input wire[7:0] m_read, output wire ready, output wire[15:0] ins, output wire[31:0] imm);
    logic`WORD load_pc;
    wire`WORD next_pc = load_pc+2;
    logic[2:0] load_time = 0;
    logic[7:0] insv[5:0];

    always @(posedge clk or posedge rst) begin
        $strobe("Cached instruction %d+:%d (expect: %d), head %d %d",load_pc[5:0],load_time,next_pc[5:0],insv[1],insv[0]);
        if(rst || (pc != load_pc && pc != next_pc)) begin
            load_pc <= pc;
            load_time <= 0;
            insv <= '{6{{8'b0}}};
        end else if(!ready) begin
            load_time <= load_time+1;
            $display("Reading into %d, byte %d",load_time,m_read);
            insv[load_time] <= m_read;
        end else if(pc != load_pc) begin
            $display("Jump.");
            load_pc <= pc;
            insv <= {8'b0,m_read,insv[5:2]};
            load_time <= 5;
        end
    end
    
    assign fetch_addr = load_pc+{61'b0,load_time};
    assign ready = (load_time == 6);
    assign ins = {insv[1],insv[0]};
    assign imm = {insv[5],insv[4],insv[3],insv[2]};
endmodule
