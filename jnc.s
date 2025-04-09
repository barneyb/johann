.set buf_len, 32

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .bss

buf: .zero buf_len

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align 3                            ; Make sure everything is 8-byte/64-bit aligned

.global _main
_main:
    bl      not_quite_lisp
    mov     x0, #0
    b       _os_exit

not_quite_lisp:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    stp     x22, x23, [sp, #-16]!
    stp     x24, x27, [sp, #-16]!
    str     x28, [sp, #-16]!
    ; end frame
    adrp    x19, buf@PAGE
    add     x19, x19, buf@PAGEOFF   ; where to read into
    mov     x20, #0                 ; floor
    mov     w21, #999               ; current char
    mov     x22, #9999              ; buffer size
    mov     x23, #9999              ; pos in buffer
    mov     x24, #9999              ; address of current char
    mov     x27, #0                 ; entered basement at
    mov     x28, #0                 ; chars read

    _main_buf_loop:
    mov     x0, x19
    mov     x1, buf_len
    bl      _os_stdin

    cmp     x0, #0
    b.le    _main_print_and_return  ; out of characters

    mov     x22, x0                 ; save buffer size
    mov     x23, #0                 ; reset pos

    _main_char_loop:
    cmp     x23, x22
    b.ge    _main_buf_loop          ; at end; read more

    add     x24, x19, x23
    add     x23, x23, #1
    ldrb    w21, [x24]
    add     x28, x28, #1            ; count char as read

    cmp     w21, '('
    b.ne    _main_p_close
    add     x20, x20, #1            ; move up a floor
    _main_p_close:
    cmp     w21, ')'
    b.ne    _main_char_loop
    sub     x20, x20, #1            ; move down a floor
    cmp     x20, #0
    b.ge    _main_char_loop         ; still above ground
    cmp     x27, #0
    b.ne    _main_char_loop         ; already went underground
    mov     x27, x28
    b       _main_char_loop

    _main_print_and_return:
    mov     x0, x20
    bl      itoa                    ; convert to null-terminated string
    mov     x20, x0                 ; save the pointer
    bl      _println_z              ; println
    mov     x0, x20                 ; free the string
    bl      _mem_free

    mov     x0, x27
    bl      itoa                    ; convert to null-terminated string
    mov     x27, x0                 ; save the pointer
    bl      _println_z              ; println
    mov     x0, x27                 ; free the string
    bl      _mem_free

    ; restore frame
    ldr     x28, [sp], #16
    ldp     x24, x27, [sp], #16
    ldp     x22, x23, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret

; The largest 64-bit integer, when decimal string-ified, has length 20. Using
; an allocation here is silly - it's only to prove dynamic memory works.
/* char* itoa( int num ) */
itoa:
    ; create frame
    stp     lr, x19, [sp, #-16]!
    stp     x20, x21, [sp, #-16]!
    stp     x22, x23, [sp, #-16]!
    stp     x24, x25, [sp, #-16]!
    ; end frame
    mov     x25, x0                 ; save num
    mov     x0, #21                 ; max len, plus room for a NULL
    bl      _mem_alloc
    mov     x24, x0                 ; pointer -> buffer
    add     x19, x24, #21           ; -> tail of buffer
    strb    wzr, [x19, #-1]!        ; put a NULL at the end
    mov     x0, x25                 ; restore num

    mov     x23, #0                 ; assume non-negative
    cmp     x0, #0
    b.ge    itoa_positive
    mov     x23, #-1                ; it's negative
    mul     x0, x0, x23
    itoa_positive:

    mov     x25, #10                ; base 10
    itoa_loop:
    sdiv    x21, x0, x25            ; x21 = x0 / 10
    msub    x22, x21, x25, x0       ; x22 = x0 - (x21 * 10)
                                    ; x22 = x0 % 10
    add     w20, w22, 0x30          ; convert to char
    strb    w20, [x19, #-1]!        ; add to string
    mov     x0, x21                 ; update x0 w/ what's left
    cmp     x0, #0
    b.ne    itoa_loop

    cmp     x23, #0
    b.eq    itoa_move
    mov     w20, '-'
    strb    w20, [x19, #-1]!        ; minus sign

    itoa_move:
    cmp     x19, x24
    b.eq    itoa_return             ; used full alloc!
    ; move to start of allocated buffer (copy [x19] to [x24])
    ; todo: straightforward implementation, but rather inefficient
    mov     x25, x24
    itoa_copy_char:
    ldrb    w20, [x19], #1          ; load and increment
    strb    w20, [x25], #1          ; store and increment
    cmp     w20, #0
    b.eq    itoa_return             ; null byte!
    b       itoa_copy_char          ; next!

    itoa_return:
    mov     x0, x24                 ; pointer to start of string & alloc
    ; restore frame
    ldp     x24, x25, [sp], #16
    ldp     x22, x23, [sp], #16
    ldp     x20, x21, [sp], #16
    ldp     lr, x19, [sp], #16
    ret
