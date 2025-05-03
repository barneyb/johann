;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.text
.global _main
_main:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    str     lr, [sp, #-16]!

    mov     x0, 'g'
    bl      __j_putchar
    mov     x0, 'o'
    bl      __j_putchar
    mov     x0, '!'
    bl      __j_putchar
    mov     x0, '\n'
    bl      __j_putchar

    mov     x0, 'g'
    bl      __j_putchar
    mov     x0, 'o'
    bl      __j_putchar
    mov     x0, '.'
    bl      __j_putchar

    mov     x0, #0
    ldr     lr, [sp], #16
    ldp     fp, lr, [sp], 0x10
    ret
