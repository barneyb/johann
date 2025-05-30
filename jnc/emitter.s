/**
 * I provide an Emitter "class", which can process "statements" from a Parser.
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
err_bad_stmt: .asciz "; ERROR(%i): Bad statement %x at line %i, char %i\n"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3 ; 8-byte/64-bit alignment
NULL    = 0
TRUE    = 1
FALSE   = 0

.include "inc_token_table.s"

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
    bl      __j_Emitter_is_global               ; see if its global
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
