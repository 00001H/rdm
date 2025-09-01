`include "commons.sv"
module rbswitch(input wire[6:0] r,output wire space`PER_RSP);
    assign space = {
        r=='h6F,                              // ep
        r=='h6E,                              // fc
        r=='h6D,                              // lc
        r=='h6C,                              // lp
        r=='h6B,                              // bms
        r=='h6A,                              // bm
        r=='h69,                              // pc
        r=='h68,                              // dc
        r>='h64 && r<'h68, r>='h60 && r<'h64, // u
        r>='h50 && r<'h60,                    // m
        r>='h40 && r<'h50,                    // p
        r>='h38 && r<'h40, r>='h30 && r<'h38, // b
        r>='h28 && r<'h30, r>='h20 && r<'h28, // a
        r>='h10 && r<'h20, r<'h10             // d
    };
endmodule
