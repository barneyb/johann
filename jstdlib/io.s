;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align  3                           ; Make sure everything is 8-byte/64-bit aligned

/* int print( char* str ) */
.global __j_print
__j_print:
    str     lr, [sp, #-16]!
    ; sp[8] : int length
    ; sp[0] : char* str
    str     x0, [sp, #-16]!

    bl      __j_strlen
    str     x0, [sp, #8]

    ldr     x2, [sp, #8]
    ldr     x1, [sp]
    mov     x0, #1                  ; 1 = StdOut
    bl      __j_sys_write

    add     sp, sp, #16
    ldr     lr, [sp], #16
    ret

/* int println( char* str ) */
.global __j_println
__j_println:
    str     lr, [sp, #-16]!
    ; sp[24]
    ; sp[16] : char* buffer
    ; sp[8] : int length
    ; sp[0] : char* str
    str     x0, [sp, #-32]!

    bl      __j_strlen
    str     x0, [sp, #8]

    add     x0, x0, #1              ; for the newline
    bl      __j_malloc
    str     x0, [sp, #16]           ; store pointer -> buffer

    ldr     x2, [sp, #8]
    ldr     x1, [sp]
    bl      __j_memcpy              ; copy str to the buffer

    ldr     x0, [sp, #16]           ; load pointer -> buffer
    ldr     x2, [sp, #8]            ; load length
    add     x2, x0, x2              ; end of buffer
    mov     w1, '\n'
    strb    w1, [x2]                ; store newline

    ldr     x2, [sp, #8]
    add     x2, x2, #1              ; for the newline
    ldr     x1, [sp, #16]
    mov     x0, #1                  ; 1 = StdOut
    bl      __j_sys_write

    add     sp, sp, #32
    ldr     lr, [sp], #16
    ret
