;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.data
err_bad_format_conv: .ascii "ERROR: Bad format string conversion spec\n"
err_bad_format_conv_len = . - err_bad_format_conv
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align  3                           ; Make sure everything is 8-byte/64-bit aligned
NULL = 0
TRUE = 1

/* int printf( char* format, ... ) */
; note, only seven variadic args will work
.global __j_printf
__j_printf:
    ; todo: do the frame correctly everywhere else too
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    ; sp[20] : void* args ; todo: the caller should set these up...
    stp     x6, x7, [sp, -0x10]!
    stp     x4, x5, [sp, -0x10]!
    stp     x2, x3, [sp, -0x10]!
    sub     x2, sp, 0x8             ; where args[0] will end up
    stp     x2, x1, [sp, -0x10]!
    ; sp[20] :
    ; sp[18] : int buffer_size
    ; sp[10] : char* buffer (consumed)
    stp     xzr, xzr, [sp, -0x10]!
    ; sp[8] : int written
    ; sp[0] : char* format (consumed)
    stp     x0, xzr, [sp, -0x10]!

    bl      __j_strlen              ; get length of format
    str     x0, [sp, 0x18]          ; store buffer_size

    bl      __j_malloc              ; allocate buffer
    str     x0, [sp, 0x10]          ; store buffer

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
        ldr     x1, [sp, 0x10]      ; load j
        strb    w0, [x1], #1        ; store buffer[j++]
        str     x1, [sp, 0x10]      ; store j
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
        cmp     x0, 'i'
        b.eq    printf_decimal
        cmp     x0, 'd'
        b.eq    printf_decimal
        mov     x0, #17
        adrp    x1, err_bad_format_conv@PAGE
        add     x1, x1, err_bad_format_conv@PAGEOFF
        mov     x2, err_bad_format_conv_len
        bl      __j_panic

    printf_decimal:
        mov     x6, #10
        b       printf_integer
    printf_hex:
        mov     x6, #16
        mov     x7, 'a'
        b       printf_integer
    printf_HEX:
        mov     x6, #16
        mov     x7, 'A'
        b       printf_integer
    printf_octal:
        mov     x6, #8
        b       printf_integer

    printf_integer:
        ldr     x1, [sp, 0x20]      ; load a
        ldr     x0, [x1], #8        ; load args[a++]
        str     x1, [sp, 0x20]      ; store a

        ; x6 holds the base
        ; x7 points to the 10 digit
        ; point to SP in x5
        mov     x5, sp
        ; store a counter in x4
        mov     x4, xzr
        ; allocate at 32 bytes on the stack
        str     xzr, [sp, -0x20]!
        ; if x0 is negative,
        cmp     x0, #0
        b.gt    printf_integer_again
        mov     x1, TRUE
        str     x1, [sp]            ; store true at SP
        neg     x0, x0              ; negate x0
        printf_integer_again:
        ; divide by base into x1
        sdiv    x1, x0, x6          ; x1 = x0 / x6
        ; take mod base into x2
        msub    x2, x1, x6, x0      ; x2 = x0 - (x1 * x6)
                                    ; x2 = x0 % x6
        mov     x0, x1              ; update to what's left
        ; convert to digit
        cmp     x2, #10
        b.ge    printf_integer_high
        add     w2, w2, 0x30        ; convert to decimal digit
        b       printf_integer_digit
        printf_integer_high:
        add     w2, w2, w7          ; convert to high digit
        printf_integer_digit:
        ; pre-decrement and write to x5
        strb    w2, [x5, #-1]!
        ; increment counter in x4
        add     x4, x4, #1
        cmp     x0, xzr
        b.gt    printf_integer_again

        ; todo: if base is 16, add 0x prefix

        ; todo: if was negative, add minus sign to buffer

        ; todo: ensure there's room in the buffer

        str     x4, [sp]            ; store counter
        ldp     x2, x0, [sp, 0x28]  ; load written and j
        mov     x2, x4
        mov     x1, x5
        bl      __j_memcpy          ; copy scratch space to buffer
        ldr     x4, [sp]            ; load counter
        ldp     x2, x0, [sp, 0x28]  ; load written and j
        add     x2, x2, x4          ; written += counter
        add     x0, x0, x4          ; j += counter
        stp     x2, x0, [sp, 0x28]  ; store written and j
        add     sp, sp, 0x20        ; deallocate 'integer' stack space
        b       printf_again

    printf_done:
        ldp     x2, x1, [sp, 0x8]       ; load written and buffer
        sub     x1, x1, x2              ; rewind to start of buffer
        mov     x0, #1                  ; 1 = StdOut
        bl      __j_sys_write

    ldr     x0, [sp, 0x8]           ; load written
    add     sp, sp, 0x60            ; release local storage
    ldp     fp, lr, [sp], 0x10 ; todo: more proper frame
    ret

/* int puts( char* str ) */
.global __j_puts
__j_puts:
    str     lr, [sp, #-16]!
    ; sp[24]
    ; sp[16] : char* buffer
    ; sp[8] : int length
    ; sp[0] : char* str
    str     x0, [sp, #-32]!

    bl      __j_strlen
    str     x0, [sp, #8]

    add     x0, x0, #1              ; for the newline
    bl      __j_malloc
    str     x0, [sp, #16]           ; store pointer -> buffer

    ldr     x2, [sp, #8]
    ldr     x1, [sp]
    bl      __j_memcpy              ; copy str to the buffer

    ldr     x0, [sp, #16]           ; load pointer -> buffer
    ldr     x2, [sp, #8]            ; load length
    add     x2, x0, x2              ; end of buffer
    mov     w1, '\n'
    strb    w1, [x2]                ; store newline

    ldr     x2, [sp, #8]
    add     x2, x2, #1              ; for the newline
    ldr     x1, [sp, #16]
    mov     x0, #1                  ; 1 = StdOut
    bl      __j_sys_write

    add     sp, sp, #32
    ldr     lr, [sp], #16
    ret
