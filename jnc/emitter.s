/**
 * I provide an Emitter "class", which can process "statements" from a Parser.
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
err_bad_stmt: .asciz "; ERROR: Bad statement at line "
err_bad_expr: .asciz "; ERROR: Bad expression at line "
err_bad_token: .asciz "; ERROR: Bad token at line "
err_bad_operator: .asciz "; ERROR: Bad operator at line "
err_invalid_nesting: .asciz "; ERROR: Invalid nesting "
at_char: .asciz ", char "

tmpl_prelude: .asciz "    .text
    .align  3
    .set NULL, 0
    .set TRUE, 1
    .set FALSE, 0"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align  3                           ; Make sure everything is 8-byte/64-bit aligned
.set    NULL    , 0
.set    TRUE    , 1
.set    FALSE   , 0
.set    C2R     , 49                ; amount to subtract from a char to get its register #

.include "inc_token_table.s"

/*
struct Emitter {
    int seq                         ; sequence for unique label names
    int depth
    [Block] blocks                  ; array/stack of "lexical" Blocks
}
*/
.set    OFF_SEQ     , 0
.set    OFF_DEPTH   , 8
.set    OFF_BLOCKS  , 16
.set    BLOCKS_CAP  , 10
.set    SIZEOF      , OFF_BLOCKS + BLOCKS_CAP * SIZEOF_BLOCK    ; blocks is always last

/* Emitter new( ) */
.global _Emitter_new
_Emitter_new:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame

    mov     x0, SIZEOF              ; how much to allocate
    bl      _mem_alloc;_LOG              ; allocate
    mov     x19, x0                 ; stash pointer -> this
    stp     xzr, xzr, [x0]          ; initialize seq and depth

    adrp    x0, tmpl_prelude@PAGE
    add     x0, x0, tmpl_prelude@PAGEOFF
    bl      _println_z

    mov     x0, x19
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/*
struct Block {
    int type                        ; type of the block, identified by its token
    int id                          ; unique id num of the block
}
*/
.set    B_OFF_TYPE    , 0
.set    B_OFF_ID      , 8
.set    SIZEOF_BLOCK, B_OFF_ID + 8

/* int id( Block* b ) */
block_id:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    ldr     x0, [x0, B_OFF_ID]

    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* int type( Block* b ) */
block_type:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    ldr     x0, [x0, B_OFF_TYPE]

    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* Block* enter_block( Emitter* self, int type ) */
enter_block:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    str     x22, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> type
    ldp     x21, x22, [x19, OFF_SEQ]; load seq and depth
    add     x21, x21, 1             ; increment seq

    add     x0, x19, OFF_BLOCKS     ; pointer -> stack of blocks
    mov     x1, SIZEOF_BLOCK        ; size of block
    madd    x0, x22, x1, x0         ; pointer -> block
    stp     x20, x21, [x0]          ; initialize type and id

    add     x22, x22, 1             ; increment depth
    stp     x21, x22, [x19, OFF_SEQ]; store seq and depth

    ; restore frame
    ldr     x22, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

/* Block* innermost_block_of( Emitter* self, int type ) */
innermost_block_of:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    str     x22, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> type
    ldr     x21, [x19, OFF_DEPTH]   ; load depth
    sub     x21, x21, 1             ; decrement depth

    innermost_block_of_loop:
    cmp     x21, #0
    b.lt    innermost_block_of_bad  ; out of blocks!
    add     x22, x19, OFF_BLOCKS    ; pointer -> stack of blocks
    mov     x1, SIZEOF_BLOCK        ; size of block
    madd    x22, x21, x1, x22       ; pointer -> block
    mov     x0, x22
    bl      block_type
    cmp     x0, x20
    b.ne    innermost_block_of_loop
    mov     x0, x22
    b       innermost_block_of_return

    innermost_block_of_bad:
        adrp    x0, err_invalid_nesting@PAGE
        add     x0, x0, err_invalid_nesting@PAGEOFF
        bl      _print_z
        mov     x0, x20
        bl      _print_h
        bl      _println
        mov     x0, #37
        b       _os_exit

    innermost_block_of_return:
    ; restore frame
    ldr     x22, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

/* Block* leave_block( Emitter* self ) */
leave_block:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
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
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

/* int seqnum( Emitter* self ) */
seqnum:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    ldr     x19, [x0, OFF_SEQ]      ; load seq
    add     x19, x19, 1             ; increment seq
    str     x19, [x0, OFF_SEQ]      ; store seq
    mov     x0, x19
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* bool is_global( Emitter* self ) */
is_global:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    ldr     x19, [x0, OFF_DEPTH]   ; load depth
    cmp     x19, #0
    b.eq    is_global_yep
    mov     x0, FALSE
    b       is_global_return

    is_global_yep:
    mov     x0, TRUE

    is_global_return:
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* void emit( Emitter* self, [Token*] stmt ) */
.global _emitter_emit
_emitter_emit:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    str     x22, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer

    ldr     x21, [x20]              ; stash pointer -> first token
    mov     x0, x21
    bl      _token_type
    mov     x22, x0                 ; stash type of first token

    __emit_fn:
    cmp     x22, T_KW_FN
    b.ne    __emit_int              ; next!
    mov     x0, x19
    mov     x1, x20
    bl      do_fn                   ; this.do_fn( buffer )
    b       __emit_return__

    __emit_int:
    cmp     x22, T_KW_INT
    b.ne    __emit_char             ; next!
    mov     x0, x19
    mov     x1, x20
    bl      do_decl                 ; this.do_decl( buffer )
    b       __emit_return__

    __emit_char:
    cmp     x22, T_KW_CHAR
    b.ne    __emit_bool             ; next!
    mov     x0, x19
    mov     x1, x20
    bl      do_decl                 ; this.do_decl( buffer )
    b       __emit_return__

    __emit_bool:
    cmp     x22, T_KW_BOOL
    b.ne    __emit_while            ; next!
    mov     x0, x19
    mov     x1, x20
    bl      do_decl                 ; this.do_decl( buffer )
    b       __emit_return__

    __emit_while:
    cmp     x22, T_KW_WHILE
    b.ne    __emit_if               ; next!
    mov     x0, x19
    mov     x1, x20
    bl      do_while                ; this.do_while( buffer )
    b       __emit_return__

    __emit_if:
    cmp     x22, T_KW_IF
    b.ne    __emit_return           ; next!
    mov     x0, x19
    mov     x1, x20
    bl      do_if                   ; this.do_if( buffer )
    b       __emit_return__

    __emit_return:
    cmp     x22, T_KW_RETURN
    b.ne    __emit_close_block      ; next!
    mov     x0, x19
    mov     x1, x20
    bl      do_return               ; this.do_return( buffer )
    b       __emit_return__

    __emit_close_block:
    cmp     x22, T_CBRACE
    b.ne    __emit_second_token     ; next!
    mov     x0, x19
    mov     x1, x20
    bl      do_close_block          ; this.do_close_block( buffer )
    b       __emit_return__

    ; now need to check the second token...

    __emit_second_token:
    ldr     x21, [x20, #8]          ; stash pointer -> second token
    mov     x0, x21
    bl      _token_type
    mov     x22, x0                 ; stash type of second token

    __emit_assign:
    cmp     x22, T_ASSIGN
    b.ne    __emit_call             ; next!
    mov     x0, x19
    mov     x1, x20
    bl      do_assign               ; this.do_assign( buffer )
    b       __emit_return__

    __emit_call:
    cmp     x22, T_OPAREN
    b.ne    __emit_bad__; next!
    mov     x0, x19
    mov     x1, x20
    bl      do_call                 ; this.do_call( buffer )
    b       __emit_return__

    __emit_bad__:
        adrp    x0, err_bad_stmt@PAGE
        add     x0, x0, err_bad_stmt@PAGEOFF    ; pointer -> msg
        mov     x1, x21             ; pointer -> token
        mov     x2, #27             ; error code
        bl      do_panic            ; print and terminate

    __emit_return__:
    ; restore frame
    ldr     x22, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
s_main: .asciz "main"
tmpl_main: .asciz "    .global _main
    _main:
        bl      __j_main
        b       _os_exit
"

.macro tmpl_sec r=x21
    mov     x0, \r
    bl      _print_z                ; print segment
    mov     x0, \r
    bl      _strlen                 ; get its length
    add     x0, x0, #1
    add     \r, \r, x0              ; advance to the next segment
.endm

tmpl_fn_intro: .asciz "    .global __j_\0
    __j_\0:
        ; create frame
        stp     lr, x19, [sp, #-16]!
        stp     x20, x21, [sp, #-16]!
        stp     x22, x23, [sp, #-16]!
        stp     x24, x25, [sp, #-16]!
        stp     x26, x27, [sp, #-16]!
        ; end frame"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_fn( Emitter* self, [Token*] buffer ) */
do_fn:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    stp     x22, x23, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer
    adrp    x21, tmpl_fn_intro@PAGE ; pointer -> template
    add     x21, x21, tmpl_fn_intro@PAGEOFF
    ldr     x0, [x20, #8]           ; load pointer -> name token
    bl      _token_value_ptr        ; token.value_ptr()
    mov     x22, x0                 ; stash pointer -> name
    mov     x0, x19
    mov     x1, T_KW_FN
    bl      enter_block             ; this.enter_block()
    mov     x23, x0                 ; stash pointer -> block

    ; see if we need to introduce main
    mov     x0, x22
    adrp    x1, s_main@PAGE
    add     x1, x1, s_main@PAGEOFF
    bl      _strcmp
    cmp     x0, #0
    b.ne    do_fn_intro
    adrp    x0, tmpl_main@PAGE
    add     x0, x0, tmpl_main@PAGEOFF
    bl      _println_z

    do_fn_intro:
    tmpl_sec
    mov     x0, x22
    bl      _print_z
    tmpl_sec
    mov     x0, x22
    bl      _print_z
    tmpl_sec
    bl      _println

    ; restore frame
    ldp     x22, x23, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_if_intro: .asciz "\0
        cmp     x0, FALSE
        b.eq    _if_\0_done"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_if( Emitter* self, [Token*] buffer ) */
do_if:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    str     x22, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer
    adrp    x21, tmpl_if_intro@PAGE   ; pointer -> template
    add     x21, x21, tmpl_if_intro@PAGEOFF
    mov     x0, x19
    mov     x1, T_KW_IF
    bl      enter_block             ; this.enter_block()
    bl      block_id
    mov     x22, x0                 ; stash current block id

    tmpl_sec
    mov     x0, x19
    add     x1, x20, #8             ; pointer -> condition token
    bl      do_expr
    tmpl_sec
    mov     x0, x22
    bl      _print_i
    tmpl_sec
    bl      _println

    ; restore frame
    ldr     x22, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_while_intro: .asciz "        _while_\0_again:
\0
        cmp     x0, FALSE
        b.eq    _while_\0_done"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_while( Emitter* self, [Token*] buffer ) */
do_while:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    str     x22, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer
    adrp    x21, tmpl_while_intro@PAGE   ; pointer -> template
    add     x21, x21, tmpl_while_intro@PAGEOFF
    mov     x0, x19
    mov     x1, T_KW_WHILE
    bl      enter_block             ; this.enter_block()
    bl      block_id
    mov     x22, x0                 ; stash current block id

    tmpl_sec
    mov     x0, x22
    bl      _print_i
    tmpl_sec
    mov     x0, x19
    add     x1, x20, #8             ; pointer -> condition token
    bl      do_expr
    tmpl_sec
    mov     x0, x22
    bl      _print_i
    tmpl_sec
    bl      _println

    ; restore frame
    ldr     x22, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_return: .asciz "        b       _return_"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_return( Emitter* self, [Token*] buffer ) */
do_return:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    stp     x22, x23, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer
    adrp    x21, tmpl_return@PAGE   ; pointer -> template
    add     x21, x21, tmpl_return@PAGEOFF
    mov     x1, T_KW_FN
    bl      innermost_block_of
    bl      block_id
    mov     x22, x0                 ; stash current block id

    mov     x0, x19
    add     x1, x20, #8            ; pointer -> buffer[1] (pointer -> value token)
    bl      do_expr
    tmpl_sec
    mov     x0, x22
    bl      _print_i
    bl      _println

    ; restore frame
    ldp     x22, x23, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_global_int: .asciz "    .data
        _j_gbl_\0: .xword \0
    .text"
tmpl_global_char: .asciz "    .data
        _j_gbl_\0: .xword '\0'
    .text"
tmpl_global_string: .asciz "    .data
        _j_gbl_\0: .asciz \"\0\"
    .text"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_decl( Emitter* self, [Token*] buffer ) */
do_decl:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    stp     x22, x23, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer

    ; scan until find an ASSIGN
    add     x21, x20, #8            ; first token is type
    do_decl_again:
    ldr     x0, [x21, #8]!          ; stash pointer -> next token
    bl      _token_type             ; token.type()
    cmp     x0, T_ASSIGN
    b.eq    do_decl_delegate
    b       do_decl_again

    do_decl_delegate:
    mov     x0, x19
    bl      is_global               ; see if its global
    cmp     x0, FALSE
    b.ne    do_decl_global

    ; go back one and delegate to do_assign
    sub     x1, x21, #8             ; go back one token (to the name)
    mov     x0, x19
    bl      do_assign
    b       do_decl_return

    ; go back one and set up a named data value
    do_decl_global:
    ldr     x20, [x21, #8]          ; stash pointer -> value token
    ldr     x22, [x21, #-8]         ; stash pointer -> name token
    mov     x0, x20
    bl      _token_type             ; token.type()
    mov     x21, x0                 ; stash token type

    cmp     x21, T_BOOL
    b.eq    do_decl_bool
    cmp     x21, T_CHAR
    b.eq    do_decl_char
    cmp     x21, T_INT
    b.eq    do_decl_int
    cmp     x21, T_STRING
    b.eq    do_decl_string

    do_decl_bad:
        adrp    x0, err_bad_token@PAGE
        add     x0, x0, err_bad_token@PAGEOFF    ; pointer -> msg
        mov     x1, x20             ; pointer -> token
        mov     x2, #26             ; error code
        bl      do_panic            ; print and terminate

    do_decl_bool:                  ; these two happen to be the same
    do_decl_int:
    adrp    x21, tmpl_global_int@PAGE
    add     x21, x21, tmpl_global_int@PAGEOFF
    tmpl_sec
    mov     x0, x22                 ; pointer -> name token
    bl      _token_value_ptr        ; pointer -> value
    bl      _print_z
    tmpl_sec
    mov     x0, x20                 ; pointer -> value token
    bl      _token_value            ; pointer -> value
    bl      _print_i
    tmpl_sec
    bl      _println
    b       do_decl_return

    do_decl_char:
    adrp    x21, tmpl_global_char@PAGE
    add     x21, x21, tmpl_global_char@PAGEOFF
    tmpl_sec
    mov     x0, x22                 ; pointer -> name token
    bl      _token_value_ptr        ; pointer -> value
    bl      _print_z
    tmpl_sec
    mov     x0, x20                 ; pointer -> value token
    bl      _token_value            ; pointer -> value
    bl      _print_c
    tmpl_sec
    bl      _println
    b       do_decl_return

    do_decl_string:
    adrp    x21, tmpl_global_string@PAGE
    add     x21, x21, tmpl_global_string@PAGEOFF
    tmpl_sec
    mov     x0, x22                 ; pointer -> name token
    bl      _token_value_ptr        ; pointer -> value
    bl      _print_z
    tmpl_sec
    mov     x0, x20                 ; pointer -> value token
    bl      _token_value_ptr        ; pointer -> value
    bl      _print_z
    tmpl_sec
    bl      _println
    b       do_decl_return

    do_decl_return:
    ; restore frame
    ldp     x22, x23, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_assign: .asciz "\0        mov     x2\0, x0 ; assign"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_assign( Emitter* self, [Token*] buffer ) */
do_assign:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer
    adrp    x21, tmpl_assign@PAGE   ; pointer -> template
    add     x21, x21, tmpl_assign@PAGEOFF

    tmpl_sec
    mov     x0, x19
    add     x1, x20, #16            ; pointer -> buffer[2] (the RHS)
    bl      do_expr
    tmpl_sec
    ldr     x0, [x20]               ; pointer -> token
    bl      _token_value_ptr        ; pointer -> name
    ldrb    w0, [x0]                ; first char of name
    sub     w0, w0, C2R             ; convert lower alpha to digit
    bl      _print_c
    tmpl_sec
    bl      _println

    ; restore frame
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_fn_outro: .asciz "        mov      x0, #0             ; if no return, use zero
        _return_\0:
        ; restore frame
        ldp     x26, x27, [sp], #16
        ldp     x24, x25, [sp], #16
        ldp     x22, x23, [sp], #16
        ldp     x20, x21, [sp], #16
        ldp     lr, x19, [sp], #16
        ret"
tmpl_if_outro: .asciz "        _if_\0_done:"
tmpl_while_outro: .asciz "        b     _while_\0_again
        _while_\0_done:"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_close_block( Emitter* self, [Token*] buffer ) */
do_close_block:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    stp     x22, x23, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer
    bl      leave_block             ; this.leave_block()
    mov     x22, x0                 ; stash pointer -> block
    bl      block_id                ; block.id()
    mov     x23, x0                 ; stash id
    mov     x0, x22
    bl      block_type              ; block.type()

    cmp     x0, T_KW_FN
    b.ne    do_close_block_if
    adrp    x21, tmpl_fn_outro@PAGE ; pointer -> template
    add     x21, x21, tmpl_fn_outro@PAGEOFF
    tmpl_sec
    mov     x0, x23
    bl      _print_i
    tmpl_sec
    bl      _println
    b       do_close_block_return

    do_close_block_if:
    cmp     x0, T_KW_IF
    b.ne    do_close_block_while
    adrp    x21, tmpl_if_outro@PAGE ; pointer -> template
    add     x21, x21, tmpl_if_outro@PAGEOFF
    tmpl_sec
    mov     x0, x23
    bl      _print_i
    tmpl_sec
    bl      _println
    b       do_close_block_return

    do_close_block_while:
    cmp     x0, T_KW_WHILE
    b.ne    do_close_block_return
    adrp    x21, tmpl_while_outro@PAGE ; pointer -> template
    add     x21, x21, tmpl_while_outro@PAGEOFF
    tmpl_sec
    mov     x0, x23
    bl      _print_i
    tmpl_sec
    mov     x0, x23
    bl      _print_i
    tmpl_sec
    bl      _println
    b       do_close_block_return

    do_close_block_return:
    ; restore frame
    ldp     x22, x23, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_call: .asciz "        bl       __j_"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_call( Emitter* self, [Token*] buffer ) */
do_call:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    stp     x22, x23, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer
    ; todo: call params!
    adrp    x21, tmpl_call@PAGE
    add     x21, x21, tmpl_call@PAGEOFF
    ldr     x0, [x20]               ; load pointer -> name token
    bl      _token_value_ptr        ; token.value_ptr()
    mov     x22, x0                 ; stash pointer -> name

    tmpl_sec
    mov     x0, x22
    bl      _println_z

    ; restore frame
    ldp     x22, x23, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

/* void do_expr( Emitter* self, [Token*] buffer ) */
do_expr:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    stp     x22, x23, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer
    ldr     x22, [x20, #8]          ; stash pointer -> second token
    mov     x0, x22
    bl      _token_type
    mov     x23, x0                 ; type of second token

    ; if second token is SEMI, it's a copy
    cmp     x23, T_SEMI
    b.ne    do_expr_cond
    mov     x0, x19
    ldr     x1, [x20]               ; pointer -> first token
    bl      do_token
    b       do_expr_return
    ; if second token is OBRACE, it's a condition
    do_expr_cond:
    cmp     x23, T_OBRACE
    b.ne    do_expr_call
    mov     x0, x19
    ldr     x1, [x20]               ; pointer -> first token
    bl      do_token
    b       do_expr_return
    ; if second token is OPAREN, it's a function call
    do_expr_call:
    cmp     x23, T_OPAREN
    b.ne    do_expr_bool
    mov     x0, x19
    mov     x1, x20
    bl      do_call
    b       do_expr_return
    ; if second token is EQ, LT, GT, PLUS, MINUS, SLASH, STAR, PERCENT, do binary op
    do_expr_bool:
    cmp     x23, T_EQ
    b.eq    do_expr_binop
    cmp     x23, T_LT
    b.eq    do_expr_binop
    cmp     x23, T_GT
    b.eq    do_expr_binop
    cmp     x23, T_PLUS
    b.eq    do_expr_binop
    cmp     x23, T_MINUS
    b.eq    do_expr_binop
    cmp     x23, T_SLASH
    b.eq    do_expr_binop
    cmp     x23, T_STAR
    b.eq    do_expr_binop
    cmp     x23, T_PERCENT
    b.eq    do_expr_binop
    b       do_expr_first_token
    do_expr_binop:
    mov     x0, x19
    mov     x1, x20
    bl      do_binary_op
    b       do_expr_return

    ; now the first token
    do_expr_first_token:
    ldr     x22, [x20]              ; stash pointer -> first token
    mov     x0, x22
    bl      _token_type
    mov     x23, x0                 ; type of first token
;        bl _print_h
;        bl _println
    ; if the first token is BANG, MINUS, STAR, do unary op
    do_expr_deref:
    cmp     x23, T_BANG
    b.eq    do_expr_unop
    cmp     x23, T_MINUS
    b.eq    do_expr_unop
    cmp     x23, T_STAR
    b.eq    do_expr_unop
    b       do_expr_bad
    do_expr_unop:
    mov     x0, x19
    mov     x1, x20
    bl      do_unary_op
    b       do_expr_return

    do_expr_bad:
        adrp    x0, err_bad_expr@PAGE
        add     x0, x0, err_bad_expr@PAGEOFF    ; pointer -> msg
        mov     x1, x22             ; pointer -> token
        mov     x2, #28             ; error code
        bl      do_panic            ; print and terminate

    do_expr_return:
    ; restore frame
    ldp     x22, x23, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

/* void do_panic( char* msg, Token* token, int code ) */
do_panic:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    ; end frame
    mov     x19, x1                 ; stash pointer to token
    mov     x20, x2                 ; stash code

    bl      _print_z                ; print message
    mov     x0, x19
    bl      _token_line
    bl      _print_i                ; print line num
    adrp    x0, at_char@PAGE
    add     x0, x0, at_char@PAGEOFF
    bl      _print_z
    mov     x0, x19
    bl      _token_char
    bl      _print_i                ; print char pos
    bl      _println
    mov     x0, x20                 ; set status code
    b       _os_exit                ; terminate

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_un_not:    .asciz "        cmp     x0, FALSE
        b.ne    expr_\0_was_true
        mov     x0, TRUE
        b       expr_\0_end
        expr_\0_was_true:
        mov     x0, FALSE
        expr_\0_end:"
tmpl_un_negate: .asciz "        neg     x0, x0"
tmpl_un_deref:  .asciz "        ldr     x0, [x0]"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_unary_op( Emitter* self, [Token*] buffer ) */
do_unary_op:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer

    ; second token is the operand
    mov     x0, x19
    ldr     x1, [x20, #8]
    bl      do_token

    ; first token is the operator
    ldr     x0, [x20]
    bl      _token_type             ; token.type()
    mov     x21, x0                 ; stash token type

    cmp     x21, T_BANG
    b.eq    do_un_not
    cmp     x21, T_MINUS
    b.eq    do_un_neg
    cmp     x21, T_STAR
    b.eq    do_un_deref

    do_un_bad:
        adrp    x0, err_bad_operator@PAGE
        add     x0, x0, err_bad_operator@PAGEOFF    ; pointer -> msg
        ldr     x1, [x20]           ; pointer -> token
        mov     x2, #29             ; error code
        bl      do_panic            ; print and terminate

    do_un_not:
    adrp    x21, tmpl_un_not@PAGE
    add     x21, x21, tmpl_un_not@PAGEOFF
    mov     x0, x19
    bl      seqnum
    mov     x20, x0
    tmpl_sec
    mov     x0, x20
    bl      _print_i
    tmpl_sec
    mov     x0, x20
    bl      _print_i
    tmpl_sec
    mov     x0, x20
    bl      _print_i
    tmpl_sec
    mov     x0, x20
    bl      _print_i
    tmpl_sec
    bl      _println
    b       do_un_return
    do_un_neg:
    adrp    x21, tmpl_un_negate@PAGE
    add     x21, x21, tmpl_un_negate@PAGEOFF
    b       do_un_emit
    do_un_deref:
    adrp    x21, tmpl_un_deref@PAGE
    add     x21, x21, tmpl_un_deref@PAGEOFF
    b       do_un_emit

    do_un_emit:
    tmpl_sec
    bl      _println

    do_un_return:
    ; restore frame
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_bin_push:  .asciz "        str     x0, [sp, #-16]!"
tmpl_bin_pop_x1:.asciz "        ldr     x1, [sp], #16"

tmpl_bin_add:   .asciz "        add     x0, x0, x1"
tmpl_bin_sub:   .asciz "        sub     x0, x0, x1"
tmpl_bin_mul:   .asciz "        cannot multiply x0 * x1"
tmpl_bin_div:   .asciz "        cannot divide x0 / x1"
tmpl_bin_mod:   .asciz "        cannot remainder x0 % x1"
tmpl_bin_gt:    .asciz "        cmp     x0, x1
        b.gt    expr_\0
        mov     x0, FALSE
        b       expr_\0_end
        expr_\0:
        mov     x0, TRUE
        expr_\0_end:"
tmpl_bin_lt:    .asciz "        cmp     x0, x1
        b.lt    expr_\0
        mov     x0, FALSE
        b       expr_\0_end
        expr_\0:
        mov     x0, TRUE
        expr_\0_end:"
tmpl_bin_eq:    .asciz "        cmp     x0, x1
        b.eq    expr_\0
        mov     x0, FALSE
        b       expr_\0_end
        expr_\0:
        mov     x0, TRUE
        expr_\0_end:"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_binary_op( Emitter* self, [Token*] buffer ) */
do_binary_op:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer

    ; third token is an operand
    mov     x0, x19
    ldr     x1, [x20, #16]
    bl      do_token
    adrp    x0, tmpl_bin_push@PAGE
    add     x0, x0, tmpl_bin_push@PAGEOFF
    bl      _println_z

    ; first token is an operand
    mov     x0, x19
    ldr     x1, [x20]
    bl      do_token

    adrp    x0, tmpl_bin_pop_x1@PAGE
    add     x0, x0, tmpl_bin_pop_x1@PAGEOFF
    bl      _println_z

    ; second token is the operator
    ldr     x0, [x20, #8]
    bl      _token_type             ; token.type()
    mov     x21, x0                 ; stash token type

    cmp     x21, T_PLUS
    b.eq    do_bin_add
    cmp     x21, T_MINUS
    b.eq    do_bin_sub
    cmp     x21, T_STAR
    b.eq    do_bin_mul
    cmp     x21, T_SLASH
    b.eq    do_bin_div
    cmp     x21, T_PERCENT
    b.eq    do_bin_mod
    cmp     x21, T_EQ
    b.eq    do_bin_eq
    cmp     x21, T_LT
    b.eq    do_bin_lt
    cmp     x21, T_GT
    b.eq    do_bin_gt

    do_bin_bad:
        adrp    x0, err_bad_operator@PAGE
        add     x0, x0, err_bad_operator@PAGEOFF    ; pointer -> msg
        ldr     x1, [x20, #8]       ; pointer -> token
        mov     x2, #29             ; error code
        bl      do_panic            ; print and terminate

    do_bin_add:
    adrp    x21, tmpl_bin_add@PAGE
    add     x21, x21, tmpl_bin_add@PAGEOFF
    b       do_arith_emit
    do_bin_sub:
    adrp    x21, tmpl_bin_sub@PAGE
    add     x21, x21, tmpl_bin_sub@PAGEOFF
    b       do_arith_emit
    do_bin_mul:
    adrp    x21, tmpl_bin_mul@PAGE
    add     x21, x21, tmpl_bin_mul@PAGEOFF
    b       do_arith_emit
    do_bin_div:
    adrp    x21, tmpl_bin_div@PAGE
    add     x21, x21, tmpl_bin_div@PAGEOFF
    b       do_arith_emit
    do_bin_mod:
    adrp    x21, tmpl_bin_mod@PAGE
    add     x21, x21, tmpl_bin_mod@PAGEOFF
    b       do_arith_emit
    do_bin_gt:
    adrp    x21, tmpl_bin_gt@PAGE
    add     x21, x21, tmpl_bin_gt@PAGEOFF
    b       do_logic_emit
    do_bin_lt:
    adrp    x21, tmpl_bin_lt@PAGE
    add     x21, x21, tmpl_bin_lt@PAGEOFF
    b       do_logic_emit
    do_bin_eq:
    adrp    x21, tmpl_bin_eq@PAGE
    add     x21, x21, tmpl_bin_eq@PAGEOFF
    b       do_logic_emit

    do_arith_emit:
    tmpl_sec
    bl      _println
    b       do_binary_op_return

    do_logic_emit:
    mov     x0, x19
    bl      seqnum
    mov     x20, x0
    tmpl_sec
    mov     x0, x20
    bl      _print_i
    tmpl_sec
    mov     x0, x20
    bl      _print_i
    tmpl_sec
    mov     x0, x20
    bl      _print_i
    tmpl_sec
    mov     x0, x20
    bl      _print_i
    tmpl_sec
    bl      _println
    b       do_binary_op_return

    do_binary_op_return:
    ; restore frame
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

/* void do_token( Emitter* self, Token* t ) */
do_token:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> token
    mov     x0, x20
    bl      _token_type             ; token.type()
    mov     x21, x0                 ; stash token type

    cmp     x21, T_BOOL
    b.eq    do_token_bool
    cmp     x21, T_CHAR
    b.eq    do_token_char
    cmp     x21, T_ID
    b.eq    do_token_id
    cmp     x21, T_INT
    b.eq    do_token_int
    cmp     x21, T_STRING
    b.eq    do_token_string

    do_token_bad:
        adrp    x0, err_bad_token@PAGE
        add     x0, x0, err_bad_token@PAGEOFF    ; pointer -> msg
        mov     x0, x20             ; pointer -> token
        mov     x2, #26             ; error code
        bl      do_panic            ; print and terminate

    do_token_id:
    mov     x0, x20                 ; pointer -> token
    bl      _token_value_ptr        ; pointer -> name
    bl      do_value_id
    b       do_token_return
    do_token_char:                  ; these three all happen to be the same
    do_token_bool:
    do_token_int:
    mov     x0, x20
    bl      _token_value            ; value of the literal
    bl      do_value_literal
    b       do_token_return
    do_token_string:
    mov     x0, x20                 ; pointer -> token
    bl      _token_value_ptr        ; pointer -> value
    mov     x1, x0
    mov     x0, x19
    bl      do_value_string
    b       do_token_return

    do_token_return:
    ; restore frame
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_token_string: .asciz "    .data
        _j_str_\0: .asciz \"\0\"
    .text
        adrp    x0, _j_str_\0@PAGE
        add     x0, x0, _j_str_\0@PAGEOFF"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_value_id( Emitter* self, char* name ) */
do_value_string:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    str     x22, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> name
    adrp    x21, tmpl_token_string@PAGE
    add     x21, x21, tmpl_token_string@PAGEOFF
    mov     x0, x19
    bl      seqnum
    mov     x22, x0                 ; stash num

    tmpl_sec
    mov     x0, x22
    bl      _print_i
    tmpl_sec
    mov     x0, x20
    bl      _print_z
    tmpl_sec
    mov     x0, x22
    bl      _print_i
    tmpl_sec
    mov     x0, x22
    bl      _print_i
    tmpl_sec
    bl      _println

    ; restore frame
    ldr     x22, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_token_id: .asciz "        mov     x0, x2"
tmpl_token_global: .asciz "        adrp    x0, _j_gbl_\0@PAGE
        add     x0, x0, _j_gbl_\0@PAGEOFF"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_value_id( char* name ) */
do_value_id:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    str     x21, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> name
    ldrb    w0, [x19]               ; first char of name
    cmp     w0, 'g'
    b.gt    do_value_id_global

    adrp    x21, tmpl_token_id@PAGE
    add     x21, x21, tmpl_token_id@PAGEOFF
    tmpl_sec
    ldrb    w0, [x19]               ; first char of name
    sub     w0, w0, C2R             ; convert lower alpha to digit
    bl      _print_c
    bl      _println
    b       do_value_id_return

    do_value_id_global:
    adrp    x21, tmpl_token_global@PAGE
    add     x21, x21, tmpl_token_global@PAGEOFF
    tmpl_sec
    mov     x0, x19
    bl      _print_z
    tmpl_sec
    mov     x0, x19
    bl      _print_z
    tmpl_sec
    bl      _println

    do_value_id_return:
    ; restore frame
    ldr     x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
; todo: values too large to fit in a imm16 (>65,535) won't work...
tmpl_token_literal: .asciz "        mov     x0, #"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_value_literal( int v ) */
do_value_literal:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    mov     x19, x0                 ; stash the value
    adrp    x21, tmpl_token_literal@PAGE
    add     x21, x21, tmpl_token_literal@PAGEOFF
    tmpl_sec
    mov     x0, x19
    bl      _print_i
    bl      _println
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* void destroy( Emitter* self ) */
.global _emitter_destroy
_emitter_destroy:
    ; create frame
    str     lr, [sp, #-16]!
    ; end frame

    bl      _mem_free;_LOG

    ; restore frame
    ldr     lr, [sp], #16
    ret
