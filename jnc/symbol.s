/**
 * I provide a Symbol "class" which holds info about a memory object, referenced
 * by name, somewhere. This will NOT gracefully expand to handle arrays/structs,
 * but hopefully can implement that stuff in Johann (not assembly).
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.text
.align 3 ; 8-byte/64-bit alignment

.include "inc_token_table.s"

/*
struct Symbol {
    int width       ; byte width of a value
    int nptr        ; number of pointer indirections
    int offset      ; locals : register number (x20-7)
                    ; statics: negative sequence
}
*/
OFF_WIDTH   = 0
OFF_NPTR    = 0x8
OFF_OFFSET  = 0x10
SIZEOF      = OFF_OFFSET + 8

/* Symbol* new( int type, int nptr ) */
.global __j_Symbol__new
__j_Symbol__new:
    ; create frame
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    ; end frame

    cmp     x0, T_KW_BOOL
    b.eq    new_byte
    cmp     x0, T_KW_CHAR
    b.eq    new_byte
    mov     x0, 0x8
    b       new_doit

    new_byte:
    mov     x0, 0x1

    new_doit:
    stp     x0, x1, [sp, -0x10]!
    mov     x0, SIZEOF              ; how much to allocate
    bl      __j_malloc              ; allocate
    ldp     x1, x2, [sp], 0x10
    stp     x1, x2, [x0]            ; initialize width & nptr

    ; restore frame
    ldp     fp, lr, [sp], 0x10
    ret

/* int offset( Symbol* s ) */
.global __j_Symbol_offset
__j_Symbol_offset:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

    ldr     x0, [x0, OFF_OFFSET]

    ldp     fp, lr, [sp], 0x10
    ret

/* void set_offset( Symbol* s, int offset ) */
.global __j_Symbol_set_offset
__j_Symbol_set_offset:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

    str     x1, [x0, OFF_OFFSET]

    ldp     fp, lr, [sp], 0x10
    ret
