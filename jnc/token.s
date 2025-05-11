/**
 * I provide a Token "class" which represents a single lexical token identified
 * by a Lexer "instance".
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3 ; 8-byte/64-bit alignment

.include "inc_token_table.s"

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

;            str x0, [sp, -0x10]!
;            mov x1, x0
;            adrp x0, msg_new@PAGE
;            add x0, x0, msg_new@PAGEOFF
;            bl __j_printf
;            ldr x0, [sp], 0x10

    ; restore frame
    ldp     lr, x19, [sp], 0x10
    ret

/* void Token_drop( Token* t ) */
.global __j_Token_drop
__j_Token_drop:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

;            .data
;            msg_new : .asciz "        ; New token  %p\n"
;            msg_drop: .asciz "        ; Drop token %p\n"
;            .text
;            str x0, [sp, -0x10]!
;            mov x1, x0
;            adrp x0, msg_drop@PAGE
;            add x0, x0, msg_drop@PAGEOFF
;            bl __j_printf
;            ldr x0, [sp], 0x10

    ldr     x1, [x0, OFF_TYPE]
    cmp     x1, T_STRING
    b.eq    drop_value
    cmp     x1, T_ID
    b.eq    drop_value
    b       drop_go

    drop_value:
    str     x0, [sp, -0x10]!
    ldr     x0, [x0, OFF_VALUE]
    bl      __j_free
    ldr     x0, [sp], 0x10

    drop_go:
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
