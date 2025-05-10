/**
 * I provide a buffered Reader "class" and a singleton instance of it, so
 * STDIN can be efficiently consumed one character at a time by the program.
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .bss
instance: .zero 8

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
;m_read: .asciz "< read > "
;m_eof: .asciz "¡¡at EOF!!"
;m_not_eof: .asciz "¡¡not at EOF!!"

err_read_at_eof: .asciz "ERROR: cannot read (at EOF)\n"
.set    err_read_at_eof_len, . - err_read_at_eof

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3 ; 8-byte/64-bit alignment
.set    NULL    , 0
.set    TRUE    , 1
.set    FALSE   , 0

/* char peek( Reader* r ) */
.global __j_ick_reader_peek
__j_ick_reader_peek:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    bl      __j_peekchar
    ldp     fp, lr, [sp], 0x10
    ret

/* char read( Reader* r ) */
.global __j_ick_reader_read
__j_ick_reader_read:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    bl      __j_getchar
    ldp     fp, lr, [sp], 0x10
    ret

/* boolean is_eof( Reader* r ) */
.global __j_ick_reader_is_eof
__j_ick_reader_is_eof:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    bl      __j_peekchar
    cmp     x0, #0
    b.lt    is_eof_yep
    mov     x0, FALSE
    b       is_eof_done
    is_eof_yep:
    mov     x0, TRUE
    is_eof_done:
    ldp     fp, lr, [sp], 0x10
    ret
