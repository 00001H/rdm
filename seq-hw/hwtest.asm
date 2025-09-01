%include "rdm.asm"
cal BM, 64
cal BMS, 1
opr D0, BMS
opr A0, D0
opr A0, D0
cal BMS, 3
opr D0, BMS
opr A0, D0
cal BMS, 6
opr D0, BMS
opr A0, D0
opr A0, A0
opr A0, A0
cal BMS, 1
opr A0, BMS
opr EP, A0
opr EP, BM
