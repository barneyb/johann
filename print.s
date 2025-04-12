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

/* void print_z( const void *buf ) */
.global _print_z
_print_z:
    ; create frame
    str     lr, [sp, #-16]!         ; save lr
    stp     x19, x20, [sp, #-16]!   ; save x19 & x20
    ; end frame
    mov     x1, x0
    mov     x20, #0

    _print_z_char:
    ldrb    w19, [x1], #1
    cmp     w19, wzr
    b.eq    _print_z_go
    add     x20, x20, #1
    b       _print_z_char

    _print_z_go:
    mov     x1, x20
    bl      _os_stdout

    ; restore frame
    ldp     x19, x20, [sp], #16     ; restore saved registers
    ldr     lr, [sp], #16           ; restore lr
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
