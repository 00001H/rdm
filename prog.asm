%include "rdm.asm"
%include "util.asm"
cal BM, 64
main:
ldv D0+4, puts_check
call puts

ldv D0+4, data_check
call puts
ldv A0+4, 400
opr A0+4, A0+4

opr D0+4, A0+4
call printnum

ldv D0+4, comma
call puts
ldv B0+4, 0b1000100000
ldv B0+5, 0b1100000000
opr B0+4, B0+5
opr D0+4, B0+4
call printnum
ldv D0+4, comma
call puts
ldv D0, 0b1100100000
zero D0S
ldv BMS, 0b0011011111
opr D0, D0S
opr D0+4, D0
call printnum
ldv D0+4, endl
call puts

syscallv 4 ; exit

puts_check:
db "puts check passed", 0x0A, 0, "this should not be printed!!!!", 0x0A, 0
data_check:
db "the following numbers should all be 800: ", 0
comma:
db ", ", 0
endl:
db `\n`, 0

puts:
bitop 0b100
zero D0+15
opr D0+31, D0+15 ; dc = 1
rsopr A0+4, D0+4 ; a0 = data
_puts_loop:
opr P0+10, A0+4
cal BMS, 8
opr U0S+3, M0+10
cal B0+4, U0S+3
opr BMS, B0+4
jcc _puts_doprint
ret
_puts_doprint:
opr U0S+2, DC ; putchar(*a0)
syscallv 2 ; flush
opr A0+4, DC ; ++a0
jmp _puts_loop


printnum: ; d4 [num]
ariop 0b011
bitop 0b100

ldv A0+5, scratch ; a5 [index (+scratch)]
ldv D0+5, 10 ; d5 [$10]
ldv D0+6, 1 ; d6 [$1]
opr P0+4, A0+5
ldv M0+4, 255
opr A0+5, D0+6
_printnum_modloop:
rsopr A0+4, D0+5 ; a4 = d5 [$10]
caly A0+4, D0+4 ; a4 [quotient], d4 [ones] = divmod(d4 [num], a4 [$10])
opr P0+10, A0+5 ; $ind =  a5 [index]
cal BMS, 8
opr M0+10, D0+4 ; scratch[$ind] = d4 [ones]
cal B0+4, A0+4
opr BMS, B0+4
jcc _printnum_cont
jmp _printnum
_printnum_cont:
opr D0+4, A0+4 ; d4 = a4 [quotient]
opr A0+5, D0+6 ; ++a5 [index]
jmp _printnum_modloop

_printnum:
ldv D0+5, 47; d5 ['0'-1]
ldv D0+4, -1; d4 [-1]
_printnum_printloop:
opr P0+10, A0+5 ; $ind = a5 [index]
cal BMS, 8
rsopr A0+4, M0+10 ; a4 [digit] =<8> scratch[$ind]
cal BMS, 8
opr A0+4, D0+6 ; ++a4
cal B0+4, A0+4
opr BMS, B0+4
jcc _printnum_cont2
ret
_printnum_cont2:
opr A0+4, D0+5 ; a4 [digit] += '0'
opr U0S+3, A0+4
syscallv 1; putchar(a4 [digit])
syscallv 2; flush
opr A0+5, D0+4 ; --index
jmp _printnum_printloop

scratch:
