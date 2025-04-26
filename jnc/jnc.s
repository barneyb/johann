;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
.include "target/out/inc_version.s"
opt_v: .asciz "-v"
opt_version: .asciz "--version"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align  3                           ; Make sure everything is 8-byte/64-bit aligned
.set    NULL, 0
.set    FALSE, 0
.set    INDENT, 4

/* int main( int argc, char* argv[] ) */
.global _main
_main:
    mov     x20, x0                 ; stash arg count
    mov     x21, x1                 ; stash pointer -> argv
    add     x21, x21, #8            ; argv[0] is the command name
    mov     x19, #0
    main_arg_loop:
    add     x19, x19, 1
    cmp     x19, x20
    b.ge    jnc                     ; do compilation
    ldr     x0, [x21]
    adrp    x1, opt_v@PAGE
    add     x1, x1, opt_v@PAGEOFF
    bl      __j_strcmp
    cmp     x0, #0
    b.eq    main_short_version
    ldr     x0, [x21], #8
    adrp    x1, opt_version@PAGE
    add     x1, x1, opt_version@PAGEOFF
    bl      __j_strcmp
    cmp     x0, #0
    b.eq    main_long_version
    b       main_arg_loop

    main_short_version:
    adrp    x0, jnc_short_version@PAGE
    add     x0, x0, jnc_short_version@PAGEOFF
    b       print_and_exit

    main_long_version:
    adrp    x0, jnc_long_version@PAGE
    add     x0, x0, jnc_long_version@PAGEOFF
    b       print_and_exit

    main_exit:
    mov     x0, #0
    b       __j_exit

jnc:
    b       main_exit

print_and_exit:
    mov     x19, x0
    bl      __j_strlen
    mov     x2, x0                  ; bytes to write
    mov     x1, x19                 ; pointer -> buffer
    mov     x0, #1                  ; 1 = StdOut
    bl      __j_write
    b       main_exit
