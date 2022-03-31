addi x1, x0, 0x10
L2:addi x12, x0, 0x10
addi x2, x2, 0x10
add x4, x4, x12 
sd x12, 8(x12)
addi x11, x11, 0x20
sd x2, 16(x12)
beq x12, x2, L2
add x3, x12, x2 
sub x13, x2, x12
jal x8, L3
addi x5, x3, 0x0
add x6, x4, x5
add x7, x6, x5
L3: add x1, x2, x3
ld x8, 8(x12)
ld x9, 16(x12)
add x14, x8, x13
add x10, x8, x9
andi x15, x10, 0x15
and x16, x15, x10
or x17, x15, x16
