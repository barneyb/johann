# Building Johann Programs

First, you'll need an `arm64-apple-darwin` machine (aka Apple Silicon, with macOS) to run on, with the command-line developer/Xcode tools installed.

If your source is in `program.jn`, first compile it with `./bin/jnc < program.jn > program.s`. Next, assemble and link with `gcc program.s ./lib/jstdlib.o -o program`. Now you can execute it: `./program`. If you have multiple source files, compile and assemble them separately (with `-c`), and then link the object files into the final binary. The standard library (`./lib/jstdlib.o`) is pre-assembled and only needs to be linked.

!!! warning
    Compiled Johann programs are version specific. When changing versions of the compiler, you need to recompile all your sources. The standard library is always compiled with the compiler version it is bundled with. If you have third-party dependencies, their sources will need to be recompiled as well.

Implicit is a command shell that understands redirection. Compilation is always "read from STDIN and write to STDOUT" - Johann doesn't know about files!

The various `Makefile` may provide additional inspiration. It's worth mentioning that my `make` skills are commensurate with my skill coding assembly.

## Debugging Johann Programs

!!! tip
     It's generally better to simply not write bugs to begin with.

Johann provides no debugging support, but you might be able to use various third-party tools (e.g., GDB) to help? 

## Compiler Errors  

A few errors are explicitly caught by the compiler, with the exit status they yield:

* `17` - Unrecognized character
* `20` - Missing token
* `21` - Too many call parameters
* `22` - Duplicate declaration
* `23` - Unknown symbol
* `24` - Too many local vars
* `26` - Bad token/value
* `27` - Bad statement
* `28` - Bad expression
* `29` - Bad operator
* `35` - Empty struct 
* `36` - Duplicate struct member 
* `37` - Certain types of invalid block nesting
* `47` - Unrecognized format conversion spec for `printf`
* `75` - Unknown struct member
* `76` - Member or index off non-ID-pointer
* `77` - Multibyte character
* `98` - Certain double-`free` errors
* `99` - Failed to get memory from the OS (a panic, unlike C)

Most errors are not caught and result in compiler crashes, invalid assembly code, or code which will crash when executed.
