# Building Johann Itself

Johann contains two binaries, the compiler (`jnc`) and the standard library (`jstdlib.o`). The former includes the latter.

Clone the repository, then run `make` in the root. That's it. The compiler is at `jnc/target/bin/jnc` and the standard library is at `jstdlib/target/lib/jstdlib.o`.

```
% make
... snip ...
% ./jnc/target/bin/jnc --version
jnc 0.20250609
build_time: 2025-06-09T04:28:43+00:00
commit_hash: b9765e5198d7874b59605255d9f7a59bed27c70b
% echo "pub fn main(){}" | ./jnc/target/bin/jnc
; Compiled with jnc 0.20250609-b9765e5
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
Apple clang version 17.0.0 (clang-1700.0.13.5)
Target: arm64-apple-darwin24.5.0
Thread model: posix
InstalledDir: /Library/Developer/CommandLineTools/usr/bin
%
% ld -v
@(#)PROGRAM:ld PROJECT:ld-1167.5
BUILD 01:45:05 Apr 30 2025
configured to support archs: armv6 armv7 armv7s arm64 arm64e arm64_32 i386 x86_64 x86_64h armv6m armv7k armv7m armv7em
will use ld-classic for: armv6 armv7 armv7s i386 armv6m armv7k armv7m armv7em
LTO support using: LLVM version 17.0.0 (static support for 29, runtime is 29)
TAPI support using: Apple TAPI version 17.0.0 (tapi-1700.0.3.5)
```
<!--{/systemsoftware}-->

## Application Binary Interface

Johann-compiled code mostly conforms to (a subset of) the AArch64 PCS. There's no support for passing args on the stack or variadic routines. Johann doesn't understand floating point numbers, and uses only a tiny subset of available instructions. Some sort of FFI is not an explicit goal, but not painting it out either.

The linked list of frame records is only partially implemented, on its way to complete implementation where only leaf subroutines may forgo a record. Correct frames are emitted by `jnc`, but the parts of `jstdlib` still written in assembler exhibit a mixture of approaches.
