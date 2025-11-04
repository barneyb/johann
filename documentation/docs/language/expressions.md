# Operators / Expressions

Operator precedence is as in C-family languages, including using parentheses to override things. The five standard arithmetic operators are supported: `+`, `-`, `*`, `/`, and `%`. Six comparisons operators are supported: `==`, `!=`, `<`, `<=`, `>` and `>=`. Five unary operators are supported: `!`, `+`, `-`, `*` (pointer dereference), and `&` (take address). Note that unary `*` can (currently) only operate on a bare identifier, and that identifier's width - not the destination's - determines the load width. There is also the `sizeof` ... construct, which acts as either a unary operator on a parenthesized type name or a function which accepts a single type argument, depending on your mindset.

A `*` can also be used on the left side of an assignment to write to pointed-at memory, though structs are often easier to reason about/with.

```johann
int e = 16;
int* a = malloc(e); # a = new int[2];
*a = 1;             # a[0] = 1;
int p = &a;         # p = a;
p = p + 8;
*p = 2;             # a[1] = p[1] = 2;
int b = *p;         # b = 2;
int c = *a;         # c = 1;
*a = b + c;         # a[0] = 3;
free(a);
```

## Strings

Strings are double-quoted, characters are single-quoted, and identifiers start with a letter followed by any sequence of letters, numbers, and underscore. Strings are "null-terminated byte strings" a la C. A `\n` may be used for a newline _in a string_; if you need a newline _character_ use `0xa` (`'\n'` doesn't yet lex). Literals are static, so do not need to be `free`-d.  Strings constructed dynamically (e.g., via [`StringBuilder`](../library/stringbuilder.jn.md)) must be `free`-d when you're done with them.

## Integers

Integers are signed 64-bit values. Decimal literals cannot have leading `0`s (except zero itself, of course). Hexadecimal literals are allowed with a `0x` prefix; the `x` MUST be lowercase, but digits can be any case. Underscores between digits (e.g., `32_767`) are ignored. Use `-` to get a negative value.

## Floats

If you want floats, you'll need to implement IEEE 754 yourself.

## Booleans

Boolean literals `true` and `false` are recognized as aliases for `1` and `0` respectively. Compiled codes always check against `0`, so any non-`0` value will be considered `true`. The `null` keyword is also recognized as an alias for `0`. At some point these will have identity separate from their numeric value.

## Arrays

Pseudo-arrays are also supported: any pointer may be indexed into with brackets to reference the `i`-th "element" of the "array". This does about what you'd expect, but without any typesafety or bounds checking. Nested/multidimensional "arrays" are not supported.

```johann
char* str = "abcdef";
char c = str[2];
printf("Element two is '%c'\n", c);

int* fib = malloc(10 * sizeof(int));
fib[0] = 1; fib[1] = 1;
int i = 2;
while i < 10 {
    fib[i] = fib[i - 2] + fib[i - 1];
    printf("fib(%d) = %d\n", i, fib[i]);
    i = i + 1;
}
free(fib);
```
