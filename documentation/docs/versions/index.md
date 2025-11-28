# Versions

At the moment, Johann is building up from "nothing" towards "enough". There's a _lot_ of kludge in the syntax and a host of random restrictions, all in service of "anything is better than writing assembly." Right now, there only two constraints on versioning:

1. The current release can compile the development sources.
1. The development sources can compile themselves.

This provides a backwards compatibility guarantee _for a single release_. Skipping a release may break things. For example, upgrading to `v0.20250610` introduced `==` and deprecated `=`. Support for `=` (as a comparison operator) wasn't removed until `v0.20250613`.

Once the last bits of hand-coded assembly are gone, a syntactic revision is next. After that, the compilation pipeline itself has two major shortcomings: typechecks are half during parsing and half during codegen, and codegen is direct from the parse tree without an intermediate representation (aka "three address codes").

## Release History

[//]: # (### Bleeding Edge)

### `v0.20251128`

Iterator convention, and implement for `ArrayList` and `HashMap`'s keys.

Functions can have any number of formal args, and calls can pass any number of params, including to `printf`.

Nesting more than eight levels deep no longer causes memory corruption.

### `v0.20251122`

Massive performance gains in the allocator, particularly for `free`.

Logical shift operators `<<` and `>>`, _for reasonable operands_.

`printf` pads numbers with spaces by default, instead of zeros, and no longer supports `%n` (for newline).

### `v0.20251121`

`else` and `else if` are supported!

HashMap supports pointer-identity internally, so callers don't have to do it explicitly.

The standard library's collection types' "drop" functions accept `null` (like `free` does).

### `v0.20251116`

Remove the sequential-scan `table` type; `HashMap` and `TreeMap` are better.

Allow redeclaring variables w/ the same type.

`--header` no longer implies `--strict`. Too annoying to set up the build chains.

### `v0.20251115`

Add `StringBuilder_into_int` to ease memory management.

Unlimited local variables, instead of being capped at eight.

Add `calloc`, mostly for auto-zeroed memory (not array allocations).

Fix a couple allocation defects, one mis-allocating on page boundaries, one on recycling freed chunks.

### `v0.20251109`

Allow redeclaring (but not redefining) structs. Formal args can only use declared types. Include variables in headers. Alphabetize all members in the johanndocs.

Add a `--strict` option to `jnc` to fail on unknown function calls; you'll need header file(s) for multi-file projects. Using `--header` implies `--strict`.

### `v0.20251108`

Add check that calls to _declared_ functions pass the right number of params (types are not checked). Calls to undeclared functions are not checked. Don't require a declaration to take a function pointer. Add checks that function redeclarations are compatible, and disallow redefining.

Add a `--header` option to `jnc` to emit a Johann source file containing the compilation unit's `pub` declarations (aside from `main`).

### `v0.20251106`

Add a `length` "method" to `StringBuilder`. Reinstate `itoa` and add its complement `atoi` as well.

### `v0.20251104`

Add a new `HashMap` type, along with `strhash` which computes a hash for a NTSB. Index docs by declaration, not just file, and break some of the large pages into smaller ones.

### `v0.20251103`

Add a `Queue` type. Quicksort as a platform routine, with sorting `ArrayList` based on it. Several new string functions: `strstr`, `strsplit`, `strjoin`. Support setting an `ArrayList` element, and reserving capacity.

### `v0.20251029`

Pseudo-method invocation, so `StringBuilder_push(sb, 'c')` becomes `sb.push('c')`, assuming `sb` is declared `StringBuilder*`. Add `ArrayList_push_all`, `strchr`, and `substr` to jstdlib.

### `v0.20251026`

Add array-ish syntactic sugar for pointer arithmetic, though not actual arrays or array types. Add a `read_line` function to `io`. Add `push_str` method to `StringBuilder`.

### `v0.20250622`

Use structs a couple places, fix an assignment ordering bug.

### `v0.20250620`

Add `struct` declarations, and support variable declarations of struct types. A new `.` operator provides access to members of a pointed-to struct for both reading and writing. 

### `v0.20250613`

Add `ArrayList` and `TreeMap` ADTs to the library. Remove support for `=` and `!` as comparison operators. Parse full programs, not just expressions.

### `v0.20250610`

Support `==` and `!=` in favor of their kludge counterparts `=` and `!`. Support `>=` and `<=` as well. Use "best fit" memory recycling, instead of "lowest address". Add actual docs, not a 20-page README.md.

### `v0.20250607`

Support compound expressions with a proper parser; statements and declarations are parsed, but still emitted from the token stream.

### `v0.20250606`

`jnc` is entirely Johann, and memory error reporting is further improved.

### `v0.20250530`

Add `StringBuilder` to the library, convert more of `jnc` to Johann, and support function pointers (via declarations).

### `v0.20250526`

Fix globals to use their declared width. Improve reporting of memory errors.

### `v0.20250525`

Recycle freed memory, and get more from the OS as needed. Introduce `pub` to make symbols available to other compilation units.

### `v0.20250524`

First parts of `jnc` and `jstdlib.o` written in Johann. Support void returns, hex literals, and taking an address.

### `v0.20250522`

Support for writing to global variables, not just reading them.

### `v0.20250518`

Lex numbers directly, use `printf` for emitting, add symbol tracking and extremely primitive register allocation so programs can use symbolic names, rather than just `a`-`h`. Still constrained to eight local vars per function.

### `v0.20250510`

Add IO functions - including `printf` - and some character recognition functions. Buffer STDIN & STDOUT. A simple linear-scan map/table/dict.

### `v0.20250426`

Add `void` as a type (for pointers), as well as `done`/`again` loop control keywords.

### `v0.20250420`

Direct translation to assembly, and direct mapping of single-character variable names to registers (variable `a` goes in `x20`, `b` goes in `x21`, etc.). Memory is fixed-size and allocate-only, never freed. Sufficient to solve [Not Quite Lisp](https://adventofcode.com/2015/day/1).
