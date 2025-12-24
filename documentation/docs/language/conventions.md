# Conventions

Johann has a few conventions to follow, primarily to set the groundwork for using new features that are planned without as much refactoring. These are on display throughout [`jstdlib`](../library/index.md), and the best example is [`ArrayList`](../library/arraylist.jn.md).

## Type-Associated Functions

Functions associated with a custom type (i.e., "methods") should be named with the type's name, followed by one or two underscores, and then the "method" name. One underscore indicates an instance method. Two underscores indicate a non-instance (`static`) method. Instance methods always take a pointer to the associated type as their first argument, typically named `self`.

For example:

```johann
struct Person { char* name }

fn Person__new(char* name);
fn Person_name(Person* self);
fn Person_set_name(Person* self, char* name);
fn Person_drop(Person* self);
```

### `new` and `drop`

Structs should have a `<type>__new` function which at least allocates a new object of the struct type and returns a pointer to it.

Structs should have a `<type>_drop` function which can deallocate an object of that type, even if it's just `free(self)`.

If a struct has optionally-owned data, a `<type>__new_owned` function should accept drop functions for the owned data, treating `null` as "you don't own it".

## Iterator Protocol

An iterator protocol is defined by convention. Eventually, Johann will formally incorporate it with the syntactic sugar you expect, but the type system is not yet capable enough. It has three parts:

1. The iterable "thing" should have a zero-arg 'method' named `iter` which returns a pointer to a newly-allocated struct type (the iterator).
1. The iterator must have a zero-arg 'method' named `next` which returns a pointer to the next element being iterator over, or `null` if the iterator is exhausted.
1. The iterator should have a zero-arg 'method' named `iter` which returns itself.

For now, the bookkeeping required to use an iterator is the programmer's responsibility. For example (`Iter_next` is the `next` method of `ArrayList`'s iterator):

```johann
ArrayList* l = ArrayList__new(3);
l.push(123); l.push(456); l.push(789);

Iter* itr = l.iter();           # get an iterator
while true {
    int* el = Iter_next(itr);   # pointer to next element
    if el == null { done; }     # if null, done
    printf("%d\n", *el);        # use the pointer to the element
}
itr.drop();                     # drop the iterator

l.drop();
```

Eventually, the central loop above will look something like this:

```
for el in l {                   # implicit iterator
    printf("%d\n", el);         # use the element
}                               # implicit free
```

Multiple iterators from a single type are no more complicated than ignoring point #1. This _should_ be close enough to leverage the (vaporware) syntactic sugar, as long as the iterator has an `iter` method that returns itself. For example, [`HashMap`](../library/hashmap.jn.md) defines `keys` to return an iterator over the map's keys.
