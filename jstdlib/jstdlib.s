/**
 * I provide the standard library of global functions Johann programs can use.
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align  3                           ; Make sure everything is 8-byte/64-bit aligned
.set    NULL    , 0
.set    EOF     , -1
.set    TRUE    , 1
.set    FALSE   , 0

.global __j_itoa
__j_itoa:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    bl      _int2str
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

.global __j_free
__j_free:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    bl      _mem_free;_LOG
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

.global __j_malloc
__j_malloc:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    bl      _mem_alloc;_LOG
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

.global __j_printc
__j_printc:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    bl      _print_c
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

.global __j_print
__j_print:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    bl      _print_z
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

.global __j_println
__j_println:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    bl      _println_z
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

.global __j_read
__j_read:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame
    bl      _Reader_instance        ; r = Reader.instance()
    mov     x19, x0
    bl      _reader_is_eof          ; r.is_eof()
    cmp     x0, FALSE
    b.ne    read_eof
    mov     x0, x19
    bl      _reader_read            ; r.read()
    b       read_return

    read_eof:
    mov     x0, EOF

    read_return:
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

.global __j_storeb
__j_storeb:
    strb    w1, [x0]
    ret
