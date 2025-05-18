;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.data
assert: .asciz "assert '%c' == '%c'\n"
assert_failed: .asciz "FAIL\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.text
EOF = -1

.global _main
_main:
    bl      __j_main
    b       __j_exit

/* void assert_eq( int actual, int expected ) */
assert_eq:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

    ; convert EOF to ETB, which "prints"
    cmp     x0, EOF
    b.gt    assert_eq_asis_a
    mov     x0, 0x17 ; ETB - end †tx block
    assert_eq_asis_a:
    cmp     x1, EOF
    b.gt    assert_eq_asis_e
    mov     x1, 0x17 ; ETB - end †tx block
    assert_eq_asis_e:

    stp     x0, x1, [sp, -0x10]!    ; store chars for later

    mov     x2, x0
    adrp    x0, assert@PAGE
    add     x0, x0, assert@PAGEOFF
    bl      __j_printf

    ldp     x0, x1, [sp], 0x10
    cmp     x0, x1
    b.eq    assert_eq_ok
    mov     x2, x0
    adrp    x0, assert_failed@PAGE
    add     x0, x0, assert_failed@PAGEOFF
    bl      __j_printf
    mov     x0, 42
    bl      __j_exit

    assert_eq_ok:
    ldp     fp, lr, [sp], 0x10
    ret

.global __j_main
__j_main:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

    .macro peek c
        bl      __j_peekchar
        mov     x1, \c
        bl      assert_eq
    .endm
    .macro get c
        bl      __j_getchar
        mov     x1, \c
        bl      assert_eq
    .endm

    peek 'q'
    peek 'q'
    get 'q'
    get 'w'
    peek 'e'
    get 'e'
    get 'r'
    get 't'
    get 'y'
    peek '\n'
    peek '\n'
    peek '\n'
    get '\n'
    peek 'a'
    get 'a'
    get 's'
    get 'd'
    peek 'f'
    get 'f'
    get '\n'
    peek EOF
    peek EOF
    get EOF
    peek EOF
    peek EOF
    get EOF
    get EOF

    mov     x0, #0
    ldp     fp, lr, [sp], 0x10
    ret
