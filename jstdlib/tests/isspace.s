.data
yep: .asciz "yep!"
nope: .asciz "nope!"

.text
.global _main
_main:
    str     lr, [sp, #-16]!
    adrp    x19, yep@PAGE
    add     x20, x19, nope@PAGEOFF ; blindly assume the same page
    add     x19, x19, yep@PAGEOFF

    mov     x21, #0             ; i == 0
    again:
    cmp     x21, #40            ; if i >= 40
    b.ge    done                ; done
    mov     x0, x21
    add     x21, x21, #1
    bl      __j_isspace         ; isspace(i++)
    cmp     x0, 0
    b.eq    false
    mov     x0, x19
    bl      __j_puts
    b       again
    false:
    mov     x0, x20
    bl      __j_puts
    b       again

    done:
    mov     x0, #0
    ldr     lr, [sp], #16
    ret
