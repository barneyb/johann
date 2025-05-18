;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
.include "target/out/inc_version.s"
opt_v: .asciz "-v"
opt_version: .asciz "--version"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3 ; 8-byte/64-bit alignment
.set    NULL, 0
.set    FALSE, 0
.set    INDENT, 4

.global _main
_main:
    bl      __j_main
    b       __j_exit

/* int main( int argc, char* argv[] ) */
.global __j_main
__j_main:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

    mov     x20, x0                 ; stash arg count
    mov     x21, x1                 ; stash pointer -> argv
    add     x21, x21, #8            ; argv[0] is the command name
    mov     x19, xzr
    main_arg_loop:
        add     x19, x19, 1
        cmp     x19, x20
        b.ge    _main_jnc
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
        adrp    x0, __j_jnc_short_version@PAGE
        add     x0, x0, __j_jnc_short_version@PAGEOFF
        bl      __j_puts
        b       main_success

    main_long_version:
        adrp    x0, __j_jnc_long_version@PAGE
        add     x0, x0, __j_jnc_long_version@PAGEOFF
        bl      __j_puts
        b       main_success

    _main_jnc:
    bl      __j_jnc_compile

    main_success:
    mov     x0, xzr
    main_exit:
    ldp     fp, lr, [sp], 0x10
    ret
