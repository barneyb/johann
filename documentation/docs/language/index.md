# The Johann Language

Johann source code is always plain text, encoded with UTF-8, and uses a `.jn` extension by convention. Multibyte characters are forbidden; only ASCII characters are supported. There is no locale/language awareness/support.

All keywords are case-sensitive. Comments are introduced with `#` and extend to end of line. Whitespace is merely a delimiter, not semantic, and braces are used for control flow blocks, but not scoping (yet). Variable declarations require a type specifier. They will move to the other side of the identifier (e.g., `int i = ...` will become `let i: int = ...`), and the type may become optional. There is no exception handling.

Functions are declared with the `fn` keyword. Use `return` to return (with a value or not). The entry point for a program is always a `pub` function named `main`. Functions may have up to eight local variables, which are always scoped to the function. There's not (yet) a way to declare a return type.

    pub fn main() {
        return 0;
    }

`main` can be declared with zero, one, or two arguments, which will be passed POSIX `argc` and `argv` values. This program will print its name and exit with the number of command line arguments it received.

    pub fn main(int a, char** b) {
        b = *b;
        puts(b);
        return a - 1;
    }

By default, declarations are private to the file they're declared in. Use `pub` to make a declaration globally available, whether a function or a global variable. 

Conditionals use the `if` keyword and loops use `while`. The conditional expression is not wrapped with parentheses, but are valid (as part of the expression) if present.. Braces are required around the body. There is no `else`. Functions are called with a pair of parens.

    int i = 0;
    int f = 0;
    char c = getchar();
    while c > b {
        i = i + 1;
        if c == '(' {
            f = f + 1;
        }
        c = getchar();
    }

You can use `done` and `again` within a `while` to ... say you're done looping or want to loop again. These two snippets are equivalent:

    # the reasonable way
    while c > b {
        c = getchar();
    }

    # the silly way
    while true {
        if c > b {
            c = getchar();
            again;
        }
        done;
    }

Only eight levels of nesting are supported. If you go deeper, you'll probably run into memory corruption. Break your function into smaller, simpler pieces.

Operator precedence is as in C-family languages, including using parentheses to force things. The five standard arithmetic operators are supported: `+`, `-`, `*`, `/`, and `%`. Six comparisons operators are supported: `==`, `!=`, `<`, `<=`, `>` and `>=`. Five unary operators are supported: `!`, `+`, `-`, `*` (pointer dereference), and `&` (take address). Note that currently `*` can only operate on a bare identifier, and that identifier's width - not the destination's - determines the load width.

A `*` can also be used on the left side of an assignment to write to pointed-at memory:

    int e = 16;
    int* a = malloc(e); # a = new int[2];
    *a = 1;             # a[0] = 1;
    int p = &a;         # p = a;
    p = p + 8;
    *p = 2;             # a[1] = p[1] = 2;
    int b = *p;         # b = 2;
    int c = *a;         # c = 1;
    *a = b + c;         # a[0] = 3;

Semicolons are required to terminate statements which don't take a block. Blocks are _not_ statements as is normal in C-family languages; they're parts of the `if` and `while` syntax. As well as not establishing scope, you can't have anonymous blocks (they would be of zero value). This will change, so don't abuse it.

Strings are double-quoted, characters are single-quoted, and identifiers start with a letter followed by any sequence of letters, numbers, and underscore. Strings are "null-terminated byte strings" a la C. A `\n` may be used for a newline _in a string_; if you need a newline _character_ use `0xa` (`'\n'` doesn't yet lex). Literals are static, so do not need to be `free`-d.  Strings constructed dynamically (e.g., via [`StringBuilder`](../library/index.md#stringbuilder)) must be `free`-d when you're done with them.

The `bool`, `char`, `int`, and `void` keywords are used to introduce a variable, local or global. As noted above, `int i` will eventually become `let i: int`. Pointers are declared with `*`. `void` only makes sense as a pointer, of course. No type checking is performed, but the type is used for `sizeof`. This will change. There is no support for compound values (structs/arrays/tuples); use a heap allocation and do the pointer arithmetic yourself (for now).

Integers are signed 64-bit values. Decimal literals cannot have leading `0`s (except zero itself, of course). Hexadecimal literals are allowed with a `0x` prefix; the `x` MUST be lowercase, but digits can be any case. Underscores between digits (e.g., `32_767`) are ignored. Use `-` to get a negative value.

Boolean literals `true` and `false` are recognized as aliases for `1` and `0` respectively. Compiled codes always check against `0`, so any non-`0` value will be considered `true`. The `null` keyword is also recognized as an alias for `0`. At some point these will have identity separate from their numeric value.

Functions can declare formal arguments within their parentheses, to create local variables from passed values. These are normal variables, which means functions can take at most eight arguments.

    fn add(int a, int b) {
        return a + b;
    }

A function call can have a max of eight parameters (which really only matters for [`printf`](../library/index.md#io)). A couple ways to print "one: 1" to STDOUT, using the `add` function defined above and several of the standard library functions:

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

    # easiest:
    printf("one: %i\n", 1);

Both functions and global variables can be declared without being defined. This is needed to reference them. Function calls do not (yet) require a reference, but taking an address (to make a function pointer) does. Global variables always require a reference, simple use or taking an address. This program prints an externally-defined greeting three times, in three different ways:

    char* GREETING;             # declare variable defined somewhere else
    fn puts(char* str);         # declare jstdlib function

    pub fn main() {
        char* str = GREETING;   # deref global (declaration required)
        void* puts_ptr = &puts; # take address of function (declaration required)
        puts(str);              # call declared jstdlib function
        puts_ptr(str);          # invoke through pointer
        printf(str);            # call undeclared jstdlib function
    }
