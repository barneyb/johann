.set buf_len, 32

.text

.global _main
_main:
    adrp    x19, buf@PAGE
    add     x19, x19, buf@PAGEOFF   ; where to read into
    mov     x20, #0                 ; floor
    mov     w21, #999               ; current char
    mov     x22, #9999              ; buffer size
    mov     x23, #9999              ; pos in buffer
    mov     x24, #9999              ; address of current char
    mov     x27, #0                 ; entered basement at
    mov     x28, #0                 ; chars read

    _main_buf_loop:
    mov     x0, x19
    mov     x1, buf_len
    bl      _os_stdin

    cmp     x0, #0
    b.le    _main_part_one          ; out of characters

    mov     x22, x0                 ; save buffer size
    mov     x23, #0                 ; reset pos

    _main_char_loop:
    cmp     x23, x22
    b.ge    _main_buf_loop          ; at end; read more

    add     x24, x19, x23
    add     x23, x23, #1
    ldrb    w21, [x24]
    add     x28, x28, #1            ; count char as read

    cmp     w21, '('
    b.ne    _main_p_close
    add     x20, x20, #1            ; move up a floor
    _main_p_close:
    cmp     w21, ')'
    b.ne    _main_char_loop
    sub     x20, x20, #1            ; move down a floor
    cmp     x20, #0
    b.ge    _main_char_loop         ; still above ground
    cmp     x27, #0
    b.ne    _main_char_loop         ; already went underground
    mov     x27, x28
    b       _main_char_loop

    _main_part_one:
    cmp     x20, #0
    b.ge    _main_part_one_pos
    neg     x20, x20
    mov     w22, '-'
    strb    w22, [x19]
    mov     x1, #1
    mov     x0, x19
    bl      _os_stdout              ; print!
    _main_part_one_pos:
    mov     x10, #10                ; base 10
    sdiv    x21, x20, x10           ; x21 = x20 / 10
    msub    x22, x21, x10, x20      ; x22 = x20 - (x21 * 10)
                                    ; x22 = x20 % 10
    add     x22, x22, 0x30          ; convert to char
    strb    w22, [x19]
    mov     x1, #1
    mov     x0, x19
    bl      _os_stdout              ; print!
    mov     x20, x21
    cmp     x20, #0
    b.ne    _main_part_one

    mov     w22, '\n'
    strb    w22, [x19]
    mov     x1, #1
    mov     x0, x19
    bl      _os_stdout              ; print!

    _main_part_two:
    cmp     x27, #0
    b.ge    _main_part_two_pos
    neg     x27, x27
    mov     w22, '-'
    strb    w22, [x19]
    mov     x1, #1
    mov     x0, x19
    bl      _os_stdout              ; print!
    _main_part_two_pos:
    mov     x10, #10                ; base 10
    sdiv    x21, x27, x10           ; x21 = x27 / 10
    msub    x22, x21, x10, x27      ; x22 = x27 - (x21 * 10)
                                    ; x22 = x27 % 10
    add     x22, x22, 0x30          ; convert to char
    strb    w22, [x19]
    mov     x1, #1
    mov     x0, x19
    bl      _os_stdout              ; print!
    mov     x27, x21
    cmp     x27, #0
    b.ne    _main_part_two

    mov     w22, '\n'
    strb    w22, [x19]
    mov     x1, #1
    mov     x0, x19
    bl      _os_stdout              ; print!

    mov     x0, #0
    b       _os_exit

.bss

buf: .zero buf_len
