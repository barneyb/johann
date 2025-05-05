/**
 * I hold thin wrappers around system calls. There are a few simplifications,
 * such as "no file descriptors", so IO is only standard in/out/err and mapped
 * memory is always anonymous, private, and read/write.
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3 ; 8-byte/64-bit alignment
.set    MAP_ANON    , 0x1000
.set    MAP_PRIVATE , 0x0002
.set    PROT_READ   , 0x01
.set    PROT_WRITE  , 0x02

/* ssize_t stout( const void *buf, size_t count ) */
.global _os_stdout
_os_stdout:
    mov     x16, #1                 ; 1 = StdOut
    b       os_write

/* ssize_t stderr( const void *buf, size_t count ) */
.global _os_stderr
_os_stderr:
    mov     x16, #2                 ; 2 = StdErr
    b       os_write

/* int munmap( caddr_t addr, size_t len ) */
.global _os_munmap
_os_munmap:
    /* 73 - int munmap(caddr_t addr, size_t len) */
    mov     x16, #73                ; 73 = munmap system call
    svc     #0x80                   ; Call kernel
    ret                             ; transfer control back, propagating return code
