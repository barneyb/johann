/**
 * I provide a Lexer "class" which tokenizes the characters from a Reader.
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
.set    TRUE, 1
.set    FALSE, 0

err_bad_token: .asciz "; ERROR: Unrecognized token '"
err_long_id: .asciz "; ERROR: >7 char identifier '"
err_long_string: .asciz "; ERROR: >7 char string '"
at_line: .asciz "' at line "
at_char: .asciz ", char "

KW_AGAIN    : .asciz    "again"
KW_BOOL     : .asciz    "bool"
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
    Reader* reader                  ; pointer -> source of characters
    int line_num                    ; line of the source being lexed
    int char_pos                    ; position in the line
    int pos                         ; next buffer index to write
    [char] buf                      ; buffered bytes
}
*/
.set    OFF_READ, 0
.set    OFF_LINE, 8
.set    OFF_CHAR, 16
.set    OFF_POS , 24
.set    OFF_BUF , 32
.set    BUF_CAP , 8                     ; todo: embiggen when identifiers get longer
.set    SIZEOF  , OFF_BUF + BUF_CAP     ; buffer is always last

/* Lexer new( Reader* r ) */
.global _Lexer_new
_Lexer_new:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame

    mov     x19, x0                 ; stash pointer -> reader
    mov     x0, SIZEOF              ; how much to allocate
    bl      __j_malloc              ; allocate
    str     x19, [x0]               ; initialize
    mov     x19, #1
    stp     x19, xzr, [x0, OFF_LINE]

    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* Token token( Lexer* self ) */
.global _lexer_token
_lexer_token:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    stp     x22, x23, [sp, #-16]!
    str     x24, [sp, #-16]!
    ; end frame

    mov     x19, x0                 ; pointer -> this
    ldr     x20, [x19, OFF_READ]    ; load this.reader
    ldp     x21, x22, [x19, OFF_LINE]   ; load this.line_num and .char_pos

    token_skip_char:
    mov     x0, x20
    bl      __j_ick_reader_is_eof          ; this.reader.is_eof()
    cmp     x0, FALSE
    b.ne    token_null
    mov     x0, x20
    bl      __j_ick_reader_read            ; this.reader.read()

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
    mov     x0, x20
    mov     x1, '\n'
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
    ; to-become-ambiguous characters tokens are easy as well (for now)
    cmp     x0, T_ASSIGN
    b.eq    token_punct
    cmp     x0, T_BANG
    b.eq    token_punct
    cmp     x0, T_GT
    b.eq    token_punct
    cmp     x0, T_LT
    b.eq    token_punct
    cmp     x0, T_MINUS
    b.eq    token_punct
    cmp     x0, T_PLUS
    b.eq    token_punct
    ; multi-character tokens...
    str     xzr, [x19, OFF_POS]     ; store this.pos = 0 to "empty" the buffer
    cmp     x0, 'a'                 ; T_ID
    b.ge    token_id_ish
    cmp     x0, '0'                 ; T_INT
    b.ge    token_int_ish
    cmp     x0, '\''                ; T_CHAR
    b.ge    token_char
    cmp     x0, '"'                 ; T_STRING
    b.ge    token_string

    token_id_ish:
    cmp     x0, 'z'
    b.le    token_id

    token_int_ish:
    cmp     x0, '9'
    b.le    token_int

    ; print the char that fell through
    mov     x23, x0                 ; save the char
    adrp    x0, err_bad_token@PAGE
    add     x0, x0, err_bad_token@PAGEOFF
    bl      __j_print
    mov     x0, x23
    bl      __j_ick_print_c
    adrp    x0, at_line@PAGE
    add     x0, x0, at_line@PAGEOFF
    bl      __j_print
    mov     x0, x21
    bl      __j_ick_print_i
    adrp    x0, at_char@PAGE
    add     x0, x0, at_char@PAGEOFF
    bl      __j_print
    mov     x0, x22
    bl      __j_ick_print_i
    bl      __j_ick_println                ; end line
    mov     x0, #17
    b       __j_sys_exit

    token_punct:
    bl      __j_Token__new
    mov     x24, x0                 ; pointer -> token
    mov     x1, x21
    mov     x2, x22
    bl      __j_Token_set_coords
    mov     x0, x24
    b       token_return

    token_int:
    mov     x1, x0                  ; pass first digit
    mov     x0, x20                 ; and the reader
    bl      lex_digits
    mov     x23, x0                 ; stash pointer -> name
    mov     x0, T_INT
    bl      __j_Token__new
    mov     x24, x0                 ; pointer -> token
    mov     x1, x21
    mov     x2, x22
    bl      __j_Token_set_coords       ; set coords of start
    mov     x0, x23                 ; unstash name
    bl      _str2int
    mov     x1, x0
    mov     x0, x24
    bl      __j_Token_set_value        ; set value
    mov     x0, x23                 ; unstash name
    bl      _strlen
    ; todo: validate len
    sub     x0, x0, #1              ; first char was already counted
    add     x22, x22, x0            ; add the scanned char count
    str     x22, [x19, OFF_CHAR]    ; store this.char_pos
    mov     x0, x24
    b       token_return

    token_id:
    mov     x1, x0                  ; pass first character
    mov     x0, x20                 ; and the reader
    bl      lex_identifier
    mov     x23, x0                 ; stash pointer -> name
    mov     x0, T_ID
    bl      __j_Token__new
    mov     x24, x0                 ; pointer -> token
    mov     x1, x21
    mov     x2, x22
    bl      __j_Token_set_coords       ; set coords of start
    mov     x0, x24
    ldr     x1, [x23]               ; load first 8 bytes of name
    bl      __j_Token_set_value        ; set value
    mov     x0, x23                 ; unstash name
    bl      _strlen
    cmp     x0, #7
    b.gt    token_id_long
    sub     x0, x0, #1              ; first char was already counted
    add     x22, x22, x0            ; add the scanned char count
    str     x22, [x19, OFF_CHAR]    ; store this.char_pos
    mov     x0, x23                 ; unstash name
    bl      __j_free               ; free name
    mov     x0, x24
    bl      convert_keyword
    mov     x0, x24
    b       token_return
    token_id_long:
        adrp    x0, err_long_id@PAGE
        add     x0, x0, err_long_id@PAGEOFF
        bl      __j_print
        mov     x0, x23
        bl      __j_print
        adrp    x0, at_line@PAGE
        add     x0, x0, at_line@PAGEOFF
        bl      __j_print
        mov     x0, x21
        bl      __j_ick_print_i
        adrp    x0, at_char@PAGE
        add     x0, x0, at_char@PAGEOFF
        bl      __j_print
        mov     x0, x22
        bl      __j_ick_print_i
        bl      __j_ick_println                ; end line
        mov     x0, #18
        b       __j_sys_exit

    token_char:
    mov     x0, x20
    bl      __j_ick_reader_read            ; the actual char
    mov     x23, x0
    mov     x0, x20
    bl      __j_ick_reader_read            ; the second single quote
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
    mov     x0, x20                 ; pass the reader
    bl      lex_string
    mov     x23, x0                 ; stash pointer -> name
    mov     x0, T_STRING
    bl      __j_Token__new
    mov     x24, x0                 ; pointer -> token
    mov     x1, x21
    mov     x2, x22
    bl      __j_Token_set_coords       ; set coords of start
    mov     x0, x24
    ldr     x1, [x23]               ; load first 8 bytes of string
    bl      __j_Token_set_value        ; set value
    mov     x0, x23                 ; unstash name
    bl      _strlen
    cmp     x0, #7
    b.gt    token_string_long
    add     x0, x0, #1              ; and close quote (open was already counted)
    add     x22, x22, x0            ; add the scanned char count
    str     x22, [x19, OFF_CHAR]    ; store this.char_pos
    mov     x0, x23                 ; unstash name
    bl      __j_free               ; free name
    mov     x0, x24
    b       token_return
    token_string_long:
        adrp    x0, err_long_string@PAGE
        add     x0, x0, err_long_string@PAGEOFF
        bl      __j_print
        mov     x0, x23
        bl      __j_print
        adrp    x0, at_line@PAGE
        add     x0, x0, at_line@PAGEOFF
        bl      __j_print
        mov     x0, x21
        bl      __j_ick_print_i
        adrp    x0, at_char@PAGE
        add     x0, x0, at_char@PAGEOFF
        bl      __j_print
        mov     x0, x22
        bl      __j_ick_print_i
        bl      __j_ick_println                ; end line
        mov     x0, #19
        b       __j_sys_exit

    token_null:
    mov     x0, NULL

    token_return:
    ; restore frame
    ldr     x24, [sp], #16
    ldp     x22, x23, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

/* void destroy( Lexer* self ) */
.global _lexer_destroy
_lexer_destroy:
    ; create frame
    str     lr, [sp, #-16]!
    ; end frame

    bl      __j_free

    ; restore frame
    ldr     lr, [sp], #16
    ret

; Eats characters from the Reader, up to and including the next newline.
/* void lex_comment( Reader* reader ) */
lex_comment:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> reader

    lex_comment_char:
    mov     x0, x19
    bl      __j_ick_reader_is_eof          ; this.reader.is_eof()
    cmp     x0, FALSE
    b.ne    lex_comment_return      ; out of characters
    mov     x0, x19
    bl      __j_ick_reader_read
    cmp     x0, '\n'
    b.eq    lex_comment_return
    b       lex_comment_char

    lex_comment_return:
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* char* lex_digits( Reader* reader, char first_char ) */
lex_digits:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    str     x22, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> reader
    mov     x22, x1                 ; stash first char
    mov     x0, #21                 ; 64-bit int max len
    bl      __j_malloc
    mov     x20, x0                 ; pointer -> start of buffer
    mov     x21, x20                ; pointer -> buffer[pos] to write
    strb    w22, [x21], #1          ; put first char in the string

    lex_digits_char:
    ; forgo the EOF check - there's no valid syntax for that case.
    mov     x0, x19
    bl      __j_ick_reader_peek            ; reader.peek()
    cmp     x0, '0'
    b.lt    lex_digits_return
    cmp     x0, '9'
    b.gt    lex_digits_return
    mov     x0, x19
    bl      __j_ick_reader_read            ; consume the char
    strb    w0, [x21], #1           ; add it to the string
    b       lex_digits_char

    lex_digits_return:
    mov     x0, NULL                ; null-terminator
    strb    w0, [x21], #1           ; add it to the string

;        ; print the number
;        mov     x0, '('
;        bl      __j_ick_print_c
;        mov     x0, x20
;        bl      __j_print
;        mov     x0, ')'
;        bl      __j_ick_print_c
;        bl      __j_ick_println

    mov     x0, x20                 ; return pointer -> buffer
    ; restore frame
    ldr     x22, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

/* char* lex_identifier( Reader* reader, char first_char ) */
lex_identifier:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    str     x22, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> reader
    mov     x22, x1                 ; stash first char
    mov     x0, #256                ; todo: max identifier length
    bl      __j_malloc
    mov     x20, x0                 ; pointer -> start of buffer
    mov     x21, x20                ; pointer -> buffer[pos] to write
    strb    w22, [x21], #1          ; put first char in the string

    lex_identifier_char:
    ; forgo the EOF check - there's no valid syntax for that case.
    mov     x0, x19
    bl      __j_ick_reader_peek            ; reader.peek()
    cmp     x0, 'a'
    b.lt    lex_identifier_return
    cmp     x0, 'z'
    b.gt    lex_identifier_return
    mov     x0, x19
    bl      __j_ick_reader_read            ; consume the char
    strb    w0, [x21], #1           ; add it to the string
    b       lex_identifier_char

    lex_identifier_return:
    mov     x0, NULL                ; null-terminator
    strb    w0, [x21], #1           ; add it to the string

;        ; print the identifier
;        mov     x0, '['
;        bl      __j_ick_print_c
;        mov     x0, x20
;        bl      __j_print
;        mov     x0, ']'
;        bl      __j_ick_print_c
;        bl      __j_ick_println

    mov     x0, x20                 ; return pointer -> buffer
    ; restore frame
    ldr     x22, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

/* char* lex_string( Reader* reader ) */
lex_string:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> reader
    mov     x0, #4096               ; todo: max string literal length
    bl      __j_malloc
    mov     x20, x0                 ; pointer -> start of buffer
    mov     x21, x20                ; pointer -> buffer[pos] to write

    lex_string_char:
    ; forgo the EOF check - there's no valid syntax for that case.
    mov     x0, x19
    bl      __j_ick_reader_read            ; read a char
    cmp     x0, '"'
    b.eq    lex_string_return
    strb    w0, [x21], #1           ; add it to the string
    b       lex_string_char

    lex_string_return:
    mov     x0, NULL                ; null-terminator
    strb    w0, [x21], #1           ; add it to the string

;        ; print the string
;        mov     x0, '{'
;        bl      __j_ick_print_c
;        mov     x0, x20
;        bl      __j_print
;        mov     x0, '}'
;        bl      __j_ick_print_c
;        bl      __j_ick_println

    mov     x0, x20                 ; return pointer -> buffer
    ; restore frame
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

/* void convert_keyword( Token* token ) */
convert_keyword:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    str     x20, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> token
    bl      __j_ick_Token_value_ptr
    mov     x20, x0                 ; stash pointer -> token.value

    convert_keyword_fn:
    mov     x0, x20
    adrp    x1, KW_FN@PAGE
    add     x1, x1, KW_FN@PAGEOFF
    bl      _strcmp
    cmp     xzr, x0
    b.ne    convert_keyword_int     ; next!
    mov     x0, x19
    mov     x1, T_KW_FN
    bl      __j_Token_set_type
    b       convert_keyword_done    ; done!

    convert_keyword_int:
    mov     x0, x20
    adrp    x1, KW_INT@PAGE
    add     x1, x1, KW_INT@PAGEOFF
    bl      _strcmp
    cmp     xzr, x0
    b.ne    convert_keyword_char    ; next!
    mov     x0, x19
    mov     x1, T_KW_INT
    bl      __j_Token_set_type
    b       convert_keyword_done    ; done!

    convert_keyword_char:
    mov     x0, x20
    adrp    x1, KW_CHAR@PAGE
    add     x1, x1, KW_CHAR@PAGEOFF
    bl      _strcmp
    cmp     xzr, x0
    b.ne    convert_keyword_bool; next!
    mov     x0, x19
    mov     x1, T_KW_CHAR
    bl      __j_Token_set_type
    b       convert_keyword_done    ; done!

    convert_keyword_bool:
    mov     x0, x20
    adrp    x1, KW_BOOL@PAGE
    add     x1, x1, KW_BOOL@PAGEOFF
    bl      _strcmp
    cmp     xzr, x0
    b.ne    convert_keyword_void      ; next!
    mov     x0, x19
    mov     x1, T_KW_BOOL
    bl      __j_Token_set_type
    b       convert_keyword_done    ; done!

    convert_keyword_void:
    mov     x0, x20
    adrp    x1, KW_VOID@PAGE
    add     x1, x1, KW_VOID@PAGEOFF
    bl      _strcmp
    cmp     xzr, x0
    b.ne    convert_keyword_if      ; next!
    mov     x0, x19
    mov     x1, T_KW_VOID
    bl      __j_Token_set_type
    b       convert_keyword_done    ; done!

    convert_keyword_if:
    mov     x0, x20
    adrp    x1, KW_IF@PAGE
    add     x1, x1, KW_IF@PAGEOFF
    bl      _strcmp
    cmp     xzr, x0
    b.ne    convert_keyword_while   ; next!
    mov     x0, x19
    mov     x1, T_KW_IF
    bl      __j_Token_set_type
    b       convert_keyword_done    ; done!

    convert_keyword_while:
    mov     x0, x20
    adrp    x1, KW_WHILE@PAGE
    add     x1, x1, KW_WHILE@PAGEOFF
    bl      _strcmp
    cmp     xzr, x0
    b.ne    convert_keyword_again   ; next!
    mov     x0, x19
    mov     x1, T_KW_WHILE
    bl      __j_Token_set_type
    b       convert_keyword_done    ; done!

    convert_keyword_again:
    mov     x0, x20
    adrp    x1, KW_AGAIN@PAGE
    add     x1, x1, KW_AGAIN@PAGEOFF
    bl      _strcmp
    cmp     xzr, x0
    b.ne    convert_keyword_done__  ; next!
    mov     x0, x19
    mov     x1, T_KW_AGAIN
    bl      __j_Token_set_type
    b       convert_keyword_done    ; done!

    convert_keyword_done__:
    mov     x0, x20
    adrp    x1, KW_DONE@PAGE
    add     x1, x1, KW_DONE@PAGEOFF
    bl      _strcmp
    cmp     xzr, x0
    b.ne    convert_keyword_return  ; next!
    mov     x0, x19
    mov     x1, T_KW_DONE
    bl      __j_Token_set_type
    b       convert_keyword_done    ; done!

    convert_keyword_return:
    mov     x0, x20
    adrp    x1, KW_RETURN@PAGE
    add     x1, x1, KW_RETURN@PAGEOFF
    bl      _strcmp
    cmp     xzr, x0
    b.ne    convert_keyword_true    ; next!
    mov     x0, x19
    mov     x1, T_KW_RETURN
    bl      __j_Token_set_type
    b       convert_keyword_done    ; done!

    convert_keyword_true:
    mov     x0, x20
    adrp    x1, KW_TRUE@PAGE
    add     x1, x1, KW_TRUE@PAGEOFF
    bl      _strcmp
    cmp     xzr, x0
    b.ne    convert_keyword_false   ; next!
    mov     x0, x19
    mov     x1, T_BOOL
    bl      __j_Token_set_type
    mov     x0, x19
    mov     x1, TRUE
    bl      __j_Token_set_value
    b       convert_keyword_done    ; done!

    convert_keyword_false:
    mov     x0, x20
    adrp    x1, KW_FALSE@PAGE
    add     x1, x1, KW_FALSE@PAGEOFF
    bl      _strcmp
    cmp     xzr, x0
    b.ne    convert_keyword_null    ; next!
    mov     x0, x19
    mov     x1, T_BOOL
    bl      __j_Token_set_type
    mov     x0, x19
    mov     x1, FALSE
    bl      __j_Token_set_value
    b       convert_keyword_done    ; done!

    convert_keyword_null:
    mov     x0, x20
    adrp    x1, KW_NULL@PAGE
    add     x1, x1, KW_NULL@PAGEOFF
    bl      _strcmp
    cmp     xzr, x0
    b.ne    convert_keyword_done    ; next!
    mov     x0, x19
    mov     x1, T_INT               ; all nulls are integers!
    bl      __j_Token_set_type
    mov     x0, x19
    mov     x1, NULL
    bl      __j_Token_set_value
    b       convert_keyword_done    ; done!

    convert_keyword_done:
    ; restore frame
    ldr     x20, [sp], #16
    ldp     lr, x19, [sp], #16
    ret
