%include "rdm.asm"
cal BM, 64
ldv D0+5, 8

db 0x80, 0x80, "Hell"
ldv D0+1, ret0
jmp printd0
ret0:
db 0x80, 0x80, "o, w"
ldv D0+1, ret1
jmp printd0
ret1:
db 0x80, 0x80, "orld"
ldv D0+1, ret2
jmp printd0
ret2:
db 0x80, 0x80, "!", 0x0A, 0, 0
ldv D0+1, ret3
jmp printd0
ret3:
ldv U0+2, 2
hlt

printd0:
bitop 0b100
cal B0, 0x00
opr BM+1, B0
ldvm PC, doprint
opr BM+1, BM
opr PC, D0+1
doprint:
opr BM+1, BM

opr U0+3, D0
ldv U0+2, 1

bitop 0b111
rsopr B0, D0
cal B0, D0+5
opr D0, B0
ldv PC, printd0
