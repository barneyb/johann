;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align  3                           ; Make sure everything is 8-byte/64-bit aligned
.set    NULL, 0
.set    FALSE, 0
.set    INDENT, 4

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
    stp     x22, x23, [sp, #-16]!
    ; end frame

    bl      _Reader_instance        ; r = Reader.instance()
    mov     x19, x0                 ; stash pointer -> r
    bl      _Lexer_new              ; lex = Lexer.new(r)
    mov     x20, x0                 ; stash pointer -> lex

    mov     x0, #123
    bl      _mem_alloc;_LOG
    mov     x21, x0                 ; pointer -> buffer
    mov     x22, x0                 ; pointer -> buffer[i] to write
    mov     x23, #0                ; block depth

    next_token:
    mov     x0, x20
    bl      _lexer_token            ; lex.token()
    cmp     x0, NULL
    b.eq    print_and_return
    cmp     w0, T_CBRACE
    b.ne    next_proceed
    sub     x22, x22, INDENT        ; "remove" a layer of indent for this line
    next_proceed:
    strb    w0, [x22], #1
    cmp     w0, T_SEMI
    b.eq    next_newline
    cmp     w0, T_OBRACE
    b.eq    next_block
    cmp     w0, T_CBRACE
    b.eq    next_unblock
    mov     w0, ' '
    strb    w0, [x22], #1
    b       next_token
    next_block:
    add     x23, x23, INDENT        ; indent one layer
    b       next_newline
    next_unblock:
    sub     x23, x23, INDENT        ; unindent one layer
    b       next_newline
    next_newline:
    mov     w0, '\n'
    strb    w0, [x22], #1
    mov     w1, ' '
    mov     x2, x23
    next_indent:
    cmp     x2, #0
    b.eq    next_token
    strb    w1, [x22], #1
    sub     x2, x2, #1
    b       next_indent

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
    ldp     x22, x23, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret
