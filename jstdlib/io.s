;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.bss
BUF_SIZE = 0x400
buf_stdout: .zero BUF_SIZE
buf_stdout_pos: .zero 8             ; start empty
buf_stdin: .zero BUF_SIZE
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.data
err_bad_format_conv: .ascii "ERROR: Bad format string conversion spec\n"
err_bad_format_conv_len = . - err_bad_format_conv

str_true: .asciz "true"
str_false: .asciz "false"

buf_stdin_pos: .quad BUF_SIZE       ; start needing more
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.text
.align 3 ; 8-byte/64-bit alignment
EOF = -1
NULL = 0
TRUE = 1
FALSE = 0

/* bool iseof( ) */
.global __j_iseof
__j_iseof:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    bl      __j_peekchar
    cmp     x0, EOF
    b.le    iseof_yep
    mov     x0, FALSE
    b       iseof_done
    iseof_yep:
    mov     x0, TRUE
    iseof_done:
    ldp     fp, lr, [sp], 0x10
    ret

/* int getchar( ) */
.global __j_getchar
__j_getchar:
.global __j_read
__j_read:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

    bl      __j_peekchar
    cmp     x0, EOF
    b.le    getchar_done            ; nothing to advance if EOF

    adrp    x1, buf_stdin_pos@PAGE
    add     x1, x1, buf_stdin_pos@PAGEOFF
    ldr     x2, [x1]                ; load pos
    add     x2, x2, #1              ; pos++
    str     x2, [x1]                ; store pos

    getchar_done:
    ldp     fp, lr, [sp], 0x10
    ret

/* int peekchar( ) */
.global __j_peekchar
__j_peekchar:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

    adrp    x0, buf_stdin_pos@PAGE
    add     x0, x0, buf_stdin_pos@PAGEOFF
    ldr     x1, [x0]
    cmp     x1, BUF_SIZE
    b.lt    peekchar_loaded
        str     xzr, [x0]           ; update pos to zero
        mov     x2, BUF_SIZE
        adrp    x1, buf_stdin@PAGE
        add     x1, x1, buf_stdin@PAGEOFF
        mov     x0, #0              ; 0 = StdIn
        bl      __j_sys_read
        ; if less than a buffer's worth, add an EOF
        cmp     x0, BUF_SIZE
        b.eq    peekchar_loaded
            adrp    x1, buf_stdin@PAGE
            add     x1, x1, buf_stdin@PAGEOFF
            add     x1, x1, x0      ; index to store EOF
            mov     x2, EOF
            strb    w2, [x1]        ; store the EOF

    peekchar_loaded:
    adrp    x0, buf_stdin_pos@PAGE
    add     x0, x0, buf_stdin_pos@PAGEOFF
    ldr     x2, [x0]                ; load pos
    adrp    x1, buf_stdin@PAGE
    add     x1, x1, buf_stdin@PAGEOFF
    add     x1, x1, x2              ; pointer -> buf[pos]
    ldrb    w0, [x1]
        cmp x0, 0xFF                ; EOF (-1)
        b.eq peekchar_ascii
        cmp x0, 0x7F                ; end of ASCII
        b.le peekchar_ascii
        .data
        err_no_multibyte: .asciz "Multibyte character %x is forbidden\n"
        .text
        mov x1, x0
        adrp x0, err_no_multibyte@PAGE
        add x0, x0, err_no_multibyte@PAGEOFF
        bl __j_eprintf
        mov x0, 77
        bl  __j_exit
        peekchar_ascii:
    sxtb    x0, w0

    ldp     fp, lr, [sp], 0x10
    ret

/* int printf( char* format, ... ) */
; note, only seven variadic args will work
.global __j_printf
__j_printf:
    adrp    x8, __j_putchar@PAGE
    add     x8, x8, __j_putchar@PAGEOFF
    b       printf

/* int eprintf( char* format, ... ) */
; note, only seven variadic args will work
.global __j_eprintf
__j_eprintf:
    adrp    x8, errchar@PAGE
    add     x8, x8, errchar@PAGEOFF
    b       printf

    ; like putchar, but unbuffered to StdErr
    errchar:
        stp     fp, lr, [sp, -0x10]!
        mov     fp, sp
        str     x0, [sp, -0x10]!

        mov     x2, 1                   ; len
        mov     x1, sp
        mov     x0, #2                  ; 2 = StdErr
        bl      __j_sys_write

        add     sp, sp, 0x10
        ldp     fp, lr, [sp], 0x10
        ret

printf:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    ; fp[-8] : padding char
    ; fp[-10] : emit_char( c )
    stp     x8, xzr, [sp, -0x10]!
    ; sp[10] : void* args ; todo: the caller should set these up...
    stp     x6, x7, [sp, -0x10]!
    stp     x4, x5, [sp, -0x10]!
    stp     x2, x3, [sp, -0x10]!
    sub     x2, sp, 0x8             ; where args[0] will end up
    stp     x2, x1, [sp, -0x10]!
    ; sp[10] : pointer to the next arg to process
    ; sp[8] : int written
    ; sp[0] : char* format (consumed)
    stp     x0, xzr, [sp, -0x10]!
    b       printf_again

    printf_next_arg:
        ldr     x1, [sp, 0x10]      ; load a (ptr to current arg)
        ldr     x0, [x1], #8        ; load args[a++]

        ; x1 points at the next arg to use
        ; if it points at fp[-10]
        sub x16, fp, 0x10
        cmp x1, x16
        b.ne printf_next_arg_go
            ; switch to stacked args
            add x1, fp, 0x10

        printf_next_arg_go:
        str     x1, [sp, 0x10]      ; store a
        ret

    printf_again:
        ldr     x1, [sp]            ; load i
        ldrb    w0, [x1], #1        ; load format[i++]
        str     x1, [sp]            ; store i
        cmp     x0, NULL
        b.eq    printf_done
        cmp     x0, '%'
        b.ne    printf_normal
        b       printf_convert

    printf_normal:
        ldr     x8, [fp, -0x10]
        blr     x8
        ldr     x0, [sp, 0x8]       ; load written
        add     x0, x0, #1          ; written++
        str     x0, [sp, 0x8]       ; store written
        b       printf_again

    printf_convert:
        ldr     x1, [sp]            ; load i
        ldrb    w0, [x1], #1        ; load format[i++]
        str     x1, [sp]            ; store i
        cmp     x0, '%'
        b.eq    printf_normal       ; the _second_ % is "normal"
        stp     x0, xzr, [sp, -0x10]!   ; store char and width
        cmp     x0, '0'             ; pad with zeros?
        b.eq    printf_pad_zero
            mov     x1, ' '
            b       printf_reset_pad
        printf_pad_zero:
            mov     x1, '0'
        printf_reset_pad:
        str     x1, [fp, -0x8]      ; reset padding char

        printf_width_again:
        bl      __j_isdigit
        cmp     x0, FALSE
        b.eq    printf_width_done
        ldp     x0, x3, [sp]        ; load char and width
        sub     x0, x0, '0'         ; parse digit -> number
        mov     x2, #10
        madd    x3, x3, x2, x0      ; add to width
        ldr     x1, [sp, 0x10]      ; load i
        ldrb    w0, [x1], #1        ; load format[i++]
        str     x1, [sp, 0x10]      ; store i
        stp     x0, x3, [sp]        ; store char and width
        b       printf_width_again
        printf_width_done:
        ldp     x0, x3, [sp], 0x10  ; load and release char and width

        cmp     x0, 'b'
        b.eq    printf_bool
        cmp     x0, 'c'
        b.eq    printf_char
        cmp     x0, 'd'
        b.eq    printf_decimal
        cmp     x0, 'i'
        b.eq    printf_decimal
        cmp     x0, 'p'
        b.eq    printf_hex
        cmp     x0, 's'
        b.eq    printf_string
        cmp     x0, 'x'
        b.eq    printf_hex
        cmp     x0, 'X'
        b.eq    printf_hex
        mov     x0, #47
        adrp    x1, err_bad_format_conv@PAGE
        add     x1, x1, err_bad_format_conv@PAGEOFF
        mov     x2, err_bad_format_conv_len
        bl      __j_panic

    printf_decimal:
        ldrb    w4, [fp, -0x8]      ; padding character
        ; width is in x3
        mov     x2, x0              ; spec
        bl      printf_next_arg
        ldr     x1, [fp, -0x10]     ; put_char
        bl      __j_printf_d__
        b       printf_after_johann
    printf_hex:
        ldrb    w4, [fp, -0x8]      ; padding character
        ; width is in x3
        mov     x2, x0              ; spec
        bl      printf_next_arg
        ldr     x1, [fp, -0x10]     ; put_char
        bl      __j_printf_x__
    printf_after_johann:
        ldr     x1, [sp, 0x8]       ; load written
        add     x1, x1, x0          ; written + n
        str     x1, [sp, 0x8]       ; store written
        b       printf_again

    printf_char:
        ; replace the spec w/ the actual character and 'normal'
        bl      printf_next_arg
        b       printf_normal

    printf_bool:
        ldrb    w4, [fp, -0x8]      ; padding character
        ; width is in x3
        mov     x2, x0              ; spec
        bl      printf_next_arg
        ldr     x1, [fp, -0x10]     ; put_char
        bl      __j_printf_b__
        b       printf_after_johann

    printf_string:
        ldrb    w4, [fp, -0x8]      ; padding character
        ; width is in x3
        mov     x2, x0              ; spec
        bl      printf_next_arg
        ldr     x1, [fp, -0x10]     ; put_char
        bl      __j_printf_s__
        b       printf_after_johann

    printf_done:
    ldr     x0, [sp, 0x8]           ; load written
    add     sp, sp, 0x60            ; release local storage
    ldp     fp, lr, [sp], 0x10
    ret

/* int putchar( char c ) */
.global __j_putchar
__j_putchar:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

    adrp    x1, buf_stdout@PAGE
    add     x1, x1, buf_stdout@PAGEOFF      ; pointer -> buffer[0]
    adrp    x2, buf_stdout_pos@PAGE
    add     x2, x2, buf_stdout_pos@PAGEOFF  ; pointer -> len
    ldr     x4, [x2]                ; load len
    add     x3, x1, x4              ; pointer -> buffer[len]
    strb    w0, [x3]                ; store char at buffer[len]
    add     x4, x4, #1              ; len++
    str     x4, [x2]                ; store len

    cmp     x4, BUF_SIZE
    b.ge    putchar_flush           ; buffer's full
    cmp     w0, '\n'
    b.eq    putchar_flush           ; end of line
    b       putchar_done

    putchar_flush:
    ; manually inlined call to __j_flush_stdout__
    str     x2, [sp, -0x10]!        ; store pointer -> len
    mov     x2, x4                  ; len
    mov     x0, #1                  ; 1 = StdOut
    bl      __j_sys_write
    ldr     x2, [sp], 0x10          ; load pointer -> len
    mov     x4, #0                  ; len = 0
    str     x4, [x2]                ; store len

    putchar_done:
    ldp     fp, lr, [sp], 0x10
    ret

.global __j_flush_stdout__
__j_flush_stdout__:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

    adrp    x3, buf_stdout_pos@PAGE
    add     x3, x3, buf_stdout_pos@PAGEOFF  ; pointer -> len
    ldr     x2, [x3]                ; load len
    cmp     x2, xzr
    b.eq    flush_done

    adrp    x1, buf_stdout@PAGE
    add     x1, x1, buf_stdout@PAGEOFF  ; pointer -> buffer[0]
    mov     x0, #1                  ; 1 = StdOut
    bl      __j_sys_write
    adrp    x3, buf_stdout_pos@PAGE
    add     x3, x3, buf_stdout_pos@PAGEOFF  ; pointer -> len
    str     xzr, [x3]               ; store len = 0

    flush_done:
    ldp     fp, lr, [sp], 0x10
    ret

/* int puts( char* str ) */
.global __j_puts
__j_puts:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    str     x19, [sp, -0x10]!
    mov     x19, x0

    cmp     x0, NULL
    b.eq    puts_done

    puts_again:
    ldrb    w0, [x19], #1           ; load str[i++]
    cmp     w0, NULL
    b.eq    puts_done
    bl      __j_putchar
    b       puts_again

    puts_done:
    mov     x0, '\n'
    bl      __j_putchar

    ldr     x19, [sp], 0x10
    ldp     fp, lr, [sp], 0x10
    ret
