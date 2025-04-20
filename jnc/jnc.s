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
    arg_loop:
    add     x19, x19, 1
    cmp     x19, x20
    b.ge    _main_jnc
    ldr     x0, [x21]
    adrp    x1, opt_v@PAGE
    add     x1, x1, opt_v@PAGEOFF
    bl      _strcmp
    cmp     x0, #0
    b.eq    _main_short_version
    ldr     x0, [x21], #8
    adrp    x1, opt_version@PAGE
    add     x1, x1, opt_version@PAGEOFF
    bl      _strcmp
    cmp     x0, #0
    b.eq    _main_long_version
    b       arg_loop

    _main_short_version:
    adrp    x0, jnc_short_version@PAGE
    add     x0, x0, jnc_short_version@PAGEOFF
    bl      _println_z
    b       _main_exit

    _main_long_version:
    adrp    x0, jnc_long_version@PAGE
    add     x0, x0, jnc_long_version@PAGEOFF
    bl      _println_z
    b       _main_exit

    _main_jnc:
    bl      jnc

    _main_exit:
    mov     x0, #0
    b       _os_exit

jnc:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    stp     x24, x25, [sp, #-16]!
    ; end frame

    bl      _Reader_instance        ; r = Reader.instance()
    mov     x19, x0                 ; stash pointer -> r
    bl      _Lexer_new              ; lex = Lexer.new(r)
    mov     x20, x0                 ; stash pointer -> lex
    bl      _Parser_new             ; parser = Parser.new(lex);
    mov     x21, x0                 ; stash pointer -> parser

    bl      _parser_parse

    mov     x0, x21
    bl      _parser_destroy         ; lex.destroy()
    mov     x0, x20
    bl      _lexer_destroy          ; lex.destroy()
    mov     x0, x19
    bl      _Reader_destroy         ; Reader.destroy()

    ; restore frame
    ldp     x24, x25, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret
