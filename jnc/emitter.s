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
