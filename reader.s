/**
 * I provide a "buffered reader" "class" and a singleton instance of it, so
 * STDIN can be efficiently consumed one character at a time by the program.
 */

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .bss
instance: .zero 8

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .data
;m_read: .asciz "< read > "
;m_eof: .asciz "¡¡at EOF!!"
;m_not_eof: .asciz "¡¡not at EOF!!"

err_read_at_eof: .asciz "ERROR: cannot read (at EOF)\n"
.set err_read_at_eof_len, . - err_read_at_eof

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3                            ; Make sure everything is 8-byte/64-bit aligned
.set NULL, 0
.set TRUE, 1
.set FALSE, 0

/*
struct Reader {
    int size                        ; number of bytes in the buffer
                                    ; negative means EOF reached
    int position                    ; next index to read
    char[CAP] buffer                ; buffered bytes
}
*/
.set CAP, 1024
.set SIZEOF, CAP + 16

/* Reader* instance( ) */
.global _Reader_instance
_Reader_instance:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    str     x20, [sp, #-16]!
    ; end frame

    adrp    x19, instance@PAGE
    add     x19, x19, instance@PAGEOFF
    ldr     x20, [x19]              ; get the pointer
    cmp     x20, NULL
    b.ne    instance_ret            ; already built it
    mov     x0, SIZEOF              ; how much to allocate
    bl      _mem_alloc              ; allocate
    stp     xzr, xzr, [x0]          ; initialize
    str     x0, [x19]               ; store singleton

    instance_ret:
;        ; print the address of the singleton
;        mov     x19, x0
;        bl      _itoa
;        mov     x20, x0
;        bl      _println_z
;        mov     x0, x20
;        bl      _mem_free
;        mov     x0, x19
    ; restore frame
    ldr     x20, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

/* char read( Reader* r ) */
.global _reader_read
_reader_read:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    ; end frame

    mov     x19, x0                 ; pointer -> this
    ldp     x20, x21, [x19]         ; size & position
    cmp     x20, #0
    b.lt    read_eof                ; already at EOF
    cmp     x21, x20
    b.lt    read_consume            ; buffer already has one
    mov     x0, x19
    bl      refill_buffer           ; this.refill_buffer()
    cmp     x0, #0
    b.gt    read_consume            ; read something

    read_eof:
    adrp    x0, err_read_at_eof@PAGE
    add     x0, x0, err_read_at_eof@PAGEOFF
    mov     x1, err_read_at_eof_len
    bl      _os_stderr              ; print error
    mov     x0, #1                  ; exit with 1
    b       _os_exit                ; bye!

    read_consume:
    ; pos <= size, so return buf[pos++]
    add     x20, x19, #16           ; pointer -> this.buffer
    add     x20, x20, x21           ; pointer -> this.buffer[pos]
    ldrb    w0, [x20]               ; read the char
    add     x21, x21, #1            ; increment pos
    add     x20, x19, #8            ; pointer -> this.position
    str     x21, [x20]              ; update this.position

    ; restore frame
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

/* boolean is_eof( Reader* r ) */
.global _reader_is_eof
_reader_is_eof:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    ; end frame

    mov     x19, x0                 ; pointer -> this
    ldp     x20, x21, [x19]         ; size & position
    cmp     x20, #0
    b.lt    is_eof_yep              ; negative size means EOF
    cmp     x21, x20
    b.lt    is_eof_nope             ; more bytes in buffer

    ; get some more bytes, if possible
    mov     x0, x19
    bl      refill_buffer           ; this.refill_buffer()
    cmp     x0, #0
    b.gt    is_eof_nope             ; read something!

    is_eof_yep:
;        ; indicate at EOF
;        adrp    x0, m_eof@PAGE
;        add     x0, x0, m_eof@PAGEOFF
;        bl      _println_z
    mov     x0, TRUE
    b       is_eof_ret

    is_eof_nope:
;        ; indicate not at EOF
;        adrp    x0, m_not_eof@PAGE
;        add     x0, x0, m_not_eof@PAGEOFF
;        bl      _println_z
    mov     x0, FALSE

    is_eof_ret:
    ; restore frame
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

/* void destroy( ) */
.global _Reader_destroy
_Reader_destroy:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    str     x20, [sp, #-16]!
    ; end frame

    adrp    x19, instance@PAGE
    add     x19, x19, instance@PAGEOFF
    ldr     x20, [x19]              ; get the pointer
    cmp     x20, NULL
    b.eq    destroy_return          ; no instance exists
    mov     x0, #0
    str     x0, [x19]               ; null the instance pointer
    mov     x0, x20
    bl      _mem_free               ; free the memory

    destroy_return:
    ; restore frame
    ldr     x20, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

/* ssize_t refill_buffer( ) */
refill_buffer:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    ; end frame

    mov     x19, x0                 ; pointer -> this
    ldp     x0, x1, [x19]           ; load this.size & .position
    cmp     x0, #0
    b.lt    refill_buffer_ret       ; reached EOL already
    cmp     x1, x0
    b.lt    refill_buffer_ret       ; buffer has more to read

    mov     x0, x19
    add     x0, x0, #16             ; pointer -> this.buffer
    mov     x1, CAP
    bl      _os_stdin

    cmp     x0, #0
    b.le    refill_buffer_eof       ; EOL / zero bytes
    mov     x1, #0                  ; back to the beginning
    stp     x0, x1, [x19]           ; update this.size & .position
;        str     x20, [sp, #-16]!    ; miniframe
;        mov     x20, x0             ; save size (for return)
;        ; print how much was just read
;        bl      _int2str
;        bl      _println_z
;        ; print what was just read
;        adrp    x0, m_read@PAGE
;        add     x0, x0, m_read@PAGEOFF
;        bl      _print_z
;        mov     x0, x19
;        add     x0, x0, #16         ; pointer -> this.buffer
;        ldr     x1, [x19]           ; load this.size
;        bl      _println_n
;        mov     x0, x20             ; restore size
;        ldr     x20, [sp], #16      ; clean up miniframe
    b       refill_buffer_ret

    refill_buffer_eof:
    mov     x0, #-1                 ; negative size means hit EOL
    str     x0, [x19]

    ; happy or sad path, x0 has the size to return

    refill_buffer_ret:
    ; restore frame
    ldp     lr, x19, [sp], #16
    ret
