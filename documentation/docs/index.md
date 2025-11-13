---
title: Home
---

# They're All Named Johann

Johann is a comical attempt at building a programming platform from scratch for `arm64-apple-darwin` (aka Apple Silicon, with macOS). You don't want to use it. You don't even want to look at the source. When a bored coder has a martini (or several...) and decides to single-handedly reinvent much of the past ~60 years of computer science from scratch, nothing good results.

??? question "Why `arm64-apple-darwin`?"

    My employer assigned me a mac, and I wasn't interested in flipping between OSes, so I replaced my personal machine. The funny part is they gave me an `x64` mac - in 2023! - but you can't buy those anymore. AArch64 it is.

The only pre-existing software tools assumed are GCC's assembler and linker. No recognizer generator (e.g., `lex` and `yacc`), no v1 compiler in an existing language (e.g., C or Rust), no compiler backend (e.g., LLVM or GCC) for codegen, and no system libraries. Plus, I suppose, macOS itself along with its command shell and text editor.

This is clearly a ridiculous undertaking. The nominal goal is to do this fall's [Advent of Code](https://adventofcode.com/) stars using only Johann (repo [here](https://github.com/barneyb/aoc-2025)), with a fully self-hosted compiler: zero assembly, aside from syscalls. The compiler itself already meets this requirement, but the IO subsystem doesn't yet.

## The Short Version

Clone (or download a [release](https://github.com/barneyb/johann/tags)) and compile a test program as below. You'll need the command-line developer/Xcode tools installed.

    git clone git@github.com:barneyb/johann.git
    cd johann
    ./bin/jnc < not_quite_lisp.jn > not_quite_lisp.s
    gcc not_quite_lisp.s ./lib/jstdlib.o
    echo "((()))))(((((" | ./a.out

This will print:

    Part A: 3
    Part B: 7

The `3` is the difference in number of `(` and `)`, and the `7` is the first character position (one-indexed) where more `)` than `(` have been encountered. Run `make not_quite_lisp` from the root to do basically the same thing.
