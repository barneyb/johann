/**
 * I provide routines for string manipulation. Null-termination is assumed.
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3 ; 8-byte/64-bit alignment
.set    NULL, 0

/* int str2int( char* str ) */
.global _str2int
_str2int:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    ; end frame
    ; todo: handle leading minus!
    mov     x20, #0                 ; n = 0
    mov     x21, #10                ; radix
    str2int_char:
    ldrb    w19, [x0], #1           ; c = str[i++]
    cmp     w19, NULL
    b.eq    str2int_return
    sub     x19, x19, '0'           ; convert digit to number
    madd    x20, x21, x20, x19      ; multiply by 10 and add digit value
    b str2int_char

    str2int_return:
    mov     x0, x20
    ; restore frame
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret
