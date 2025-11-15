# Definitions

By default, definitions are private to the file they're declared in. Use `pub` to make a definition available elsewhere, whether a function, global variable, or struct. To use a `pub` variable in another file, it must be redeclared in that file. 

!!! tip
    You _really_ want to use [header files](../build/index.md#header-files) for relating compilation units. Compile with `--strict` for much better errors.

The `bool`, `char`, `int`, and `void` keywords are used to introduce a variable, local or global. They will move to the other side of the identifier, so `int i = ...` will become `let i: int = ...`, and the type may become optional as well. Pointers are declared with `*`. `void` can be used to represent "a 64-bit value", and thus `void*` means "a pointer to something". No type checking is performed, but the type is used for `sizeof` and struct member access. This mess will improve.

## Structs

Structs can be used to model compound data. They can be marked `pub` too, but it doesn't _do_ anything, since there's no definition past the declaration. You can't make a struct's members public, only its name.

If you wanted to implement a Lisp-ish DSL in Johann, you might start with the code below, which also illustrates using a declared type to introduce parameters and local variables:

```johann
void nil = null;

struct Cell {
    void car,
    void cdr
}

fn cons(void car, Cell* tail) {
    Cell* l = malloc(sizeof(Cell));
    l.car = car;
    l.cdr = tail;
    return l;
}

fn drop(Cell* list) {
    if list == nil { return; }
    drop(list.cdr);
    free(list);
}

pub fn main() {
    Cell* my_list = cons(3, cons(2, cons(1, nil)));
    drop(my_list);
}
```

## Declarations

Functions, types, and global variables can be declared without being defined. This is needed to reference definitions from other files (where they must be declared `pub`, of course). Function calls do not (yet) require a reference, but taking an address (to make a function pointer) sometimes does. Global variables always require a reference, to use or take an address.

!!! tip
    Again, you _really_ want to use [header files](../build/index.md#header-files) for relating compilation units, though this time it's for saving copy'n'paste.

This program prints an externally-defined greeting three times, in three different ways:

```johann
char* GREETING;             # declare variable defined "somewhere else"

pub fn main() {
    char* str = GREETING;   # deref global (declaration required)
    void* puts_ptr = &puts; # take address of function
    puts(str, 99999);       # call jstdlib function (with incorrect params)
    puts_ptr(str);          # invoke through pointer
    printf(str);            # call another jstdlib function
}
```

If you use a header file, you'd get a compile error for that extra param on line 6.

## Methods

Finally, method-like syntax is supported _directly_ off identifiers which are typed with a `struct` type, as syntactic sugar for calling a function with the type's name as an underscore-delimited prefix. Easier to show, using [StringBuilder](../library/stringbuilder.jn.md), where the two `push_str` calls are equivalent, due to the explicit type of `sb`:

```johann
struct StringBuilder;                           # bring name into scope

fn build() {
    StringBuilder* sb = StringBuilder__new(10); # declare w/ type
    StringBuilder_push_str(sb, "Hello, ");      # long-form
    sb.push_str("World!");                      # pseudo-method
    char* s = sb.into_chars();
    puts(s);
    free(s);
}
```

Unlike member/field dereferences, the method-like syntax _is not typechecked_. If you call an unknown function, you'll get the same linker error whether you use the long or method form.
