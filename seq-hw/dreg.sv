`include "spec.sv"
module dreg(input wire clk, input wire rst, input wire[4:0] ra, output wire`WORD rval, input wire w, input wire[4:0] wa, input wire`WORD wval);
    assign rval = rfile[ra];

    logic`WORD rfile[31:0];
    
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
