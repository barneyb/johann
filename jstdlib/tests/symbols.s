;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
size: .asciz "size: %d\n"
contains: .asciz "contains '%s': %b\n"
value: .asciz "value of '%s': '%s'\n"
null_value: .asciz "value of '%s': null\n"
returned: .asciz "returned: '%s'\n"
ptr: .asciz "  ptr: %p\n"

k_one: .asciz "one"
k_two: .asciz "two"
k_three: .asciz "three"

spiffy: .asciz "spiffy"
goober: .asciz "goober"
thinger: .asciz "thinger"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
.text
.align 3 ; 8-byte/64-bit alignment
NULL = 0

.global _main
_main:
    bl      __j_main
    b       __j_sys_exit

.global __j_main
__j_main:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    stp     x20, x21, [sp, -0x10]!
    stp     xzr, x19, [sp, -0x10]!
    adrp    x19, k_one@PAGE
    add     x19, x19, k_one@PAGEOFF
    adrp    x20, k_two@PAGE
    add     x20, x20, k_two@PAGEOFF
    adrp    x21, k_three@PAGE
    add     x21, x21, k_three@PAGEOFF

    ; create a table
    adrp    x0, __j_strcmp@PAGE
    add     x0, x0, __j_strcmp@PAGEOFF
    bl      __j_Table__new
    str     x0, [sp]                ; store pointer -> table
;        adrp    x0, ptr@PAGE
;        add     x0, x0, ptr@PAGEOFF
;        ldr     x1, [sp]            ; load pointer -> table
;        bl      __j_printf
;        ldr     x1, [sp]            ; load pointer -> table
;        ldr     x1, [x1]    ; size
;        adrp    x0, ptr@PAGE
;        add     x0, x0, ptr@PAGEOFF
;        bl      __j_printf
;        ldr     x1, [sp]            ; load pointer -> table
;        ldr     x1, [x1, 0x8]    ; comparator
;        adrp    x0, ptr@PAGE
;        add     x0, x0, ptr@PAGEOFF
;        bl      __j_printf
;        ldr     x1, [sp]            ; load pointer -> table
;        ldr     x1, [x1, 0x10]    ; head
;        adrp    x0, ptr@PAGE
;        add     x0, x0, ptr@PAGEOFF
;        bl      __j_printf
;        ldr     x1, [sp]            ; load pointer -> table
;        ldr     x1, [x1, 0x18]    ; tail
;        adrp    x0, ptr@PAGE
;        add     x0, x0, ptr@PAGEOFF
;        bl      __j_printf
    ldr     x0, [sp]                ; load pointer -> table
    bl      print_size
        bl __flush_stdout
        bl __flush_stdout
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x19                 ; check key 1
    bl      print_contains
        bl __flush_stdout
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x20                 ; check key 2
    bl      print_contains
        bl __flush_stdout

    ; add key
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x19
    adrp    x2, spiffy@PAGE
    add     x2, x2, spiffy@PAGEOFF
    bl      __j_Table_put           ; key 1 => spiffy
    mov     x1, x0
    adrp    x0, ptr@PAGE
    add     x0, x0, ptr@PAGEOFF
    bl      __j_printf
    ldr     x0, [sp]                ; load pointer -> table
    bl      print_size
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x19                 ; check key 1
    bl      print_contains
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x19                 ; get key 1
    bl      print_get
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x20                 ; check key 2
    bl      print_contains
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x20                 ; get key 2
    bl      print_get

    ; add another key
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x20
    adrp    x2, goober@PAGE
    add     x2, x2, goober@PAGEOFF
    bl      __j_Table_put           ; key 2 => goober
    mov     x1, x0
    adrp    x0, ptr@PAGE
    add     x0, x0, ptr@PAGEOFF
    bl      __j_printf
    ldr     x0, [sp]                ; load pointer -> table
    bl      print_size
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x19                 ; check key 1
    bl      print_contains
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x19                 ; get key 1
    bl      print_get
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x20                 ; check key 2
    bl      print_contains
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x20                 ; get key 2
    bl      print_get

    ; replace key
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x19
    adrp    x2, thinger@PAGE
    add     x2, x2, thinger@PAGEOFF
    bl      __j_Table_put           ; key 1 => thinger
    mov     x1, x0
    adrp    x0, returned@PAGE
    add     x0, x0, returned@PAGEOFF
    bl      __j_printf
    ldr     x0, [sp]                ; load pointer -> table
    bl      print_size
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x19                 ; check key 1
    bl      print_contains
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x19                 ; get key 1
    bl      print_get
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x20                 ; check key 2
    bl      print_contains
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x20                 ; get key 2
    bl      print_get

    ; remove non-existent key
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x21
    bl      __j_Table_remove        ; key three is already missing
    mov     x1, x0
    adrp    x0, ptr@PAGE
    add     x0, x0, ptr@PAGEOFF
    bl      __j_printf
    ldr     x0, [sp]                ; load pointer -> table
    bl      print_size

    ; remove a key
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x19
    bl      __j_Table_remove        ; remove key 1
    mov     x1, x0
    adrp    x0, returned@PAGE
    add     x0, x0, returned@PAGEOFF
    bl      __j_printf
    ldr     x0, [sp]                ; load pointer -> table
    bl      print_size

    ; remove final key
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x20
    bl      __j_Table_remove        ; remove key 1
    mov     x1, x0
    adrp    x0, returned@PAGE
    add     x0, x0, returned@PAGEOFF
    bl      __j_printf
    ldr     x0, [sp]                ; load pointer -> table
    bl      print_size

    ; remove when empty
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x20
    bl      __j_Table_remove        ; key three is already missing
    mov     x1, x0
    adrp    x0, ptr@PAGE
    add     x0, x0, ptr@PAGEOFF
    bl      __j_printf
    ldr     x0, [sp]                ; load pointer -> table
    bl      print_size

    ; add a couple keys
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x19
    adrp    x2, spiffy@PAGE
    add     x2, x2, spiffy@PAGEOFF
    bl      __j_Table_put           ; key 1 => spiffy
    ldr     x0, [sp]                ; load pointer -> table
    mov     x1, x21
    adrp    x2, thinger@PAGE
    add     x2, x2, thinger@PAGEOFF
    bl      __j_Table_put           ; key 3 => thinger

    ; drop the table
    ldr     x0, [sp]                ; load pointer -> table
    bl      __j_Table_drop          ; drop it

    mov     x0, #0
    add     sp, sp, 0x20
    ldp     fp, lr, [sp], 0x10
    ret

/* void print_size( Table* t ) */
print_size:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    bl      __j_Table_size
    mov     x1, x0
    adrp    x0, size@PAGE
    add     x0, x0, size@PAGEOFF
    bl      __j_printf
    ldp     fp, lr, [sp], 0x10
    ret

/* void print_contains( Table* t, ? key ) */
print_contains:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    str     x1, [sp, -0x10]!        ; store key
    bl      __j_Table_contains
    mov     x2, x0
    ldr     x1, [sp], 0x10          ; load key
    adrp    x0, contains@PAGE
    add     x0, x0, contains@PAGEOFF
    bl      __j_printf
    ldp     fp, lr, [sp], 0x10
    ret

/* void print_get( Table* t, ? key ) */
print_get:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    str     x1, [sp, -0x10]!        ; store key
    bl      __j_Table_get
    cmp     x0, NULL
    b.eq    print_get_null
        mov     x2, x0
        ldr     x1, [sp], 0x10          ; load key
        adrp    x0, value@PAGE
        add     x0, x0, value@PAGEOFF
        bl      __j_printf
        b       print_get_done

    print_get_null:
        ldr     x1, [sp], 0x10          ; load key
        adrp    x0, null_value@PAGE
        add     x0, x0, null_value@PAGEOFF
        bl      __j_printf

    print_get_done:
    ldp     fp, lr, [sp], 0x10
    ret
