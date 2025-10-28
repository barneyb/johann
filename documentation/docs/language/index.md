# The Johann Language

Johann source code is always plain text, encoded with UTF-8, and uses a `.jn` extension by convention. Multibyte characters are forbidden; only ASCII characters are supported. There is no locale/language awareness/support.

All keywords are case-sensitive. Comments are introduced with `#` and extend to end of line. Whitespace is merely a delimiter, not semantic, and braces are used for control flow blocks, but not scoping (yet). There is no exception handling.

## Functions and `main`

Functions are declared with the `fn` keyword. Use `return` to return (with a value or not). The entry point for a program is always a `pub` function named `main`. There's not (yet) a way to declare a return type.

```johann
pub fn main() {
    return 0;
}
```

`main` can be declared with zero, one, or two parameters, which will be passed POSIX `argc` and `argv` values. This program will print its name and exit with the number of command line arguments it received.

```johann
pub fn main(int argc, char** argv) {
    puts(*argv);
    return argc - 1;
}
```

More generally, functions can declare parameters (aka formal arguments) within their parentheses, to create local variables from call arguments. Each function may have up to eight local variables, whether they come from parameters or are declared within. A pointless `add` function:

```johann
fn add(int a, int b) {
    return a + b;
}
```

Function calls similarly have a max of eight parameters (which really only matters for [`printf`](../library/index.md#io)). A few ways to print `one: 1` to STDOUT, using the `add` function defined above and several of the standard library functions:

```johann
# convoluted:
char* c = "one: ";
printf(c);
int a = -1;
int b = 2;
a = add(a, b);
c = itoa(a);
puts(c);
free(c);           # don't leak memory

# easier:
char* f = "one: %i\n";
a = 1;
printf(f, a);

# more direct:
printf("one: %i\n", 1);

# easiest:
puts("one: 1");
```

## Definitions

By default, definitions are private to the file they're declared in. Use `pub` to make a definition available elsewhere, whether a function or a global variable. To use a `pub` variable (or take the address of a `pub` function) in another file, it must redeclared in that file.

The `bool`, `char`, `int`, and `void` keywords are used to introduce a variable, local or global. They will move to the other side of the identifier, so `int i = ...` will become `let i: int = ...`, and the type may become optional as well. Pointers are declared with `*`. `void` can be used to represent "a 64-bit value", and thus `void*` means "a pointer to something". No type checking is performed, but the type is used for `sizeof` and struct member access. This mess will improve.

Structs can be used to model compound data. They can be marked `pub` too, but it doesn't _do_ anything, since there's no definition past the declaration. If you wanted to implement a Lisp-ish DSL in Johann, you might start with the code below, which also illustrates using a declared type to introduce parameters and local variables:

```johann
void nil = null;

struct Cell {
    void car,
    void cdr
}

fn cons(void car, Cell* tail) {
    Cell* l = malloc(sizeof(Cell));
    l.car = car;
    l.cdr = tail;
    return l;
}

fn drop(Cell* list) {
    if list == nil { return; }
    drop(list.cdr);
    free(list);
}

pub fn main() {
    Cell* my_list = cons(3, cons(2, cons(1, nil)));
    drop(my_list);
}
```

Functions, types, and global variables can be declared without being defined. This is needed to reference definitions from other files (where they must be declared `pub`, of course). Function calls do not (yet) require a reference, but taking an address (to make a function pointer) does. Global variables always require a reference, to use or take an address. This program prints an externally-defined greeting three times, in three different ways:

```johann
char* GREETING;             # declare variable defined "somewhere else"
fn puts(char* str);         # declare function defined in jstdlib.o

pub fn main() {
    char* str = GREETING;   # deref global (declaration required)
    void* puts_ptr = &puts; # take address of function (declaration required)
    puts(str);              # call declared jstdlib function
    puts_ptr(str);          # invoke through pointer
    printf(str);            # call undeclared jstdlib function
}
```

## Control Flow

Conditionals use the `if` keyword and loops use `while`. The conditional expression is not wrapped with parentheses (though you can, of course, wrap any expression with parens). Braces are required around the body. There is no `else`.

```johann
int i = 0;
int f = 0;
char c = getchar();
while c >= 0 {
    i = i + 1;
    if c == '(' {
        f = f + 1;
    }
    c = getchar();
}
```

You can use `done` and `again` within a `while` to ... say you're done looping or want to loop again. These two snippets are equivalent:

```johann
# the reasonable way
char c;
while c >= 0 {
    c = getchar();
}

# the silly way
while true {
    if c >= 0 {
        c = getchar();
        again;
    }
    done;
}
```

Only eight levels of nesting are supported. If you go deeper, you'll probably run into memory corruption. Break your function into smaller, simpler pieces.

Semicolons are required to terminate statements which don't take a block. Blocks are _not_ statements as is normal in C-family languages; they're parts of the `if` and `while` syntax. As well as not establishing scope, you can't have anonymous blocks (they would be of zero value). This will change, so don't abuse it.

## Operators / Expressions

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

Strings are double-quoted, characters are single-quoted, and identifiers start with a letter followed by any sequence of letters, numbers, and underscore. Strings are "null-terminated byte strings" a la C. A `\n` may be used for a newline _in a string_; if you need a newline _character_ use `0xa` (`'\n'` doesn't yet lex). Literals are static, so do not need to be `free`-d.  Strings constructed dynamically (e.g., via [`StringBuilder`](../library/index.md#stringbuilder)) must be `free`-d when you're done with them.

Integers are signed 64-bit values. Decimal literals cannot have leading `0`s (except zero itself, of course). Hexadecimal literals are allowed with a `0x` prefix; the `x` MUST be lowercase, but digits can be any case. Underscores between digits (e.g., `32_767`) are ignored. Use `-` to get a negative value.

If you want floats, you'll need to implement IEEE 754 yourself.

Boolean literals `true` and `false` are recognized as aliases for `1` and `0` respectively. Compiled codes always check against `0`, so any non-`0` value will be considered `true`. The `null` keyword is also recognized as an alias for `0`. At some point these will have identity separate from their numeric value.

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

## I'm Sorry, What?!

If the above seems like it was designed by a kindergartener, you're half right. Johann started with tooling commensurate to "late 1960's", but without a library of already-coded assembly routines (e.g., regex, a BST, or a hashtable). Now it's somewhere around 1970, plus a few of those library routines. Kindergartener is apropos for synthetic progress of a few years.  
