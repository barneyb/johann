.text
.align 3                            ; Make sure everything is 8-byte/64-bit aligned
.set MAP_ANON, 0x1000
.set MAP_PRIVATE, 0x0002
.set PROT_READ, 0x01
.set PROT_WRITE, 0x02

/* void exit(int status) */
.global _os_exit
_os_exit:
    /* 1 - void exit(int status) */
    mov     x16, #1                 ; 1 = terminate system call
    svc     #0x80                   ; Call kernel to terminate the program (propagating x0)

/* ssize_t stout(const void *buf, size_t count) */
.global _os_stdout
_os_stdout:
    mov     x16, #1                 ; 1 = StdOut
    b       os_write

/* ssize_t stderr(const void *buf, size_t count) */
.global _os_stderr
_os_stderr:
    mov     x16, #2                 ; 2 = StdErr
    b       os_write

; pass the file descriptor in x16
os_write:
    /* 4 - write(int fd, const void *buf, size_t count) */
    mov     x2, x1                  ; number of bytes write
    mov     x1, x0                  ; buffer to print from
    mov     x0, x16                 ; file descriptor
    mov     x16, #4                 ; 4 = write system call
    svc     #0x80                   ; Call kernel
    ret                             ; transfer control back, propagating nbytes written

/* ssize_t stdin(void *buf, size_t nbyte); */
.global _os_stdin
_os_stdin:
    /* 3 - ssize_t read(int fd, void *buf, size_t nbyte); */
    mov     x2, x1                  ; max bytes to read
    mov     x1, x0                  ; buffer to read them into
    mov     x0, #0                  ; 0 = StdIn
    mov     x16, #3                 ; 3 = read system call
    svc     #0x80                   ; Call the kernel
    ret                             ; transfer control back, propagating nbytes read

/* user_addr_t mmap(caddr_t addr, size_t len) */
.global _os_mmap
_os_mmap:
    /* 197 - user_addr_t mmap(caddr_t addr, size_t len, int prot, int flags, int fd, off_t pos) */
    mov     x5, #0                  ; ignored w/out a fd?
    mov     x4, #-1                 ; -1 = no file descriptor
    mov     x3, MAP_ANON ^ MAP_PRIVATE
    mov     x2, PROT_READ ^ PROT_WRITE
    mov     x16, #197               ; 197 = mmap system call
    svc     #0x80                   ; Call kernel
    ret                             ; transfer control back, propagating address

/* int munmap(caddr_t addr, size_t len) */
.global _os_munmap
_os_munmap:
    /* 73 - int munmap(caddr_t addr, size_t len) */
    mov     x16, #73                ; 73 = munmap system call
    svc     #0x80                   ; Call kernel
    ret                             ; transfer control back, propagating return code
