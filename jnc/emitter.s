/**
 * I provide an Emitter "class", which can process "statements" from a Parser.
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
err_bad_stmt: .asciz "; ERROR(%i): Bad statement %x at line %i, char %i\n"
err_bad_expr: .asciz "; ERROR(%i): Bad expression %x at line %i, char %i\n"
err_bad_token: .asciz "; ERROR(%i): Bad token %x at line %i, char %i\n"
err_bad_operator: .asciz "; ERROR(%i): Bad operator %x at line %i, char %i\n"
err_invalid_nesting: .asciz "; ERROR(%i): Invalid nesting %x at line %i, char %i\n"
err_dupe_decl: .asciz "; ERROR(%i): Duplicate declaration of '%s' at line %i, char %i\n"
err_unknown_symbol: .asciz "; ERROR(%i): Unknown symbol '%s' at line %i, char %i\n"
err_too_many_locals: .asciz "; ERROR(%i): Only eight local vars are allowed; '%s' is a ninth at line %i, char %i\n"
err_global_param: .asciz "ERROR(%i): global call param '%s' at line %i, char %i\n"

tmpl_prelude: .asciz "; Compiled with %s ; tmpl_prelude\n\
    .text\n\
    .align  3\n\
    NULL  = 0\n\
    TRUE  = 1\n\
    FALSE = 0\n"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3 ; 8-byte/64-bit alignment
NULL    = 0
TRUE    = 1
FALSE   = 0

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
    adrp    x1, _j_gbl_JNC_SHORT_VERSION@PAGE
    add     x1, x1, _j_gbl_JNC_SHORT_VERSION@PAGEOFF
    bl      __j_printf

    mov     x0, x19

    ldp     x19, x21, [sp], 0x10
    ldp     fp, lr, [sp], 0x10
    ret

/*
struct Block {
    int type                        ; type of the block, identified by its token
    int id                          ; unique id num of the block
    int nvars                       ; number of vars (function only)
    Table* symbols
}
*/
B_OFF_TYPE    = 0
B_OFF_ID      = 0x8
B_OFF_NVARS   = 0x10
B_OFF_SYMBOLS = 0x18
SIZEOF_BLOCK  = B_OFF_SYMBOLS + 0x8

/* void drop( Block* b ) */
block_drop:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

    ldr     x0, [x0, B_OFF_SYMBOLS] ; load block's symbol table
    bl      __j_Table_drop_values   ; drop nodes AND their values

    ldp     fp, lr, [sp], 0x10
    ret

/* int id( Block* b ) */
.global __j_Emitter_Block_id
__j_Emitter_Block_id:
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

/* int symbols( Block* b ) */
.global __j_Emitter_Block_symbols
__j_Emitter_Block_symbols:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    ; end frame
    ldr     x0, [x0, B_OFF_SYMBOLS]

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
    stp     x20, x21, [x0]          ; initialize type & id

    mov     x20, x0                 ; stash pointer -> block
    adrp    x0, __j_strcmp@PAGE
    add     x0, x0, __j_strcmp@PAGEOFF
    bl      __j_Table__new
    stp     xzr, x0, [x20, B_OFF_NVARS]; initialize nvars & symbol table
;        .data
;        bt:.asciz "; block: %p, table: %p\n"
;        .text
;        mov x2, x0
;        mov x1, x20
;        adrp x0, bt@PAGE
;        add x0, x0, bt@PAGEOFF    ; pointer -> msg
;        bl __j_printf
    mov     x0, x20                 ; restore pointer -> block

    add     x22, x22, 1             ; increment depth
    stp     x21, x22, [x19, OFF_SEQ]; store seq and depth

    ; restore frame
    ldp     x21, x22, [sp], 0x10
    ldp     x19, x20, [sp], 0x10
    ldp     fp, lr, [sp], 0x10
    ret

/* Symbol* lookup_symbol_by_token( Emitter* self, Token* id_token ) */
lookup_symbol_by_token:
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

/* Symbol* lookup_symbol_by_name_and_token( Emitter* self, char* name, Token* t ) */
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
    ldr     x0, [x0, B_OFF_SYMBOLS] ; block.symbol_table()
    ldr     x1, [sp]                ; load pointer -> name
    bl      __j_Table_get
    cmp     x0, NULL
    b.ne    lookup_symbol_return
    b       lookup_symbol_loop

    lookup_symbol_bad:
        ; build a panic tuple on the stack, since the token itself won't work
        ldp     x1, x0, [sp]
        bl      __j_Token_char
        str     x0, [sp, -0x10]!
        ldp     x1, x0, [sp, 0x10]
        bl      __j_Token_line
        stp     x1, x0, [sp, -0x10]!
        adrp    x0, err_unknown_symbol@PAGE
        add     x0, x0, err_unknown_symbol@PAGEOFF
        mov     x1, sp
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
innermost_block_of:
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
    bl      block_type
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

    cmp     x22, T_SEMI
    b.eq    __emit_return__         ; well that was kind of silly...

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
    bl      __j_Emitter_return               ; this.do_return( buffer )
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
tmpl_main: .asciz "    .global _main ; tmpl_main\n\
    _main:\n\
        bl      __j_main\n\
        b       __j_exit\n\
"

; todo: viz support
tmpl_fn_intro: .asciz "    .global __j_%s ; tmpl_fn_intro\n\
    __j_%s:\n\
        ; create frame\n\
        stp     fp, lr, [sp, -0x10]!\n\
        mov     fp, sp\n\
            ; todo: this is enough space for the same 8 locals as before\n\
            sub sp, sp, 0x40\n\
        ; end frame\n"

tmpl_fn_arg: .asciz "        str     x%i, [fp, -%x] ; tmpl_fn_arg\n"
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

    add     x20, x20, 0x18          ; skip to first arg or close paren
    mov     x22, #0                 ; index of param's register
    do_fn_next_arg:
    ldr     x0, [x20], 0x8          ; load pointer -> token to interrogate
    mov     x23, x0                 ; stash pointer -> token
    bl      __j_Token_type          ; token.type()
    cmp     x0, T_CPAREN
    b.eq    do_fn_return            ; done!
    cmp     x0, T_KW_INT
    b.eq    do_fn_decl
    cmp     x0, T_KW_CHAR
    b.eq    do_fn_decl
    cmp     x0, T_KW_BOOL
    b.eq    do_fn_decl
    cmp     x0, T_KW_VOID
    b.eq    do_fn_decl
    cmp     x0, T_ID
    b.eq    do_fn_argname
    b       do_fn_next_arg          ; again!

    do_fn_decl:
    mov     x0, x19
    mov     x1, x20
    sub     x1, x1, 0x8
    bl      __j_Emitter_vardecl
    b       do_fn_next_arg          ; again!

    do_fn_argname:
    mov     x1, x23                 ; pointer -> token
    mov     x0, x19
    bl      lookup_symbol_by_token  ; self.lookup_symbol_by_token(token)
    bl      __j_Symbol_offset       ; symbol.offset();
    mov     x1, x22
    lsl     x2, x0, 3
    adrp    x0, tmpl_fn_arg@PAGE    ; pointer -> template
    add     x0, x0, tmpl_fn_arg@PAGEOFF
    bl      __j_printf
    add     x22, x22, #1            ; increment arg register
    b       do_fn_next_arg          ; again!

    do_fn_return:
    ; restore frame
    ldp     x22, x23, [sp], 0x10
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_if_intro: .asciz "        cmp     x0, FALSE ; tmpl_if_intro\n\
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
tmpl_while_intro_a: .asciz "        while_%i_again: ; tmpl_while_intro_a\n"
tmpl_while_intro_b: .asciz "        cmp     x0, FALSE ; tmpl_while_intro_b\n\
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
tmpl_again: .asciz "        b       while_%i_again ; tmpl_again\n"
tmpl_done : .asciz "        b       while_%i_done ; tmpl_done\n"
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

    ldr     x2, [x1]
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
; todo: viz support
tmpl_global_bool: .asciz "    .data ; tmpl_global_bool\n\
        .global _j_gbl_%s\n\
        _j_gbl_%s: .byte %i\n\
    .text\n"
tmpl_global_int: .asciz "    .data ; tmpl_global_int\n\
        .global _j_gbl_%s\n\
        _j_gbl_%s: .quad %i\n\
    .text\n"
tmpl_global_char: .asciz "    .data ; tmpl_global_char\n\
        .global _j_gbl_%s\n\
        _j_gbl_%s: .byte '%c'\n\
    .text\n"
tmpl_global_string: .asciz "    .data ; tmpl_global_string\n\
        .global _j_gbl_%s\n\
        _j_gbl_%s: .asciz \"%s\"\n\
    .text\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_decl( Emitter* self, [Token*] buffer ) */

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
        bl      innermost_block_of
        b       vardecl_got_block
    vardecl_global:
        mov     x0, x19
        bl      current_block           ; self.current_block()

    vardecl_got_block:
    ; get its symbol table
    ldr     x0, [x0, B_OFF_SYMBOLS] ; block.symbol_table()
    mov     x23, x0                 ; stash pointer -> symbols
    ; if already defined, panic
    ldr     x1, [sp]                ; load pointer -> name
    bl      __j_Table_contains
    cmp     x0, FALSE
    b.eq    vardecl_non_dupe
        ; build a panic tuple on the stack, since the token itself won't work
        ldp     x1, x0, [sp]
        bl      __j_Token_char
        str     x0, [sp, -0x10]!
        ldp     x1, x0, [sp, 0x10]
        bl      __j_Token_line
        stp     x1, x0, [sp, -0x10]!
        adrp    x0, err_dupe_decl@PAGE
        add     x0, x0, err_dupe_decl@PAGEOFF    ; pointer -> msg
        mov     x1, sp
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
            ; build a panic tuple on the stack, since the token itself won't work
            ldp     x1, x0, [sp]
            bl      __j_Token_char
            str     x0, [sp, -0x10]!
            ldp     x1, x0, [sp, 0x10]
            bl      __j_Token_line
            stp     x1, x0, [sp, -0x10]!
            adrp    x0, err_too_many_locals@PAGE
            add     x0, x0, err_too_many_locals@PAGEOFF    ; pointer -> msg
            mov     x1, sp
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
    mov     x2, x24                 ; pointer -> symbol
    ldr     x1, [sp]                ; load pointer -> name
    mov     x0, x23                 ; pointer -> symbols
    bl      __j_Table_put
;        .data
;        ns:.asciz "; added '%s' to table w/ type %x width %d and nptr %d\n"
;        .text
;        ldp x3, x4, [x24]           ; load width and nptr
;        ldr x0, [x20]               ; load pointer -> tokens[0]
;        bl __j_Token_type           ; token.type()
;        mov x2, x0
;        ldr x1, [sp]
;        adrp x0, ns@PAGE
;        add x0, x0, ns@PAGEOFF
;        bl __j_printf

    add     sp, sp, 0x10            ; release locals

    ldp     x23, x24, [sp], 0x10
    ldp     x21, x22, [sp], 0x10
    ldp     x19, x20, [sp], 0x10
    ldp     fp, lr, [sp], 0x10
    ret

do_decl:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    stp     x22, x23, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer

    bl      __j_Emitter_vardecl

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

    ; set up the template params
    mov     x0, x22                 ; pointer -> name token
    bl      __j_Token_value         ; pointer -> value
    str     x0, [sp, -0x10]!        ; store pointer -> name
    mov     x0, x20                 ; pointer -> value token
    bl      __j_Token_value         ; pointer -> value
    mov     x3, x0
    ldr     x2, [sp], 0x10          ; load pointer -> name
    mov     x1, x2

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

    do_decl_bool:
    adrp    x0, tmpl_global_bool@PAGE
    add     x0, x0, tmpl_global_bool@PAGEOFF
    b       do_decl_emit_global

    do_decl_int:
    adrp    x0, tmpl_global_int@PAGE
    add     x0, x0, tmpl_global_int@PAGEOFF
    b       do_decl_emit_global

    do_decl_char:
    adrp    x0, tmpl_global_char@PAGE
    add     x0, x0, tmpl_global_char@PAGEOFF
    b       do_decl_emit_global

    do_decl_string:
    adrp    x0, tmpl_global_string@PAGE
    add     x0, x0, tmpl_global_string@PAGEOFF
    b       do_decl_emit_global

    do_decl_emit_global:
    bl      __j_printf

    do_decl_return:
    ; restore frame
    ldp     x22, x23, [sp], 0x10
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_assign: .asciz "        str     x0, [fp, -%x] ; tmpl_assign\n"
tmpl_assign_global_quad: .asciz "        adrp    x7, _j_gbl_%s@PAGE ; tmpl_assign_global_quad\n\
        add     x7, x7, _j_gbl_%s@PAGEOFF\n\
        str     x0, [x7]\n"
tmpl_assign_global_byte: .asciz "        adrp    x7, _j_gbl_%s@PAGE ; tmpl_assign_global_byte\n\
        add     x7, x7, _j_gbl_%s@PAGEOFF\n\
        strb    w0, [x7]\n"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_assign( Emitter* self, [Token*] buffer ) */
do_assign:
    ; create frame
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    stp     x19, x20, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer

    mov     x0, x19
    add     x1, x20, 0x10            ; pointer -> buffer[2] (the RHS)
    bl      do_expr

    ldr     x1, [x20]               ; pointer -> name token
    mov     x0, x19                 ; pointer -> self
    bl      lookup_symbol_by_token  ; self.lookup_symbol_by_token(token)
    str     x0, [sp, -0x10]!        ; store pointer -> symbol
    bl      __j_Symbol_offset
        cmp     x0, #0
        b.le    do_assign_global
    lsl     x1, x0, 3
    adrp    x0, tmpl_assign@PAGE    ; pointer -> template
    add     x0, x0, tmpl_assign@PAGEOFF
    bl      __j_printf
    b       do_assign_return

    do_assign_global:
        ldr     x0, [x20]               ; pointer -> name token
        bl      __j_Token_value
        mov     x2, x0              ; set up template params
        mov     x1, x0
        ldr     x0, [sp]            ; load pointer -> symbol
        ldr     x7, [x0]            ; load width from the symbol - nasty!
        cmp     x7, #1
        b.eq    do_assign_global_byte
            adrp    x0, tmpl_assign_global_quad@PAGE    ; pointer -> template
            add     x0, x0, tmpl_assign_global_quad@PAGEOFF
            bl      __j_printf
            b       do_assign_return
        do_assign_global_byte:
            adrp    x0, tmpl_assign_global_byte@PAGE    ; pointer -> template
            add     x0, x0, tmpl_assign_global_byte@PAGEOFF
            bl      __j_printf

    do_assign_return:
    ; restore frame
    add     sp, sp, 0x10            ; release locals
    ldp     x21, x20, [sp], 0x10
    ldp     fp, lr, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_get_addr_local: .asciz "        ldr     x7, [fp, -%x] ; tmpl_get_addr_local\n"
tmpl_get_addr_global: .asciz "        adrp    x7, _j_gbl_%s@PAGE ; tmpl_token_id_global\n\
        add     x7, x7, _j_gbl_%s@PAGEOFF\n"
tmpl_assign_ptr_quad: .asciz "        str     x0, [x7] ; tmpl_assign_ptr_quad\n"
tmpl_assign_ptr_byte: .asciz "        strb    w0, [x7] ; tmpl_assign_ptr_byte\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

do_assign_pointer:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    stp     x20, x21, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> this
    mov     x20, x1                 ; stash pointer -> buffer

    mov     x0, x19
    add     x1, x20, #24            ; pointer -> buffer[3] (the RHS)
    bl      do_expr

    ldr     x1, [x20, 0x8]          ; pointer -> name token
    mov     x0, x19
    bl      lookup_symbol_by_token  ; self.lookup_symbol_by_token(token)
    ldp     x3, x4, [x0]            ; load width and nptr from the symbol - nasty!
    stp     x3, x4, [sp, -0x10]!    ; store width/nptr
    bl      __j_Symbol_offset
    cmp     x0, #0
    b.le    do_assign_pointer_global
        lsl     x1, x0, 3
        adrp    x0, tmpl_get_addr_local@PAGE
        add     x0, x0, tmpl_get_addr_local@PAGEOFF
        bl      __j_printf
        b       do_assign_pointer_go
    do_assign_pointer_global:
        ldr     x0, [x20, 0x8]          ; pointer -> name token
        bl      __j_Token_value
        mov     x2, x0
        mov     x1, x0
        adrp    x0, tmpl_get_addr_global@PAGE
        add     x0, x0, tmpl_get_addr_global@PAGEOFF
        bl      __j_printf

    do_assign_pointer_go:
    ldp     x3, x4, [sp], 0x10      ; load width/nptr
    cmp     x3, #1
    b.ne    do_assign_pointer_quad  ; if width != 1, use quad
    cmp     x4, #1
    b.gt    do_assign_pointer_quad  ; if npts > 1, use quad (deref is a pointer)
    adrp    x0, tmpl_assign_ptr_byte@PAGE
    add     x0, x0, tmpl_assign_ptr_byte@PAGEOFF
    bl      __j_printf
    b       do_assign_pointer_return
    do_assign_pointer_quad:
    adrp    x0, tmpl_assign_ptr_quad@PAGE
    add     x0, x0, tmpl_assign_ptr_quad@PAGEOFF
    bl      __j_printf

    do_assign_pointer_return:
    ; restore frame
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_fn_outro: .asciz "        mov      x0, #0             ; fell off end; return zero ; tmpl_fn_outro\n\
        _return_%i:\n\
        ; restore frame\n\
            ; todo: this was enough space for the same 8 locals as before\n\
            add sp, sp, 0x40\n\
        ldp     fp, lr, [sp], 0x10\n\
        ret\n\n\n"
tmpl_if_outro: .asciz "        if_%i_done: ; tmpl_if_outro\n"
tmpl_while_outro: .asciz "        b     while_%i_again ; tmpl_while_outro\n\
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
tmpl_call_param: .asciz "        ldr     x%i, [fp, -%x] ; tmpl_call_param\n"
tmpl_call: .asciz "        bl      __j_%s ; tmpl_call\n"
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

    ; todo: respect globals...
    mov     x1, x23                 ; pointer -> token
    mov     x0, x19
    bl      lookup_symbol_by_token  ; self.lookup_symbol_by_token(token)
    bl      __j_Symbol_offset
    cmp     x0, #0
    b.gt    do_call_local_param
        ; assemble a "token" on the stack
        mov     x0, x23                 ; pointer -> token
        bl      __j_Token_char
        str     x0, [sp, -0x10]!
        mov     x0, x23                 ; pointer -> token
        bl      __j_Token_value
        str     x0, [sp, -0x10]!
        mov     x0, x23                 ; pointer -> token
        bl      __j_Token_line
        str     x0, [sp, 0x8]
        adrp    x0, err_global_param@PAGE
        add     x0, x0, err_global_param@PAGEOFF
        mov     x1, sp
        mov     x2, #25             ; error code
        bl      __j_jnc_panic
    do_call_local_param:
    lsl     x2, x0, 3
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
.global __j_Emitter_expr
__j_Emitter_expr:
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
    ; if second token is EQ, BANG, LT, GT, PLUS, MINUS, SLASH, STAR, PERCENT, do binary op
    do_expr_bool:
    cmp     x23, T_EQ
    b.eq    do_expr_binop
    cmp     x23, T_BANG
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
tmpl_un_not:    .asciz "        cmp     x0, FALSE ; tmpl_un_not\n\
        b.ne    expr_%i_was_true\n\
        mov     x0, TRUE\n\
        b       expr_%i_end\n\
        expr_%i_was_true:\n\
        mov     x0, FALSE\n\
        expr_%i_end:\n"
tmpl_un_negate: .asciz "        neg     x0, x0 ; tmpl_un_negate\n"
tmpl_un_deref_quad: .asciz "        ldr     x0, [x0] ; tmpl_un_deref_quad\n"
tmpl_un_deref_byte: .asciz "        ldrb    w0, [x0] ; tmpl_un_deref_byte\n"
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
    ldr     x1, [x20, 0x8]
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
    ; get the symbol
    mov     x0, x19
    ldr     x1, [x20, 0x8]          ; pointer -> name token
    bl      lookup_symbol_by_token
    ldp     x2, x3, [x0]            ; load width and nptr from the symbol - nasty!
    cmp     x2, #1
    b.ne    do_un_deref_quad        ; if width != 1, use quad
    cmp     x3, #1
    b.gt    do_un_deref_quad        ; if npts > 1, use quad (deref is a pointer)
    adrp    x0, tmpl_un_deref_byte@PAGE
    add     x0, x0, tmpl_un_deref_byte@PAGEOFF
    bl      __j_printf
    b       do_un_return
    do_un_deref_quad:
    adrp    x0, tmpl_un_deref_quad@PAGE
    add     x0, x0, tmpl_un_deref_quad@PAGEOFF
    bl      __j_printf

    do_un_return:
    ; restore frame
    ldp     x20, x21, [sp], 0x10
    ldp     lr, x19, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
tmpl_bin_push:  .asciz "        str     x0, [sp, -0x10]! ; tmpl_bin_push"
tmpl_bin_pop_x1:.asciz "        ldr     x1, [sp], 0x10 ; tmpl_bin_pop_x1"

tmpl_bin_add:   .asciz "        add     x0, x0, x1 ; tmpl_bin_add"
tmpl_bin_sub:   .asciz "        sub     x0, x0, x1 ; tmpl_bin_sub"
tmpl_bin_mul:   .asciz "        mul     x0, x0, x1 ; tmpl_bin_mul"
tmpl_bin_div:   .asciz "        sdiv    x0, x0, x1 ; tmpl_bin_div"
tmpl_bin_mod:   .asciz "        str     x2, [sp, -0x10]! ; tmpl_bin_mod\n\
        sdiv    x2, x0, x1\n\
        msub    x0, x2, x1, x0\n\
        ldr     x2, [sp], 0x10"
tmpl_b_gt:    .asciz "gt"
tmpl_b_lt:    .asciz "lt"
tmpl_b_eq:    .asciz "eq"
tmpl_b_ne:    .asciz "ne"
tmpl_bin_comp:    .asciz "        cmp     x0, x1 ; tmpl_bin_comp\n\
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
    cmp     x21, T_BANG
    b.eq    do_bin_ne
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
    do_bin_ne:
    adrp    x21, tmpl_b_ne@PAGE
    add     x21, x21, tmpl_b_ne@PAGEOFF
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
    mov     x1, x20                 ; pointer -> token
    mov     x0, x19
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
tmpl_token_string: .asciz "        .data ; tmpl_token_string\n\
          _j_str_%i: .asciz \"%s\"\n\
        .text\n\
        adrp    x0, _j_str_%i@PAGE\n\
        add     x0, x0, _j_str_%i@PAGEOFF\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_value_string( Emitter* self, char* name ) */
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
tmpl_token_id: .asciz "        ldr     x0, [fp, -%x] ; tmpl_token_id\n"
tmpl_token_id_global: .asciz "        adrp    x0, _j_gbl_%s@PAGE ; tmpl_token_id_global\n\
        add     x0, x0, _j_gbl_%s@PAGEOFF\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_value_id( Emitter* self, Token* t ) */
do_value_id:
    ; create frame
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    stp     x19, x21, [sp, -0x10]!
    ; end frame
    mov     x19, x0                 ; stash pointer -> self
    mov     x21, x1                 ; stash pointer -> token

    mov     x1, x21
    mov     x0, x19
    bl      lookup_symbol_by_token
    str     x0, [sp, -0x10]!        ; store pointer -> symbol
    bl      __j_Symbol_offset
    cmp     x0, #0
    b.le    do_value_id_global
    lsl     x1, x0, 3
    adrp    x0, tmpl_token_id@PAGE
    add     x0, x0, tmpl_token_id@PAGEOFF
    bl      __j_printf
    b       do_value_id_return

    ; todo: treat globals uniformly...
    do_value_id_global:
    mov     x0, x21
    bl      __j_Token_value
    mov     x2, x0
    mov     x1, x0
    adrp    x0, tmpl_token_id_global@PAGE
    add     x0, x0, tmpl_token_id_global@PAGEOFF
    bl      __j_printf
    ldr     x7, [sp]
    ldp     x2, x3, [x7]            ; load width and nptr from the s ymbol - nasty!
    cmp     x3, #0
    b.gt    do_value_id_return
        ; need to deref
        cmp     x2, #1
        b.ne    do_value_id_global_quad        ; if width != 1, use quad
        adrp    x0, tmpl_un_deref_byte@PAGE
        add     x0, x0, tmpl_un_deref_byte@PAGEOFF
        bl      __j_printf
        b       do_value_id_return
        do_value_id_global_quad:
        adrp    x0, tmpl_un_deref_quad@PAGE
        add     x0, x0, tmpl_un_deref_quad@PAGEOFF
        bl      __j_printf

    do_value_id_return:
    ; restore frame
    add     sp, sp, 0x10            ; release locals
    ldp     x19, x21, [sp], 0x10
    ldp     fp, lr, [sp], 0x10
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
; todo: values too large to fit in a imm16 (>65,535) won't work...
tmpl_token_literal: .asciz "        mov     x0, #%i ; tmpl_token_literal\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text

/* void do_value_literal( int v ) */
do_value_literal:
    ; create frame
    stp     lr, x19, [sp, -0x10]!
    ; end frame
    mov     x1, x0
    adrp    x0, tmpl_token_literal@PAGE
    add     x0, x0, tmpl_token_literal@PAGEOFF
    bl      __j_printf
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
