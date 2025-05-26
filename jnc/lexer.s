;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3 ; 8-byte/64-bit alignment
NULL    = 0
TRUE    = 1
FALSE   = 0

.include "inc_token_table.s"

/*
struct Lexer {
    int line_num                    ; line of the source being lexed
    int char_pos                    ; position in the line
}
*/
OFF_LINE    = 0
OFF_CHAR    = 0x8
SIZEOF      = OFF_CHAR + 0x8

/* Lexer new( ) */
.global __j_Lexer__new
__j_Lexer__new:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

    mov     x0, SIZEOF              ; how much to allocate
    bl      __j_malloc              ; allocate
    mov     x1, #1
    stp     x1, xzr, [x0, OFF_LINE] ; initialize line and char

    ldp     fp, lr, [sp], 0x10
    ret

/* Token token( Lexer* self ) */
.global __j_Lexer_token
__j_Lexer_token:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    stp     x22, x23, [sp, -0x10]!
    str     x24, [sp, -0x10]!
    ; end frame

    mov     x19, x0                 ; pointer -> this
    ldp     x21, x22, [x19, OFF_LINE]   ; load this.line_num and .char_pos

;        .data
;        msda:.asciz "; NEXT TOKEN (from %d, %d)\n"
;        .text
;        adrp x0, msda@PAGE
;        add x0, x0, msda@PAGEOFF
;        mov x1, x21
;        mov x2, x22
;        bl __j_printf

    token_skip_char:
    bl      __j_iseof
    cmp     x0, FALSE
    b.ne    token_null
    bl      __j_getchar

    ; see if it's a newline
    cmp     x0, '\n'
    b.ne    token_same_line
    token_handle_newline:
    add     x21, x21, #1            ; increment line_num
    mov     x22, xzr                ; zero char_pos
    stp     x21, x22, [x19, OFF_LINE]   ; store this.line_num and .char_pos
    b       token_skip_char         ; NEXT!

    token_same_line:
    add     x22, x22, #1            ; increment char_pos
    str     x22, [x19, OFF_CHAR]    ; store this.char_pos

    ; see if it's a space
    cmp     x0, ' '
    b.eq    token_skip_char         ; NEXT!
    ; see if it's a tab
    cmp     x0, '\t'
    b.eq    token_skip_char         ; NEXT!

    ; see if it's a comment, and consume until end of line if so
    cmp     x0, T_HASH
    b.ne    token_keep_going
    bl      __j_Lexer_lex_comment
    b       token_handle_newline

    token_keep_going:

    ; unambiguous single-character tokens are easy
    cmp     x0, T_AMP
    b.eq    token_punct
    cmp     x0, T_CBRACE
    b.eq    token_punct
    cmp     x0, T_CBRACKET
    b.eq    token_punct
    cmp     x0, T_COLON
    b.eq    token_punct
    cmp     x0, T_COMMA
    b.eq    token_punct
    cmp     x0, T_CPAREN
    b.eq    token_punct
    cmp     x0, T_DOT
    b.eq    token_punct
    cmp     x0, T_OBRACE
    b.eq    token_punct
    cmp     x0, T_OBRACKET
    b.eq    token_punct
    cmp     x0, T_OPAREN
    b.eq    token_punct
    cmp     x0, T_PERCENT
    b.eq    token_punct
    cmp     x0, T_PIPE
    b.eq    token_punct
    cmp     x0, T_QUESTION
    b.eq    token_punct
    cmp     x0, T_SEMI
    b.eq    token_punct
    cmp     x0, T_SLASH
    b.eq    token_punct
    cmp     x0, T_STAR
    b.eq    token_punct
    ; to-become-ambiguous character tokens are easy as well (for now)
    cmp     x0, T_ASSIGN
    b.eq    token_punct
    cmp     x0, T_BANG
    b.eq    token_punct
    cmp     x0, T_GT
    b.eq    token_punct
    cmp     x0, T_LT
    b.eq    token_punct
    cmp     x0, T_PLUS
    b.eq    token_punct
    ; ambiguous character tokens...
    cmp     x0, T_MINUS
    b.eq    token_minus
    ; multi-character tokens...
    cmp     x0, 'a'                 ; T_ID
    b.ge    token_id_ish
    cmp     x0, 'A'                 ; T_ID
    b.ge    token_ID_ish
    cmp     x0, '0'                 ; T_INT
    b.ge    token_int_ish
    cmp     x0, '\''                ; T_CHAR
    b.ge    token_char
    cmp     x0, '"'                 ; T_STRING
    b.ge    token_string

    token_bad_char:
    ; indicate the char that fell through
        mov     x1, x0
        mov     x0, x19
        bl      __j_Lexer_bad_char

    token_minus:
    bl      __j_peekchar
    bl      __j_isdigit
    cmp     x0, FALSE               ; check if start of integer
    mov     x0, '-'                 ; put the minus back
    b.eq    token_punct             ; not an integer
    b       token_int

    token_id_ish:
    cmp     x0, 'z'
    b.le    token_id
    b       token_bad_char

    token_ID_ish:
    cmp     x0, 'Z'
    b.le    token_id
    b       token_bad_char

    token_int_ish:
    cmp     x0, '9'
    b.le    token_int
    b       token_bad_char

    token_punct:
    mov     x1, x0
    mov     x0, x19
    bl      __j_token_punct
    b       token_return

    token_int:
    mov     x1, x0
    mov     x0, x19
    bl      __j_token_int
    b       token_return

    token_id:
    mov     x1, x0
    mov     x0, x19
    bl      __j_token_id
    b       token_return

    token_char:
    mov     x1, x0
    mov     x0, x19
    bl      __j_token_char
    b       token_return

    token_string:
    mov     x1, x0
    mov     x0, x19
    bl      __j_token_string
    b       token_return

    token_null:
    mov     x0, NULL

    token_return:
    ; restore frame
    ldr     x24, [sp], 0x10
    ldp     x22, x23, [sp], 0x10
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

/* void destroy( Lexer* self ) */
.global __j_Lexer_drop
__j_Lexer_drop:
    ; create frame
    str     lr, [sp, -0x10]!
    ; end frame

    bl      __j_free

    ; restore frame
    ldr     lr, [sp], 0x10
    ret

; Eats characters up to and including the next newline.
/* void lex_comment( ) */
.global __j_Lexer_lex_comment
__j_Lexer_lex_comment:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

    lex_comment_char:
    bl      __j_iseof
    cmp     x0, FALSE
    b.ne    lex_comment_return      ; out of characters
    bl      __j_getchar
    cmp     x0, '\n'
    b.eq    lex_comment_return
    b       lex_comment_char

    lex_comment_return:
    ldp     fp, lr, [sp], 0x10
    ret
