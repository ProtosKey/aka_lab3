    .text
    .org 0x100

_start:
    addi s4, zero, 0x80     / addi s5, zero, 0x84  / nop           / nop
    addi s6, zero, 3        / addi s7, zero, 2      / nop           / nop
    addi sp, zero, 0x800    / nop                   / nop           / jal ra, run_filter
    nop                     / nop                   / nop           / halt


run_filter:
    addi sp, sp, -4         / nop                   / nop           / nop
    nop                     / nop                   / sw ra, 0(sp)  / nop
    nop                     / nop                   / lw s1, 0(s4)  / nop
    addi s2, zero, 0        / addi s3, zero, 0      / nop           / blt s1, zero, rf_error
    nop                     / nop                   / nop           / beqz s1, rf_end

rf_loop:
    addi s1, s1, -1         / nop                   / nop           / jal ra, compute_y
    nop                     / nop                   / nop           / bnez s1, rf_loop

rf_end:
    nop                     / nop                   / lw ra, 0(sp)  / nop
    addi sp, sp, 4          / nop                   / nop           / jr ra

rf_error:
    addi t0, zero, -1       / nop                   / nop           / nop
    nop                     / nop                   / sw t0, 0(s5)  / nop
    nop                     / nop                   / lw ra, 0(sp)  / nop
    addi sp, sp, 4          / nop                   / nop           / jr ra

compute_y:
    nop                     / mul t2, s7, s2        / lw t0, 0(s4)  / nop
    mul t1, s6, t0          / add t3, t2, s3        / nop           / nop
    add t1, t1, t3          / nop                   / nop           / nop
    mv  s3, s2              / mv  s2, t0            / sw t1, 0(s5)  / jr ra
