.data
yep: .asciz "yep!!"
nope: .asciz "nope!"

.text
.global _main
_main:
    str     lr, [sp, #-16]!
    sub     sp, sp, #16
    mov     x19, ' '
    strb    w19, [sp, #1]
    strb    wzr, [sp, #2]
    adrp    x19, yep@PAGE
    add     x20, x19, nope@PAGEOFF ; blindly assume the same page
    add     x19, x19, yep@PAGEOFF

    mov     x21, '-'            ; i == '-'
    again:
    cmp     x21, 'i'            ; if i > 'i'
    b.gt    done                ; done
    strb    w21, [sp]
    mov     x0, sp
    bl      __j_printf
    mov     x0, x21
    bl      __j_isdigit         ; isdigit(i)
    cmp     x0, 0
    b.eq    false
    mov     x0, x19
    bl      __j_printf
    b       now_hex
    false:
    mov     x0, x20
    bl      __j_printf
    b       now_hex

    now_hex:
    mov     x0, sp
    add     x0, x0, #1          ; just the space
    bl      __j_printf
    mov     x0, x21
    bl      __j_isxdigit        ; isxdigit(i)
    add     x21, x21, #1        ; i++
    cmp     x0, 0
    b.eq    xfalse
    mov     x0, x19
    bl      __j_puts
    b       again
    xfalse:
    mov     x0, x20
    bl      __j_puts
    b       again

    done:
    mov     x0, #0
    add     sp, sp, #16
    ldr     lr, [sp], #16
    ret
