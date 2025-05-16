;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3 ; 8-byte/64-bit alignment
NULL = 0
TRUE = 1
FALSE = 0

; struct Table {
;   int size
;   fn* comparator
;   Node* head
;   Note* tail
; }

; struct Node {
;   Node* prev
;   ? key
;   ? value
;   Node* next
; }

/* Table* Table__new( fn* comparator ) */
.global __j_Table__new
__j_Table__new:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    str     x0, [sp, -0x10]!        ; store pointer -> comparator
    mov     x0, 0x20                ; size, comparator, head, tail
    bl      __j_malloc
    ldr     x1, [sp], 0x10          ; load pointer -> comparator
    stp     xzr, x1, [x0]           ; initialize size and comparator
    stp     xzr, xzr, [x0, 0x10]    ; initialize head and tail

    ldp     fp, lr, [sp], 0x10
    ret

/* int Table_size( Table* t ) */
.global __j_Table_size
__j_Table_size:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    ldr     x0, [x0]                ; load the size field
    ldp     fp, lr, [sp], 0x10
    ret

/* void Table_drop( Table* t ) */
.global __j_Table_drop
__j_Table_drop:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

    ldr     x1, [x0, 0x10]          ; load t.head
    str     x1, [sp, -0x10]!        ; store curr
    bl      __j_free                ; free t

    drop_again:
    ldr     x0, [sp]                ; load curr
    cmp     x0, NULL
    b.eq    drop_done
    ldr     x1, [x0, 0x18]          ; load curr.next
    str     x1, [sp]                ; store curr
    bl      __j_free                ; free curr
    b       drop_again

    drop_done:
    add     sp, sp, 0x10
    ldp     fp, lr, [sp], 0x10
    ret

/* ? Table_put( Table* t, ? key, ? value ) */
.global __j_Table_put
__j_Table_put:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    ; sp[0x10] : value
    str     x2, [sp, -0x10]!        ; store pointer -> value
    ; sp[0x8] : key
    ; sp[0x0] : table
    stp     x0, x1, [sp, -0x10]!    ; store pointer -> table and -> key

    bl      find_node
    cmp     x0, NULL
    b.eq    put_add
        ldr     x1, [x0, 0x10]      ; load node.value
        ldr     x2, [sp, 0x10]      ; load pointer -> value
        str     x2, [x0, 0x10]      ; node.value = pointer -> value
        mov     x0, x1              ; return prior value
        b       put_done

    put_add:
    mov     x0, 0x20                ; prev, key, value, next
    bl      __j_malloc              ; allocate new node
    str     xzr, [x0, 0x18]         ; new node.next = NULL
    ldr     x3, [sp]                ; load pointer -> table
    ldr     x4, [x3]                ; load table.size
    add     x4, x4, #1
    str     x4, [x3]                ; store table.size
    cmp     x4, #1                  ; first node is special
    b.eq    put_add_first
        ; add to the list...
        ldr     x4, [x3, 0x18]          ; load table.tail
        str     x0, [x4, 0x18]          ; tail.next = pointer -> new node
        str     x4, [x0]                ; new node.prev = pointer -> tail
        str     x0, [x3, 0x18]          ; table.tail = pointer -> new node
        b       put_add_done
    put_add_first:
        str     xzr, [x0]               ; new node.prev = NULL
        stp     x0, x0, [x3, 0x10]      ; table.head = .tail = pointer -> new node
    put_add_done:
        ldp     x1, x2, [sp, 0x8]       ; load pointers -> key and -> value
        stp     x1, x2, [x0, 0x8]       ; new node.key = pointer -> key
                                        ; new node.value = pointer -> value
        mov     x0, NULL                ; return null (prior value)

    put_done:
    add     sp, sp, 0x20            ; release local variables
    ldp     fp, lr, [sp], 0x10
    ret

/* ? Table_remove( Table* t, ? key ) */
.global __j_Table_remove
__j_Table_remove:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    ; sp[0x0] : table
    str     x0, [sp, -0x10]!        ; store pointer -> table

    bl      find_node
    cmp     x0, NULL
    b.eq    remove_done

    ldr     x3, [sp]                ; load pointer -> table
    ldp     x1, x2, [x3, 0x10]      ; load table.head and .tail
    ; if (table.head == node)
    cmp     x1, x0
    b.ne    remove_not_head
        ; table.head = node.next
        ldr     x4, [x0, 0x18]
        str     x4, [x3, 0x10]
        b       remove_tail
    remove_not_head:
        ;  node.prev.next = node.next
        ldr     x4, [x0, 0x18]      ; load node.next
        ldr     x5, [x0]            ; load node.prev
        str     x4, [x5, 0x18]
    remove_tail:
    ; if (table.tail == node)
    cmp     x2, x0
    b.ne    remove_not_tail
        ; table.tail = node.prev
        ldr     x4, [x0]
        str     x4, [x3, 0x18]
        b       remove_free
    remove_not_tail:
        ; else node.next.prev = node.prev
        ldr     x4, [x0]            ; load node.prev
        ldr     x5, [x0, 0x18]      ; load node.next
        str     x4, [x5]

    remove_free:
    ldr     x1, [x3]                ; load table.size
    sub     x1, x1, #1              ; decrement
    str     x1, [x3]                ; store table.size

    ldr     x1, [x0, 0x10]          ; load node.value
    str     x1, [sp]                ; store value
    bl      __j_free                ; free node
    ldr     x0, [sp]                ; return value

    remove_done:
    add     sp, sp, 0x10            ; release local variables
    ldp     fp, lr, [sp], 0x10
    ret

/* ? Table_get( Table* t, ? key ) */
.global __j_Table_get
__j_Table_get:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    bl      find_node
    cmp     x0, NULL
    b.eq    get_done
    ldr     x0, [x0, 0x10]          ; load node.value

    get_done:
    ldp     fp, lr, [sp], 0x10
    ret

/* bool Table_contains( Table* t, ? key ) */
.global __j_Table_contains
__j_Table_contains:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    bl      find_node
    ldp     fp, lr, [sp], 0x10
    ret

/* Node* find_node( Table* t, ? key ) */
.global find_node
find_node:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    stp     x19, x20, [sp, -0x10]!  ; save registers
    stp     x0, x1, [sp, -0x10]!    ; store pointer -> table and key
    ldp     x19, x20, [x0, 0x8]     ; load comparator and head

    find_node_again:
    cmp     x20, NULL
    b.eq    find_node_done          ; didn't find it
    ldr     x0, [sp, 0x8]           ; load key
    ldr     x1, [x20, 0x8]          ; load head's key
    blr     x19                     ; call comparator
    cmp     x0, xzr
    b.eq    find_node_done          ; keys matched
    ldr     x20, [x20, 0x18]        ; load head.next
    b       find_node_again

    find_node_done:
    mov     x0, x20                 ; return pointer -> node
    add     sp, sp, 0x10            ; release local storage
    ldp     x19, x20, [sp], 0x10    ; restore registers
    ldp     fp, lr, [sp], 0x10
    ret
