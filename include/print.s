/**
 * I provide routines for easing printing to STDOUT and STDERR
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .bss
c_buf: .zero 1

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
newline: .ascii "\n"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align  3                           ; Make sure everything is 8-byte/64-bit aligned

/* void print_i( int num ) */
.global _print_i
_print_i:
    stp     lr, x19, [sp, #-16]!
    bl      _int2str
    mov     x19, x0
    bl      _print_z
    mov     x0, x19
    bl      _mem_free;_LOG
    ldp     lr, x19, [sp], #16
    ret

/* void print_h( int num ) */
.global _print_h
_print_h:
    stp     lr, x19, [sp, #-16]!
    bl      _int2hex
    mov     x19, x0
    bl      _print_z
    mov     x0, x19
    bl      _mem_free;_LOG
    ldp     lr, x19, [sp], #16
    ret

/* void println_z( const void *buf ) */
.global _println_z
_println_z:
    ; create frame
    str     lr, [sp, #-16]!         ; save lr
    ; end frame
    bl      _print_z
    bl      _println

    ; restore frame
    ldr     lr, [sp], #16           ; restore lr
    ret

/* void println_n( const void *buf, size_t count ) */
.global _println_n
_println_n:
    ; create frame
    str     lr, [sp, #-16]!         ; save lr
    ; end frame
    bl      _os_stdout
    bl      _println

    ; restore frame
    ldr     lr, [sp], #16           ; restore lr
    ret

/* void print_c( char c ) */
.global _print_c
_print_c:
    ; create frame
    stp     lr, x19, [sp, #-16]!    ; save lr and x19
    ; end frame
    adrp    x19, c_buf@PAGE
    add     x19, x19, c_buf@PAGEOFF
    strb    w0, [x19]
    mov     x0, x19
    mov     x1, #1
    bl      _os_stdout

    ; restore frame
    ldp     lr, x19, [sp], #16      ; restore lr and x19
    ret

/* void println( ) */
.global _println
_println:
    ; create frame
    str     lr, [sp, #-16]!         ; save lr
    ; end frame
    adrp    x0, newline@PAGE
    add     x0, x0, newline@PAGEOFF
    mov     x1, #1
    bl      _os_stdout              ; print!

    ; restore frame
    ldr     lr, [sp], #16           ; restore lr
    ret
