.data
percent: .asciz "percent: [[%%]]\n"
char: .asciz "char: [[%c]]\n"
string: .asciz "string: [[%s]]\n"
integer: .asciz "integer: [[%d:%7i]]\n"
hex: .asciz "hex: [[%x:%X]]\n"
octal: .asciz "octal: [[%o]]\n"
pointer: .asciz "pointer: [[%4p]]\n"
newline: .asciz "newline: [[%n]]\n"          ; not num chars emitted!
everything: .asciz "everything: %%, %c, %s, %d, %x, %12p%n"
hello_world: .asciz "Hello, this most beautiful world!"
count: .asciz "written: %d\n"

.text
.global _main
_main:
    str     lr, [sp, #-16]!
    adrp    x19, count@PAGE
    add     x19, x19, count@PAGEOFF

    adrp    x0, percent@PAGE
    add     x0, x0, percent@PAGEOFF
    bl      __j_printf
    mov     x1, x0
    mov     x0, x19
    bl      __j_printf

    mov     x1, 'B'
    adrp    x0, char@PAGE
    add     x0, x0, char@PAGEOFF
    bl      __j_printf
    mov     x1, x0
    mov     x0, x19
    bl      __j_printf

    adrp    x1, hello_world@PAGE
    add     x1, x1, hello_world@PAGEOFF
    adrp    x0, string@PAGE
    add     x0, x0, string@PAGEOFF
    bl      __j_printf
    mov     x1, x0
    mov     x0, x19
    bl      __j_printf

    mov     x2, 0
    mov     x1, 0
    adrp    x0, integer@PAGE
    add     x0, x0, integer@PAGEOFF
    bl      __j_printf
    mov     x1, x0
    mov     x0, x19
    bl      __j_printf

    mov     x2, 12345
    mov     x1, 12345
    adrp    x0, integer@PAGE
    add     x0, x0, integer@PAGEOFF
    bl      __j_printf
    mov     x1, x0
    mov     x0, x19
    bl      __j_printf

    mov     x2, -987
    mov     x1, -987
    adrp    x0, integer@PAGE
    add     x0, x0, integer@PAGEOFF
    bl      __j_printf
    mov     x1, x0
    mov     x0, x19
    bl      __j_printf

    mov     x1, 88
    adrp    x0, octal@PAGE
    add     x0, x0, octal@PAGEOFF
    bl      __j_printf
    mov     x1, x0
    mov     x0, x19
    bl      __j_printf

    mov     x2, 123
    mov     x1, 123
    adrp    x0, hex@PAGE
    add     x0, x0, hex@PAGEOFF
    bl      __j_printf
    mov     x1, x0
    mov     x0, x19
    bl      __j_printf

    mov     x1, 32
    adrp    x0, pointer@PAGE
    add     x0, x0, pointer@PAGEOFF
    bl      __j_printf
    mov     x1, x0
    mov     x0, x19
    bl      __j_printf

    adrp    x0, newline@PAGE
    add     x0, x0, newline@PAGEOFF
    bl      __j_printf
    mov     x1, x0
    mov     x0, x19
    bl      __j_printf

    mov     x5, 1023
    mov     x4, 1024
    mov     x3, 456
    adrp    x2, hello_world@PAGE
    add     x2, x2, hello_world@PAGEOFF
    mov     x1, 'Z'
    adrp    x0, everything@PAGE
    add     x0, x0, everything@PAGEOFF
    bl      __j_printf
    mov     x1, x0
    mov     x0, x19
    bl      __j_printf

    mov     x0, #0
    ldr     lr, [sp], #16
    ret
