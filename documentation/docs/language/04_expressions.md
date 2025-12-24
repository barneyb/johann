# Operators / Expressions

Operators are mostly as in C-family languages, aside from assignment. Assignment is not an expression in Johann, it's a statement. All operators, in order of decreasing precedence:

| Operator                                               | Description                                                          | Associativity     |
|--------------------------------------------------------|----------------------------------------------------------------------|-------------------|
| `()` <br/> `[]` <br/> `.`                              | functioncall<br/>array indexing<br/>member access                    | left to right     |
| `&` <br/> `*` <br/> `!` <br/> `+` , `-` <br/> `sizeof` | address-of<br/>dereference<br/>logical NOT<br />unary plus and minus | **right to left** |
| `*` , `/` , `%`                                        | multiply, divide, remainder                                          | left to right     |
| `+` , `-`                                              | add and subtract                                                     | left to right     |
| `<<` , `>>`                                            | left and right logical shift                                         | left to right     |
| `<` , `<=` <br/> `>` , `>=`                            | less than, less than equal<br/>greater than, greater than equal      | left to right     |
| `==` , `!=`                                            | is-equal, not-equal                                                  | left to right     |
| `&`                                                    | bitwise AND                                                          | left to right     |
| `^`                                                    | bitwise exclusive OR                                                 | left to right     |
| <code>&#124;</code>                                    | bitwise (inclusive) OR                                               | left to right     |
| `&&`                                                   | logical AND                                                          | left to right     |
| <code>&#124;&#124;</code>                              | logical OR                                                           | left to right     |

A ridiculous example of using many of them:

```johann
int e = 1 << 4;     # e = 16
int* a = malloc(e); # a = new int[2];
*a = 1;             # a[0] = 1;
int p = &a;         # p = a;
p = p + 8;
*p = 2;             # a[1] = p[1] = 2;
int b = *p;         # b = 2;
int c = *a;         # c = 1;
*a = b + c;         # a[0] = 3;
printf("i <%d u!\n",
       a[0]);       # i <3 u!
free(a);
```

A few notes:

* Unary `*`, `&`, `[]`, and `.` can (currently) only operate on a bare identifier, 
* Unary `*` uses the source's width - not the destination's - determines the load width.
* The `sizeof` construct only accepts a type, not an expression to infer the type of.
* A `*` can also be used on the left side of an assignment to write to pointed-at memory, though structs/arrays are often easier to reason about/with.
* The `%` operator's result may be negative. It always satisfies `(a / b) * b + a % b == a`, if the division is valid. 
* The shift operators work as you'd expect for reasonable operands. Be careful if you might hit over- or underflow, if either operand might be negative, or if the second operand might be greater than 63. All those cases are undefined.
* The `!`, `&&`, and `||` operators _do not_ always evaluate to `1` or `0`. Any non-zero value may be returned for `true` (per usual).

## Strings

Strings are double-quoted, characters are single-quoted, and identifiers start with a letter followed by any sequence of letters, numbers, and underscore. Strings are "null-terminated byte strings" a la C. A `\n` may be used for a newline _in a string_; if you need a newline _character_ use `0xa`, as escapes aren't supported. Literals are static, so do not need to be `free`-d.  Strings constructed dynamically (e.g., via [`StringBuilder`](../library/stringbuilder.jn.md)) must be `free`-d when you're done with them.

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

int* fib = calloc(10, sizeof(int));
fib[0] = 1; fib[1] = 1;
int i = 2;
while i < 10 {
    fib[i] = fib[i - 2] + fib[i - 1];
    printf("fib(%d) = %d\n", i, fib[i]);
    i = i + 1;
}
free(fib);
```
