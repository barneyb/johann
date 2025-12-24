# Johann's Standard Library

Johann's standard library is minimal. Functions are grouped by the file defining them, which is currently an opaque detail.

If you want to use [header files](../build/index.md#header-files) for the standard library, there is a `jstdlib.jnh` next to `jstdlib.o`, ready to go.

## Johann vs Assembly

While the compiler is written entirely in Johann itself, parts of the standard library are still implemented in assembly. System calls can't be made with Johann syntax directly, which motivates most of the lingering assembly. This is some of the oldest code, and hasn't been rewritten.

The `printf` and `syscall` functions are variadic, which Johann doesn't yet have support for, so they must remain assembly. `printf` has a special exemption from `--strict` for this reason. `syscall` probably should as well; I'll add one if/when it proves useful enough.
