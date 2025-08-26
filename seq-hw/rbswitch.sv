`include "spec.sv"
module rbswitch(input[6:0] r,output space`PER_RSP);
    assign space = {r=='h6F,r=='h6E,r=='h6D,r=='h6C,r=='h6B,6=='h6A,r=='h69,r=='h68,r>='h60 && r<'h68,r>='h50 && r<'h60,r>='h40 && r<'h50,r>='h30 && r<'h40,r>='h20 && r<'h30,r<'h20};
endmodule
