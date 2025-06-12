%include "rdm.asm"
cal BM, 64
ldv LP, forever
ldv D0, 1
ldv D0+1, 2
ldv D0+2, 3
forever:
opr U0+6, D0+2
opr U0+6, D0
opr U0+6, D0+1
opr LC, D0
