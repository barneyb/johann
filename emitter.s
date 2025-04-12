/**
 * I provide an Emitter "class", which can process "statements" from a Parser.
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
err_bad_stmt: .asciz "; Bad statement at line "
at_char: .asciz ", char "

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align  3                           ; Make sure everything is 8-byte/64-bit aligned
.set    NULL, 0

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
    stp     xzr, xzr, [x0]          ; initialize seq and depth

    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/*
struct Block {
    int type                        ; type of the block, identified by its token
    int id                          ; unique id num of the block
}
*/
.set    OFF_TYPE    , 0
.set    OFF_ID      , 8
.set    SIZEOF_BLOCK, OFF_ID + 8

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

    add     x0, x19, OFF_BLOCKS     ; pointer -> stack of blocks
    mov     x1, SIZEOF_BLOCK        ; size of block
    madd    x0, x22, x1, x0         ; pointer -> block
    stp     x20, x21, [x0]          ; initialize type and id

    add     x21, x21, 1             ; increment seq
    add     x22, x22, 1             ; increment depth
    stp     x21, x22, [x19, OFF_SEQ]; store seq and depth

    ; restore frame
    ldr     x22, [sp], #16
    ldp     x20, x21, [sp], #16
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
    b.ne    __emit_return     ; next!
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
        add     x0, x0, err_bad_stmt@PAGEOFF
        bl      _print_z                ; todo: send errors to STDERR....
        mov     x0, x21
        bl      _token_line
        bl      _int2str
        bl      _print_z
        adrp    x0, at_char@PAGE
        add     x0, x0, at_char@PAGEOFF
        bl      _print_z
        mov     x0, x21
        bl      _token_char
        bl      _int2str
        bl      _println_z
        mov     x0, #27
        b       _os_exit

    __emit_return__:
    ; restore frame
    ldr     x22, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
s_main: .asciz "main"
tmpl_main: .asciz ".global _main
_main:
    mov     x0, #0
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

tmpl_fn_intro: .asciz ".global __j_\0
__j_\0:
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    stp     x22, x23, [sp, #-16]!
    stp     x24, x25, [sp, #-16]!
    stp     x26, x27, [sp, #-16]!
"
tmpl_fn_outro: .asciz "    _return_\0:
    ldp     x26, x27, [sp], #16
    ldp     x24, x25, [sp], #16
    ldp     x22, x23, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret
"
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

/* void do_if( Emitter* self, [Token*] buffer ) */
do_if:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* void do_while( Emitter* self, [Token*] buffer ) */
do_while:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* void do_return( Emitter* self, [Token*] buffer ) */
do_return:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* void do_decl( Emitter* self, [Token*] buffer ) */
do_decl:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* void do_assign( Emitter* self, [Token*] buffer ) */
do_assign:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* void do_close_block( Emitter* self, [Token*] buffer ) */
do_close_block:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* void do_call( Emitter* self, [Token*] buffer ) */
do_call:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
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
