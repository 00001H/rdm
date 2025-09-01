`include "commons.sv"
module dreg(input wire clk, input wire rst, input wire[4:0] ra, output wire`WORD rval, input wire w, input wire[4:0] wa, input wire`WORD wval,input wire`WORD mask);
    assign rval = rfile[ra];

    logic`WORD rfile[31:0];

    wire`WORD write = masked(rfile[wa],wval,mask);
    
    always @(posedge clk or posedge rst) begin
        if(rst)
            rfile <= '{32{{`BITNESS'h0}}};
        else if(w) begin
            rfile[wa] <= write;
            if(wa<'h10)
                rfile[wa+'h10] <= write;
        end
    end
endmodule
