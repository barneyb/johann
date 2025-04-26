;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align  3                           ; Make sure everything is 8-byte/64-bit aligned
.set    PAGE_SIZE, 0x4000           ; todo: compile-time dynamic!

/* void exit( int status ) */
.global __j_exit
__j_exit:
    mov     x16, #1                 ; 1 = terminate system call
    svc     #0x80                   ; Call kernel to terminate the program (propagating x0)

/* void panic( int status, const char *buf, size_t count ) */
.global __j_panic
__j_panic:
    mov     x19, x0
    mov     x0, #2                  ; 2 = StdErr
    bl      __j_write
    mov     x0, x19
    b       __j_exit

/* ssize_t write( int fd, const void *buf, size_t count ) */
.global __j_write
__j_write:
    mov     x16, #4                 ; 4 = write system call
    svc     #0x80                   ; Call kernel
    ret                             ; transfer control back, propagating nbytes written
