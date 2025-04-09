/**
 * I provide an "allocator" for dynamic memory, in an EXTREMELY loose sense.
 * Memory is allocated with egregious waste AND leaked with gusto! Don't let the
 * names fool you into thinking there's competence present: there isn't.
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
pre_alloc: .ascii "#[alloc]: "
.set    pre_alloc_len, . - pre_alloc

pre_free: .ascii "#[free ]: "
.set    pre_free_len, . - pre_free

err_alloc: .ascii "ERROR: Failed to allocate\n"
.set    err_alloc_len, . - err_alloc

err_free: .ascii "ERROR: Failed to free\n"
.set    err_free_len, . - err_free

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align  3                           ; Make sure everything is 8-byte/64-bit aligned
.set    PAGE_SIZE, 0x4000           ; todo: compile-time dynamic!

/* void* malloc( size_t size ) */
.global _mem_alloc
_mem_alloc:
    ; create frame
    stp     lr, x19, [sp, #-16]!    ; save LR and x19
    ; end frame
    mov     x0, #0                  ; don't care where
    mov     x1, PAGE_SIZE           ; every allocation gets a page
    bl      _os_mmap
    cmp     x0, #0
    b.ge    alloc_return            ; successfully allocated
    mov     x19, #-1                ; FAIL. negate return value
    mul     x19, x19, x0

    adrp    x0, err_alloc@PAGE
    add     x0, x0, err_alloc@PAGEOFF
    mov     x1, err_alloc_len
    bl      _os_stderr              ; print error

    mov     x0, x19
    b       _os_exit                ; bye!

    alloc_return:
    ; restore frame
    ldp     lr, x19, [sp], #16      ; restore LR and x19
    ret

/* void* malloc_LOG( size_t size ) */
.global _mem_alloc_LOG
_mem_alloc_LOG:
    ; create frame
    stp     lr, x19, [sp, #-16]!    ; save LR and x19
    str     x20, [sp, #-16]!        ; save x20
    ; end frame

    bl  _mem_alloc
    mov     x19, x0                 ; stash for later

    ; print the address of the new allocation
    adrp    x0, pre_alloc@PAGE
    add     x0, x0, pre_alloc@PAGEOFF
    mov     x1, pre_alloc_len
    bl      _os_stdout
    mov     x0, x19
    bl      _int2str
    mov     x20, x0
    bl      _println_z
    mov     x0, x20
    bl      _mem_free

    mov     x0, x19
    ; restore frame
    ldr     x20, [sp], #16      ; restore x20
    ldp     lr, x19, [sp], #16      ; restore LR and x19
    ret

/* void free_LOG( void* ptr ) */
.global _mem_free_LOG
_mem_free_LOG:
    ; create frame
    stp     lr, x19, [sp, #-16]!    ; save LR and x19
    str     x20, [sp, #-16]!        ; save x20
    ; end frame

    mov     x19, x0                 ; stash for later

    ; print the address of the allocation to free
    adrp    x0, pre_free@PAGE
    add     x0, x0, pre_free@PAGEOFF
    mov     x1, pre_free_len
    bl      _os_stdout
    mov     x0, x19
    bl      _int2str
    mov     x20, x0
    bl      _println_z
    mov     x0, x20
    bl      _mem_free

    mov     x0, x19
    bl      _mem_free
    ; restore frame
    ldr     x20, [sp], #16      ; restore x20
    ldp     lr, x19, [sp], #16      ; restore LR and x19
    ret

/* void free( void* ptr ) */
.global _mem_free
_mem_free:
    ; create frame
    stp     lr, x19, [sp, #-16]!    ; save LR and x19
    ; end frame
    mov     x1, PAGE_SIZE           ; every allocation got a page
    bl      _os_munmap
    cmp     x0, #0
    b.eq    free_return             ; success!
    mov     x19, x0                 ; stash to use as exit code

    adrp    x0, err_free@PAGE
    add     x0, x0, err_free@PAGEOFF
    mov     x1, err_free_len
    bl      _os_stderr              ; print error

    mov     x0, x19
    b       _os_exit                ; bye!

    free_return:
    ; restore frame
    ldp     lr, x19, [sp], #16      ; restore LR and x19
    ret

/* void* calloc( size_t num, size_t size ) */
; todo

/* void* realloc( void* ptr, size_t new_size ) */
; todo
