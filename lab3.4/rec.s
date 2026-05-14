    .data
    .org 0x800

input: .word 0x80
output: .word 0x84

    .text

_start:
    addi sp, zero, 0x800
    lui t0, %hi(input)
    addi t0, t0, %lo(input)
    lw t0, 0(t0)
    mv a0, zero
    lw a1, 0(t0)
    jal ra, calculate_result
    j end


calculate_result:
    addi sp, sp, -4
    sw ra, 0(sp)
    bgt a1, zero, next_iteration
    addi t0, zero, -1
    ble a1, t0, error_iteration
    j end_iteration
next_iteration:
    addi t0, zero, 2
    rem t1, a1, t0
    beqz t1, skip_iteration
    add a0, a0, a1
skip_iteration:
    addi a1, a1, -1
    jal ra, calculate_result
    addi t0, zero, -1
    ble a0, t0, error_iteration
    j end_iteration
error_iteration:
    addi a0, zero, -1
end_iteration:
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra


end:
    lui t0, %hi(output)
    addi t0, t0, %lo(output)
    lw t0, 0(t0)
    sw a0, 0(t0)
    halt
