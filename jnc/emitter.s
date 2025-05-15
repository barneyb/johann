/**
 * I provide an Emitter "class", which can process "statements" from a Parser.
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
err_bad_stmt: .asciz "; ERROR(%i): Bad statement %x at line %i, char %i\n"
err_bad_expr: .asciz "; ERROR(%i): Bad expression %x at line %i, char %i\n"
err_bad_token: .asciz "; ERROR(%i): Bad token %x at line %i, char %i\n"
err_bad_operator: .asciz "; ERROR(%i): Bad operator %x at line %i, char %i\n"
err_invalid_nesting: .asciz "; ERROR: Invalid nesting "

.macro tmpl_sec r=x21
    mov     x0, \r
    bl      __j_print               ; print segment
    mov     x0, \r
    bl      _strlen                 ; get its length
    add     x0, x0, #1
    add     \r, \r, x0              ; advance to the next segment
.endm

tmpl_prelude: .asciz "; Compiled with %s\n\
    .text\n\
    .align  3\n\
    .set NULL, 0\n\
    .set TRUE, 1\n\
    .set FALSE, 0\n"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3 ; 8-byte/64-bit alignment
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
OFF_SEQ     = 0
OFF_DEPTH   = 0x8
OFF_BLOCKS  = 0x10
BLOCKS_CAP  = 10
SIZEOF      = OFF_BLOCKS + BLOCKS_CAP * SIZEOF_BLOCK    ; blocks is always last

/* Emitter new( ) */
.global __j_Emitter__new
__j_Emitter__new:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    stp     x19, x21, [sp, -0x10]!

    mov     x0, SIZEOF              ; how much to allocate
    bl      __j_malloc              ; allocate
    mov     x19, x0                 ; stash pointer -> this
    stp     xzr, xzr, [x0]          ; initialize seq and depth
    ; enter global "block"
    mov     x0, x19
    mov     x1, NULL
    bl      enter_block             ; this.enter_block()

    adrp    x0, tmpl_prelude@PAGE
    add     x0, x0, tmpl_prelude@PAGEOFF
    adrp    x1, __j_jnc_short_version@PAGE
    add     x1, x1, __j_jnc_short_version@PAGEOFF
    bl      __j_printf

    mov     x0, x19

    ldp     x19, x21, [sp], 0x10
    ldp     fp, lr, [sp], 0x10
    ret

/*
struct Block {
    int type                        ; type of the block, identified by its token
    int id                          ; unique id num of the block
    Table* symbols
}
*/
B_OFF_TYPE    = 0
B_OFF_ID      = 0x8
B_OFF_SYMBOLS = 0x10
SIZEOF_BLOCK  = B_OFF_SYMBOLS + 0x8

/* void drop( Block* b ) */
block_drop:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

    ldr     x0, [x0, B_OFF_SYMBOLS]; load block's symbol table
    bl      __j_Table_drop

    ldp     fp, lr, [sp], 0x10
    ret

/* int id( Block* b ) */
block_id:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    ; end frame
    ldr     x0, [x0, B_OFF_ID]

    ; restore frame
    ldp     lr, x19, [sp], 0x10
    ret

/* int type( Block* b ) */
block_type:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    ; end frame
    ldr     x0, [x0, B_OFF_TYPE]

    ; restore frame
    ldp     lr, x19, [sp], 0x10
    ret

/* Block* enter_block( Emitter* self, int type ) */
enter_block:
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
    stp     x20, x21, [x0]          ; initialize type and id

    mov     x20, x0                 ; stash pointer -> block
    adrp    x0, __j_strcmp@PAGE
    add     x0, x0, __j_strcmp@PAGEOFF
    bl      __j_Table__new
    str     x0, [x20, B_OFF_SYMBOLS]; initialize symbol table
    mov     x0, x20                 ; restore pointer -> block

    add     x22, x22, 1             ; increment depth
    stp     x21, x22, [x19, OFF_SEQ]; store seq and depth

    ; restore frame
    ldp     x21, x22, [sp], 0x10
    ldp     x19, x20, [sp], 0x10
    ldp     fp, lr, [sp], 0x10
    ret

/* Block* innermost_block_of( Emitter* self, int type ) */
innermost_block_of:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    str     x22, [sp, -0x10]!
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
    bl      block_type
    cmp     x0, x20
    b.ne    innermost_block_of_loop
    mov     x0, x22
    b       innermost_block_of_return

    innermost_block_of_bad:
        adrp    x0, err_invalid_nesting@PAGE
        add     x0, x0, err_invalid_nesting@PAGEOFF
        bl      __j_print
        mov     x0, x20
        bl      __j_ick_print_h
        bl      __j_ick_println
        mov     x0, #37
        b       __j_sys_exit

    innermost_block_of_return:
    ; restore frame
    ldr     x22, [sp], 0x10
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

/* Block* leave_block( Emitter* self ) */
leave_block:
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

/* int seqnum( Emitter* self ) */
seqnum:
    ; create frame
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    ; end frame
    mov     x1, x0                  ; stash pointer -> this
    ldr     x0, [x1, OFF_SEQ]       ; load seq
    add     x0, x0, 1               ; increment seq
    str     x0, [x1, OFF_SEQ]       ; store seq
    ; restore frame
    ldp     fp, lr, [sp], 0x10
    ret

/* bool is_global( Emitter* self ) */
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

/* void emit( Emitter* self, [Token*] stmt ) */
.global _emitter_emit
_emitter_emit:
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
    b.ne    __emit_void             ; next!
    mov     x0, x19
    mov     x1, x20
    bl      do_decl                 ; this.do_decl( buffer )
    b       __emit_return__

    __emit_void:
    cmp     x22, T_KW_VOID
    b.ne    __emit_while            ; next!
    mov     x0, x19
    mov     x1, x20
    bl      do_decl                 ; this.do_decl( buffer )
    b       __emit_return__

    __emit_while:
    cmp     x22, T_KW_WHILE
    b.ne    __emit_again            ; next!
    mov     x0, x19
    mov     x1, x20
    bl      do_while                ; this.do_while( buffer )
    b       __emit_return__

    __emit_again:
    cmp     x22, T_KW_AGAIN
    b.ne    __emit_done             ; next!
    mov     x0, x19
    mov     x1, x20
    bl      do_again                ; this.do_again( buffer )
    b       __emit_return__

    __emit_done:
    cmp     x22, T_KW_DONE
    b.ne    __emit_if               ; next!
    mov     x0, x19
    mov     x1, x20
    bl      do_done                 ; this.do_done( buffer )
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
    b.ne    __emit_star             ; next!
    mov     x0, x19
    mov     x1, x20
    bl      do_close_block          ; this.do_close_block( buffer )
    b       __emit_return__

    __emit_star:
    cmp     x22, T_STAR
    b.ne    __emit_second_token     ; next!
    mov     x0, x19
    mov     x1, x20
    bl      do_assign_pointer       ; this.do_assign_pointer( buffer )
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
        bl      __j_jnc_panic            ; print and terminate

    __emit_return__:
    ; restore frame
    ldr     x22, [sp], 0x10
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
s_main: .asciz "main"
tmpl_main: .asciz "    .global _main\n\
    _main:\n\
        bl      __j_main\n\
        b       __j_sys_exit\n\
"

tmpl_fn_intro: .asciz "    .global __j_%s\n\
    __j_%s:\n\
        ; create frame\n\
        stp     fp, lr, [sp, -0x10]!\n\
        mov     fp, sp\n\
        stp     x20, x21, [sp, -0x10]!\n\
        stp     x22, x23, [sp, -0x10]!\n\
        stp     x24, x25, [sp, -0x10]!\n\
        stp     x26, x27, [sp, -0x10]!\n\
        ; end frame\n"

tmpl_fn_arg: .asciz "        mov     x2%c, x%i ; capture param %s\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_fn( Emitter* self, [Token*] buffer ) */
do_fn:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    stp     x22, x23, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer
    ldr     x0, [x20, #8]           ; load pointer -> name token
    bl      __j_Token_value         ; token.value()
    mov     x22, x0                 ; stash pointer -> name
    mov     x0, x19
    mov     x1, T_KW_FN
    bl      enter_block             ; this.enter_block()

    ; see if we need to introduce main
    mov     x0, x22
    adrp    x1, s_main@PAGE
    add     x1, x1, s_main@PAGEOFF
    bl      _strcmp
    cmp     x0, #0
    b.ne    do_fn_intro
    adrp    x0, tmpl_main@PAGE
    add     x0, x0, tmpl_main@PAGEOFF
    bl      __j_puts

    do_fn_intro:
    mov     x1, x22
    mov     x2, x22
    adrp    x0, tmpl_fn_intro@PAGE ; pointer -> template
    add     x0, x0, tmpl_fn_intro@PAGEOFF
    bl      __j_printf

    add     x20, x20, #24           ; skip to first arg or close paren
    mov     x22, #0                 ; index of param's register
    do_fn_next_arg:
    ldr     x0, [x20], #8           ; load pointer -> token to interrogate
    mov     x23, x0                 ; stash pointer -> token
    bl      __j_Token_type             ; token.type()
    cmp     x0, T_CPAREN
    b.eq    do_fn_return            ; done!
    cmp     x0, T_ID
    b.ne    do_fn_next_arg          ; again!

    mov     x0, x23                 ; pointer -> token
    bl      __j_Token_value         ; pointer -> name
    ldrb    w1, [x0]                ; first char of name
    sub     w1, w1, C2R             ; convert lower alpha to digit
    mov     x2, x22
    add     x22, x22, #1            ; increment register
    stp     x1, x2, [sp, -0x10]!
    mov     x0, x23                 ; pointer -> token
    bl      __j_Token_value         ; pointer -> name
    mov     x3, x0
    ldp     x1, x2, [sp], 0x10
    adrp    x0, tmpl_fn_arg@PAGE   ; pointer -> template
    add     x0, x0, tmpl_fn_arg@PAGEOFF
    bl      __j_printf
    b.eq    do_fn_next_arg          ; again!

    do_fn_return:
    ; restore frame
    ldp     x22, x23, [sp], 0x10
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_if_intro: .asciz "        cmp     x0, FALSE\n\
        b.eq    if_%i_done\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_if( Emitter* self, [Token*] buffer ) */
do_if:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    str     x22, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer
    mov     x0, x19
    mov     x1, T_KW_IF
    bl      enter_block             ; this.enter_block()
    bl      block_id
    mov     x22, x0                 ; stash current block id

    mov     x0, x19
    add     x1, x20, #8             ; pointer -> condition token
    bl      do_expr
    mov     x1, x22
    adrp    x0, tmpl_if_intro@PAGE   ; pointer -> template
    add     x0, x0, tmpl_if_intro@PAGEOFF
    bl      __j_printf

    ; restore frame
    ldr     x22, [sp], 0x10
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_while_intro_a: .asciz "        while_%i_again:\n"
tmpl_while_intro_b: .asciz "        cmp     x0, FALSE\n\
        b.eq    while_%i_done\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_while( Emitter* self, [Token*] buffer ) */
do_while:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    str     x22, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer
    mov     x0, x19
    mov     x1, T_KW_WHILE
    bl      enter_block             ; this.enter_block()
    bl      block_id
    mov     x22, x0                 ; stash current block id

    mov     x1, x22
    adrp    x0, tmpl_while_intro_a@PAGE   ; pointer -> template
    add     x0, x0, tmpl_while_intro_a@PAGEOFF
    bl      __j_printf
    mov     x0, x19
    add     x1, x20, #8             ; pointer -> condition token
    bl      do_expr
    mov     x1, x22
    adrp    x0, tmpl_while_intro_b@PAGE   ; pointer -> template
    add     x0, x0, tmpl_while_intro_b@PAGEOFF
    bl      __j_printf

    ; restore frame
    ldr     x22, [sp], 0x10
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_return: .asciz "        b       _return_%i\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_return( Emitter* self, [Token*] buffer ) */
do_return:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    stp     x22, x23, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer
    adrp    x21, tmpl_return@PAGE   ; pointer -> template
    add     x21, x21, tmpl_return@PAGEOFF

    mov     x1, T_KW_FN
    mov     x0, x19
    bl      innermost_block_of
    bl      block_id
    mov     x22, x0                 ; stash current block id

    mov     x0, x19
    add     x1, x20, #8             ; pointer -> buffer[1] (pointer -> value token)
    bl      do_expr
    adrp    x0, tmpl_return@PAGE    ; pointer -> template
    add     x0, x0, tmpl_return@PAGEOFF
    mov     x1, x22
    bl      __j_printf

    ; restore frame
    ldp     x22, x23, [sp], 0x10
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_again: .asciz "        b       while_%i_again\n"
tmpl_done : .asciz "        b       while_%i_done\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_again( Emitter* self, [Token*] buffer ) */
do_again:
    adrp    x2, tmpl_again@PAGE   ; pointer -> template
    add     x2, x2, tmpl_again@PAGEOFF
    b       do_loop_thinger

/* void do_done( Emitter* self, [Token*] buffer ) */
do_done:
    adrp    x2, tmpl_done@PAGE   ; pointer -> template
    add     x2, x2, tmpl_done@PAGEOFF
    b       do_loop_thinger

/* void do_loop_thinger( Emitter* self, [Token*] buffer, char* tmpl ) */
do_loop_thinger:
    ; create frame
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    stp     x19, x21, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x21, x2                 ; pointer -> template

    mov     x1, T_KW_WHILE
    mov     x0, x19
    bl      innermost_block_of
    bl      block_id
    mov     x1, x0

    mov     x0, x21
    bl      __j_printf

    ; restore frame
    ldp     x20, x21, [sp], 0x10
    ldp     fp, lr, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_global_int: .asciz "    .data\n\
        _j_gbl_%s: .quad %i\n\
    .text\n"
tmpl_global_char: .asciz "    .data\n\
        _j_gbl_%s: .byte '%c'\n\
    .text\n"
tmpl_global_string: .asciz "    .data\n\
        _j_gbl_%s: .asciz \"%s\"\n\
    .text\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_decl( Emitter* self, [Token*] buffer ) */
do_decl:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    stp     x22, x23, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer

    ; scan until find an ASSIGN or SEMI
    add     x21, x20, #8            ; first token is type
    do_decl_again:
    ldr     x0, [x21, #8]!          ; stash pointer -> next token
    bl      __j_Token_type             ; token.type()
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
    bl      __j_Token_type          ; token.type()
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
        bl      __j_jnc_panic       ; print and terminate

    do_decl_bool:                  ; these two happen to be the same
    do_decl_int:
    mov     x0, x22                 ; pointer -> name token
    bl      __j_Token_value         ; pointer -> value
    str     x0, [sp, -0x10]!
    mov     x0, x20                 ; pointer -> value token
    bl      __j_Token_value         ; pointer -> value
    mov     x2, x0
    ldr     x1, [sp], 0x10
    adrp    x0, tmpl_global_int@PAGE
    add     x0, x0, tmpl_global_int@PAGEOFF
    bl      __j_printf
    b       do_decl_return

    do_decl_char:
    mov     x0, x22                 ; pointer -> name token
    bl      __j_Token_value         ; pointer -> value
    str     x0, [sp, -0x10]!
    mov     x0, x20                 ; pointer -> value token
    bl      __j_Token_value            ; pointer -> value
    mov     x2, x0
    ldr     x1, [sp], 0x10
    adrp    x0, tmpl_global_char@PAGE
    add     x0, x0, tmpl_global_char@PAGEOFF
    bl      __j_printf
    b       do_decl_return

    do_decl_string:
    mov     x0, x22                 ; pointer -> name token
    bl      __j_Token_value         ; pointer -> value
    str     x0, [sp, -0x10]!
    mov     x0, x20                 ; pointer -> value token
    bl      __j_Token_value         ; pointer -> value
    mov     x2, x0
    ldr     x1, [sp], 0x10
    adrp    x0, tmpl_global_string@PAGE
    add     x0, x0, tmpl_global_string@PAGEOFF
    bl      __j_printf
    b       do_decl_return

    do_decl_return:
    ; restore frame
    ldp     x22, x23, [sp], 0x10
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_assign: .asciz "        mov     x2%c, x0 ; assign %s\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_assign( Emitter* self, [Token*] buffer ) */
do_assign:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer
    adrp    x21, tmpl_assign@PAGE   ; pointer -> template
    add     x21, x21, tmpl_assign@PAGEOFF

    mov     x0, x19
    add     x1, x20, 0x10            ; pointer -> buffer[2] (the RHS)
    bl      do_expr
    ldr     x0, [x20]               ; pointer -> name token
    bl      __j_Token_value         ; pointer -> name
    ldrb    w1, [x0]                ; first char of name
    sub     w1, w1, C2R             ; convert lower alpha to digit
    mov     x2, x0
    adrp    x0, tmpl_assign@PAGE   ; pointer -> template
    add     x0, x0, tmpl_assign@PAGEOFF
    bl      __j_printf

    ; restore frame
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_assign_ptr: .asciz "        str     x0, [x2%c] ; assign *%s\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

do_assign_pointer:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer
    adrp    x21, tmpl_assign_ptr@PAGE   ; pointer -> template
    add     x21, x21, tmpl_assign_ptr@PAGEOFF

    mov     x0, x19
    add     x1, x20, #24            ; pointer -> buffer[3] (the RHS)
    bl      do_expr
    ldr     x0, [x20, #8]           ; pointer -> name token
    bl      __j_Token_value         ; pointer -> name
    ldrb    w1, [x0]                ; first char of name
    sub     w1, w1, C2R             ; convert lower alpha to digit
    mov     x2, x0
    adrp    x0, tmpl_assign_ptr@PAGE   ; pointer -> template
    add     x0, x0, tmpl_assign_ptr@PAGEOFF
    bl      __j_printf

    ; restore frame
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_fn_outro: .asciz "        mov      x0, #0             ; fell off end; return zero\n\
        _return_%i:\n\
        ; restore frame\n\
        ldp     x26, x27, [sp], 0x10\n\
        ldp     x24, x25, [sp], 0x10\n\
        ldp     x22, x23, [sp], 0x10\n\
        ldp     x20, x21, [sp], 0x10\n\
        ldp     fp, lr, [sp], 0x10\n\
        ret\n"
tmpl_if_outro: .asciz "        if_%i_done:\n"
tmpl_while_outro: .asciz "        b     while_%i_again\n\
        while_%i_done:\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_close_block( Emitter* self, [Token*] buffer ) */
do_close_block:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    stp     x22, x23, [sp, -0x10]!
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
    mov     x1, x23
    adrp    x0, tmpl_fn_outro@PAGE ; pointer -> template
    add     x0, x0, tmpl_fn_outro@PAGEOFF
    bl      __j_printf
    b       do_close_block_return

    do_close_block_if:
    cmp     x0, T_KW_IF
    b.ne    do_close_block_while
    mov     x1, x23
    adrp    x0, tmpl_if_outro@PAGE ; pointer -> template
    add     x0, x0, tmpl_if_outro@PAGEOFF
    bl      __j_printf
    b       do_close_block_return

    do_close_block_while:
    cmp     x0, T_KW_WHILE
    b.ne    do_close_block_return
    mov     x2, x23
    mov     x1, x23
    adrp    x0, tmpl_while_outro@PAGE ; pointer -> template
    add     x0, x0, tmpl_while_outro@PAGEOFF
    bl      __j_printf
    b       do_close_block_return

    do_close_block_return:
    mov     x0, x22
    bl      block_drop
    ; restore frame
    ldp     x22, x23, [sp], 0x10
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_call_param: .asciz "        mov     x%i, x2%c ; pass %s\n"
tmpl_call: .asciz "        bl       __j_%s\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_call( Emitter* self, [Token*] buffer ) */
do_call:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    stp     x22, x23, [sp, -0x10]!
    str     x24, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer

    ; pass parameters
    add     x24, x20, 0x10          ; skip to first arg or close paren
    mov     x22, #0                 ; index of param's register
    do_call_next_arg:
    ldr     x0, [x24], #8           ; load pointer -> token to interrogate
    mov     x23, x0                 ; stash pointer -> token
    bl      __j_Token_type          ; token.type()
    cmp     x0, T_CPAREN
    b.eq    do_call_invoke          ; done!
    cmp     x0, T_COMMA
    b.eq    do_call_next_arg        ; again!

    mov     x0, x23                 ; pointer -> token
    bl      __j_Token_value         ; pointer -> name
    mov     x3, x0
    ldrb    w2, [x0]                ; first char of name
    sub     w2, w2, C2R             ; convert lower alpha to digit
    mov     x1, x22
    adrp    x0, tmpl_call_param@PAGE   ; pointer -> template
    add     x0, x0, tmpl_call_param@PAGEOFF
    bl      __j_printf
    add     x22, x22, #1            ; increment register
    b.eq    do_call_next_arg        ; again!

    do_call_invoke:
    ldr     x0, [x20]               ; load pointer -> name token
    bl      __j_Token_value         ; token.value_ptr()
    mov     x1, x0
    adrp    x0, tmpl_call@PAGE
    add     x0, x0, tmpl_call@PAGEOFF
    bl      __j_printf

    ; restore frame
    ldr     x24, [sp], 0x10
    ldp     x22, x23, [sp], 0x10
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

/* void do_expr( Emitter* self, [Token*] buffer ) */
do_expr:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    stp     x22, x23, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer
    ldr     x22, [x20, #8]          ; stash pointer -> second token
    mov     x0, x22
    bl      __j_Token_type
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
    bl      __j_Token_type
    mov     x23, x0                 ; type of first token
;        bl __j_ick_print_h
;        bl __j_ick_println
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
        bl      __j_jnc_panic            ; print and terminate

    do_expr_return:
    ; restore frame
    ldp     x22, x23, [sp], 0x10
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_un_not:    .asciz "        cmp     x0, FALSE\n\
        b.ne    expr_%i_was_true\n\
        mov     x0, TRUE\n\
        b       expr_%i_end\n\
        expr_%i_was_true:\n\
        mov     x0, FALSE\n\
        expr_%i_end:\n"
tmpl_un_negate: .asciz "        neg     x0, x0\n"
tmpl_un_deref:  .asciz "        ldr     x0, [x0]\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_unary_op( Emitter* self, [Token*] buffer ) */
do_unary_op:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer

    ; second token is the operand
    mov     x0, x19
    ldr     x1, [x20, #8]
    bl      do_token

    ; first token is the operator
    ldr     x0, [x20]
    bl      __j_Token_type          ; token.type()
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
        bl      __j_jnc_panic       ; print and terminate

    do_un_not:
    mov     x0, x19
    bl      seqnum
    mov     x4, x0
    mov     x3, x0
    mov     x2, x0
    mov     x1, x0
    adrp    x0, tmpl_un_not@PAGE
    add     x0, x0, tmpl_un_not@PAGEOFF
    bl      __j_printf
    b       do_un_return
    do_un_neg:
    adrp    x0, tmpl_un_negate@PAGE
    add     x0, x0, tmpl_un_negate@PAGEOFF
    bl      __j_printf
    b       do_un_return
    do_un_deref:
    adrp    x0, tmpl_un_deref@PAGE
    add     x0, x0, tmpl_un_deref@PAGEOFF
    bl      __j_printf

    do_un_return:
    ; restore frame
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_bin_push:  .asciz "        str     x0, [sp, -0x10]!"
tmpl_bin_pop_x1:.asciz "        ldr     x1, [sp], 0x10"

tmpl_bin_add:   .asciz "        add     x0, x0, x1"
tmpl_bin_sub:   .asciz "        sub     x0, x0, x1"
tmpl_bin_mul:   .asciz "        mul     x0, x0, x1"
tmpl_bin_div:   .asciz "        sdiv    x0, x0, x1"
tmpl_bin_mod:   .asciz "        str     x2, [sp, -0x10]!\n\
        sdiv    x2, x0, x1\n\
        msub    x0, x2, x1, x0\n\
        ldr     x2, [sp], 0x10"
tmpl_b_gt:    .asciz "gt"
tmpl_b_lt:    .asciz "lt"
tmpl_b_eq:    .asciz "eq"
tmpl_bin_comp:    .asciz "        cmp     x0, x1\n\
        b.%s    expr_%i\n\
        mov     x0, FALSE\n\
        b       expr_%i_end\n\
        expr_%i:\n\
        mov     x0, TRUE\n\
        expr_%i_end:\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_binary_op( Emitter* self, [Token*] buffer ) */
do_binary_op:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer

    ; third token is an operand
    mov     x0, x19
    ldr     x1, [x20, 0x10]
    bl      do_token
    adrp    x0, tmpl_bin_push@PAGE
    add     x0, x0, tmpl_bin_push@PAGEOFF
    bl      __j_puts

    ; first token is an operand
    mov     x0, x19
    ldr     x1, [x20]
    bl      do_token

    adrp    x0, tmpl_bin_pop_x1@PAGE
    add     x0, x0, tmpl_bin_pop_x1@PAGEOFF
    bl      __j_puts

    ; second token is the operator
    ldr     x0, [x20, #8]
    bl      __j_Token_type             ; token.type()
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
        bl      __j_jnc_panic            ; print and terminate

    do_bin_add:
    adrp    x0, tmpl_bin_add@PAGE
    add     x0, x0, tmpl_bin_add@PAGEOFF
    b       do_arith_emit
    do_bin_sub:
    adrp    x0, tmpl_bin_sub@PAGE
    add     x0, x0, tmpl_bin_sub@PAGEOFF
    b       do_arith_emit
    do_bin_mul:
    adrp    x0, tmpl_bin_mul@PAGE
    add     x0, x0, tmpl_bin_mul@PAGEOFF
    b       do_arith_emit
    do_bin_div:
    adrp    x0, tmpl_bin_div@PAGE
    add     x0, x0, tmpl_bin_div@PAGEOFF
    b       do_arith_emit
    do_bin_mod:
    adrp    x0, tmpl_bin_mod@PAGE
    add     x0, x0, tmpl_bin_mod@PAGEOFF
    b       do_arith_emit
    do_bin_gt:
    adrp    x21, tmpl_b_gt@PAGE
    add     x21, x21, tmpl_b_gt@PAGEOFF
    b       do_logic_emit
    do_bin_lt:
    adrp    x21, tmpl_b_lt@PAGE
    add     x21, x21, tmpl_b_lt@PAGEOFF
    b       do_logic_emit
    do_bin_eq:
    adrp    x21, tmpl_b_eq@PAGE
    add     x21, x21, tmpl_b_eq@PAGEOFF
    b       do_logic_emit

    do_arith_emit:
    bl      __j_puts
    b       do_binary_op_return

    do_logic_emit:
    mov     x0, x19
    bl      seqnum
    mov     x5, x0
    mov     x4, x0
    mov     x3, x0
    mov     x2, x0
    mov     x1, x21
    adrp    x0, tmpl_bin_comp@PAGE
    add     x0, x0, tmpl_bin_comp@PAGEOFF
    bl      __j_printf
    b       do_binary_op_return

    do_binary_op_return:
    ; restore frame
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

/* void do_token( Emitter* self, Token* t ) */
do_token:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> token
    mov     x0, x20
    bl      __j_Token_type             ; token.type()
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
        mov     x1, x20             ; pointer -> token
        mov     x2, #26             ; error code
        bl      __j_jnc_panic            ; print and terminate

    do_token_id:
    mov     x0, x20                 ; pointer -> token
    bl      __j_Token_value         ; pointer -> name
    bl      do_value_id
    b       do_token_return
    do_token_char:                  ; these three all happen to be the same
    do_token_bool:
    do_token_int:
    mov     x0, x20
    bl      __j_Token_value            ; value of the literal
    bl      do_value_literal
    b       do_token_return
    do_token_string:
    mov     x0, x20                 ; pointer -> token
    bl      __j_Token_value         ; pointer -> value
    mov     x1, x0
    mov     x0, x19
    bl      do_value_string
    b       do_token_return

    do_token_return:
    ; restore frame
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_token_string: .asciz "    .data\n\
        _j_str_%i: .asciz \"%s\"\n\
    .text\n\
        adrp    x0, _j_str_%i@PAGE\n\
        add     x0, x0, _j_str_%i@PAGEOFF\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_value_id( Emitter* self, char* name ) */
do_value_string:
    ; create frame
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    str     x20, [sp, -0x10]!
    ; end frame
    mov     x20, x1                 ; stash pointer -> name
    bl      seqnum                  ; self.seqnum()

    mov     x4, x0
    mov     x3, x0
    mov     x2, x20                 ; pointer -> name
    mov     x1, x0
    adrp    x0, tmpl_token_string@PAGE
    add     x0, x0, tmpl_token_string@PAGEOFF
    bl      __j_printf

    ; restore frame
    ldr     x20, [sp], 0x10
    ldp     fp, lr, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_token_id: .asciz "        mov     x0, x2"
tmpl_token_global: .asciz "        adrp    x0, _j_gbl_\0@PAGE\n\
        add     x0, x0, _j_gbl_\0@PAGEOFF"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_value_id( char* name ) */
do_value_id:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    str     x21, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> name
    ldrb    w0, [x19]               ; first char of name
    cmp     w0, 'g'
    b.gt    do_value_id_global
    cmp     w0, 'a'
    b.lt    do_value_id_global

    adrp    x21, tmpl_token_id@PAGE
    add     x21, x21, tmpl_token_id@PAGEOFF
    tmpl_sec
    ldrb    w0, [x19]               ; first char of name
    sub     w0, w0, C2R             ; convert lower alpha to digit
    bl      __j_putchar
    bl      __j_ick_println
    b       do_value_id_return

    do_value_id_global:
    adrp    x21, tmpl_token_global@PAGE
    add     x21, x21, tmpl_token_global@PAGEOFF
    tmpl_sec
    mov     x0, x19
    bl      __j_print
    tmpl_sec
    mov     x0, x19
    bl      __j_print
    tmpl_sec
    bl      __j_ick_println

    do_value_id_return:
    ; restore frame
    ldr     x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
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
    stp     lr, x19, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash the value
    adrp    x21, tmpl_token_literal@PAGE
    add     x21, x21, tmpl_token_literal@PAGEOFF
    tmpl_sec
    mov     x0, x19
    bl      __j_ick_print_i
    bl      __j_ick_println
    ; restore frame
    ldp     lr, x19, [sp], 0x10
    ret

/* void drop( Emitter* self ) */
.global __j_Emitter_drop
__j_Emitter_drop:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    str     x0, [sp, -0x10]!

    bl      leave_block
    bl      block_drop
    ldr     x0, [sp], 0x10
    bl      __j_free

    ldp     fp, lr, [sp], 0x10
    ret
