# Johann's Standard Library

Johann's standard library is minimal. Functions are grouped by the file defining them, which is currently an opaque detail. Symbols use a `__j_` prefix, so `puts` is actually exported to the linker as `__j_puts`.

If you want to use [header files](../build/index.md#header-files) for the standard library, you must build them yourself; they're not currently provided. You'll need the sources, of course, but there's nothing different from creating headers from your own sources.

## Iterator Protocol

An iterator protocol is defined by convention. Eventually, Johann will formally incorporate it with the syntactic sugar you expect, but the type system is not yet capable enough. It has three parts:

1. The iterable "thing" must have a zero-arg 'method' named `iter` which returns a pointer to a newly-allocated struct type (the iterator).
1. The iterator must have a zero-arg 'method' named `next` which returns a pointer to the next element being iterator over, or `null` if the iterator is exhausted.
1. The iterator must have no owned state, so it can be `free`-ed directly (no custom drop behavior).

For now, the bookkeeping required to use an iterator is the programmer's responsibility. For example (`Iter_next` is the `next` method of `ArrayList`'s iterator):

```johann
ArrayList* l = ArrayList__new(3);
l.push(123); l.push(456); l.push(789);

void* itr = l.iter();           # get an iterator
while true {
    int* el = Iter_next(itr);   # pointer to next element
    if el == null { done; }     # if null, done
    printf("%d\n", *el);        # use the pointer to the element
}
free(itr);                      # free the iterator

l.drop();
```

Eventually, the central loop above will look something like this:

```
for el in l {                   # implicit iterator
    printf("%d\n", el);         # use the element
}                               # implicit free
```

Multiple iterators from a single type are no more complicated than ignoring point #1. This _should_ be close enough to leverage the (vaporware) syntactic sugar, as long as the iterator has an `iter` method that returns itself. For example, [`HashMap`](hashmap.jn.md) defines [`keys`](hashmap.jn.md#hashmap_keys) to return an iterator over the map's keys.

## Johann vs Assembly

While the compiler is written entirely in Johann itself, parts of the standard library are still implemented in assembly. System calls can't be made with Johann syntax directly, which motivates most of the lingering assembly. This is some of the oldest code, and hasn't been rewritten.

The `printf` and `syscall` functions are variadic, which Johann doesn't yet have support for, so they must remain assembly. `printf` has a special exemption from `--strict` for this reason. `syscall` probably should as well; I'll add one if/when it proves useful enough.
