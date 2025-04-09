;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align  3                           ; Make sure everything is 8-byte/64-bit aligned
.set    FALSE   , 0

.global _main
_main:
    bl      not_quite_lisp
    mov     x0, #0
    b       _os_exit

not_quite_lisp:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    stp     x22, x23, [sp, #-16]!
    ; end frame

    bl      _Reader_instance
    mov     x19, x0                 ; Reader.instance()

    mov     x20, #0                 ; floor
    mov     w21, #999               ; current char
    mov     x22, #0                 ; entered basement at
    mov     x23, #0                 ; chars read

    next_char:
    mov     x0, x19
    bl      _reader_is_eof          ; reader.is_eof()
    cmp     x0, FALSE
    b.ne    print_and_return

    mov     x0, x19
    bl      _reader_read            ; reader.read()
    mov     w21, w0
    add     x23, x23, #1            ; count char as read

    cmp     w21, '('
    b.ne    try_close
    add     x20, x20, #1            ; move up a floor
    try_close:
    cmp     w21, ')'
    b.ne    next_char
    sub     x20, x20, #1            ; move down a floor
    cmp     x20, #0
    b.ge    next_char               ; still above ground
    cmp     x22, #0
    b.ne    next_char               ; already went underground
    mov     x22, x23
    b       next_char

    print_and_return:
    bl      _Reader_destroy
    mov     x0, x20
    bl      _int2str                ; convert to null-terminated string
    mov     x20, x0                 ; save the pointer
    bl      _println_z              ; println
    mov     x0, x20                 ; free the string
    bl      _mem_free

    mov     x0, x22
    bl      _int2str                ; convert to null-terminated string
    mov     x22, x0                 ; save the pointer
    bl      _println_z              ; println
    mov     x0, x22                 ; free the string
    bl      _mem_free

    ; restore frame
    ldp     x22, x23, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret
