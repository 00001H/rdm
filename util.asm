%include "rdm.asm"
%macro call 1
ldv FC, %1
%endmacro
%macro ret 0
opr PC, FC
%endmacro
