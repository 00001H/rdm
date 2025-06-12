%ifndef HAS_RDM
%define HAS_RDM
D0 equ 0x00
D0S equ 0x10
A0 equ 0x20
A0S equ 0x28
B0 equ 0x30
B0S equ 0x38
P0 equ 0x40
M0 equ 0x50
U0 equ 0x60
U0S equ 0x64
DC equ 0x68
PC equ 0x69
BM equ 0x6A
BMS equ 0x6B
LP equ 0x6C
LC equ 0x6D
FC equ 0x6E
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
%macro caly 2
db (%2+0x80), (%1+0x80)
%endmacro
%macro ldv 2
caly %1, %1
dd %2
%endmacro
%macro ldvm 2
cal %1, %1
dd %2
%endmacro
%macro hlt 0
ldv U0+5, 1
%endmacro
%macro jmp 1
ldv PC, %1
%endmacro
%macro jcc 1
ldvm PC, %1
%endmacro
%macro ariop 1
cal U0, %1
%endmacro
%macro bitop 1
caly U0, %1
%endmacro
%macro syscallv 1
ldv U0S+2, %1
%endmacro
%endif
