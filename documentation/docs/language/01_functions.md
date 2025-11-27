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

A few ways to print `one: 1` to STDOUT, using the `add` function defined above and several of the standard library functions:

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

## Methods

Method-like syntax is supported _directly_ off identifiers which are typed with a `struct` type, as syntactic sugar for calling a function with the type's name as an underscore-delimited prefix.

Using [ArrayList](../library/arraylist.jn.md), the two `push` calls below are equivalent, due to the explicit type of `l`:

```johann
ArrayList* l = ArrayList__new(10); # declare w/ type

ArrayList_push(l, "Hello, ");      # long-form
        l.push(   "World!" );      # pseudo-method

l.drop();
```

Unlike member/field dereferences, the method-like syntax _is not typechecked_. If you call an unknown function, you'll get the same error whether you use the long or method form. If you're use `--strict`, it'll be a compiler error, otherwise a linker error.
