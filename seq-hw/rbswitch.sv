`include "spec.sv"
module rbswitch(input[6:0] r,output space`PER_RSP);
    assign space = {r=='h6F,r=='h69,r<32};
endmodule
