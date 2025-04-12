/**
 * I provide a Parser "class" which processes Tokens from a Lexer.
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
found_semi: .asciz "; semicolon w/ "
found_open_brace: .asciz "; open brace w/ "
found_close_brace: .asciz "; close brace w/ "

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align  3                           ; Make sure everything is 8-byte/64-bit aligned
.set    NULL, 0

.include "inc_token_table.s"

/*
struct Parser {
    Lexer* lexer                    ; pointer -> source of Tokens
    int pos                         ; next buffer index to write
    [Token*] buf                    ; buffered tokens
}
*/
.set    OFF_LEX , 0
.set    OFF_POS , 8
.set    OFF_BUF , 16
.set    BUF_CAP , 25
.set    SIZEOF  , OFF_BUF + BUF_CAP * 8 ; buffer is always last

/* Parser new( Lexer* lex ) */
.global _Parser_new
_Parser_new:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame

    mov     x19, x0                 ; stash pointer -> lexer
    mov     x0, SIZEOF              ; how much to allocate
    bl      _mem_alloc;_LOG              ; allocate
    stp     x19, xzr, [x0]          ; initialize lexer & pos
    str     xzr, [x0, OFF_BUF]      ; put a null in the buffer

    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* void parse( Parser* self ) */
.global _parser_parse
_parser_parse:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x21, x25, [sp, #-16]!
    ; end frame

    mov     x19, x0                 ; stash pointer -> this

    ; build an emitter to send "statements" to
    bl      _Emitter_new
    mov     x21, x0                 ; stash pointer -> emitter

    parse_next:
    mov     x0, x19
    bl      load_buffer             ; this.load_buffer()
    ; see if we're done
    ldr     x25, [x19, OFF_BUF]     ; load pointer -> first token
;            mov     x0, x25
;            bl      _int2str
;            bl      _print_z
;            bl      _println                ; end line
    cmp     x25, NULL
    b.eq    parse_return            ; zero tokens - we're done!
    ; figure out what kind of statement it is
    mov     x0, x21
    add     x1, x19, OFF_BUF        ; load pointer -> this.buffer
    bl      _emitter_emit           ; this.emitter.emit( this.buffer )
    ; free all the tokens
    mov     x0, x19
    bl      free_buffer             ; this.free_buffer()
    b       parse_next

    parse_return:
    mov     x0, x21
    bl      _emitter_destroy        ; emitter.destroy()
    ; restore frame
    ldp     x21, x25, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

/* void free_buffer( Parser* self ) */
free_buffer:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x21, x25, [sp, #-16]!
    ; end frame

    mov     x19, x0                 ; stash pointer -> this
    ldr     x25, [x19, OFF_POS]     ; load pos
;            mov     x0, x25
;            bl      _int2str
;            bl      _print_z
;            bl      _println                ; end line
    add     x21, x19, OFF_BUF       ; pointer to buffer
;            mov     x0, x21
;            bl      _int2str
;            bl      _print_z
;            bl      _println                ; end line
    free_buffer_loop:
    cmp     x25, xzr
    b.eq    free_buffer_done
    sub     x25, x25, #1
    mov     x1, #8                  ; sizeof element
    mul     x0, x25, x1             ; offset in buffer
    add     x0, x21, x0             ; address in buffer
    ldr     x0, [x0]                ; load pointer from buffer
    bl      _mem_free;_LOG               ; free the token
    b       free_buffer_loop
    free_buffer_done:
    str     x25, [x19, OFF_POS]     ; store
;            mov     x0, x25
;            bl      _int2str
;            bl      _print_z
;            bl      _println                ; end line

    ; restore frame
    ldp     x21, x25, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

/* void load_buffer( Parser* self ) */
load_buffer:
    ; create frame
    stp     lr, x19, [sp, #-16]!    ; this
    stp     x20, x21, [sp, #-16]!   ; lexer & buffer
    stp     x24, x25, [sp, #-16]!   ; token & pos
    ; end frame

    mov     x19, x0                 ; stash pointer -> this
    ldr     x20, [x19, OFF_LEX]     ; load pointer -> lexer
    add     x21, x19, OFF_BUF       ; pointer -> buffer
    mov     x25, #0                 ; start at zero

;            mov     x0, x21
;            bl      _int2str
;            bl      _print_z
;            bl      _println                ; end line

    load_buffer_token:
    ; next token
    mov     x0, x20
    bl      _lexer_token            ; lex.token()
    cmp     x0, NULL
    b.eq    load_buffer_return
    mov     x24, x0                 ; stash pointer -> token

            ; print the token
            mov     x0, ';'
            bl      _print_c
            mov     x0, ' '
            bl      _print_c
            mov     x0, x24
            bl      _token_type
            bl      _print_c                ; get and print token type as char
            mov     x0, ' '
            bl      _print_c
            mov     x0, x24
            bl      _token_line
            bl      _int2str
            bl      _print_z
            mov     x0, ','
            bl      _print_c
            mov     x0, x24
            bl      _token_char
            bl      _int2str
            bl      _print_z
            ; and the value, as appropriate
            mov     x0, x24
            bl      _token_type
            cmp     x0, T_INT
            b.eq    _token_val_int
            cmp     x0, T_ID
            b.eq    _token_val_id
            cmp     x0, T_CHAR
            b.eq    _token_val_char
            cmp     x0, T_STRING
            b.eq    _token_val_string
            cmp     x0, 0x100
            b.ge    _token_val_id   ; keywords are identifiers
            b       _token_eol
            _token_val_int:
            mov     x0, ':'
            bl      _print_c
            mov     x0, ' '
            bl      _print_c
            mov     x0, x24
            bl      _token_value
            bl      _int2str
            bl      _print_z
            b       _token_eol
            _token_val_id:
            mov     x0, ':'
            bl      _print_c
            mov     x0, ' '
            bl      _print_c
            mov     x0, x24
            bl      _token_value_ptr
            bl      _print_z
            b       _token_eol
            _token_val_char:
            mov     x0, ':'
            bl      _print_c
            mov     x0, ' '
            bl      _print_c
            mov     x0, '\''
            bl      _print_c
            mov     x0, x24
            bl      _token_value
            bl      _print_c
            mov     x0, '\''
            bl      _print_c
            b       _token_eol
            _token_val_string:
            mov     x0, ':'
            bl      _print_c
            mov     x0, ' '
            bl      _print_c
            mov     x0, '"'
            bl      _print_c
            mov     x0, x24
            bl      _token_value_ptr
            bl      _print_z
            mov     x0, '"'
            bl      _print_c
            b       _token_eol
            _token_eol:
;            bl      _println                ; end line

    mov     x1, #8                  ; sizeof element
    mul     x0, x25, x1             ; offset in buffer
    add     x0, x21, x0             ; address in buffer
    str     x24, [x0]               ; put pointer in buffer
    add     x25, x25, #1            ; i++
    str     x25, [x19, OFF_POS]     ; store

    ; if semi, obrace, or cbrace, we're done
    mov     x0, x24
    bl      _token_type
    cmp     w0, T_SEMI
    b.eq    load_buffer_semi
    cmp     w0, T_OBRACE
    b.eq    load_buffer_open
    cmp     w0, T_CBRACE
    b.eq    load_buffer_close
    b       load_buffer_token

    load_buffer_semi:
            adrp    x0, found_semi@PAGE
            add     x0, x0, found_semi@PAGEOFF
            bl      _print_z
            mov     x0, x25
            bl      _int2str
            bl      _print_z
            bl      _println
            b       load_buffer_return
    load_buffer_open:
            adrp    x0, found_open_brace@PAGE
            add     x0, x0, found_open_brace@PAGEOFF
            bl      _print_z
            mov     x0, x25
            bl      _int2str
            bl      _print_z
            bl      _println
            b       load_buffer_return
    load_buffer_close:
            adrp    x0, found_close_brace@PAGE
            add     x0, x0, found_close_brace@PAGEOFF
            bl      _print_z
            mov     x0, x25
            bl      _int2str
            bl      _print_z
            bl      _println
            b       load_buffer_return

    load_buffer_return:
    ; add a null terminator
    mov     x1, #8                  ; sizeof element
    mul     x0, x25, x1             ; offset in buffer
    add     x0, x21, x0             ; address in buffer
    str     xzr, [x0]               ; put NULL in buffer
    add     x25, x25, #1            ; i++
    str     x25, [x19, OFF_POS]     ; store
    ; restore frame
    ldp     x24, x25, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

/* void destroy( Parser* self ) */
.global _parser_destroy
_parser_destroy:
    ; create frame
    str     lr, [sp, #-16]!
    ; end frame

    bl      _mem_free;_LOG

    ; restore frame
    ldr     lr, [sp], #16
    ret
