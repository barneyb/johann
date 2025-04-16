;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align  3                           ; Make sure everything is 8-byte/64-bit aligned
.set    NULL, 0
.set    FALSE, 0
.set    INDENT, 4

.global _main
_main:
    bl      jnc
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
    bl      _Parser_new             ; parser = Parser.name(lex);
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
