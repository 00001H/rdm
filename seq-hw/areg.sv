`include "spec.sv"
module areg(input clk, input rst, input[3:0] ra, output`WORD rval, input w, input y, input[3:0] wa, input`WORD wval);
    assign rval = rfile[ra];

    reg`WORD rfile[15:0];
    
    wire`WORD nval = y?wval:(rfile[wa]+wval);
    always @(posedge clk or posedge rst) begin
        if(rst)
            rfile <= '{16{{`BITNESS'h0}}};
        else if(w) begin
            rfile[wa] <= nval;
            if(wa<'h8)
                rfile[wa+'h8] <= nval;
        end
    end
endmodule
