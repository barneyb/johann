/**
 * I provide a Lexer "class" which tokenizes the characters from a Reader.
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
err_bad_token: .asciz "ERROR: Unrecognized token '"
.set    err_bad_token_len, . - err_bad_token

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align  3                           ; Make sure everything is 8-byte/64-bit aligned
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
    bl      _mem_alloc;_LOG              ; allocate
    stp     x19, xzr, [x0]          ; initialize
    str     xzr, [x0, OFF_CHAR]

    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* Token token( Lexer* lex ) */
.global _lexer_token
_lexer_token:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    stp     x22, x23, [sp, #-16]!
    ; end frame

    mov     x19, x0                 ; pointer -> this
    ldr     x20, [x19, OFF_READ]    ; load this.reader
    ldp     x21, x22, [x19, OFF_LINE]   ; load this.line_num and .char_pos

    token_skip_char:
    mov     x0, x20
    bl      _reader_is_eof          ; this.reader.is_eof()
    cmp     x0, FALSE
    b.ne    token_null
    mov     x0, x20
    bl      _reader_read            ; this.reader.read()

    ; see if it's a newline
    cmp     x0, '\n'
    b.ne    token_same_line
    token_handle_newline:
    add     x21, x21, #1            ; increment line_num
    mov     x22, xzr                ; zero char_pos
    stp     x21, x22, [x19, OFF_LINE]   ; store this.line_num and .char_pos
    b       token_skip_char         ; NEXT!

    add     x22, x22, #1            ; increment char_pos
    token_same_line:
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

    ; todo: record coords somewhere

    ; unambiguous single-character tokens are easy
    cmp     x0, T_OBRACE
    b.eq    token_punct
    cmp     x0, T_CBRACE
    b.eq    token_punct
    cmp     x0, T_PERCENT
    b.eq    token_punct
    cmp     x0, T_AMP
    b.eq    token_punct
    cmp     x0, T_STAR
    b.eq    token_punct
    cmp     x0, T_OPAREN
    b.eq    token_punct
    cmp     x0, T_CPAREN
    b.eq    token_punct
    cmp     x0, T_OBRACKET
    b.eq    token_punct
    cmp     x0, T_CBRACKET
    b.eq    token_punct
    cmp     x0, T_SEMI
    b.eq    token_punct
    cmp     x0, T_COLON
    b.eq    token_punct
    cmp     x0, T_COMMA
    b.eq    token_punct
    cmp     x0, T_DOT
    b.eq    token_punct
    cmp     x0, T_SLASH
    b.eq    token_punct
    cmp     x0, T_QUESTION
    b.eq    token_punct
    ; to-become-ambiguous characters tokens are easy as well (for now)
    cmp     x0, T_LT
    b.eq    token_punct
    cmp     x0, T_GT
    b.eq    token_punct
    cmp     x0, T_ASSIGN
    b.eq    token_punct
    cmp     x0, T_MINUS
    b.eq    token_punct
    cmp     x0, T_PLUS
    b.eq    token_punct
    str     xzr, [x19, OFF_POS]     ; store this.pos = 0 to "empty" the buffer
    cmp     x0, 'a'                 ; T_ID
    b.ge    token_id_ish
    cmp     x0, '0'                 ;  T_INT
    b.ge    token_int_ish
    cmp     x0, '\''                ;  T_CHAR
    b.ge    token_char
    cmp     x0, '"'                 ;  T_STRING
    b.ge    token_string

    token_id_ish:
    cmp     x0, 'z'
    b.le    token_id

    token_int_ish:
    cmp     x0, '9'
    b.le    token_int

    ; print the token that fell through
    mov     x23, x0                 ; save the token
    adrp    x0, err_bad_token@PAGE
    add     x0, x0, err_bad_token@PAGEOFF
    mov     x1, err_bad_token_len
    bl      _os_stdout              ; todo: send errors to STDERR....
    mov     x0, x23
    bl      _print_c
    mov     x0, '\''
    bl      _print_c
    bl      _println
    mov     x0, #17
    b       _os_exit

    token_punct:
    b       token_return

    token_int:
    mov     x1, x0                  ; pass first digit
    mov     x0, x20                 ; and the reader
    bl      lex_int
    ; todo: retain numeric value; don't convert to ASCII
    b       token_return

    token_id:
    mov     x1, x0                  ; pass first character
    mov     x0, x20                 ; and the reader
    bl      lex_identifier
    ; todo: transmute T_ID to T_KW_XXX as appropriate
    ; todo: transmute T_ID to T_BOOL as appropriate
    ldrb    w20, [x0]               ; todo: don't keep only first char
    bl      _mem_free
    mov     x0, x20
    b       token_return

    token_char:
    mov     x0, x20
    bl      _reader_read            ; the actual char
    mov     x23, x0
    mov     x0, x20
    bl      _reader_read            ; the second single quote
    mov     x0, x23
    b       token_return

    token_string:
    mov     x0, x20                 ; pass the reader
    bl      lex_string
    ldrb    w20, [x0]               ; todo: don't keep only first char
    bl      _mem_free
    mov     x0, x20
    b       token_return

    token_null:
    mov     x0, NULL

    token_return:
    ; todo: need to return a Token, not a character
    ; restore frame
    ldp     x22, x23, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

/* void destroy( Lexer* lex ) */
.global _lexer_destroy
_lexer_destroy:
    ; create frame
    str     lr, [sp, #-16]!
    ; end frame

    bl      _mem_free;_LOG

    ; restore frame
    ldr     lr, [sp], #16
    ret

; Eats characters from the Reader, up to and including the first newline.
/* void lex_comment( Reader* reader ) */
lex_comment:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> reader

    lex_comment_char:
    mov     x0, x19
    bl      _reader_is_eof          ; this.reader.is_eof()
    cmp     x0, FALSE
    b.ne    lex_comment_return      ; out of characters
    mov     x0, x19
    bl      _reader_read
    cmp     x0, '\n'
    b.eq    lex_comment_return
    b       lex_comment_char

    lex_comment_return:
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* int lex_int( Reader* reader, char first_digit ) */
lex_int:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> reader
    sub     x20, x1, '0'            ; convert digit to number
    mov     x21, #10                ; radix

    lex_int_char:
    ; forgo the EOF check - there's no valid syntax for that case.
    mov     x0, x19
    bl      _reader_peek            ; reader.peek()
    cmp     x0, '0'
    b.lt    lex_int_return
    cmp     x0, '9'
    b.gt    lex_int_return
    mov     x0, x19
    bl      _reader_read            ; consume the digit
    sub     x0, x0, '0'             ; convert digit to number
    madd    x20, x21, x20, x0       ; multiply by 10 and add digit value
    b       lex_int_char

    lex_int_return:
    mov     x0, x20
    ; restore frame
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
    bl      _mem_alloc
    mov     x20, x0                 ; pointer -> start of buffer
    mov     x21, x20                ; pointer -> buffer[pos] to write
    strb    w22, [x21], #1          ; put first char in the string

    lex_identifier_char:
    ; forgo the EOF check - there's no valid syntax for that case.
    mov     x0, x19
    bl      _reader_peek            ; reader.peek()
    cmp     x0, 'a'
    b.lt    lex_identifier_return
    cmp     x0, 'z'
    b.gt    lex_identifier_return
    mov     x0, x19
    bl      _reader_read            ; consume the char
    strb    w0, [x21], #1           ; add it to the string
    b       lex_identifier_char

    lex_identifier_return:
    mov     x0, NULL                ; null-terminator
    strb    w0, [x21], #1           ; add it to the string

;        ; print the identifier
;        mov     x0, '['
;        bl      _print_c
;        mov     x0, x20
;        bl      _print_z
;        mov     x0, ']'
;        bl      _print_c
;        bl      _println

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
    bl      _mem_alloc
    mov     x20, x0                 ; pointer -> start of buffer
    mov     x21, x20                ; pointer -> buffer[pos] to write

    lex_string_char:
    ; forgo the EOF check - there's no valid syntax for that case.
    mov     x0, x19
    bl      _reader_read            ; read a char
    cmp     x0, '"'
    b.eq    lex_string_return
    strb    w0, [x21], #1           ; add it to the string
    b       lex_string_char

    lex_string_return:
    mov     x0, NULL                ; null-terminator
    strb    w0, [x21], #1           ; add it to the string

;        ; print the string
;        mov     x0, '['
;        bl      _print_c
;        mov     x0, x20
;        bl      _print_z
;        mov     x0, ']'
;        bl      _print_c
;        bl      _println

    mov     x0, x20                 ; return pointer -> buffer
    ; restore frame
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret
