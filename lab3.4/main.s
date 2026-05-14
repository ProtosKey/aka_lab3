    .data
    .org 0x100

input: .word 0x80
output: .word 0x84
overflow: .word 0xCCCCCCCC

    .text

_start:
    addi sp, zero, 0x60
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
    ble a1, zero, error_result
    addi t0, zero, 2
    rem t1, a1, t0
    beqz t1, skip_sub
    addi t0, a1, 1
    j start_calculate
skip_sub:
    mv t0, a1
start_calculate:
    mv t1, t0
    addi t2, zero, 2
    div t0, t0, t2
    rem t3, t0, t2
    beqz t3, first_div
    mul t0, t0, t1
    div t0, t0, t2
    j end_div
first_div:
    div t0, t0, t2
    mul t0, t0, t1
end_div:
    ble t0, zero, overflow_result
    mv a0, t0
    j end_calculate
overflow_result:
    lui t1, %hi(overflow)
    addi t1, t1, %lo(overflow)
    lw a0, 0(t1)
    j end_calculate
error_result:
    addi t0, zero, -1
    mv a0, t0
end_calculate:
    lw ra, 0(sp)
    addi sp, sp, 4
    jr ra


end:
    lui t0, %hi(output)
    addi t0, t0, %lo(output)
    lw t0, 0(t0)
    sw a0, 0(t0)
    halt
