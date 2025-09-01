`ifndef COMMONS_SV
`define COMMONS_SV
`include "spec.sv"
function logic`WORD masked(input`WORD dst,input`WORD src,input`WORD m);
    return (dst&~m) | (src&m);
endfunction
`endif
