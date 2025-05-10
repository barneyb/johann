;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.data
__j_print_i_format: .asciz "%i"
__j_print_h_format: .asciz "%x"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.text
.align 3 ; 8-byte/64-bit alignment

/* void print_i( int num ) */
.global __j_ick_print_i
__j_ick_print_i:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    mov     x1, x0
    adrp    x0, __j_print_i_format@PAGE
    add     x0, x0, __j_print_i_format@PAGEOFF
    bl      __j_printf
    ldp     fp, lr, [sp], 0x10
    ret

/* void print_h( int num ) */
.global __j_ick_print_h
__j_ick_print_h:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    mov     x1, x0
    adrp    x0, __j_print_h_format@PAGE
    add     x0, x0, __j_print_h_format@PAGEOFF
    bl      __j_printf
    ldp     fp, lr, [sp], 0x10
    ret

/* void println( ) */
.global __j_ick_println
__j_ick_println:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    mov     x0, '\n'
    bl      __j_ick_print_c
    ldp     fp, lr, [sp], 0x10
    ret
