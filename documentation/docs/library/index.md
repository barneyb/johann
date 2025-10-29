# Johann's Standard Library

Johann's standard library is minimal. Functions are grouped by the file defining them, which is currently an opaque detail. Symbols use a `__j_` prefix, so `puts` is actually exported to the linker as `__j_puts`.

??? note "Johann vs Assembly"

    While the compiler is written entirely in Johann itself, parts of the standard library are still implemented in assembly. You can see behind the curtain a bit below; the Johann bits (e.g., [`allocator`](#allocator)) have their docs generated from the source itself, while the assembly bits (e.g., the first [`io`](#io)) are hand-documented as if C. The second [`io`](#io_1) is Johann.

<!--{johanndoc:jstdlib/allocator.jn}-->

## `allocator`

Dynamic memory functions. Eventually, these will go away in favor of `new`/`drop` or something. And hopefully be taken over by the compiler itself, so programmers can't screw it up. We'll see.

`pub fn free(void* mem) `

: Free the allocation pointed to by the passed pointer, previously returned from `malloc`. A null pointer may be "freed" as a no-op.

`pub fn malloc(int bytes) `

: Allocate (at least) the specified number of bytes of memory and return a pointer to it. The same pointer must be passed back to `free` at some point.


<!--{/johanndoc:jstdlib/allocator.jn}-->

<!--{johanndoc:jstdlib/ArrayList.jn}-->

## `ArrayList`

I am auto-resizing array-backed list structure. Elements are always 64-bit values with pass by value semantics. `ArrayList__new_owned` can if the elements are pointers to owned objects.

 The `push`, `peek`, and `pop` "methods" offer graceful use as a stack.

`pub fn ArrayList__new(int capacity) `

: I create a new list with the specified capacity.

`pub fn ArrayList__new_owned(int capacity, void* drop_el) `

: I create a new list with the specified capacity, and function pointer for dropping elements.

`pub fn ArrayList_size(void* self) `

: I return the number of elements current in the list.

`pub fn ArrayList_push(void* self, void el) `

: I add the passed element to the end of the list, extending it if needed.

`pub fn ArrayList_push_all(void* self, void* els) `

: I add every element in the null-terminated `els` array to the end of the list, extending it if needed.

`pub fn ArrayList_get(void* self, int i) `

: I return the `i`th element in the list. If `i` < 0 or `i` >= size, panic.

`pub fn ArrayList_into_array(void* self) `

: I consume the list and return a null-terminated array of its elements. The array may have unfreed capacity beyond the terminating null.

`pub fn ArrayList_drop(void* self) `

: I drop the list, along with its elements (if they are owned).

`pub fn ArrayList_pop(void* self) `

: I remove and return the last element on the stack (in the list), panicking if the stack is empty.

`pub fn ArrayList_peek(void* self) `

: I return the last element on the stack (in the list), without removing it, panicking if the stack is empty.


<!--{/johanndoc:jstdlib/ArrayList.jn}-->

## `io`

No files, just STDIN and STDOUT. `EOF` is any negative number. Additional functions are found below in the second [`io`](#io_1).

* `int getchar( )` - consume the next character from STDIN, or `EOF`.
* `bool iseof( )` - whether STDIN has reached EOF.
* `int peekchar( )` - peek at the next character from STDIN without consuming it, or `EOF`.
* `int printf( char* format, ... )` - converts args to strings based on the null-terminated `format`, and write to STDOUT.
* `int eprintf( char* format, ... )` - same as `printf`, but write to STDERR (without buffering).
* `int putchar( int ch )` - write `ch` to STDOUT and return the `char` written.
* `int puts( char* str )` - write the null-terminated byte string `str` _and a newline_ to STDOUT.

<!--{johanndoc:jstdlib/io.jn}-->

## `io`

No files, just STDIN and STDOUT. `EOF` is any negative number. Additional functions are found above in the first [`io`](#io).

`pub fn read_line() `

: I read one line of characters and return a pointer to a heap-allocated null-terminated byte string containing them. A line ends when `EOF` is reached, or a newline (`0xa`) is encountered. Such newlines _are_ consumed, but _are not_ returned as part of the result. If already at `EOF`, `null` is returned (not an empty string).

`pub fn strchr(char* str, char ch) `

: I return a pointer to the first occurrence of `ch` in `str`, or `null` if no occurrence was found. The terminating `null` is considered part of `str`.

`pub fn substr(char* str, int start, int end) `

: I create a new null-terminated byte string from the given half-open range of the passed `str`. No bounds checking is performed.


<!--{/johanndoc:jstdlib/io.jn}-->

<!--{johanndoc:jstdlib/string.jn}-->

## `string`

Utilities for null-terminated byte string (NTBS) manipulation. Plus `memcpy`, because those C guys are weird.

`pub fn isdigit(char c) `

: is the passed character a decimal digit?

`pub fn isspace(char c) `

: is the passed character whitespace?

`pub fn isxdigit(char c) `

: is the passed character a hexidecimal digit?

`pub fn memcpy(void* dest, void* src, int count) `

: copy bytes between non-overlapping memory regions.

`pub fn strclone(char* src) `

: clone the passed string into a new allocation.

`pub fn strcmp(char* lhs, char* rhs) `

: I compare two null-terminated byte strings and return a negative number if `lhs` sorts lexicographically first, a positive number if `rhs` is first, and zero if they are equal.

`pub fn strlen(char* str) `

: I return the length of the passed string, not including the terminating null byte.


<!--{/johanndoc:jstdlib/string.jn}-->

<!--{johanndoc:jstdlib/StringBuilder.jn}-->

## `StringBuilder`

I am a dynamically resizing builder for null-terminated byte strings.

`pub fn StringBuilder__new(int capacity) `

: I create new builder, with the given initial capacity.

`pub fn StringBuilder_push(StringBuilder* self, char c) `

: I push a single character into the buffer, which will be automatically extended if the character won't fit.

`pub fn StringBuilder_push_str(StringBuilder* self, char* str) `

: I push another string into the buffer, which will be automatically extended if needed.

`pub fn StringBuilder_into_chars(StringBuilder* self) `

: I consume the builder and produce a null-terminated byte string from it.


<!--{/johanndoc:jstdlib/StringBuilder.jn}-->

<!--{johanndoc:jstdlib/sys.jn}-->

## `sys`

Functions for interacting with the underlying operating system. `syscall` is the magic sledgehammer, since Johann's pretty thin on wrappers.

`pub fn exit(int status);`

: Terminate the process, with the given exit status.

`pub fn panic(int status, char* buf, int nbytes);`

: Print a character buffer to STDERR and terminate processing, as if by `exit`.

`pub fn syscall(int number);`

: Make an arbitrary system call, by number. All additional arguments passed will be moved forward one "slot", so the second argument passed to `syscall` will be the first argument passed to the kernel.


<!--{/johanndoc:jstdlib/sys.jn}-->

<!--{johanndoc:jstdlib/TreeMap.jn}-->

## `TreeMap`

I am a binary tree-based map/dict ADT. Keys and values are arbitrary 64-bit values with pass-by-value semantics. `TreeMap__new_owned` can help with cleanup if the keys and/or values are pointers to owned objects. Using `null` as a key works _if `comparator` and `drop_key` are `null`-safe_. Using `null` as a value works _if `drop_value` is `null`-safe_.

 Currently, the tree structure is not balanced, so time complexity is nominally `O(n)`, _including `size`_! This will change.

`pub fn TreeMap__new(void* comparator) `

: I create a new `TreeMap`, using the provided `comparator` function pointer to provide total order over its keys.

`pub fn TreeMap__new_owned(void* comparator, void* drop_key, void* drop_value) `

: 

`pub fn TreeMap_drop(TreeMap* self) `

: I drop the map, `free`-ing all internal structure, along with its keys and values (if they are owned).

`pub fn TreeMap_is_empty(TreeMap* self) `

: I return whether the map is empty.

`pub fn TreeMap_size(TreeMap* self) `

: I return the number of entries in the map.

`pub fn TreeMap_contains(TreeMap* self, void key) `

: I indicate whether the map has a mapping for `key`.

`pub fn TreeMap_get(TreeMap* self, void key) `

: I return the value mapped to the provided `key`, or `null` if one doesn't exit in the map.

`pub fn TreeMap_put(TreeMap* self, void key, void value) `

: I ensure the map contains an entry with the provided `key`, mapped to the provided `value`. If a mapping already existed, its `value` is replaced, but its `key` is not.

`pub fn TreeMap_delete(TreeMap* self, void key) `

: I ensure the map does not contain an entry with the provided `key`, whether one previously existed or not.

`pub fn TreeMap_min_key(TreeMap* self) `

: 

`pub fn TreeMap_max_key(TreeMap* self) `

: 


<!--{/johanndoc:jstdlib/TreeMap.jn}-->

## Obsolete

These are still present, but should not be used. They'll be removed, eventually.

### `io`

* `char* itoa( int n )` - no direct replacement, but `printf` can do it on the way to STDOUT

### `table`

Superseded by [TreeMap](#treemap)

A table/map/associative-array ADT, which has a reasonable interface (for a tree-based structure), and a linear-scan implementation. This is intended to eventually be a "class". Keys and values are arbitrary 64-bit values, with pass-by-value semantics, and otherwise generic/open-ended. The `Table_drop_owned` method can help if the keys and/or value are pointers to table-owned objects.

* `Table* Table__new( fn* comparator )` - create a new empty table, where `comparator` points to a function which defines both equality and total order over the table's keys.
* `bool Table_contains( Table* t, ? key )` - check whether `key` exists in `t`.
* `void Table_drop( Table* t )` - drops `t`, freeing all internal structure.
* `void Table_drop_owned( Table* t, fn* drop_key, fn* drop_value )` - drops `t`, freeing all internal structure, and passing each key & value to the corresponding drop-function's pointer (if non-`null`).
* `? Table_get( Table* t, ? key )` - return the value associated with `key` in `t`, otherwise `null`.
* `? Table_remove( Table* t, ? key )` - ensure `key` doesn't exist in `t`, returning its previous value (or `null`).
* `? Table_put( Table* t, ? key, ? value )` - associate `key` with `value` in `t`, returning its previous value (or `null`).
* `int Table_size( Table* t )` - return the number of keys in `t`.
