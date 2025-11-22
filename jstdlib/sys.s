;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3 ; 8-byte/64-bit alignment
NULL = 0

/* void exit( int status ) */
.global __j_exit
__j_exit:
    ; flush STDOUT first
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    str     x0, [sp, -0x10]!
    bl      __j_flush_stdout__
    ldr     x0, [sp], 0x10

    ; dump mem stats if non-error
    cmp     x0, #0
    b.ne    sys_exit
    str     x0, [sp, -0x10]!
    mov     x1, xzr                 ; don't force
    bl      __j_mem_stats__
    ldr     x0, [sp], 0x10

    sys_exit:
    mov     x16, #1                 ; 1 = terminate system call
    svc     #0x80                   ; Call kernel to terminate the program (propagating x0)

/* void panic( int status, const char *buf, size_t count ) */
.global __j_panic
__j_panic:
    ; flush STDOUT first
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    str     x0, [sp, -0x10]!        ; store status
    stp     x1, x2, [sp, -0x10]!    ; store buf and count
    bl      __j_flush_stdout__
    mov     x0, NULL
    bl      __j_puts
    ldp     x1, x2, [sp], 0x10      ; load buf and count

    ; print the message
    mov     x0, #2                  ; 2 = StdErr
    bl      __j_sys_write

    ; exit with status code
    ldr     x0, [sp], 0x10          ; load status
    b       sys_exit

/* 197 - user_addr_t mmap( caddr_t addr, size_t len, int prot, int flags, int fd, off_t pos ) */
.global __j_sys_mmap
__j_sys_mmap:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    mov     x16, #197               ; 197 = mmap system call
    svc     #0x80                   ; Call kernel
    ldp     fp, lr, [sp], 0x10
    ret

/* ssize_t read( int fd, void *buf, size_t nbyte ) */
.global __j_sys_read
__j_sys_read:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    mov     x16, #3                 ; 3 = read system call
    svc     #0x80                   ; Call the kernel
    ldp     fp, lr, [sp], 0x10
    ret

/* ssize_t write( int fd, const void *buf, size_t count ) */
.global __j_sys_write
__j_sys_write:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    mov     x16, #4                 ; 4 = write system call
    svc     #0x80                   ; Call kernel
    ldp     fp, lr, [sp], 0x10
    ret                             ; transfer control back, propagating nbytes written

.global __j_syscall
__j_syscall:
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    stp     x19, x20, [sp, -0x10]!
    stp     x21, x22, [sp, -0x10]!
    stp     x23, x24, [sp, -0x10]!
    stp     x25, x26, [sp, -0x10]!
    stp     x27, x28, [sp, -0x10]!

    mov     x16, x0                 ; put the call number in the right spot
    mov     x0, x1                  ; scoot any args "down" one register
    mov     x1, x2
    mov     x2, x3
    mov     x3, x4
    mov     x4, x5
    mov     x5, x6
    mov     x6, x7
    svc     #0x80                   ; Call kernel

    ldp     x27, x28, [sp], 0x10
    ldp     x25, x26, [sp], 0x10
    ldp     x23, x24, [sp], 0x10
    ldp     x21, x22, [sp], 0x10
    ldp     x19, x20, [sp], 0x10
    ldp     fp, lr, [sp], 0x10
    ret                             ; pass back whatever the kernel left in x0/1
