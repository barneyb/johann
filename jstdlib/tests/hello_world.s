NULL = 0
EOF = -1
BUF_SIZE = 20                       ; max 'name' bytes to read from STDIN
.data
prompt: .asciz  "Name: "
hello: .asciz  "Hello, "
world: .asciz  "world"
bang: .asciz  "!"

.text

.global _main
_main:
    bl      __j_main
    b       __j_sys_exit

.global __j_main
__j_main:
    str     lr, [sp, #-16]!
    ; sp[24] : char* buf
    ; sp[16] : char* name
    stp     xzr, xzr, [sp, #-16]!
    ; sp[8] : char** argv
    ; sp[0] : int argc
    stp     x0, x1, [sp, #-16]!

    ldr     x0, [sp]                ; load argc
    cmp     x0, #1
    b.gt    main_use_arg
    bl      get_name
    cmp     x0, NULL
    b.eq    main_use_world
    str     x0, [sp, #24]           ; store pointer -> buffer
    str     x0, [sp, #16]           ; store pointer -> name
    b       main_greet

    main_use_world:
    adrp    x0, world@PAGE
    add     x0, x0, world@PAGEOFF
    str     x0, [sp, #16]           ; store world in name
    b       main_greet

    main_use_arg:
    ldr     x0, [sp, #8]            ; load argv
    ldr     x0, [x0, #8]            ; load argv[1]
    str     x0, [sp, #16]           ; store argv[1] in name

    main_greet:
    adrp    x0, hello@PAGE
    add     x0, x0, hello@PAGEOFF
    bl      __j_print
    ldr     x0, [sp, #16]           ; load pointer -> name
    bl      __j_print
    adrp    x0, bang@PAGE
    add     x0, x0, bang@PAGEOFF
    bl      __j_println

    str     x0, [sp, #24]
    bl      __j_free                ; free the buffer (if non-null)

    mov     x0, #0
    add     sp, sp, #32
    ldr     lr, [sp], #16
    ret

get_name:
    str     lr, [sp, #-16]!
    ; sp[8] : int read
    ; sp[0] : char* buffer
    stp     xzr, xzr, [sp, #-16]!

    adrp    x0, prompt@PAGE
    add     x0, x0, prompt@PAGEOFF
    bl      __j_print
    mov     x0, BUF_SIZE
    bl      __j_malloc
    str     x0, [sp]                ; store pointer -> buffer

    mov     x2, BUF_SIZE
    mov     x1, x0
    mov     x0, #0                  ; 0 = StdIn
    bl      __j_sys_read
    str     x0, [sp, #8]            ; store bytes read

    cmp     x0, #1
    b.gt    get_name_doit           ; read at least one byte before EOL
    ; read nothing
    ldr     x0, [sp]                ; load pointer -> buffer
    bl      __j_free
    mov     x0, NULL
    b       get_name_return

    get_name_doit:
    ldr     x0, [sp]                ; load pointer -> buffer
    ldr     x2, [sp, #8]            ; load bytes read
    sub     x2, x2, #1              ; don't want the EOL
    add     x2, x0, x2              ; pointer -> write the null
    mov     w1, NULL
    strb    w1, [x2]                ; add a null byte at the end

    get_name_return:
    add     sp, sp, #16
    ldr     lr, [sp], #16
    ret
