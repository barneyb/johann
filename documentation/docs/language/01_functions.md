# Functions

Functions are declared with the `fn` keyword. Use `return` to return (with a value or not). The entry point for a program is always a `pub` function named `main`. There's not (yet) a way to declare a return type.

```johann
pub fn main() {
    return 0;
}
```

`main` can be declared with zero, one, or two parameters, which will be passed POSIX `argc` and `argv` values. This program will print its name and exit with the number of command line arguments it received.

```johann
pub fn main(int argc, char** argv) {
    puts(*argv);
    return argc - 1;
}
```

More generally, functions can declare parameters (aka formal arguments) within their parentheses, to create local variables from call arguments. Each function may any number of local variables, whether they come from parameters or are declared within. A pointless `add` function:

```johann
fn add(int a, int b) {
    return a + b;
}
```

Function calls have a max of eight parameters, which really only matters for [`printf`](../library/io.jn.md). A few ways to print `one: 1` to STDOUT, using the `add` function defined above and several of the standard library functions:

```johann
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

# more direct:
printf("one: %i\n", 1);

# easiest:
puts("one: 1");
```
