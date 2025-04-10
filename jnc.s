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

    jnc_token:
    mov     x0, x20
    bl      _lexer_token            ; lex.token()
    cmp     x0, NULL
    b.eq    jnc_print_and_return
;    cmp     w0, T_CBRACE
;    b.ne    jnc_deindent
;    sub     x22, x22, INDENT        ; "remove" a layer of indent for this line
;    jnc_deindent:
    strb    w0, [x22], #1
    cmp     w0, T_SEMI
    b.eq    jnc_next_line
    cmp     w0, T_OBRACE
    b.eq    jnc_enter_block
    cmp     w0, T_CBRACE
    b.eq    jnc_leave_block
    mov     w0, ' '
    strb    w0, [x22], #1
    b       jnc_token
    jnc_enter_block:
    add     x23, x23, INDENT        ; indent one layer
    b       jnc_next_line
    jnc_leave_block:
    sub     x23, x23, INDENT        ; unindent one layer
    b       jnc_next_line
    jnc_next_line:
    mov     w0, '\n'
    strb    w0, [x22], #1
    mov     w1, ' '
    mov     x2, x23
    jnc_keep_indenting:
    cmp     x2, #0
    b.eq    jnc_token
    strb    w1, [x22], #1
    sub     x2, x2, #1
    b       jnc_keep_indenting

    jnc_print_and_return:
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
