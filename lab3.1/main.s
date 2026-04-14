    .data

.org 0x100

input:           .word  0x80               ; Адрес ввода
output:          .word  0x84               ; Адрес вывода

end_line:        .word  0x0                ; Символ окончения строки
next:            .word  0x0A               ; Символ переноса
under:           .word  0x5F               ; Символ нижнего подчеркивания

max_size:        .word 0x20                ; Максимальный размер буфера
buffer_start:    .word 0x0                 ; Указатель на результат
buffer_end:      .word 0x50                ; Указатель на буфер чтения

buffer_ptr:      .word 0x0                 ; Указатель на буфер
result_ptr:      .word 0x0                 ; Указатель на результат
buffer_size:     .word 0x0                 ; Размер буфера

letter:          .word 0x0                 ; Буфер для хранения символа
shift8:          .word 0x8                 ; Сдвиг при заполнении нижним подчеркиванием
shift16:         .word 0x10

overflow:        .word 0xCCCCCCCC          ; Значение при ошибке данных
mask:            .word 0xFF
const_0:         .word 0x0
const_1:         .word 0x1
const_4:         .word 0x4

    .text

_start:
    jmp prepare_result
after_prepare:
    jmp reverse_string_cstr
after_reverse:
    jmp good


prepare_result:
    load buffer_start
    add const_1
    store buffer_ptr
while_prepare:
    load under
    store_ind buffer_ptr
    load buffer_ptr
    add const_1
    store buffer_ptr
    sub max_size
    beqz after_prepare
    jmp while_prepare


read_line:
    load buffer_end
    store buffer_ptr
while_read:
    load input
    load_acc
    and mask
    store letter
    sub next
    beqz after_read_line
    load letter
    store_ind buffer_ptr
    load buffer_ptr
    add const_1
    store buffer_ptr
    sub buffer_end
    sub max_size
    beqz default_s
    jmp while_read


reverse_string_cstr:
    jmp read_line
after_read_line:
    load buffer_end
    store buffer_ptr
prepare_reverse:
    load buffer_ptr
    load_acc
    and mask
    beqz end_prepare
    load buffer_ptr
    add const_1
    store buffer_ptr
    jmp prepare_reverse
end_prepare:
    load buffer_ptr
    sub const_1
    store buffer_ptr
    sub buffer_end
    beqz after_reverse
    ble after_reverse
    load buffer_start
    store result_ptr
while_reverse:
    load buffer_ptr
    load_acc
    and mask
    store letter
    load const_0
    or under
    shiftl shift8
    or under
    shiftl shift16
    or letter
    store_ind result_ptr
    load result_ptr
    add const_1
    store result_ptr
    load buffer_ptr
    sub const_1
    store buffer_ptr
    sub buffer_end
    ble restore
    jmp while_reverse
restore:
    load result_ptr
    add buffer_ptr
    add const_1
    store buffer_ptr
while_restore:
    load result_ptr
    add const_1
    store result_ptr
    load buffer_ptr
    add const_1
    store buffer_ptr
    load_acc
    and mask
    beqz after_reverse
    store letter
    load const_0
    or under
    shiftl shift8
    or under
    shiftl shift16
    or letter
    store_ind result_ptr
    jmp while_restore


default_s:
    load overflow
    store_ind output
    jmp end


good:
    load buffer_start
    store result_ptr
while_good:
    load result_ptr
    load_acc
    and mask
    beqz end
    store_ind output
    load result_ptr
    add const_1
    store result_ptr
    sub max_size
    beqz end
    jmp while_good


end:
    halt
