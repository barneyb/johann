;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align  3                           ; Make sure everything is 8-byte/64-bit aligned
.set    PAGE_SIZE, 0x4000           ; todo: compile-time dynamic!

/* void exit( int status ) */
.global __j_sys_exit
__j_sys_exit:
    mov     x16, #1                 ; 1 = terminate system call
    svc     #0x80                   ; Call kernel to terminate the program (propagating x0)

/* void panic( int status, const char *buf, size_t count ) */
.global __j_panic
__j_panic:
    mov     x19, x0
    mov     x0, #2                  ; 2 = StdErr
    bl      __j_sys_write
    mov     x0, x19
    b       __j_sys_exit

/* ssize_t read( int fd, void *buf, size_t nbyte ) */
.global __j_sys_read
__j_sys_read:
    str     lr, [sp, #-16]!
    mov     x16, #3                 ; 3 = read system call
    svc     #0x80                   ; Call the kernel
    ldr     lr, [sp], #16
    ret

/* ssize_t write( int fd, const void *buf, size_t count ) */
.global __j_sys_write
__j_sys_write:
    str     lr, [sp, #-16]!
    mov     x16, #4                 ; 4 = write system call
    svc     #0x80                   ; Call kernel
    ldr     lr, [sp], #16
    ret                             ; transfer control back, propagating nbytes written
