#include <stdio.h>
#include "clib.h"
//void _j_puts(char*);

int main(void) {
    long six = 6;
    long seven = 7;
    long eight = 8;
    long nine = 9;
    long ten = 10;
    long one = 1;
    long two = 2;
    long three = 3;
    long four = 4;
    long five = 5;
    puts("from C:");
//    _j_puts("from C:");
    fflush(stdout);
    _j_print_seven_longs(one, two, three, four, five, six, seven);
    _j_print_eight_longs(one, two, three, four, five, six, seven, eight);
    _j_print_nine_longs(one, two, three, four, five, six, seven, eight, nine);
    _j_print_ten_longs(one, two, three, four, five, six, seven, eight, nine, ten);
}
