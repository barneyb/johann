# They're All Named Johann

Johann is a programming platform for `arm64-apple-darwin` (aka Apple Silicon, with macOS). You don't want to use it. You don't even want to look at the source. When a bored coder has a martini (or several...) and decides to single-handedly reinvent much of the past ~60 years of computer science from scratch, nothing good results.

The nominal goal is to get 2025's [Advent of Code](https://adventofcode.com/) stars using only Johann, via its self-hosted compiler.

## The Short Version

Clone, compile, and link a test program as below. You'll need the command-line developer/Xcode tools installed.

    git clone git@github.com:barneyb/johann.git
    cd johann
    echo 'pub fn main() { puts("Hello, world!"); }' | ./bin/jnc > hello.s
    gcc hello.s ./lib/jstdlib.o
    ./a.out

This will print _exactly_ what you'd expect<sup>1</sup>:

    Hello, world!

If you're intrigued (or mortified), https://barneyb.github.io/johann/ has additional info for human consumption. The sources are the definitive resource, of course.

---
<sup>1</sup> If you start any computer programming project with something more complicated than printing 'Hello, world!', you've already introduced your first defect, even if you can't see it yet.
