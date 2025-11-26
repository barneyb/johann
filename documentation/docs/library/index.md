# Johann's Standard Library

Johann's standard library is minimal. Functions are grouped by the file defining them, which is currently an opaque detail. Symbols use a `__j_` prefix, so `puts` is actually exported to the linker as `__j_puts`. If you wanted to call Johan's `puts` from C, declare `void _j_puts(char*);` and link with `jstdlib.o`.

If you want to use [header files](../build/index.md#header-files) for the standard library, you must build them yourself; they're not currently provided. You'll need the sources, of course, but there's nothing different from creating headers from your own sources.

## Johann vs Assembly

While the compiler is written entirely in Johann itself, parts of the standard library are still implemented in assembly. System calls can't be made with Johann syntax directly, which motivates most of the lingering assembly. This is some of the oldest code, and hasn't been rewritten.

The `printf` and `syscall` functions are variadic, which Johann doesn't yet have support for, so they must remain assembly. `printf` has a special exemption from `--strict` for this reason. `syscall` probably should as well; I'll add one if/when it proves useful enough.
