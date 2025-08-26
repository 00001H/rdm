`include "spec.sv"
module dreg(input clk, input rst, input[4:0] ra, output`WORD rval, input w, input[4:0] wa, input`WORD wval);
    assign rval = rfile[ra];

    reg`WORD rfile[31:0];
    
    always @(posedge clk or posedge rst) begin
        if(rst)
            rfile <= '{32{{`BITNESS'h0}}};
        else if(w) begin
            rfile[wa] <= wval;
            if(wa<'h10)
                rfile[wa+'h10] <= wval;
        end
    end
endmodule
