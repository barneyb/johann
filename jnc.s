.text

.global _main
_main:
    adrp    x19, char@PAGE
    add     x19, x19, char@PAGEOFF
    mov     x20, #0
    mov     x27, #0
    mov     x28, #0
    _main_loop:
    mov     x0, x19
    mov     x1, #1
    bl      _os_stdin

    cmp     x0, #0
    b.le    _main_bye
    add     x28, x28, #1            ; read character

    ldrb    w21, [x19]
    cmp     w21, '('
    b.ne    _main_p_close
    add     x20, x20, #1            ; move up
    _main_p_close:
    cmp     w21, ')'
    b.ne    _main_loop
    sub     x20, x20, #1            ; move down
    cmp     x20, #0
    b.ge    _main_loop              ; still above ground
    cmp     x27, #0
    b.ne    _main_loop              ; already went underground
    mov     x27, x28
    b       _main_loop

    _main_bye:
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
    b.ne    _main_bye

    mov     w22, '\n'
    strb    w22, [x19]
    mov     x1, #1
    mov     x0, x19
    bl      _os_stdout              ; print!

    _main_part_two:
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

.data

char: .zero 1
newline: .ascii "\n"
