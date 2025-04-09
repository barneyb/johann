;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align  3                           ; Make sure everything is 8-byte/64-bit aligned
.set    NULL, 0
.set    FALSE, 0

.include "inc_token_table.s"

.global _main
_main:
    bl      jnc
    mov     x0, #0
    b       _os_exit

jnc:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    ; end frame

    bl      _Reader_instance        ; r = Reader.instance()
    mov     x19, x0                 ; stash pointer -> r
    bl      _Lexer_new              ; lex = Lexer.new(r)
    mov     x20, x0                 ; stash pointer -> lex

    mov     x0, #123
    bl      _mem_alloc;_LOG
    mov     x21, x0                 ; pointer -> buffer
    mov     x22, x0                 ; pointer -> buffer[i] to write

    next_token:
    mov     x0, x20
    bl      _lexer_token            ; lex.token()
    cmp     x0, NULL
    b.eq    print_and_return
    strb    w0, [x22], #1
    cmp     w0, T_SEMI
    b.eq    next_newline
    cmp     w0, T_OBRACE
    b.eq    next_newline
    cmp     w0, T_CBRACE
    b.eq    next_newline
    mov     w0, ' '
    strb    w0, [x22], #1
    b       next_token
    next_newline:
    mov     w0, '\n'
    strb    w0, [x22], #1
    b       next_token

    print_and_return:
    mov     x0, x20
    bl      _lexer_destroy          ; lex.destroy()
    mov     x0, x19
    bl      _Reader_destroy         ; Reader.destroy()

    mov     x0, x21
    bl      _println_z              ; print!
    mov     x0, x21
    bl      _mem_free;_LOG               ; release buffer

    ; restore frame
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret
