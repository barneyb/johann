/**
 * I provide a Parser "class" which processes Tokens from a Lexer.
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.data
p_token: .asciz "; %c %i,%i"
p_token_int: .asciz ": %i"
p_token_char: .asciz ": '%c'"
p_token_id: .asciz ": %s"
p_token_string: .asciz ": \"%s\""
p_token_true: .asciz ": true"
p_token_false: .asciz ": false"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.text
.align 3 ; 8-byte/64-bit alignment
.set    NULL, 0
.set    FALSE, 0
.set    TRUE, 1

.include "inc_token_table.s"

/*
struct Parser {
    Lexer* lexer                    ; pointer -> source of Tokens
    int pos                         ; next buffer index to write
    [Token*] buf                    ; buffered tokens
}
*/
OFF_LEX     = 0
OFF_POS     = 0x8
OFF_BUF     = 0x10
BUF_CAP     = 25
SIZEOF      = OFF_BUF + BUF_CAP * 8 ; buffer is always last

/* Parser new( Lexer* lex ) */
.global __j_Parser__new
__j_Parser__new:
    ; create frame
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    str     x19, [sp, -0x10]!
    ; end frame

    mov     x19, x0                 ; stash pointer -> lexer
    mov     x0, SIZEOF              ; how much to allocate
    bl      __j_malloc              ; allocate
    str     x19, [x0]               ; initialize lexer
    stp     xzr, xzr, [x0, OFF_POS] ; initialize pos & buffer

    ; restore frame
    ldr     x19, [sp], 0x10
    ldp     fp, lr, [sp], 0x10
    ret

/* void parse( Parser* self ) */
.global __j_Parser_parse
__j_Parser_parse:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x21, x25, [sp, -0x10]!
    ; end frame

    mov     x19, x0                 ; stash pointer -> this

    ; build an emitter to send "statements" to
    bl      __j_Emitter__new
    mov     x21, x0                 ; stash pointer -> emitter

    parse_next:
    mov     x0, x19
    bl      load_buffer             ; this.load_buffer()
    ; see if we're done
    ldr     x25, [x19, OFF_BUF]     ; load pointer -> first token
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
    bl      __j_Emitter_drop        ; emitter.destroy()
    ; restore frame
    ldp     x21, x25, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

/* void free_buffer( Parser* self ) */
free_buffer:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x21, x25, [sp, -0x10]!
    ; end frame

    mov     x19, x0                 ; stash pointer -> this
    ldr     x25, [x19, OFF_POS]     ; load pos
    sub     x25, x25, #1            ; don't need to free the null
    add     x21, x19, OFF_BUF       ; pointer to buffer
    free_buffer_loop:
    cmp     x25, xzr
    b.eq    free_buffer_done
    sub     x25, x25, #1
    mov     x1, #8                  ; sizeof element
    mul     x0, x25, x1             ; offset in buffer
    add     x0, x21, x0             ; address in buffer
    ldr     x0, [x0]                ; load pointer from buffer
    cmp     x0, NULL
    b.ne    free_buffer_drop
    b       free_buffer_loop
    free_buffer_drop:
    bl      __j_Token_drop          ; drop the token
    b       free_buffer_loop
    free_buffer_done:
    str     x25, [x19, OFF_POS]     ; store

    ; restore frame
    ldp     x21, x25, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

/* void load_buffer( Parser* self ) */
load_buffer:
    ; create frame
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    str     x19, [sp, -0x10]!       ; this
    stp     x20, x21, [sp, -0x10]!  ; lexer & buffer
    stp     x24, x25, [sp, -0x10]!  ; token & pos
    ; end frame

    mov     x19, x0                 ; stash pointer -> this
    ldr     x20, [x19, OFF_LEX]     ; load pointer -> lexer
    add     x21, x19, OFF_BUF       ; pointer -> buffer
    mov     x25, #0                 ; start at zero

    load_buffer_token:
    ; next token
    mov     x0, x20
    bl      __j_Lexer_token         ; lex.token()
    cmp     x0, NULL
    b.eq    load_buffer_return
    mov     x24, x0                 ; stash pointer -> token

            ; print the token
            mov     x0, x24
            bl      __j_Token_type
            stp     xzr, x0, [sp, -0x10]!
            mov     x0, x24
            bl      __j_Token_line
            str     x0, [sp]
            mov     x0, x24
            bl      __j_Token_char
            mov     x3, x0
            ldp     x2, x1, [sp], 0x10
            adrp    x0, p_token@PAGE
            add     x0, x0, p_token@PAGEOFF
            bl      __j_printf
            ; and the value, as appropriate
            mov     x0, x24
            bl      __j_Token_type
            cmp     x0, T_INT
            b.eq    _token_val_int
            cmp     x0, T_ID
            b.eq    _token_val_id
            cmp     x0, T_CHAR
            b.eq    _token_val_char
            cmp     x0, T_STRING
            b.eq    _token_val_string
            cmp     x0, T_BOOL
            b.eq    _token_val_bool
            cmp     x0, 0x100
            b.ge    _token_val_id   ; keywords are identifiers
            b       _token_eol
            _token_val_int:
            mov     x0, x24
            bl      __j_Token_value
            mov     x1, x0
            adrp    x0, p_token_int@PAGE
            add     x0, x0, p_token_int@PAGEOFF
            bl      __j_printf
            b       _token_eol
            _token_val_id:
            mov     x0, x24
            bl      __j_Token_value
            mov     x1, x0
            adrp    x0, p_token_id@PAGE
            add     x0, x0, p_token_id@PAGEOFF
            bl      __j_printf
            b       _token_eol
            _token_val_char:
            mov     x0, x24
            bl      __j_Token_value
            mov     x1, x0
            adrp    x0, p_token_char@PAGE
            add     x0, x0, p_token_char@PAGEOFF
            bl      __j_printf
            b       _token_eol
            _token_val_string:
            mov     x0, x24
            bl      __j_Token_value
            mov     x1, x0
            adrp    x0, p_token_string@PAGE
            add     x0, x0, p_token_string@PAGEOFF
            bl      __j_printf
            b       _token_eol
            _token_val_bool:
            mov     x0, x24
            bl      __j_Token_value
            cmp     x0, FALSE
            b.eq    _token_val_bool_false
            adrp    x0, p_token_false@PAGE
            add     x0, x0, p_token_false@PAGEOFF
            bl      __j_printf
            b       _token_eol
            _token_val_bool_false:
            adrp    x0, p_token_true@PAGE
            add     x0, x0, p_token_true@PAGEOFF
            bl      __j_printf
            b       _token_eol
            _token_eol:

    mov     x1, #8                  ; sizeof element
    mul     x0, x25, x1             ; offset in buffer
    add     x0, x21, x0             ; address in buffer
    str     x24, [x0]               ; put pointer in buffer
    add     x25, x25, #1            ; i++
    str     x25, [x19, OFF_POS]     ; store

    ; if semi, obrace, or cbrace, we're done
    mov     x0, x24
    bl      __j_Token_type
    cmp     w0, T_SEMI
    b.eq    load_buffer_return
    cmp     w0, T_OBRACE
    b.eq    load_buffer_return
    cmp     w0, T_CBRACE
    b.eq    load_buffer_return
    b       load_buffer_token

    load_buffer_return:
    mov     x0, '\n'
    bl      __j_putchar
    ; add a null terminator
    mov     x1, #8                  ; sizeof element
    mul     x0, x25, x1             ; offset in buffer
    add     x0, x21, x0             ; address in buffer
    str     xzr, [x0]               ; put NULL in buffer
    add     x25, x25, #1            ; i++
    str     x25, [x19, OFF_POS]     ; store
    ; restore frame
    ldp     x24, x25, [sp], 0x10
    ldp     x20, x21, [sp], 0x10
    ldr     x19, [sp], 0x10
    ldp     fp, lr, [sp], 0x10
    ret

/* void destroy( Parser* self ) */
.global __j_Parser_drop
__j_Parser_drop:
    ; create frame
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    ; end frame

    bl      __j_free

    ; restore frame
    ldp     fp, lr, [sp], 0x10
    ret
