`include "commons.sv"
module breg(input wire clk, input wire rst, input wire[3:0] ra, output wire`WORD rval, input wire w, input wire y, input wire[3:0] wa, input wire`WORD wval,input wire`WORD mask);
    assign rval = rfile[ra];

    logic`WORD rfile[15:0];
    
    wire`WORD nval = y?wval:(rfile[wa]^wval);
    wire`WORD write = masked(rfile[wa],nval,mask);
    always @(posedge clk or posedge rst) begin
        if(rst)
            rfile <= '{16{{`BITNESS'h0}}};
        else if(w) begin
            rfile[wa] <= write;
            if(wa<'h8)
                rfile[wa+'h8] <= write;
        end
    end
endmodule
