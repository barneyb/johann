;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align  3                           ; Make sure everything is 8-byte/64-bit aligned
.set    PAGE_SIZE, 0x4000           ; todo: compile-time dynamic!

/* void exit( int status ) */
.global __j_sys_exit
__j_sys_exit:
    ; flush STDOUT first
    stp     fp, lr, [sp, -0x10]!
    mov     fp, sp
    str     x0, [sp, -0x10]!
    bl      __flush_stdout
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
    bl      __flush_stdout
    ldp     x1, x2, [sp], 0x10      ; load buf and count

    ; print the message
    mov     x0, #2                  ; 2 = StdErr
    bl      __j_sys_write

    ; exit with status code
    ldr     x0, [sp], 0x10          ; load status
    b       sys_exit

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
