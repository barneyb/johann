;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.text
.align 3 ; 8-byte/64-bit alignment
NULL = 0
FALSE = 0

/* int strcmp( const char* lhs, const char* rhs ) */
.global __j_strcmp
__j_strcmp:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    str     x20, [sp, #-16]!
    ; end frame
    strcmp_char:
    ldrb    w19, [x0], #1           ; l = lhs[i++]
    ldrb    w20, [x1], #1           ; r = rhs[i++]
    subs    w19, w19, w20
    b.ne    strcmp_return           ; l != r
    cmp     w20, NULL
    b.eq    strcmp_return           ; l == r == NULL
    b       strcmp_char             ; again!

    strcmp_return:
    mov     w0, w19
    ; restore frame
    ldr     x20, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

/* size_t strlen( const char* str ) */
.global __j_strlen
__j_strlen:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    str     x20, [sp, #-16]!
    ; end frame
    mov     x20, xzr                ; l = 0
    strlen_char:
    ldrb    w19, [x0], #1           ; c = str[i++]
    cmp     w19, NULL
    b.eq    strlen_return
    add     x20, x20, #1            ; l++
    b strlen_char

    strlen_return:
    mov     x0, x20
    ; restore frame
    ldr     x20, [sp], #16
    ldp     lr, x19, [sp], #16
    ret
