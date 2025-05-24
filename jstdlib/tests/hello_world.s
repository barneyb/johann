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
    b       __j_exit

.global __j_main
__j_main:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    ; sp[24] : char* buf
    ; sp[16] : char* name
    stp     xzr, xzr, [sp, -0x10]!
    ; sp[8] : char** argv
    ; sp[0] : int argc
    stp     x0, x1, [sp, -0x10]!

    ldr     x0, [sp]                ; load argc
    cmp     x0, #1
    b.gt    main_use_arg
    bl      get_name
    cmp     x0, NULL
    b.eq    main_use_world
    stp     x0, x0, [sp, 0x10]       ; store pointers -> name and -> buffer
    b       main_greet

    main_use_world:
    adrp    x0, world@PAGE
    add     x0, x0, world@PAGEOFF
    str     x0, [sp, 0x10]           ; store world in name
    b       main_greet

    main_use_arg:
    ldr     x0, [sp, 0x8]            ; load argv
    ldr     x0, [x0, 0x8]            ; load argv[1]
    str     x0, [sp, 0x10]           ; store argv[1] in name

    main_greet:
    adrp    x0, hello@PAGE
    add     x0, x0, hello@PAGEOFF
    bl      __j_printf
    ldr     x0, [sp, 0x10]           ; load pointer -> name
    bl      __j_printf
    adrp    x0, bang@PAGE
    add     x0, x0, bang@PAGEOFF
    bl      __j_puts

    ldr     x0, [sp, 0x18]
    bl      __j_free                ; free the buffer (if non-null)

    mov     x0, #0
    add     sp, sp, 0x20
    ldp     fp, lr, [sp], 0x10
    ret

get_name:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    ; sp[8] : int nchars
    ; sp[0] : char* buffer
    stp     xzr, xzr, [sp, -0x10]!

    adrp    x0, prompt@PAGE
    add     x0, x0, prompt@PAGEOFF
    bl      __j_printf
    mov     x0, BUF_SIZE
    bl      __j_malloc
    str     x0, [sp]                ; store pointer -> buffer

    get_name_again:
        bl      __j_getchar
        cmp     x0, xzr
        b.lt    get_name_done
        cmp     x0, '\n'
        b.eq    get_name_done
        ldp     x1, x2, [sp]        ; load pointer -> buffer and nchars
        add     x1, x1, x2          ; pointer -> buffer[len]
        add     x2, x2, #1          ; increment nchars
        cmp     x2, BUF_SIZE
        b.ge    get_name_done       ; out of room (with the null to come)
        strb    w0, [x1]            ; store char
        str     x2, [sp, 0x8]       ; store nchars
        b       get_name_again

    get_name_done:
    ldp     x0, x1, [sp]            ; load pointer -> buffer and nchars
    cmp     x1, #1
    b.ge    get_name_doit           ; read at least one 'real' byte
    ; read nothing
    bl      __j_free
    mov     x0, NULL
    b       get_name_return

    get_name_doit:
    add     x2, x0, x1              ; pointer -> write the null
    mov     w1, NULL
    strb    w1, [x2]                ; add a null byte at the end

    get_name_return:
    add     sp, sp, 0x10
    ldp     fp, lr, [sp], 0x10
    ret
