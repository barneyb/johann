/**
 * I provide a Token "class" which represents a single lexical token identified
 * by a Lexer "instance".
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3 ; 8-byte/64-bit alignment

/*
struct Token {
    int type                        ; type of token
    int line_num                    ; line of the source the token started on
    int char_offset                 ; position in the line the token started on
    ? value                         ; sumthin' or other. Numeric value? Pointer
                                    ; to a NTBS? A very short, inline NTBS? No
                                    ; one knows, other than eight-byte value!
}
*/
.set    OFF_TYPE    , 0
.set    OFF_LINE    , 8
.set    OFF_CHAR    , 16
.set    OFF_VALUE   , 24
.set    SIZEOF      , OFF_VALUE + 8

/* Token new( int type ) */
.global _Token_new
_Token_new:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame

    mov     x19, x0                 ; type
    mov     x0, SIZEOF              ; how much to allocate
    bl      _mem_alloc;_LOG              ; allocate
    stp     x19, xzr, [x0, OFF_TYPE]     ; initialize
    stp     xzr, xzr, [x0, OFF_CHAR]     ; initialize

    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* int type( Token* t ) */
.global _token_type
_token_type:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    ldr     x0, [x0, OFF_TYPE]

    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* void set_type( Token* t, int type ) */
.global _token_set_type
_token_set_type:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    str     x1, [x0, OFF_TYPE]

    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* int line( Token* t ) */
.global _token_line
_token_line:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    ldr     x0, [x0, OFF_LINE]

    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* int char( Token* t ) */
.global _token_char
_token_char:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    ldr     x0, [x0, OFF_CHAR]

    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* void set_coords( Token* t, int line, int char ) */
.global _token_set_coords
_token_set_coords:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    stp     x1, x2, [x0, OFF_LINE]

    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* ? value( Token* t ) */
.global _token_value
_token_value:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    ldr     x0, [x0, OFF_VALUE]

    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* ?* value_ptr( Token* t ) */
.global _token_value_ptr
_token_value_ptr:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    add     x0, x0, OFF_VALUE

    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* void set_value( Token* t, ? value ) */
.global _token_set_value
_token_set_value:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    str     x1, [x0, OFF_VALUE]

    ; restore frame
    ldp     lr, x19, [sp], #16
    ret
