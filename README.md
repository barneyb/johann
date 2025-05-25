# They're All Named Johann

Johann is a comical attempt at building a programming platform from scratch for `arm64-apple-darwin` (aka Apple Silicon running macOS). You don't want to use it. You don't even want to look at the source. When a bored coder has a martini (or several...) and decides to single-handedly reinvent much of the past ~60 years of computer science from scratch, nothing good results.

The only pre-existing software tools assumed are GCC's assembler and linker. No recognizer generator (e.g., `lex` and `yacc`), no v1 compiler in an existing language (e.g., C or Rust), no compiler backend (e.g., LLVM or GCC) for codegen, and no system libraries. Plus, I suppose, macOS itself along with its command shell and text editor.

> **Why `arm64-apple-darwin`?** My employer assigned me a mac, and I wasn't interested in flipping between OSes, so I replaced my personal machine. The funny part is they gave me an `x64` mac - in 2023! - but you can't buy those anymore. AArch64 it is.

This is clearly a ridiculous undertaking. The nominal goal is to get this fall's [Advent of Code](https://adventofcode.com/) stars using only Johann, with a fully self-hosted compiler (no lingering assembly, aside from syscalls).

## The Short Version

Clone and compile a test program as below. You'll need the command-line developer/Xcode tools installed.

    git clone git@github.com:barneyb/johann.git
    cd johann
    ./bin/jnc < not_quite_lisp.jn > not_quite_lisp.s
    gcc not_quite_lisp.s ./lib/jstdlib.o
    echo "((()))))(((((" | ./a.out

This will print:

    Part A: 3
    Part B: 7

The `3` is the difference in number of `(` and `)`, and the `7` is the first character position (one-indexed) where more `)` than `(` have been encountered. Run `make not_quite_lisp` from the root to do basically the same thing.

## Writing Johann Programs

Johann source code is always plain text, encoded with UTF-8, and uses a `.jn` extension by convention. Multibyte characters are forbidden; only ASCII characters are supported. There is no locale/language awareness.

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

Conditionals use the `if` keyword and loops use `while`. Parentheses are not permitted around the conditional expression. Braces are required around the body. There is no `else`. Functions are called with a pair of parens.

    int i = 0;
    int f = 0;
    char c = getchar();
    while c > b {
        i = i + 1;
        if c = '(' {
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

Only eight levels of nesting are supported. If you go deeper, you'll probably run into memory corruption. It's a _race!_

Compound expressions are not supported, so there is no operator precedence. The five normal arithmetic operators are supported: `+`, `-`, `*`, `/`, and `%`. Four comparisons operators are supported: `<`, `>`, `=`, and '!' (not `==` and `!=` - yet!). Four unary operators are supported: `!`, `-`, `*` (pointer dereference), and `&` (take address). A `*` can also be used on the left side of an assignment to write to pointed-at memory.

    int e = 16;
    int* a = malloc(e); # a = new int[2];
    *a = 1;             # a[0] = 1;
    int p = &a;         # p = a;
    p = p + 8;
    *p = 2;             # a[1] = p[1] = 2;
    int b = *p;         # b = 2;
    int c = *a;         # c = 1;
    *a = b + c;         # a[0] = 3;

Semicolons are required to terminate statements which don't take a block. Blocks are _not_ statements as is normal in C-family languages; they're parts of the `if` and `while` syntax. As well as not establishing scope, you can't have anonymous blocks (they would be of zero value). This will change. 

Strings are double-quoted, characters are single-quoted, and identifiers start with a letter followed by any sequence of letters, numbers, and underscore. Strings are "null-terminated byte strings" a la C. A `\n` may be used for a newline; other escapes may work, but are unsupported. Literals are static, so do not need to be `free`-d.  Strings constructed dynamically (e.g., via `itoa`) must be `free`-d when you're done with them.

The `bool`, `char`, `int`, and `void` keywords are used to introduce a variable, local or global. As noted above, `int i` will eventually become `let i: int`. Pointers are declared with `*`. `void` only makes sense as a pointer, of course. No type checking is performed, but the type is used for `sizeof`. This will change.

Integers are signed 64-bit values. Decimal literals cannot have leading `0`s (aside from zero itself, of course). Hexadecimal literals are allowed with a `0x` prefix; the `x` MUST be lowercase, but digits can any case. A leading `-` indicates a negative value. A second `-` (associating right-to-left!) is a unary negate (for now).

Boolean literals `true` and `false` are recognized as aliases for `1` and `0` respectively. Compiled codes always check against `0`, so any non-`0` value will be considered `true`.

The `null` keyword is recognized as an alias for `0`.

Functions can declare formal arguments within their parentheses, to create local variables from passed values. These are normal variables, which means functions can take at most eight arguments.

    fn add(int a, int b) {
        return a + b;
    }

Parameters passed in a function call must be local variables, not expressions. This includes literals and global variables! A couple ways to print "one: 1" to STDOUT, using the `add` function defined above and several of the standard library functions:

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

    # not allowed:
    # printf("one: %i\n", 1);

## Building Johann Programs

First, you'll need `arm64-apple-darwin` machine (aka Apple Silicon, running macOS) to run on, with the command-line developer/Xcode tools installed.

If your source is in `program.jn`, first compile it with `./bin/jnc < program.jn > program.s`. Next, assemble and link with `gcc program.s ./lib/jstdlib.o -o program`. Now you can execute it: `./program`. If you have multiple source files, compile and assemble them separately (with `-c`), and then link the object files into the final binary. The standard library (`./lib/jstdlib.o`) is pre-assembled and only needs to be linked.

> **NB:** Compiled Johann programs are version specific. When changing versions of the compiler, you need to recompile all your sources. The standard library is always compiled with the compiler version it is bundled with. If you have third-party dependencies, their sources will need to be recompiled as well.

Implicit is a command shell that understands redirection. Compilation is always "read from STDIN and write to STDOUT" - Johann doesn't know about files!

The various `Makefile` may provide additional inspiration. It's worth mentioning that my `make` skills are commensurate with my skill coding assembly.

## Debugging Johann Programs

> **NB:** It's generally better to simply not write bugs to begin with.

Johann provides no debugging support, but you might be able to use various third-party tools (e.g., GDB) to help? 

## Dynamic Memory Allocation

The allocator only uses anonymously `mmap`ed pages, which are acquired on-demand. Currently, they are never `unmmap`ed. Each `malloc` call will return a suitable memory chunk. Chunks passed back to `free` are marked for recycling. Recycling is always preferred to requesting more space from the OS. Recycled chunks are neither coalesced nor re-chunked more finely. `malloc` only looks for "big enough", not "reasonably sized," so an allocation request may recycle a wildly oversize chunk, "wasting" the overage. This also means overflow errors are less predictable than one might hope.

When a program exits (without panicking), the count of `malloc` and `free` calls over the life of the execution is compared, as are the total bytes allocated and freed. If they don't match, a warning is printed to both STDOUT and STDERR with the details. Here's one which leaked pretty dramatically, almost 20% of its allocations:

    ; MEM: 279 allocs (0x2db0 bytes)
    ;      227 frees  (0x2290 bytes)

Certain double-free errors cause a `98` panic, but only a minority of them. Both checks will eventually go away, once the language itself takes at least partial ownership of dynamic memory, instead of letting humans do it.

## Standard Library

Johann's standard library is minimal. Functions are grouped by the file defining them, which is currently an opaque detail. Symbols use a `__j_` prefix, so `puts` is actually exported to the linker as `__j_puts`.

### `allocator`

Eventually, these will go away in favor of `new`/`drop` or something. And hopefully be taken over by the compiler itself, so programmers can't screw it up.

* `void free( void* )` - free the allocation pointed to by the passed pointer.
* `void* malloc( size_t size )` - allocate (at least) the specified number of bytes of memory and return a pointer to it.

### `io`

No files, just STDIN and STDOUT. `EOF` is any negative number.

* `int getchar( )` - consume the next character from STDIN, or `EOF`.
* `bool iseof( )` - whether STDIN has reached EOF.
* `int peekchar( )` - peek at the next character from STDIN without consuming it, or `EOF`.
* `int printf( char* format, ... )` - converts args to strings based on the null-terminated `format`, and write to STDOUT.
* `int eprintf( char* format, ... )` - same as `printf`, but write to STDERR (without buffering).
* `int putchar( int ch )` - write `ch` to STDOUT and return the `char` written.
* `int puts( char* str )` - write the null-terminated byte string `str` _and a newline_ to STDOUT.

### `string`

* `int isdigit( int ch )` - is the passed character a decimal digit?
* `int isspace( int ch )` - is the passed character whitespace?
* `int isxdigit( int ch )` - is the passed character a hexidecimal digit?
* `void* memcpy( void *dest, const void *src, size_t count )` - copy bytes between non-overlapping memory regions.
* `char* strclone( char* str )` - clone the passed string into a new allocation. 
* `int strcmp( const char* lhs, const char* rhs )` - compare two null-terminated strings.
* `size_t strlen( const char* str )` - get the length of a null-terminated string.

### `sys`

Those starting with `sys_` (thin syscall wrappers) are not expected to remain available.

* `void exit( int status )` - terminate the program with the given exit status.
* `void panic( int status, const char *buf, size_t count )` - write bytes to STDERR and terminate.
* `ssize_t sys_read( int fd, void *buf, size_t nbyte )` - read bytes from a file descriptor.
* `ssize_t sys_write( int fd, const void *buf, size_t count )` - write bytes to a file descriptor.

### `table`

A table/map/associative-array ADT, which has a reasonable interface (for a tree-based structure), and a linear-scan implementation. This is intended to eventually be a "class". Keys and values are arbitrary 64-bit values, with pass-by-value semantics, and otherwise generic/open-ended. The `Table_drop_owned` method can help if the table owns the key and/or value objects.

* `Table* Table__new( fn* comparator )` - create a new empty table, where `comparator` points to a function which defines both equality and total order over the table's keys.
* `bool Table_contains( Table* t, ? key )` - check whether `key` exists in `t`.
* `void Table_drop( Table* t )` - drops `t`, freeing all internal structure.
* `void Table_drop_owned( Table* t, fn* drop_key, fn* drop_value )` - drops `t`, freeing all internal structure, and passing each key & value to the corresponding drop-function's pointer (if non-`null`).
* `? Table_get( Table* t, ? key )` - return the value associated with `key` in `t`, otherwise `null`.
* `? Table_remove( Table* t, ? key )` - ensure `key` doesn't exist in `t`, returning its previous value (or `null`).
* `? Table_put( Table* t, ? key, ? value )` - associate `key` with `value` in `t`, returning its previous value (or `null`).
* `int Table_size( Table* t )` - return the number of keys in `t`.

### Obsolete

One obsolete function remains available, and will eventually be removed.

* `char* itoa( int n )` - no direct replacement, but `printf` can do it on the way to STDOUT

## Compiler Errors

A few errors are explicitly caught by the compiler, with the exit status they yield:

* `17` - Unrecognized character
* `22` - Duplicate declaration
* `23` - Unknown symbol
* `24` - Too many local vars
* `25` - Non-local call parameter
* `26` - Bad token/value
* `27` - Bad statement
* `28` - Bad expression
* `29` - Bad operator
* `37` - Certain types of invalid block nesting
* `47` - Unrecognized format conversion spec for `printf`
* `77` - Multibyte character
* `98` - Certain double-`free` errors
* `99` - Failed to get memory from the OS

Most errors are not caught and result in compiler crashes, invalid assembly code, or code which will crash when executed.

## Building Johann Itself (`jnc` and `jstdlib.o`)

Clone the repository, then run `make` in the root. That's it. The compiler is at `jnc/target/bin/jnc` and the standard library is at `jstdlib/target/lib/jstdlib.o`.

```
% make
... snip ...
% ./jnc/target/bin/jnc --version
jnc 0.20250525
build_time: 2025-05-25T02:28:57+00:00
commit_hash: 05c2b725da0030de8a2acf538c5b6926f1c815b4
% echo "pub fn main(){}" | ./jnc/target/bin/jnc
; Compiled with jnc 0.20250525-05c2b72 ; tmpl_prelude
    .text
    .align  3
... snip ...
```

Running `make clean all` in the root will ensure your local development version of the compiler and standard library are in sync. If things seem screwy, that's the first thing to do. You'd think `make` would be _exactly_ the tool to automatically prevent this, but I can't figure out the right incantation(s). 

The specific versions of the system software I have are listed below. Note that Apple made several backwards-incompatible changes in clang 17 (macOS 15.4.1).

<!--{systemsoftware}-->
```
% uname -a
Darwin mac.lan 24.5.0 Darwin Kernel Version 24.5.0: Tue Apr 22 19:54:26 PDT 2025; root:xnu-11417.121.6~2/RELEASE_ARM64_T8112 arm64
%
% make --version
GNU Make 3.81
Copyright (C) 2006  Free Software Foundation, Inc.
This is free software; see the source for copying conditions.
There is NO warranty; not even for MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE.

This program built for i386-apple-darwin11.3.0
%
% gcc --version
Apple clang version 17.0.0 (clang-1700.0.13.3)
Target: arm64-apple-darwin24.5.0
Thread model: posix
InstalledDir: /Library/Developer/CommandLineTools/usr/bin
%
% ld -v
@(#)PROGRAM:ld PROJECT:ld-1167.4.1
BUILD 20:00:10 Mar 12 2025
configured to support archs: armv6 armv7 armv7s arm64 arm64e arm64_32 i386 x86_64 x86_64h armv6m armv7k armv7m armv7em
will use ld-classic for: armv6 armv7 armv7s i386 armv6m armv7k armv7m armv7em
LTO support using: LLVM version 17.0.0 (static support for 29, runtime is 29)
TAPI support using: Apple TAPI version 17.0.0 (tapi-1700.0.3.4)
```
<!--{/systemsoftware}-->

## Application Binary Interface

Johann-compiled code mostly conforms to (a subset of) the AArch64 PCS. There's no support for passing args on the stack or variadic routines. Johann doesn't understand floating point numbers, and uses only a tiny subset of available instructions. Some sort of FFI is not an explicit goal, but not painting it out either.

The linked list of frame records is only partially implemented, on its way to complete implementation where only leaf subroutines may forgo a record.
