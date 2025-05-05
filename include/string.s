/**
 * I provide routines for string manipulation. Null-termination is assumed.
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3 ; 8-byte/64-bit alignment
.set    NULL, 0

; The largest 64-bit integer, when decimal string-ified, has length 20.
/* char* int2str( int num ) */
.global _int2str
_int2str:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    stp     x22, x23, [sp, #-16]!
    stp     x24, x25, [sp, #-16]!
    ; end frame
    mov     x25, x0                 ; save num
    mov     x0, #21                 ; max len, plus room for a NULL
    bl      _mem_alloc;_LOG
    mov     x24, x0                 ; pointer -> buffer
    add     x19, x24, #21           ; -> tail of buffer
    strb    wzr, [x19, #-1]!        ; put a NULL at the end
    mov     x0, x25                 ; restore num

    mov     x23, #0                 ; assume non-negative
    cmp     x0, #0
    b.ge    int2str_positive
    mov     x23, #-1                ; it's negative
    mul     x0, x0, x23
    int2str_positive:

    mov     x25, #10                ; base 10
    int2str_loop:
    sdiv    x21, x0, x25            ; x21 = x0 / 10
    msub    x22, x21, x25, x0       ; x22 = x0 - (x21 * 10)
                                    ; x22 = x0 % 10
    add     w20, w22, 0x30          ; convert to char
    strb    w20, [x19, #-1]!        ; add to string
    mov     x0, x21                 ; update x0 w/ what's left
    cmp     x0, #0
    b.ne    int2str_loop

    cmp     x23, #0
    b.eq    int2str_move
    mov     w20, '-'
    strb    w20, [x19, #-1]!        ; minus sign

    int2str_move:
    cmp     x19, x24
    b.eq    int2str_return          ; used full alloc!
    ; move to start of allocated buffer (copy [x19] to [x24])
    ; todo: straightforward implementation, but rather inefficient
    mov     x25, x24
    int2str_copy_char:
    ldrb    w20, [x19], #1          ; load and increment
    strb    w20, [x25], #1          ; store and increment
    cmp     w20, #0
    b.eq    int2str_return          ; null byte!
    b       int2str_copy_char       ; next!

    int2str_return:
    mov     x0, x24                 ; pointer to start of string & alloc
    ; restore frame
    ldp     x24, x25, [sp], #16
    ldp     x22, x23, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

; todo: combine int2str and int2hex
/* char* int2hex( int num ) */
.global _int2hex
_int2hex:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    stp     x22, x23, [sp, #-16]!
    stp     x24, x25, [sp, #-16]!
    ; end frame
    mov     x25, x0                 ; save num
    mov     x0, #21                 ; max len, plus room for a NULL
    bl      _mem_alloc
    mov     x24, x0                 ; pointer -> buffer
    add     x19, x24, #21           ; -> tail of buffer
    strb    wzr, [x19, #-1]!        ; put a NULL at the end
    mov     x0, x25                 ; restore num

    mov     x23, #0                 ; assume non-negative
    cmp     x0, #0
    b.ge    int2hex_positive
    mov     x23, #-1                ; it's negative
    mul     x0, x0, x23
    int2hex_positive:

    mov     x25, #16                ; base 16
    int2hex_loop:
    sdiv    x21, x0, x25            ; x21 = x0 / 16
    msub    x22, x21, x25, x0       ; x22 = x0 - (x21 * 16)
                                    ; x22 = x0 % 16
    add     w20, w22, 0x30          ; convert to char
    cmp     x20, '9'
    b.le    int2hex_decimal
    add     x20, x20, #39           ; alphabetic digit
    int2hex_decimal:
    strb    w20, [x19, #-1]!        ; add to string
    mov     x0, x21                 ; update x0 w/ what's left
    cmp     x0, #0
    b.ne    int2hex_loop

    cmp     x23, #0
    b.eq    int2hex_move
    mov     w20, '-'
    strb    w20, [x19, #-1]!        ; minus sign

    int2hex_move:
    mov     w20, 'x'
    strb    w20, [x19, #-1]!        ; x
    mov     w20, '0'
    strb    w20, [x19, #-1]!        ; 0
    cmp     x19, x24
    b.eq    int2hex_return          ; used full alloc!
    ; move to start of allocated buffer (copy [x19] to [x24])
    ; todo: straightforward implementation, but rather inefficient
    mov     x25, x24
    int2hex_copy_char:
    ldrb    w20, [x19], #1          ; load and increment
    strb    w20, [x25], #1          ; store and increment
    cmp     w20, #0
    b.eq    int2hex_return          ; null byte!
    b       int2hex_copy_char       ; next!

    int2hex_return:
    mov     x0, x24                 ; pointer to start of string & alloc
    ; restore frame
    ldp     x24, x25, [sp], #16
    ldp     x22, x23, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

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
