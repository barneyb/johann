;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
.include "target/out/inc_version.s"
opt_v: .asciz "-v"
opt_version: .asciz "--version"

err_panic: .ascii "Compilation error\n"
err_panic_len = . - err_panic

tmpl_panic: .asciz ".data\n\
err_compiler_fail: .ascii \"Prior compilation error\\n\"\n\
err_compiler_fail_len = . - err_compiler_fail\n\
.text\n\
mov x0, #%i\n\
adrp x1, err_compiler_fail@PAGE\n\
add x1, x1, err_compiler_fail@PAGEOFF\n\
mov x2, err_compiler_fail_len\n\
bl __j_panic\n"
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
        adrp    x0, jnc_short_version@PAGE
        add     x0, x0, jnc_short_version@PAGEOFF
        bl      __j_puts
        b       main_success

    main_long_version:
        adrp    x0, jnc_long_version@PAGE
        add     x0, x0, jnc_long_version@PAGEOFF
        bl      __j_puts
        b       main_success

    _main_jnc:
    bl      jnc

    main_success:
    mov     x0, xzr
    main_exit:
    ldp     fp, lr, [sp], 0x10
    ret

jnc:
    ; create frame
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    stp     x20, x21, [sp, #-16]!
    ; end frame

    bl      _Lexer_new              ; lex = Lexer.new(r)
    mov     x20, x0                 ; stash pointer -> lex
    bl      _Parser_new             ; parser = Parser.new(lex);
    mov     x21, x0                 ; stash pointer -> parser

    bl      _parser_parse

    mov     x0, x21
    bl      _parser_destroy         ; parser.destroy()
    mov     x0, x20
    bl      _lexer_destroy          ; lex.destroy()

    ; restore frame
    ldp     x20, x21, [sp], #16
    ldp     fp, lr, [sp], 0x10
    ret

/* void jnc_panic( char* format, [val, line, char]* token, int code ) */
.global __j_jnc_panic
__j_jnc_panic:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    str     x2, [sp, -0x10]!    ; store status code

    ldr     x3, [x1, 0x8]
    ldr     x4, [x1, 0x10]
    ldr     x2, [x1]
    ldr     x1, [sp]            ; load status code
    bl      __j_printf
    ldr     x1, [sp]            ; load status code
    adrp    x0, tmpl_panic@PAGE
    add     x0, x0, tmpl_panic@PAGEOFF
    bl      __j_printf
    ldr     x0, [sp], 0x10      ; load status code
    adrp    x1, err_panic@PAGE
    add     x1, x1, err_panic@PAGEOFF
    mov     x2, err_panic_len
    b       __j_panic
