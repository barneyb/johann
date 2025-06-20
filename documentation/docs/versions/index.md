# Versions

At the moment, Johann is building up from "nothing" towards "complete". There's a _lot_ of kludge in the syntax and a host of random restrictions, all in service of "anything is better than writing assembly." As the compiler gains power, the language will gel, hopefully ending up somewhere graceful. Right now, there only two constraints:

1. The current release can compile the development sources.
2. The development sources can compile themselves.

This provides a backwards compatibility guarantee _for a single release_. Skipping a release may break things. For example, upgrading to `v0.20250610` introduced `==` and deprecated `=`. Support wasn't removed until the following release. 

## Release History

### Bleeding Edge

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
