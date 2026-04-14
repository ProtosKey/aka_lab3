    .data

input: .word 0x80
output: .word 0x84
stack: .word 0x200

int_size: .word 0xC
max_size: .word 0x21
max_int: .word 0xA
integer: .word 0x60

buffer: .word 0x10
result: .word 0x100

.org 0x300

    .text

_start:
    movea.l stack, A7
    movea.l (A7), A7

    link A6, -8
    movea.l input, A0
    move.l (A0), -4(A6)
    movea.l buffer, A0
    move.l (A0), -8(A6)

    jsr read_line
    unlk A6
    cmp.b -1, D0
    beq error_result

    link A6, -8
    movea.l buffer, A0
    move.l (A0), -4(A6)
    movea.l result, A0
    move.l (A0), -8(A6)
    jsr format_string
    unlk A6
    cmp.b -1, D0
    beq error_result

    link A6, -4
    movea.l result, A0
    move.l (A0), -4(A6)
    jsr write_all
    unlk A6
    cmp.b -1, D0
    beq error_result
    jmp end


read_integer:
    link A6, -24
    move.l D1, -4(A6) ; сохраняем
    move.l D2, -8(A6) ; сохраняем
    move.l 0, D2 ; число
    move.l 8(A6), -12(A6) ; указатель на буфер
    move.l 0, -16(A6) ; флаг числа
    move.l 12(A6), -20(A6) ; стоп символ
    move.l -1, -24(A6) ; флаг наличия
while_read_integer:
    movea.l -12(A6), A0 ; читаем символ
    move.b (A0), D1
    cmp.b D1, -20(A6) ; проверяем, не конец ли
    beq end_read_integer ; выходим
    move.l 0, -24(A6) ; число есть
    cmp.b 0x2D, D1 ; отрицательное число
    beq minus_read_integer
    cmp.b 0x30, D1 ; проверяем, что символ цифра
    blt error_read_integer ; не цифра
    cmp.b 0x39, D1 ; проверяем, что символ цифра
    bgt error_read_integer ; не цифра
    sub.b 0x30, D1 ; превращаем в символ
    mul.l 10, D2 ; добавляем символ
    bvs error_read_integer ; переполнение
    cmp.l -1, -16(A6)
    beq add_minus
    add.l D1, D2
    bvs error_read_integer ; переполнение
    jmp next_read_integer
add_minus:
    sub.l D1, D2
    bvs error_read_integer ; переполнение
next_read_integer:
    add.l 1, -12(A6) ; увеличиваем указатель
    jmp while_read_integer
minus_read_integer:
    move.l -1, -16(A6) ; число отрицательное
    jmp next_read_integer
error_read_integer:
    move.b -1, D0
end_read_integer:
    cmp.l 0, -24(A6) ; проверка
    beq good_result_integer
    move.b -1, D0
good_result_integer:
    cmp.l -1, -16(A6) ; проверка числа
    move.l D2, D7 ; значение числа
    move.l -12(A6), D6 ; указатель на окончание
    move.l -4(A6), D1 ; восстанавливаем
    move.l -8(A6), D2 ; восстанавливаем
    unlk A6
    rts


calc_spaces:
    link A6, -12
    move.l D1, -4(A6) ; сохраняем
    move.l D2, -8(A6) ; сохраняем
    move.l 8(A6), -12(A6) ; буфер числа
    move.l 0, D2 ; счетчик символов
while_calc_spaces:
    movea.l -12(A6), A0 ; загружаем символ
    move.b (A0), D1
    cmp.b 0xA, D1 ; проверяем, что не выход
    beq end_calc_spaces
    add.l 1, -12(A6) ; увеличиваем указатель
    add.l 1, D2 ; увеличиваем счетчик
    jmp while_calc_spaces
end_calc_spaces:
    move.l D2, D7 ; возвращаем символы
    move.l -4(A6), D1 ; восстанавливаем
    move.l -8(A6), D2 ; восстанавливаем
    unlk A6
    rts


insert_integer:
    link A6, -28
    move.l D1, -4(A6) ; сохраняем
    move.l D2, -8(A6) ; сохраняем
    move.l 8(A6), -12(A6) ; указатель на ввод
    move.l 12(A6), -16(A6) ; указатель на вывод
    movea.l -12(A6), A0 ; проверяем вид
    move.b (A0), D1
    cmp.b 0x64, D1 ; сравниваем с концом
    beq no_filtering_insert_integer ; без пробелов
    move.l 0x64, -24(A6) ; стоп символ
    move.l -12(A6), -28(A6) ; буфер числа
    jsr read_integer ; читаем число
    cmp.b -1, D0 ; проверяем ошибку
    beq end_format_string ; выходим
    move.l D6, -12(A6) ; загружаем указатель
    move.l D7, D1 ; загружаем само число
    bmi negative_insert_integer
positive_insert_integer:
    jsr just_read_insert_integer
    cmp.b -1, D0 ; проверяем, что не ошибка
    beq end_insert_integer
    link A6, -4 ; для передачи аргумента
    movea.l integer, A0 ; буфер числа
    move.l (A0), -4(A6)
    jsr calc_spaces
    unlk A6
    move.l D7, D2 ; количество символов
    sub.l D2, D1 ; количество пробелов
    jsr while_insert_spaces
    movea.l integer, A0 ; для чтения из буфера
    move.l (A0), -28(A6)
    jsr while_insert_integer
    move.l 0xfcfc, D0
    jmp end_insert_integer
negative_insert_integer:
    mul.l -1, D1
    jsr just_read_insert_integer
    cmp.b -1, D0 ; проверяем, что не ошибка
    beq end_insert_integer
    link A6, -4 ; для передачи аргумента
    movea.l integer, A0 ; буфер числа
    move.l (A0), -4(A6)
    jsr calc_spaces
    unlk A6
    move.l D7, D2 ; количество символов
    sub.l D2, D1 ; количество пробелов
    movea.l integer, A0 ; для чтения из буфера
    move.l (A0), -28(A6)
    move.l D1, D2
    jsr while_insert_integer
    move.l D2, D1
    jsr while_insert_spaces
    move.l 0xfcfc, D0
    jmp end_insert_integer
no_filtering_insert_integer:
    jsr just_read_insert_integer
    cmp.b -1, D0 ; проверяем, что не ошибка
    beq end_insert_integer
    movea.l integer, A0 ; для чтения из буфера
    move.l (A0), -28(A6)
    jsr while_insert_integer
    jmp end_insert_integer
while_insert_integer:
    movea.l -28(A6), A0 ; читаем символ
    move.b (A0), D1
    cmp.b 0xA, D1 ; символ переноса
    beq end_while_insert_integer ; выходим
    movea.l -16(A6), A0 ; сохраняем символ
    move.b D1, (A0)
    add.l 1, -28(A6) ; увеличиваем указатель
    add.l 1, -16(A6) ; увеличиваем указатель
    jmp while_insert_integer
end_while_insert_integer:
    rts
while_insert_spaces:
    cmp.l 0, D1 ; проверяем количество пробелов
    ble end_while_insert_spaces ; выходим
    sub.l 1, D1 ; уменьшаем количество
    movea.l -16(A6), A0 ; сохраняем пробел
    move.b 0x20, (A0)
    add.l 1, -16(A6) ; увеличиваем указатель
    jmp while_insert_spaces
end_while_insert_spaces:
    rts
end_insert_integer:
    move.l -4(A6), D1 ; восстанавливаем
    move.l -8(A6), D2 ; восстанавливаем
    move.l -12(A6), D7 ; возвращаем указатель на ввод
    move.l -16(A6), D6 ; возвращаем указатель на вывод
    unlk A6
    rts


just_read_insert_integer:
    link A6, -8
    movea.l input, A0 ; чтение числа
    move.l (A0), -4(A6)
    movea.l integer, A0 ; запись в буфер
    move.l (A0), -8(A6)
    jsr read_line_integer ; чтение числа
    unlk A6
end_just_read:
    rts


format_string:
    link A6, -20
    move.l D1, -4(A6) ; сохраняем
    move.l 8(A6), -8(A6) ; указатель на результат
    move.l 12(A6), -12(A6) ; указатель на строку
while_format_string:
    movea.l -12(A6), A0
    move.b (A0), D1 ; читаем первый символ
    add.l 1, -12(A6) ; увеличиваем указатель
    cmp.b 0x25, D1 ; форматирование
    bne output_char ; если нет, идем дальше
    ; jmp output_char ; УБРАТЬ ПОТОМ
    move.l -8(A6), -16(A6) ; результат
    move.l -12(A6), -20(A6) ; ввод
    jsr insert_integer ; вставляем строку
    cmp.b -1, D0 ; ошибка
    beq end_format_string ; выходим
    move.l D6, -8(A6) ; сдвигаем указатель
    move.l D7, -12(A6) ; сдвигаем указатель
    add.l 1, -12(A6)
    jmp while_format_string
output_char:
    movea.l -8(A6), A0
    move.b D1, (A0) ; сохраняем символ в результат
    add.l 1, -8(A6) ; увеличиваем указатель
    cmp.b 0xA, D1 ; окончание строки
    beq end_format_string ; выходим
    jmp while_format_string ; повторяем цикл
end_format_string:
    move.l -4(A6), D1 ; восстанавливаем
    unlk A6
    rts


read_line_integer:
    link A6, -32
    move.l D1, -4(A6) ; сохраняем
    move.l D2, -8(A6) ; сохраняем
    move.l 8(A6), -12(A6) ; буфер ввода
    move.l 12(A6), -16(A6) ; ввод данных
    move.l 0, -20(A6) ; счетчик символов
    movea.l max_int, A0 ; максимальный размер
    move.l 1, -24(A6) ; флаг числа
    move.l (A0), D2
while_read_line_integer:
    movea.l -16(A6), A0 ; чтение символа
    move.b (A0), D1
    movea.l -12(A6), A0 ; сохраняем в буфер
    move.b D1, (A0)
    add.l 1, -12(A6) ; увеличиваем
    cmp.b 0xA, D1 ; символ переноса
    beq end_read_line_integer
    move.l 0, -24(A6)
    cmp.b 0x2D, D1 ; отрицательное число
    beq minus_integer
    cmp.b 0x30, D1 ; проверяем, что символ цифра
    blt error_read_line_integer ; не цифра
    cmp.b 0x39, D1 ; проверяем, что символ цифра
    bgt error_read_line_integer ; не цифра
skip_number_check:
    add.l 1, -20(A6) ; увеличиваем счетчик
    cmp.l D2, -20(A6) ; место буфера
    bne while_read_line_integer
    movea.l -12(A6), A0 ; сохраняем в буфер
    move.b 0xA, (A0)
    move.l 0xA, -28(A6) ; символ окончания
    move.l 8(A6), -32(A6) ; буфер для числа
    jsr read_integer
    cmp.b -1, D0
    beq error_read_line_integer
    movea.l -16(A6), A0
    move.l (A0), D1
    cmp.b 0xA, D1
    bne error_read_line_integer
    jmp end_read_line_integer
error_read_line_integer:
    move.b -1, D0 ; ошибка
end_read_line_integer:
    move.l -4(A6), D1 ; восстанавливаем
    move.l -8(A6), D2 ; восстанавливаем
    cmp.l 0, -24(A6)
    beq good_read_line_integer
    move.b -1, D0 ; ошибка
good_read_line_integer:
    unlk A6
    rts
minus_integer:
    add.l 1, D2
    jmp skip_number_check


read_line:
    link A6, -20
    move.l D1, -4(A6) ; сохраняем
    move.l D2, -8(A6) ; сохраняем
    move.l 8(A6), -12(A6) ; буфер ввода
    move.l 12(A6), -16(A6) ; ввод данных
    move.l 0, -20(A6) ; счетчик символов
    movea.l max_size, A0 ; Максимальный размер
    move.l (A0), D2
while_read_line:
    movea.l -16(A6), A0 ; чтение символа
    move.b (A0), D1
    movea.l -12(A6), A0 ; сохраняем в буфер
    move.b D1, (A0)
    add.l 1, -12(A6) ; увеличиваем
    cmp.b 0xA, D1 ; символ переноса
    beq end_read_line
    add.l 1, -20(A6) ; увеличиваем счетчик
    cmp.l D2, -20(A6) ; место буфера
    bne while_read_line
    move.b -1, D0 ; ошибка
end_read_line:
    move.l -4(A6), D1 ; восстанавливаем
    move.l -8(A6), D2 ; восстанавливаем
    unlk A6
    rts


write_all:
    link A6, -12
    move.l D1, -4(A6) ; сохраняем
    move.l 8(A6), -8(A6) ; буфер ввода
    movea.l output, A0
    move.l (A0), -12(A6) ; вывод
while_write_all:
    movea.l -8(A6), A0
    move.b (A0), D1
    cmp.b 0xA, D1
    beq end_write_all
    add.l 1, -8(A6)
    movea.l -12(A6), A0
    move.b D1, (A0)
    jmp while_write_all
end_write_all:
    move.l -4(A6), D1 ; восстанавливаем
    unlk A6
    rts


error_result:
    movea.l output, A0
    movea.l (A0), A0
    move.l -1, (A0)
    jmp end


end:
    halt
