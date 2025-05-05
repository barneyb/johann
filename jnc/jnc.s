;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
.include "target/out/inc_version.s"
opt_v: .asciz "-v"
opt_version: .asciz "--version"
err_unimplemented: .asciz "Unimplemented"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3 ; 8-byte/64-bit alignment
.set    NULL, 0
.set    FALSE, 0
.set    INDENT, 4

.global _main
_main:
    bl      __j_main
    b       __j_sys_exit

/* int main( int argc, char* argv[] ) */
.global __j_main
__j_main:
    mov     x20, x0                 ; stash arg count
    mov     x21, x1                 ; stash pointer -> argv
    add     x21, x21, #8            ; argv[0] is the command name
    mov     x19, xzr
    main_arg_loop:
    add     x19, x19, 1
    cmp     x19, x20
    b.ge    jnc                     ; do compilation
    ldr     x0, [x21]
    adrp    x1, opt_v@PAGE
    add     x1, x1, opt_v@PAGEOFF
    bl      __j_strcmp
    cmp     x0, xzr
    b.eq    main_short_version
    ldr     x0, [x21], #8
    adrp    x1, opt_version@PAGE
    add     x1, x1, opt_version@PAGEOFF
    bl      __j_strcmp
    cmp     x0, xzr
    b.eq    main_long_version
    b       main_arg_loop

    main_short_version:
    adrp    x0, jnc_short_version@PAGE
    add     x0, x0, jnc_short_version@PAGEOFF
    bl      __j_puts
    b       main_exit

    main_long_version:
    adrp    x0, jnc_long_version@PAGE
    add     x0, x0, jnc_long_version@PAGEOFF
    bl      __j_puts

    main_exit:
    mov     x0, xzr
    b       __j_sys_exit

jnc:
    sub     sp, sp, #32             ; sp[0] = pointer -> string
                                    ; sp[1] = length
                                    ; sp[2] = pointer -> buffer
                                    ; sp[3] = pointer -> second buffer
    adrp    x0, err_unimplemented@PAGE
    add     x0, x0, err_unimplemented@PAGEOFF
    str     x0, [sp]                ; store pointer -> string
    bl      __j_strlen
    str     x0, [sp, #8]            ; store length
    add     x0, x0, #2              ; for the ! and newline
    bl      __j_malloc
    str     x0, [sp, #16]           ; store pointer -> dest
    ldr     x2, [sp, #8]            ; count
    add     x2, x0, x2
    mov     x1, '!'
    strb    w1, [x2]                ; store !
    ldr     x1, [sp]                ; load pointer -> string
    ldr     x2, [sp, #8]            ; load length
    bl      __j_memcpy
    ldr     x0, [sp, #16]           ; load pointer -> allocation
    ldr     x2, [sp, #8]            ; load length
    add     x2, x0, x2              ; pointer -> bang
    add     x2, x2, #1              ; pointer -> slot for newline
    mov     x1, '\n'
    strb    w1, [x2]                ; store newline

;        ; copy to a new buffer
;        ldr x0, [sp, #8]            ; load length
;        add x0, x0, #2              ; two more for ! and newline
;        bl __j_malloc
;        str x0, [sp, #24]
;        ldr x1, [sp, #16]
;        ldr x2, [sp, #8]
;        add x2, x2, #2              ; two more for ! and newline
;        bl __j_memcpy
;
;        ; copy "ted!" after "Un"
;        ldr x0, [sp, #16]           ; pointer -> allocation
;        mov x2, #4
;        add x1, x0, #10
;        add x0, x0, #2
;        bl __j_memcpy

    ldr     x1, [sp, #16]           ; load pointer -> allocation
    ldr     x2, [sp, #8]            ; load length
    add     x2, x2, #2              ; two more for ! and newline
    mov     x0, #2                  ; 2 = StdErr
    bl      __j_sys_write
    ldr     x1, [sp, #16]           ; load pointer -> allocation
    bl      __j_free                ; free the allocation

;        ; print un-munged buffer
;        ldr x1, [sp, #24]
;        ldr x2, [sp, #8]            ; load length
;        add x2, x2, #2              ; two more for ! and newline
;        mov x0, #1
;        bl __j_sys_write
;        ldr x1, [sp, #24]           ; load pointer -> allocation
;        bl __j_free                ; free the allocation

    add     sp, sp, #32             ; release local vars
    mov     x0, #1
    b       __j_sys_exit
