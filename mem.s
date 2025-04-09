/**
 * I provide an "allocator" for dynamic memory, in an EXTREMELY loose sense.
 * Memory is allocated with egregious waste AND leaked with gusto! Don't let the
 * names fool you into thinking there's competence present: there isn't.
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
err_alloc: .ascii "Failed to allocate\n"
.set err_alloc_len, . - err_alloc

err_free: .ascii "Failed to free\n"
.set err_free_len, . - err_free

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3                            ; Make sure everything is 8-byte/64-bit aligned
.set PAGE_SIZE, 0x4000              ; todo: compile-time dynamic!

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
    b.ge    _mem_alloc_return       ; successfully allocated
    mov     x19, #-1                ; FAIL. negate return value
    mul     x19, x19, x0

    adrp    x0, err_alloc@PAGE
    add     x0, x0, err_alloc@PAGEOFF
    mov     x1, err_alloc_len
    bl      _os_stderr              ; print error

    mov     x0, x19
    b       _os_exit                ; bye!

    _mem_alloc_return:
    ; restore frame
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
    b.eq    _mem_free_return        ; success!
    mov     x19, x0                 ; stash to use as exit code

    adrp    x0, err_free@PAGE
    add     x0, x0, err_free@PAGEOFF
    mov     x1, err_free_len
    bl      _os_stderr              ; print error

    mov     x0, x19
    b       _os_exit                ; bye!

    _mem_free_return:
    ; restore frame
    ldp     lr, x19, [sp], #16      ; restore LR and x19
    ret

/* void* calloc( size_t num, size_t size ) */
; todo

/* void* realloc( void* ptr, size_t new_size ) */
; todo
