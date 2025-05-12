;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
.set    TRUE, 1
.set    FALSE, 0

err_bad_char: .asciz "\n; ERROR(%i): Unrecognized char '%c' at line %i, char %i\n"
err_long_id: .asciz "\n; ERROR(%i): >7 char identifier '%s' at line %i, char %i\n"
err_long_string: .asciz "\n; ERROR(%i): >7 char string '%s' at line %i, char %i\n"

KW_AGAIN    : .asciz    "again"
KW_BOOL     : .asciz    "boolean"
KW_CHAR     : .asciz    "char"
KW_DONE     : .asciz    "done"
KW_FALSE    : .asciz    "false"
KW_FN       : .asciz    "fn"
KW_IF       : .asciz    "if"
KW_INT      : .asciz    "int"
KW_NULL     : .asciz    "null"
KW_RETURN   : .asciz    "return"
KW_TRUE     : .asciz    "true"
KW_VOID     : .asciz    "void"
KW_WHILE    : .asciz    "while"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3 ; 8-byte/64-bit alignment
.set    NULL, 0
.set    FALSE, 0

.include "inc_token_table.s"

/*
struct Lexer {
    int line_num                    ; line of the source being lexed
    int char_pos                    ; position in the line
}
*/
.set    OFF_LINE, 0
.set    OFF_CHAR, 0x8
.set    SIZEOF  , OFF_CHAR + 0x8    ; buffer is always last

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
.global _lexer_token
_lexer_token:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    stp     x22, x23, [sp, -0x10]!
    str     x24, [sp, -0x10]!
    ; end frame

    mov     x19, x0                 ; pointer -> this
    ldp     x21, x22, [x19, OFF_LINE]   ; load this.line_num and .char_pos

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
    bl      lex_comment
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

    token_ID_ish:
    cmp     x0, 'Z'
    b.le    token_id

    token_int_ish:
    cmp     x0, '9'
    b.le    token_int

    ; print the char that fell through
        str     x22, [sp, -0x10]!
        stp     x0, x21, [sp, -0x10]!
        adrp    x0, err_bad_char@PAGE
        add     x0, x0, err_bad_char@PAGEOFF
        mov     x1, sp
        mov     x2, #17
        bl      __j_jnc_panic

    token_punct:
    bl      __j_Token__new
    mov     x24, x0                 ; pointer -> token
    mov     x1, x21
    mov     x2, x22
    bl      __j_Token_set_coords
    mov     x0, x24
    b       token_return

    token_int:
    sub     sp, sp, 0x10            ; two-int return "structure"
    mov     x8, sp
    bl      lex_digits
    mov     x0, T_INT
    bl      __j_Token__new
    mov     x24, x0                 ; pointer -> token
    mov     x1, x21
    mov     x2, x22
    bl      __j_Token_set_coords    ; set coords of start
    ldp     x1, x23, [sp], 0x10     ; load value/consumed
    mov     x0, x24
    bl      __j_Token_set_value     ; set value
    add     x22, x22, x23           ; add the consumed char count
    str     x22, [x19, OFF_CHAR]    ; store this.char_pos
    mov     x0, x24
    b       token_return

    token_id:
    bl      lex_identifier
    mov     x23, x0                 ; stash pointer -> name
    mov     x0, T_ID
    bl      __j_Token__new
    mov     x24, x0                 ; pointer -> token
    mov     x1, x21
    mov     x2, x22
    bl      __j_Token_set_coords    ; set coords of start
    mov     x0, x24
    mov     x1, x23
    bl      __j_Token_set_value     ; set value
    mov     x0, x23                 ; unstash name
    bl      _strlen ; todo: silly to remeasure...
    sub     x0, x0, #1              ; first char was already counted
    add     x22, x22, x0            ; add the scanned char count
    str     x22, [x19, OFF_CHAR]    ; store this.char_pos
    mov     x0, x24
    bl      convert_keyword
    mov     x0, x24
    b       token_return

    token_char:
    mov     x0, x20
    bl      __j_getchar            ; the actual char
    mov     x23, x0
    mov     x0, x20
    bl      __j_getchar            ; the second single quote
    mov     x0, T_CHAR
    bl      __j_Token__new
    mov     x24, x0                 ; pointer -> token
    mov     x1, x21
    mov     x2, x22
    bl      __j_Token_set_coords       ; set coords of start
    mov     x0, x24
    mov     x1, x23                 ; the character
    bl      __j_Token_set_value        ; set value
    add     x22, x22, #2            ; add the char and close quote
    str     x22, [x19, OFF_CHAR]    ; store this.char_pos
    mov     x0, x24
    b       token_return

    token_string:
    bl      lex_string
    mov     x23, x0                 ; stash pointer -> name
    mov     x0, T_STRING
    bl      __j_Token__new
    mov     x24, x0                 ; pointer -> token
    mov     x1, x21
    mov     x2, x22
    bl      __j_Token_set_coords    ; set coords of start
    mov     x0, x24
    mov     x1, x23
    bl      __j_Token_set_value     ; set value
    mov     x0, x23                 ; unstash name
    bl      _strlen ; todo: silly to remeasure...
    add     x0, x0, #1              ; and close quote (open was already counted)
    add     x22, x22, x0            ; add the scanned char count
    str     x22, [x19, OFF_CHAR]    ; store this.char_pos
    mov     x0, x24
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
lex_comment:
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

/* [val, consumed] lex_digits( char first_char ) */
lex_digits:
    ; create frame
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    stp     x19, x20, [sp, -0x10]!  ; stash negative, value
    stp     x21, x8, [sp, -0x10]!   ; stash consumed, XR

    mov     x21, xzr                ; chars consumed
    cmp     x0, '-'
    b.eq    lex_digits_negative
    mov     x19, FALSE              ; not negative
    sub     x20, x0, '0'            ; parse first digit
    b       lex_digits_go
    lex_digits_negative:
    mov     x19, TRUE               ; negative
    mov     x20, xzr
    lex_digits_go:

    lex_digits_again:
    bl      __j_peekchar
    bl      __j_isdigit
    cmp     x0, FALSE
    b.eq    lex_digits_done
    bl      __j_getchar
    sub     x0, x0, '0'             ; parse
    mov     x1, #10                 ; base
    madd    x20, x20, x1, x0        ; add to result
    add     x21, x21, #1            ; count char
    b       lex_digits_again

    lex_digits_done:
    cmp     x19, FALSE
    b.eq    lex_digits_return
    neg     x20, x20

    lex_digits_return:
    ldr     x19, [sp, 0x8]          ; load pointer -> indirect return
    stp     x20, x21, [x19]         ; indirect return

    ldp     x21, xzr, [sp], 0x10
    ldp     x19, x20, [sp], 0x10
    ldp     fp, lr, [sp], 0x10
    ret

/* char* lex_identifier( char first_char ) */
lex_identifier:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    str     x22, [sp, -0x10]!
    ; end frame
    mov     x22, x0                 ; stash first char
    mov     x0, #64                 ; todo: max identifier length
    bl      __j_malloc
    mov     x20, x0                 ; pointer -> start of buffer
    mov     x21, x20                ; pointer -> buffer[pos] to write
    strb    w22, [x21], #1          ; put first char in the string

    lex_identifier_char:
    ; forgo the EOF check - there's no valid syntax for that case.
    bl      __j_peekchar
    cmp     x0, 'z'
    b.gt    lex_identifier_return
    cmp     x0, 'a'
    b.ge    lex_identifier_consume
    cmp     x0, '_'
    b.eq    lex_identifier_consume
    cmp     x0, 'Z'
    b.gt    lex_identifier_return
    cmp     x0, 'A'
    b.ge    lex_identifier_consume
    cmp     x0, '9'
    b.gt    lex_identifier_return
    cmp     x0, '0'
    b.ge    lex_identifier_consume
    b       lex_identifier_return
    lex_identifier_consume:
    bl      __j_getchar            ; consume the char
    strb    w0, [x21], #1           ; add it to the string
    b       lex_identifier_char

    lex_identifier_return:
    mov     x0, NULL                ; null-terminator
    strb    w0, [x21], #1           ; add it to the string

    mov     x0, x20                 ; return pointer -> buffer
    ; restore frame
    ldr     x22, [sp], 0x10
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

/* char* lex_string( ) */
lex_string:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    ; end frame
    mov     x0, #4096               ; todo: max string literal length
    bl      __j_malloc
    mov     x20, x0                 ; pointer -> start of buffer
    mov     x21, x20                ; pointer -> buffer[pos] to write

    lex_string_char:
    ; forgo the EOF check - there's no valid syntax for that case.
    bl      __j_getchar
    cmp     x0, '"'
    b.eq    lex_string_return
    strb    w0, [x21], #1           ; add it to the string
    b       lex_string_char

    lex_string_return:
    mov     x0, NULL                ; null-terminator
    strb    w0, [x21], #1           ; add it to the string

    mov     x0, x20                 ; return pointer -> buffer
    ; restore frame
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

/* void convert_keyword( Token* token ) */
convert_keyword:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    str     x20, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> token
    bl      __j_Token_value
    mov     x20, x0                 ; stash pointer -> token.value
    b       convert_keyword_fn

    /* boolean test( int type, char* kw ), closed over x19=token, x20=token.value */
    convert_keyword_test:
        stp     fp, lr, [sp, -0x10]!
        mov     fp, sp
        stp     x0, x1, [sp, -0x10]!

        mov     x0, x20             ; token.value
        bl      _strcmp
        cmp     xzr, x0
        b.ne    convert_keyword_test_no
        mov     x0, x20
        bl      __j_free            ; free the identifier
        mov     x0, x19
        ldr     x1, [sp]            ; load type
        bl      __j_Token_set_type
        mov     x0, x19
        ldr     x1, [sp, 0x8]       ; load static pointer -> keyword
        bl      __j_Token_set_value
        mov     x0, TRUE
        b       convert_keyword_test_done

        convert_keyword_test_no:
        mov     x0, FALSE

        convert_keyword_test_done:
        add     sp, sp, 0x10
        ldp     fp, lr, [sp], 0x10
        ret

    convert_keyword_fn:
    mov     x0, T_KW_FN
    adrp    x1, KW_FN@PAGE
    add     x1, x1, KW_FN@PAGEOFF
    bl      convert_keyword_test
    cmp     x0, FALSE
    b.eq    convert_keyword_int     ; next!
    b       convert_keyword_done    ; done!

    convert_keyword_int:
    mov     x0, T_KW_INT
    adrp    x1, KW_INT@PAGE
    add     x1, x1, KW_INT@PAGEOFF
    bl      convert_keyword_test
    cmp     x0, FALSE
    b.eq    convert_keyword_char    ; next!
    b       convert_keyword_done    ; done!

    convert_keyword_char:
    mov     x0, T_KW_CHAR
    adrp    x1, KW_CHAR@PAGE
    add     x1, x1, KW_CHAR@PAGEOFF
    bl      convert_keyword_test
    cmp     x0, FALSE
    b.eq    convert_keyword_bool    ; next!
    b       convert_keyword_done    ; done!

    convert_keyword_bool:
    mov     x0, T_KW_BOOL
    adrp    x1, KW_BOOL@PAGE
    add     x1, x1, KW_BOOL@PAGEOFF
    bl      convert_keyword_test
    cmp     x0, FALSE
    b.eq    convert_keyword_void    ; next!
    b       convert_keyword_done    ; done!

    convert_keyword_void:
    mov     x0, T_KW_VOID
    adrp    x1, KW_VOID@PAGE
    add     x1, x1, KW_VOID@PAGEOFF
    bl      convert_keyword_test
    cmp     x0, FALSE
    b.eq    convert_keyword_if      ; next!
    b       convert_keyword_done    ; done!

    convert_keyword_if:
    mov     x0, T_KW_IF
    adrp    x1, KW_IF@PAGE
    add     x1, x1, KW_IF@PAGEOFF
    bl      convert_keyword_test
    cmp     x0, FALSE
    b.eq    convert_keyword_while   ; next!
    b       convert_keyword_done    ; done!

    convert_keyword_while:
    mov     x0, T_KW_WHILE
    adrp    x1, KW_WHILE@PAGE
    add     x1, x1, KW_WHILE@PAGEOFF
    bl      convert_keyword_test
    cmp     x0, FALSE
    b.eq    convert_keyword_again   ; next!
    b       convert_keyword_done    ; done!

    convert_keyword_again:
    mov     x0, T_KW_AGAIN
    adrp    x1, KW_AGAIN@PAGE
    add     x1, x1, KW_AGAIN@PAGEOFF
    bl      convert_keyword_test
    cmp     x0, FALSE
    b.eq    convert_keyword_done__  ; next!
    b       convert_keyword_done    ; done!

    convert_keyword_done__:
    mov     x0, T_KW_DONE
    adrp    x1, KW_DONE@PAGE
    add     x1, x1, KW_DONE@PAGEOFF
    bl      convert_keyword_test
    cmp     x0, FALSE
    b.eq    convert_keyword_return  ; next!
    b       convert_keyword_done    ; done!

    convert_keyword_return:
    mov     x0, T_KW_RETURN
    adrp    x1, KW_RETURN@PAGE
    add     x1, x1, KW_RETURN@PAGEOFF
    bl      convert_keyword_test
    cmp     x0, FALSE
    b.eq    convert_keyword_true    ; next!
    b       convert_keyword_done    ; done!

    convert_keyword_true:
    mov     x0, T_BOOL
    adrp    x1, KW_TRUE@PAGE
    add     x1, x1, KW_TRUE@PAGEOFF
    bl      convert_keyword_test
    cmp     x0, FALSE
    b.eq    convert_keyword_false   ; next!
    mov     x0, x19
    mov     x1, TRUE
    bl      __j_Token_set_value
    b       convert_keyword_done    ; done!

    convert_keyword_false:
    mov     x0, T_BOOL
    adrp    x1, KW_FALSE@PAGE
    add     x1, x1, KW_FALSE@PAGEOFF
    bl      convert_keyword_test
    cmp     x0, FALSE
    b.eq    convert_keyword_null    ; next!
    mov     x0, x19
    mov     x1, FALSE
    bl      __j_Token_set_value
    b       convert_keyword_done    ; done!

    convert_keyword_null:
    mov     x0, T_INT
    adrp    x1, KW_NULL@PAGE
    add     x1, x1, KW_NULL@PAGEOFF
    bl      convert_keyword_test
    cmp     x0, FALSE
    b.eq    convert_keyword_done    ; next!
    mov     x0, x19
    mov     x1, NULL
    bl      __j_Token_set_value
    b       convert_keyword_done    ; done!

    convert_keyword_done:
    ; restore frame
    ldr     x20, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret
