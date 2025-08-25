`include "spec.sv"
module dreg(input clk, input[4:0] ra, output`WORD rval, input w, input[4:0] wa, input`WORD wval);
    assign rval = rfile[ra];

    reg`WORD rfile[31:0];
    
    always @(posedge clk) begin
        if(w) begin
            rfile[wa] <= wval;
            if(wa<'h10)
                rfile[wa+'h10] <= wval;
        end
    end
endmodule
