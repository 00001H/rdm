D0 equ 0x00
A0 equ 0x30
B0 equ 0x40
P0 equ 0x50
M0 equ 0x60
U0 equ 0x70
DC equ 0x78
PC equ 0x79
BM equ 0x7A
LP equ 0x7C
LC equ 0x7D
%macro opr 2
db %2, %1
%endmacro
%macro rsopr 2
db %2, (%1+0x80)
%endmacro
%macro zero 1
rsopr %1, %1
%endmacro
%macro cal 2
db (%2+0x80), %1
%endmacro
%macro ldv 2
db (%1+0x80), (%1+0x80)
dd %2
%endmacro
%macro ldvm 2
db (%1+0x80), %1
dd %2
%endmacro
%macro hlt 0
ldv U0+5, 1
%endmacro
%macro jmp 1
ldv PC, %1
%endmacro
%macro bitop 1
ldv U0, (%1)<<3
%endmacro
