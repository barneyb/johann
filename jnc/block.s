.text
.align 3 ; 8-byte/64-bit alignment

B_OFF_TYPE    = 0
B_OFF_ID      = 0x8
B_OFF_NVARS   = 0x10
B_OFF_SYMBOLS = 0x18
SIZEOF_BLOCK  = B_OFF_SYMBOLS + 0x8

/* Block init( Block* b, int type, int id )*/
.global __j_Block_init
__j_Block_init:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

    stp     x1, x2, [x0]            ; initialize type & id
    str     x0, [sp, -0x10]!        ; store pointer -> block
    adrp    x0, __j_strcmp@PAGE
    add     x0, x0, __j_strcmp@PAGEOFF
    bl      __j_Table__new
    mov     x1, x0
    ldr     x0, [sp], 0x10          ; load pointer -> block
    stp     xzr, x1, [x0, B_OFF_NVARS]; initialize nvars & symbol table

    ldp     fp, lr, [sp], 0x10
    ret

/* void drop( Block* b ) */
.global __j_Block_drop
__j_Block_drop:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

    ldr     x0, [x0, B_OFF_SYMBOLS] ; load block's symbol table
    adrp    x1, __j_free@PAGE
    add     x1, x1, __j_free@PAGEOFF; use free to drop keys (names)
    mov     x2, x1                  ; use free to drop values (symbols)
    bl      __j_Table_drop_owned    ; drop nodes AND their values

    ldp     fp, lr, [sp], 0x10
    ret
