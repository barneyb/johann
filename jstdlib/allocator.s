;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
err_alloc: .ascii "ERROR: Failed to allocate\n"
err_alloc_len = . - err_alloc

err_free: .ascii "ERROR: Failed to free\n"
err_free_len = . - err_free

msg_mem_stats: .asciz "; MEM: %d allocs (%x bytes)\n;      %d frees\n"
al: .asciz "    ; alloc: %p\n"
fr: .asciz "    ; free : %p\n"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .bss
start: .zero 8
end: .zero 8

alloc_stats: .zero 16
free_stats: .zero 16
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3 ; 8-byte/64-bit alignment
NULL        = 0
PAGE_SIZE   = 0x4000                ; todo: compile-time dynamic!
MAP_ANON    = 0x1000
MAP_PRIVATE = 0x0002
PROT_READ   = 0x01
PROT_WRITE  = 0x02

.global __mem_stats
__mem_stats:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp

    adrp    x0, msg_mem_stats@PAGE
    add     x0, x0, msg_mem_stats@PAGEOFF
    adrp    x1, alloc_stats@PAGE
    add     x1, x1, alloc_stats@PAGEOFF
    ldp     x1, x2, [x1]
    adrp    x3, free_stats@PAGE
    add     x3, x3, free_stats@PAGEOFF
    ldp     x3, x4, [x3]

    cmp     x1, x3
    b.ne    mem_stat_bad_count
    ; todo: sizes too!
    b       mem_stats_done

    mem_stat_bad_count:
    adrp    x0, msg_mem_stats@PAGE
    add     x0, x0, msg_mem_stats@PAGEOFF
    bl      __j_printf

    mem_stats_done:
    ldp     fp, lr, [sp], 0x10
    ret

/* void free( void *ptr ) */
.global __j_free
__j_free:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    str     x0, [sp, -0x10]!

;        mov     x1, x0
;        adrp    x0, fr@PAGE
;        add     x0, x0, fr@PAGEOFF
;        bl      __j_printf
;        ldr     x0, [sp]

    cmp     x0, NULL
    b.eq    free_return

        adrp    x3, free_stats@PAGE
        add     x3, x3, free_stats@PAGEOFF
        ldp     x1, x2, [x3]
        add     x1, x1, #1
;        add     x2, x2, x0
        stp     x1, x2, [x3]

    ; todo /* 73 - int munmap(caddr_t addr, size_t len) */

    free_return:
    add     sp, sp, 0x10
    ldp     fp, lr, [sp], 0x10
    ret

/* void* malloc( size_t size ) */
.global __j_malloc
__j_malloc:
    ; create frame
    stp     lr, x19,    [sp, #-16]!
    ; end frame
    mov     x19, x0

    ; ensure 64-bit / 8-byte aligned
    mov     x2, x0
    ubfx    x1, x0, #0, #3          ; extract three low bits
    cmp     x1, xzr
    b.eq    malloc_go               ; already aligned
    mov     x3, #8
    sub     x1, x3, x1              ; bytes to add
    add     x0, x0, x1              ; total allocation
;        .data
;        malign: .asciz "      ; resize %x (req %x)\n"
;        .text
;        stp     x0, x1, [sp, -0x10]!
;        mov x1, x0
;        adrp x0, malign@PAGE
;        add x0, x0, malign@PAGEOFF
;        bl __j_printf
;        ldp     x0, x1, [sp], 0x10

    malloc_go:
        adrp    x3, alloc_stats@PAGE
        add     x3, x3, alloc_stats@PAGEOFF
        ldp     x1, x2, [x3]
        add     x1, x1, #1
        add     x2, x2, x0
        stp     x1, x2, [x3]

    ; if start is null, ask OS
    adrp    x1, start@PAGE
    add     x1, x1, start@PAGEOFF
    ldr     x1, [x1]
    cmp     x1, NULL
    b.ne    malloc_alloc
    mov     x0, x19
    bl      get_more_memory
    ; todo: if start + size > end, need to get more from the OS as well
    malloc_alloc:
    adrp    x1, start@PAGE
    add     x1, x1, start@PAGEOFF
    ldr     x0, [x1]                ; start of allocatable spaces
    add     x2, x0, x19
    str     x2, [x1]                ; record allocation

;        str     x0, [sp, -0x10]!
;        mov     x1, x0
;        adrp    x0, al@PAGE
;        add     x0, x0, al@PAGEOFF
;        bl      __j_printf
;        ldr     x0, [sp], 0x10

    ; restore frame
    ldp     lr, x19, [sp], #16
    ret

/* user_addr_t mmap( size_t len ) */
get_more_memory:
    sub     sp, sp, #16             ; sp[0] bytes to allocate
                                    ; sp[1] return pointer
    str     lr, [sp, #8]            ; save return pointer
    ; todo: make sure this is sufficient for request
    mov     x1, PAGE_SIZE
    lsl     x1, x1, #2              ; get four pages
    str     x1, [sp]                ; store bytes to allocate

    /* 197 - user_addr_t mmap( caddr_t addr, size_t len, int prot, int flags, int fd, off_t pos ) */
    mov     x5, xzr                 ; ignored w/out a fd?
    mov     x4, #-1                 ; -1 = no file descriptor
    mov     x3, MAP_ANON ^ MAP_PRIVATE
    mov     x2, PROT_READ ^ PROT_WRITE
    mov     x0, xzr                 ; don't care where
    mov     x16, #197               ; 197 = mmap system call
    svc     #0x80                   ; Call kernel

    cmp     x0, NULL
    b.ne    get_more_memory_yerp
    mov     x0, #99
    adrp    x1, err_alloc@PAGE
    add     x1, x1, err_alloc@PAGEOFF
    mov     x2, err_alloc_len
    bl      __j_panic

    get_more_memory_yerp:
    adrp    x1, start@PAGE
    add     x1, x1, start@PAGEOFF
    str     x0, [x1]                ; store start of allocation
    ldr     x2, [sp]                ; bytes allocated
    add     x2, x0, x2              ; end of allocation
    adrp    x1, end@PAGE
    add     x1, x1, end@PAGEOFF
    str     x2, [x1]                ; store end of allocation
    ldr     lr, [sp, #8]            ; load return pointer
    add     sp, sp, #16             ; release stack frame
    ret                             ; transfer control back, propagating address
