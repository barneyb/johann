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
    ? value                         ; a 64-bit "something"
}
*/
.set    OFF_TYPE    , 0
.set    OFF_LINE    , 8
.set    OFF_CHAR    , 16
.set    OFF_VALUE   , 24
.set    SIZEOF      , OFF_VALUE + 8

/* Token* new( int type ) */
.global __j_Token__new
__j_Token__new:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    ; end frame

    mov     x19, x0                 ; type
    mov     x0, SIZEOF              ; how much to allocate
    bl      __j_malloc              ; allocate
    stp     x19, xzr, [x0, OFF_TYPE]     ; initialize
    stp     xzr, xzr, [x0, OFF_CHAR]     ; initialize

    ; restore frame
    ldp     lr, x19, [sp], 0x10
    ret

/* void Token_drop( Token* t ) */
.global __j_Token_drop
__j_Token_drop:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    bl      __j_free                ; free t
    ldp     fp, lr, [sp], 0x10
    ret

/* int type( Token* t ) */
.global __j_Token_type
__j_Token_type:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    ; end frame
    ldr     x0, [x0, OFF_TYPE]

    ; restore frame
    ldp     lr, x19, [sp], 0x10
    ret

/* void set_type( Token* t, int type ) */
.global __j_Token_set_type
__j_Token_set_type:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    ; end frame
    str     x1, [x0, OFF_TYPE]

    ; restore frame
    ldp     lr, x19, [sp], 0x10
    ret

/* int line( Token* t ) */
.global __j_Token_line
__j_Token_line:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    ; end frame
    ldr     x0, [x0, OFF_LINE]

    ; restore frame
    ldp     lr, x19, [sp], 0x10
    ret

/* int char( Token* t ) */
.global __j_Token_char
__j_Token_char:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    ; end frame
    ldr     x0, [x0, OFF_CHAR]

    ; restore frame
    ldp     lr, x19, [sp], 0x10
    ret

/* void set_coords( Token* t, int line, int char ) */
.global __j_Token_set_coords
__j_Token_set_coords:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    ; end frame
    stp     x1, x2, [x0, OFF_LINE]

    ; restore frame
    ldp     lr, x19, [sp], 0x10
    ret

/* ? value( Token* t ) */
.global __j_Token_value
__j_Token_value:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    ; end frame
    ldr     x0, [x0, OFF_VALUE]

    ; restore frame
    ldp     lr, x19, [sp], 0x10
    ret

/* ?* value_ptr( Token* t ) */
.global __j_ick_Token_value_ptr
__j_ick_Token_value_ptr:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    ; end frame
    add     x0, x0, OFF_VALUE

    ; restore frame
    ldp     lr, x19, [sp], 0x10
    ret

/* void set_value( Token* t, ? value ) */
.global __j_Token_set_value
__j_Token_set_value:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    ; end frame
    str     x1, [x0, OFF_VALUE]

    ; restore frame
    ldp     lr, x19, [sp], 0x10
    ret
