/**
 * I provide an Emitter "class", which can process "statements" from a Parser.
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
err_bad_stmt: .asciz "; ERROR(%i): Bad statement %x at line %i, char %i\n"
err_invalid_nesting: .asciz "; ERROR(%i): Invalid nesting %x at line %i, char %i\n"
err_unknown_symbol: .asciz "; ERROR(%i): Unknown symbol '%s' at line %i, char %i\n"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3 ; 8-byte/64-bit alignment
NULL    = 0
TRUE    = 1
FALSE   = 0

.include "inc_token_table.s"

OFF_SEQ     = 0
OFF_DEPTH   = 0x8
OFF_BLOCKS  = 0x10

SIZEOF_BLOCK  = 0x20

/* Block* __j_Emitter_enter_block( Emitter* self, int type ) */
.global __j_Emitter_enter_block
__j_Emitter_enter_block:
    ; create frame
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    stp     x19, x20, [sp, -0x10]!
    stp     x21, x22, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> type
    ldp     x21, x22, [x19, OFF_SEQ]; load seq and depth
    add     x21, x21, 1             ; increment seq

    add     x0, x19, OFF_BLOCKS     ; pointer -> stack of blocks
    mov     x1, SIZEOF_BLOCK        ; size of block
    madd    x0, x22, x1, x0         ; pointer -> block
    mov     x1, x20
    mov     x2, x21
    bl      __j_Block_init

    add     x22, x22, 1             ; increment depth
    stp     x21, x22, [x19, OFF_SEQ]; store seq and depth

    ; restore frame
    ldp     x21, x22, [sp], 0x10
    ldp     x19, x20, [sp], 0x10
    ldp     fp, lr, [sp], 0x10
    ret

/* Symbol* Emitter_lookup_symbol_for( Emitter* self, Token* id_token, bool allow_null ) */
.global __j_Emitter_lookup_symbol_for
__j_Emitter_lookup_symbol_for:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

    stp     x0, x1, [sp, -0x10]!
    mov     x0, x1
    bl      __j_Token_value         ; pointer -> name
    mov     x1, x0
    ldp     x0, x2, [sp], 0x10
    bl      lookup_symbol_by_name_and_token

    ldp     fp, lr, [sp], 0x10
    ret

/* Symbol* lookup_symbol_by_name_and_token( Emitter* self, char* name, Token* t, bool allow_null ) */
lookup_symbol_by_name_and_token:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    stp     x19, x20, [sp, -0x10]!
    stp     x1, x2, [sp, -0x10]!    ; store pointers -> name & -> t
    mov     x19, x0                 ; stash pointer -> this
    ldr     x20, [x19, OFF_DEPTH]   ; load depth
;        .data
;        asdf:.asciz "          ; LOOKUP name: '%s', type: %x, line: %i, char: %i, value: %x\n"
;        .text
;        ldp     x1, x6, [sp]
;        ldp     x2, x3, [x6]
;        ldp     x4, x5, [x6, 0x10]
;        adrp x0, asdf@PAGE
;        add x0, x0, asdf@PAGEOFF
;        bl __j_printf

    lookup_symbol_loop:
    sub     x20, x20, 1             ; decrement depth
    cmp     x20, #0
    b.lt    lookup_symbol_bad       ; out of blocks!
    add     x0, x19, OFF_BLOCKS     ; pointer -> stack of blocks
    mov     x1, SIZEOF_BLOCK        ; size of block
    madd    x0, x20, x1, x0         ; pointer -> block
    bl      __j_Block_symbols
    ldr     x1, [sp]                ; load pointer -> name
    bl      __j_Table_get
    cmp     x0, NULL
    b.ne    lookup_symbol_return
    b       lookup_symbol_loop

    lookup_symbol_bad:
        cmp     x3, FALSE
        b.ne    lookup_symbol_return
        ; munge the token for printing
        ldp     x1, x0, [sp]
        bl      __j_Token_value
        mov     x1, x0
        ldp     xzr, x0, [sp]
        bl      __j_Token_set_type
        adrp    x0, err_unknown_symbol@PAGE
        add     x0, x0, err_unknown_symbol@PAGEOFF
        ldp     xzr, x1, [sp]
        mov     x2, #23             ; error code
        bl      __j_jnc_panic       ; print and terminate

    lookup_symbol_return:
    add     sp, sp, 0x10            ; release locals
    ldp     x19, x20, [sp], 0x10
    ldp     fp, lr, [sp], 0x10
    ret

/* Block* innermost_block_of( Emitter* self, int type, Token* t ) */
.global __j_Emitter_innermost_block_of
__j_Emitter_innermost_block_of:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    stp     x22, x2, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> type
    ldr     x21, [x19, OFF_DEPTH]   ; load depth

    innermost_block_of_loop:
    sub     x21, x21, 1             ; decrement depth
    cmp     x21, #0
    b.lt    innermost_block_of_bad  ; out of blocks!
    add     x22, x19, OFF_BLOCKS    ; pointer -> stack of blocks
    mov     x1, SIZEOF_BLOCK        ; size of block
    madd    x22, x21, x1, x22       ; pointer -> block
    mov     x0, x22
    bl      __j_Block_type
    cmp     x0, x20
    b.ne    innermost_block_of_loop
    mov     x0, x22
    b       innermost_block_of_return

    innermost_block_of_bad:
        adrp    x0, err_invalid_nesting@PAGE
        add     x0, x0, err_invalid_nesting@PAGEOFF
        ldr     x1, [sp, 0x8]       ; load pointer -> token
        mov     x2, #37             ; error code
        bl      __j_jnc_panic       ; print and terminate

    innermost_block_of_return:
    ; restore frame
    ldr     x22, [sp], 0x10
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

/* Block* current_block( Emitter* self ) */
.global __j_Emitter_current_block
__j_Emitter_current_block:
current_block:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

    add     x1, x0, OFF_BLOCKS      ; pointer -> stack of blocks
    mov     x2, SIZEOF_BLOCK        ; size of block
    ldr     x3, [x0, OFF_DEPTH]     ; load depth
    sub     x3, x3, #1              ; decrement depth
    madd    x0, x2, x3, x1          ; pointer -> block

    ldp     fp, lr, [sp], 0x10
    ret

/* Block* leave_block( Emitter* self ) */
.global __j_Emitter_leave_block
__j_Emitter_leave_block:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    ldr     x20, [x19, OFF_DEPTH]   ; load depth
    sub     x20, x20, 1             ; decrement depth
    str     x20, [x19, OFF_DEPTH]   ; store depth
    add     x21, x19, OFF_BLOCKS    ; pointer -> stack of blocks
    mov     x1, SIZEOF_BLOCK        ; size of block
    madd    x21, x20, x1, x21       ; pointer -> block
    mov     x0, x21
    ; restore frame
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

/* bool is_global( Emitter* self ) */
.global __j_Emitter_is_global
__j_Emitter_is_global:
is_global:
    ; create frame
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    ; end frame
    ldr     x1, [x0, OFF_DEPTH]     ; load depth
    cmp     x1, #1
    b.eq    is_global_yep
    mov     x0, FALSE
    b       is_global_return

    is_global_yep:
    mov     x0, TRUE

    is_global_return:
    ; restore frame
    ldp     fp, lr, [sp], 0x10
    ret

.data
.global _j_gbl_IS_PUB
_j_gbl_IS_PUB: .byte 0 ; todo: this is so gross
.text

/* void emit( Emitter* self, [Token*] stmt ) */
.global __j_Emitter_emit
__j_Emitter_emit:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    str     x22, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer

    ldr     x21, [x20]              ; stash pointer -> first token
    mov     x0, x21
    bl      __j_Token_type
    adrp    x7, _j_gbl_IS_PUB@PAGE
    add     x7, x7, _j_gbl_IS_PUB@PAGEOFF
    cmp     x0, T_KW_PUB
    b.ne    __emit_noviz
        mov     x1, TRUE
        strb    w1, [x7]
        ldr     x21, [x20, 0x8]!    ; stash pointer -> new "first" token
        mov     x0, x21
        bl      __j_Token_type
        b       __emit_proceed
    __emit_noviz:
        mov     x1, FALSE
        strb    w1, [x7]
    __emit_proceed:
    mov     x22, x0                 ; stash type of first token

    cmp     x22, T_SEMI
    b.eq    __emit_return__         ; well that was kind of silly...

    __emit_fn:
    cmp     x22, T_KW_FN
    b.ne    __emit_int              ; next!
    mov     x0, x19
    mov     x1, x20
    bl      __j_Emitter_do_fn                   ; this.__j_Emitter_do_fn( buffer )
    b       __emit_return__

    __emit_int:
    cmp     x22, T_KW_INT
    b.ne    __emit_char             ; next!
    mov     x0, x19
    mov     x1, x20
    bl      __j_Emitter_do_decl                 ; this.__j_Emitter_do_decl( buffer )
    b       __emit_return__

    __emit_char:
    cmp     x22, T_KW_CHAR
    b.ne    __emit_bool             ; next!
    mov     x0, x19
    mov     x1, x20
    bl      __j_Emitter_do_decl                 ; this.__j_Emitter_do_decl( buffer )
    b       __emit_return__

    __emit_bool:
    cmp     x22, T_KW_BOOL
    b.ne    __emit_void             ; next!
    mov     x0, x19
    mov     x1, x20
    bl      __j_Emitter_do_decl                 ; this.__j_Emitter_do_decl( buffer )
    b       __emit_return__

    __emit_void:
    cmp     x22, T_KW_VOID
    b.ne    __emit_while            ; next!
    mov     x0, x19
    mov     x1, x20
    bl      __j_Emitter_do_decl                 ; this.__j_Emitter_do_decl( buffer )
    b       __emit_return__

    __emit_while:
    cmp     x22, T_KW_WHILE
    b.ne    __emit_again            ; next!
    mov     x0, x19
    mov     x1, x20
    bl      __j_Emitter_do_while                ; this.__j_Emitter_do_while( buffer )
    b       __emit_return__

    __emit_again:
    cmp     x22, T_KW_AGAIN
    b.ne    __emit_done             ; next!
    mov     x0, x19
    mov     x1, x20
    bl      __j_Emitter_do_again                ; this.__j_Emitter_do_again( buffer )
    b       __emit_return__

    __emit_done:
    cmp     x22, T_KW_DONE
    b.ne    __emit_if               ; next!
    mov     x0, x19
    mov     x1, x20
    bl      __j_Emitter_do_done                 ; this.__j_Emitter_do_done( buffer )
    b       __emit_return__

    __emit_if:
    cmp     x22, T_KW_IF
    b.ne    __emit_return           ; next!
    mov     x0, x19
    mov     x1, x20
    bl      __j_Emitter_do_if                   ; this.__j_Emitter_do_if( buffer )
    b       __emit_return__

    __emit_return:
    cmp     x22, T_KW_RETURN
    b.ne    __emit_close_block      ; next!
    mov     x0, x19
    mov     x1, x20
    bl      __j_Emitter_return               ; this.do_return( buffer )
    b       __emit_return__

    __emit_close_block:
    cmp     x22, T_CBRACE
    b.ne    __emit_star             ; next!
    mov     x0, x19
    mov     x1, x20
    bl      __j_Emitter_do_close_block          ; this.__j_Emitter_do_close_block( buffer )
    b       __emit_return__

    __emit_star:
    cmp     x22, T_STAR
    b.ne    __emit_second_token     ; next!
    mov     x0, x19
    mov     x1, x20
    bl      __j_Emitter_do_assign_pointer       ; this.__j_Emitter_do_assign_pointer( buffer )
    b       __emit_return__

    ; now need to check the second token...

    __emit_second_token:
    ldr     x21, [x20, #8]          ; stash pointer -> second token
    mov     x0, x21
    bl      __j_Token_type
    mov     x22, x0                 ; stash type of second token

    __emit_assign:
    cmp     x22, T_ASSIGN
    b.ne    __emit_call             ; next!
    mov     x0, x19
    mov     x1, x20
    bl      __j_Emitter_do_assign               ; this.__j_Emitter_do_assign( buffer )
    b       __emit_return__

    __emit_call:
    cmp     x22, T_OPAREN
    b.ne    __emit_bad__; next!
    mov     x0, x19
    mov     x1, x20
    bl      __j_Emitter_do_call                 ; this.__j_Emitter_do_call( buffer )
    b       __emit_return__

    __emit_bad__:
        adrp    x0, err_bad_stmt@PAGE
        add     x0, x0, err_bad_stmt@PAGEOFF    ; pointer -> msg
        mov     x1, x21             ; pointer -> token
        mov     x2, #27             ; error code
        bl      __j_jnc_panic            ; print and terminate

    __emit_return__:
    ; restore frame
    ldr     x22, [sp], 0x10
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_global_pub: .asciz "    .global _j_gbl_%s\n"
tmpl_width_byte: .asciz ".byte"
tmpl_width_quad: .asciz ".quad"
tmpl_width_string: .asciz ".asciz"
tmpl_global_raw: .asciz "    .data\n\
        _j_gbl_%s: %s %i\n\
    .text\n"
tmpl_global_char: .asciz "    .data\n\
        _j_gbl_%s: %s '%c'\n\
    .text\n"
tmpl_global_string: .asciz "    .data\n\
        _j_gbl_%s: %s \"%s\"\n\
    .text\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* Symbol* vardecl( Emitter* self, [Token*] buffer ) */
.global __j_Emitter_vardecl
__j_Emitter_vardecl:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    stp     x19, x20, [sp, -0x10]!
    stp     x21, x22, [sp, -0x10]!
    stp     x23, x24, [sp, -0x10]!
    mov     x19, x0                 ; stash pointer -> self
    mov     x20, x1                 ; stash pointer -> buffer

    sub     x21, x20, 0x8           ; i = -1 (poor man's for loop)
    mov     x24, #-2                ; nptr = -2
    vardecl_again:
    add     x21, x21, 0x8           ; i++
    add     x24, x24, #1            ; nptr++
    ldr     x0, [x21]               ; load pointer -> tokens[i]
    bl      __j_Token_type          ; token.type()
;        .data
;        asdf:.asciz "; vd: token %x %i\n"
;        .text
;        mov x2, x0
;        mov x1, x0
;        adrp x0, asdf@PAGE
;        add x0, x0, asdf@PAGEOFF
;        bl __j_printf
;        ldr x0, [x21]
;        bl __j_Token_type
    cmp     x0, T_ID
    b.ne    vardecl_again

    ; find the name
    ldr     x23, [x21]              ; load pointer -> id token
    mov     x0, x23
    bl      __j_Token_value
    stp     x0, x23, [sp, -0x10]!   ; store pointers -> name & -> id token
    ; get the current block
    mov     x0, x19
    bl      is_global
    cmp     x0, FALSE
    b.ne    vardecl_global
        mov     x0, x19
        mov     x1, T_KW_FN
        mov     x2, x23
        bl      __j_Emitter_innermost_block_of
        b       vardecl_got_block
    vardecl_global:
        mov     x0, x19
        bl      current_block           ; self.current_block()

    vardecl_got_block:
    ; get its symbol table
    bl      __j_Block_symbols
    mov     x23, x0                 ; stash pointer -> symbols
    ; if already defined, panic
    ldr     x1, [sp]                ; load pointer -> name
    bl      __j_Table_contains
    cmp     x0, FALSE
    b.eq    vardecl_non_dupe
        ; build a panic tuple on the stack, since the token itself won't work
        ldp     x1, x0, [sp]
        bl      __j_Token_value
        mov     x1, x0
        ldp     xzr, x0, [sp]
        bl      __j_Token_set_type
        adrp    x0, _j_gbl_ERR_DUPE_DECL@PAGE
        add     x0, x0, _j_gbl_ERR_DUPE_DECL@PAGEOFF    ; pointer -> msg
        ldp     xzr, x1, [sp]
        mov     x2, #22             ; error code
        bl      __j_jnc_panic       ; print and terminate
    vardecl_non_dupe:
    ; find base type
    ldr     x0, [x20]               ; load pointer -> tokens[0]
    bl      __j_Token_type          ; token.type()
    ; build symbol
    mov     x1, x24
    bl      __j_Symbol__new
    mov     x24, x0                 ; stash pointer -> symbol

    mov     x0, x19
    bl      is_global
    cmp     x0, FALSE
    b.ne    vardecl_global_offset
        ; set its register/offset
        mov     x0, x23                 ; pointer -> symbols
        bl      __j_Table_size
        cmp     x0, #8                  ; max number of local vars
        b.lt    vardecl_few_enough
            ; todo: allocate stack space on demand, rather than locking to eight
            ; munge the token for paniking
            ldp     x1, x0, [sp]
            bl      __j_Token_value
            mov     x1, x0
            ldp     xzr, x0, [sp]
            bl      __j_Token_set_type
            adrp    x0, _j_gbl_ERR_TOO_MANY_LOCALS@PAGE
            add     x0, x0, _j_gbl_ERR_TOO_MANY_LOCALS@PAGEOFF    ; pointer -> msg
            ldp     xzr, x1, [sp]
            mov     x2, #24             ; error code
            bl      __j_jnc_panic       ; print and terminate
        vardecl_few_enough:
        add     x1, x0, #1              ; local vars are one-indexed
        bl      vardecl_set_offset
    vardecl_global_offset:
        mov     x1, NULL

    vardecl_set_offset:
        mov     x0, x24
    bl      __j_Symbol_set_offset

    ; add to table
    ldr     x0, [sp]                ; load pointer -> name
    bl      __j_strclone            ; clone it, so the token can be dropped
    mov     x2, x24                 ; pointer -> symbol
    mov     x1, x0                  ; cloned name
    mov     x0, x23                 ; pointer -> symbols
    bl      __j_Table_put
;        .data
;        ns:.asciz "; added '%s' to table w/ type %x width %d and nptr %d\n"
;        .text
;        ldp x3, x4, [x24]           ; load width and nptr - nasty!
;        ldr x0, [x20]               ; load pointer -> tokens[0]
;        bl __j_Token_type           ; token.type()
;        mov x2, x0
;        ldr x1, [sp]
;        adrp x0, ns@PAGE
;        add x0, x0, ns@PAGEOFF
;        bl __j_printf

    mov     x0, x23                 ; return pointer -> symbols
    add     sp, sp, 0x10            ; release locals

    ldp     x23, x24, [sp], 0x10
    ldp     x21, x22, [sp], 0x10
    ldp     x19, x20, [sp], 0x10
    ldp     fp, lr, [sp], 0x10
    ret

/* void do_decl( Emitter* self, [Token*] buffer ) */
.global __j_Emitter_do_decl
__j_Emitter_do_decl:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    stp     x22, x23, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer

    bl      __j_Emitter_vardecl
    bl      __j_Symbol_offset ; todo: this has GOT to be a defect?!
    mov     x23, x0                 ; stash width

    ; scan until find an ASSIGN or SEMI
    add     x21, x20, #8            ; first token is type
    do_decl_again:
    ldr     x0, [x21, #8]!          ; stash pointer -> next token
    bl      __j_Token_type          ; token.type()
    cmp     x0, T_ASSIGN
    b.eq    do_decl_delegate
    cmp     x0, T_SEMI
    b.eq    do_decl_return          ; no initializer
    b       do_decl_again

    do_decl_delegate:
    mov     x0, x19
    bl      is_global               ; see if its global
    cmp     x0, FALSE
    b.ne    do_decl_global

    ; go back one and delegate to __j_Emitter_do_assign
    sub     x1, x21, #8             ; go back one token (to the name)
    mov     x0, x19
    bl      __j_Emitter_do_assign
    b       do_decl_return

    ; go back one and set up a named data value
    do_decl_global:
    ldr     x20, [x21, #8]          ; stash pointer -> value token
    ldr     x22, [x21, #-8]         ; stash pointer -> name token
    mov     x0, x20
    bl      __j_Token_type          ; token.type()
    mov     x21, x0                 ; stash token type

    ; set up the template params
    mov     x0, x22                 ; pointer -> name token
    bl      __j_Token_value         ; pointer -> value
    str     x0, [sp, -0x10]!        ; store pointer -> name
    mov     x0, x20                 ; pointer -> value token
    bl      __j_Token_value         ; pointer -> value
    mov     x3, x0
    cmp     x23, #1
    b.eq    do_decl_byte_width
        adrp    x2, tmpl_width_quad@PAGE
        add     x2, x2, tmpl_width_quad@PAGEOFF
        b       do_decl_width_ready
    do_decl_byte_width:
        adrp    x2, tmpl_width_byte@PAGE
        add     x2, x2, tmpl_width_byte@PAGEOFF
    do_decl_width_ready:
    ldr     x1, [sp], 0x10          ; load pointer -> name

    cmp     x21, T_BOOL
    b.eq    do_decl_raw
    cmp     x21, T_CHAR
    b.eq    do_decl_char
    cmp     x21, T_INT
    b.eq    do_decl_raw
    cmp     x21, T_STRING
    b.eq    do_decl_string

    do_decl_bad:
        adrp    x0, _j_gbl_ERR_DUPE_DECL@PAGE
        add     x0, x0, _j_gbl_ERR_DUPE_DECL@PAGEOFF    ; pointer -> msg
        mov     x1, x20             ; pointer -> token
        mov     x2, #26             ; error code
        bl      __j_jnc_panic       ; print and terminate

    do_decl_raw:
    adrp    x0, tmpl_global_raw@PAGE
    add     x0, x0, tmpl_global_raw@PAGEOFF
    b       do_decl_emit_global

    do_decl_char:
    adrp    x0, tmpl_global_char@PAGE
    add     x0, x0, tmpl_global_char@PAGEOFF
    b       do_decl_emit_global

    do_decl_string:
    adrp    x0, tmpl_global_string@PAGE
    add     x0, x0, tmpl_global_string@PAGEOFF
    adrp    x2, tmpl_width_string@PAGE
    add     x2, x2, tmpl_width_string@PAGEOFF
    b       do_decl_emit_global

    do_decl_emit_global:
    mov     x22, x1                 ; stash pointer -> name
    bl      __j_printf
    adrp    x23, _j_gbl_IS_PUB@PAGE
    add     x23, x23, _j_gbl_IS_PUB@PAGEOFF
    ldrb    w23, [x23]
    cmp     x23, FALSE
    b.eq    do_decl_return
        adrp    x0, tmpl_global_pub@PAGE
        add     x0, x0, tmpl_global_pub@PAGEOFF
        mov     x1, x22
        bl      __j_printf

    do_decl_return:
    ; restore frame
    ldp     x22, x23, [sp], 0x10
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret
