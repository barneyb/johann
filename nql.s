;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
                                    .text
.align  3                           ; Make sure everything is 8-byte/64-bit aligned
.set    TRUE    , 1
.set    FALSE   , 0

; printf "" | target/bin/nql
; 0
; 0
; echo "(()))((((" | target/bin/nql
; 3
; 5
; echo "())())" | target/bin/nql
; -2
; 3
; target/bin/nql < not_quite_lisp.txt
; 7
; 47

;fn main(): int { # block 0
    .global _main
    _main:
        bl      __j_main
        mov     x0, #0
        b       _os_exit

    .global __j_main
    __j_main:
        ; create frame - block 0
        stp     lr, x19, [sp, #-16]!
        stp     x20, x21, [sp, #-16]!
        stp     x22, x23, [sp, #-16]!
        stp     x24, x25, [sp, #-16]!
        stp     x26, x27, [sp, #-16]!
        ; end frame - block 0

;    int f = 0;
        mov     x0, 0
        mov     x25, x0 ; f = 102 - 49

;    char c = read();
        bl      __j_read
        mov     x22, x0 ; c = 99 - 49

;    int b = 0 - 1;
        mov     x0, 0
        mov     x1, 1
        sub     x0, x0, x1
        mov     x21, x0 ; b = 98 - 49

;    b = c > b;
        mov     x0, x22 ; c = 99 - 49
        mov     x1, x21 ; b = 98 - 49
        cmp     x0, x1
        b.gt    expr_0
        mov     x0, FALSE
        b       expr_0_end
        expr_0:
        mov     x0, TRUE
        expr_0_end:
        mov     x21, x0 ; b = 98 - 49

;    while b { # block 1
        while_1_again:
        mov     x0, x21 ; b = 98 - 49
        cmp     x0, FALSE
        b.eq    while_1_done

;        bool d = c = '(';
        mov     x0, x22 ; c = 99 - 49
        mov     x1, '('
        cmp     x0, x1
        b.eq    expr_1
        mov     x0, FALSE
        b       expr_1_end
        expr_1:
        mov     x0, TRUE
        expr_1_end:
        mov     x23, x0 ; d = 100 - 49

;        if d { # block 2
        mov     x0, x23 ; d = 100 - 49
        cmp     x0, FALSE
        b.eq    if_2_done

;            f = f + 1;
        mov     x0, x25 ; f = 102 - 49
        mov     x1, 1
        add     x0, x0, x1
        mov     x25, x0 ; f = 102 - 49

;        } # block 2 - if
        if_2_done:

;        d = c = ')';
        mov     x0, x22 ; c = 99 - 49
        mov     x1, ')'
        cmp     x0, x1
        b.eq    expr_2
        mov     x0, FALSE
        b       expr_2_end
        expr_2:
        mov     x0, TRUE
        expr_2_end:
        mov     x23, x0 ; d = 100 - 49

;        if d { # block 3
        mov     x0, x23 ; d = 100 - 49
        cmp     x0, FALSE
        b.eq    if_3_done

;            f = f - 1;
        mov     x0, x25 ; f = 102 - 49
        mov     x1, 1
        sub     x0, x0, x1
        mov     x25, x0 ; f = 102 - 49

;        } # block 3 - if
        if_3_done:

;        c = read();
        bl      __j_read
        mov     x22, x0 ; c = 99 - 49

;        b = 0 - 1;
        mov     x0, 0
        mov     x1, 1
        sub     x0, x0, x1
        mov     x21, x0 ; b = 98 - 49

;        b = c > b;
        mov     x0, x22 ; c = 99 - 49
        mov     x1, x21 ; b = 98 - 49
        cmp     x0, x1
        b.gt    expr_3
        mov     x0, FALSE
        b       expr_3_end
        expr_3:
        mov     x0, TRUE
        expr_3_end:
        mov     x21, x0 ; b = 98 - 49

;    } # block 1 - while
        b       while_1_again
        while_1_done:

;    char* a = itoa(f);
        mov     x0, x25 ; f = 102 - 49
        bl      __j_itoa
        mov     x20, x0 ; a = 97 - 49

;    println(a);
        mov     x0, x20 ; a = 97 - 49
        bl      __j_println

;    return f;
        mov     x0, x25 ; f = 102 - 49
        b       _return_0

;} # block 0 - fn
        _return_0:
        ; restore frame - block 0
        ldp     x26, x27, [sp], #16
        ldp     x24, x25, [sp], #16
        ldp     x22, x23, [sp], #16
        ldp     x20, x21, [sp], #16
        ldp     lr, x19, [sp], #16
        ret

;fn goat(): int { # block 4
    .global __j_goat
    __j_goat:
        ; create frame - block 4
        stp     lr, x19, [sp, #-16]!
        stp     x20, x21, [sp, #-16]!
        stp     x22, x23, [sp, #-16]!
        stp     x24, x25, [sp, #-16]!
        stp     x26, x27, [sp, #-16]!
        ; end frame - block 4

;} # block 4 - fn
        _return_4:
        ; restore frame - block 4
        ldp     x26, x27, [sp], #16
        ldp     x24, x25, [sp], #16
        ldp     x22, x23, [sp], #16
        ldp     x20, x21, [sp], #16
        ldp     lr, x19, [sp], #16
        ret
