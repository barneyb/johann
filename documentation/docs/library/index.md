# Johann's Standard Library

Johann's standard library is minimal. Functions are grouped by the file defining them, which is currently an opaque detail. Symbols use a `__j_` prefix, so `puts` is actually exported to the linker as `__j_puts`.

??? note "Johann vs Assembly"

    While the compiler is written entirely in Johann itself, parts of the standard library are still implemented in assembly. You can see behind the curtain a bit below; the Johann bits have their docs generated from the source itself, while the assembly bits are hand-documented as if C.

## Obsolete

These are still present, but should not be used. They'll be removed, eventually.

### `io`

* `char* itoa( int n )` - no direct replacement, but `printf` can do it on the way to STDOUT

### `table`

Superseded by [TreeMap](treemap.jn.md)

A table/map/associative-array ADT, which has a reasonable interface (for a tree-based structure), and a linear-scan implementation. This is intended to eventually be a "class". Keys and values are arbitrary 64-bit values, with pass-by-value semantics, and otherwise generic/open-ended. The `Table_drop_owned` method can help if the keys and/or value are pointers to table-owned objects.

* `Table* Table__new( fn* comparator )` - create a new empty table, where `comparator` points to a function which defines both equality and total order over the table's keys.
* `bool Table_contains( Table* t, ? key )` - check whether `key` exists in `t`.
* `void Table_drop( Table* t )` - drops `t`, freeing all internal structure.
* `void Table_drop_owned( Table* t, fn* drop_key, fn* drop_value )` - drops `t`, freeing all internal structure, and passing each key & value to the corresponding drop-function's pointer (if non-`null`).
* `? Table_get( Table* t, ? key )` - return the value associated with `key` in `t`, otherwise `null`.
* `? Table_remove( Table* t, ? key )` - ensure `key` doesn't exist in `t`, returning its previous value (or `null`).
* `? Table_put( Table* t, ? key, ? value )` - associate `key` with `value` in `t`, returning its previous value (or `null`).
* `int Table_size( Table* t )` - return the number of keys in `t`.
