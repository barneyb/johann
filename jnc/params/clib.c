#include <stdio.h>
#include "clib.h"

void _j_print_seven_longs(long a, long b, long c, long d, long e, long f, long g) {
    printf("C: %ld, %ld, %ld, %ld, %ld, %ld, and %ld\n",
                 a,   b,   c,   d,   e,   f,       g);
    fflush(stdout);
}

void _j_print_eight_longs(long a, long b, long c, long d, long e, long f, long g, long h) {
    printf("C: %ld, %ld, %ld, %ld, %ld, %ld, %ld, and %ld\n",
                 a,   b,   c,   d,   e,   f,   g,       h);
    fflush(stdout);
}

void _j_print_nine_longs(long a, long b, long c, long d, long e, long f, long g, long h, long i) {
    printf("C: %ld, %ld, %ld, %ld, %ld, %ld, %ld, %ld, and %ld\n",
                 a,   b,   c,   d,   e,   f,   g,   h,       i);
    fflush(stdout);
}

void _j_print_ten_longs(long a, long b, long c, long d, long e, long f, long g, long h, long i, long j) {
    printf("C: %ld, %ld, %ld, %ld, %ld, %ld, %ld, %ld, %ld, and %ld\n",
                 a,   b,   c,   d,   e,   f,   g,   h,   i,       j);
    fflush(stdout);
}
