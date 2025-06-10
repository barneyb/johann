# Johann's Standard Library

Johann's standard library is minimal. Functions are grouped by the file defining them, which is currently an opaque detail. Symbols use a `__j_` prefix, so `puts` is actually exported to the linker as `__j_puts`.

??? note "Johann vs Assembly"

    While the compiler is written entirely in Johann itself, parts of the standard library are still implemented in assembly. You can see behind the curtain a bit below; the assembly bits (e.g., [`io`](#io)) are hand-documented as if C, while the Johann bits (e.g., [`allocator`](#allocator)) have their docs generated from the source itself.

<!--{johanndoc:jstdlib/allocator.jn}-->

### `allocator`

Dynamic memory functions. Eventually, these will go away in favor of `new`/`drop` or something. And hopefully be taken over by the compiler itself, so programmers can't screw it up. We'll see. 

* `pub fn free(void* mem) ` - Free the allocation pointed to by the passed pointer, previously returned from `malloc`. A null pointer may be "freed" as a no-op. 
* `pub fn malloc(int bytes) ` - Allocate (at least) the specified number of bytes of memory and return a pointer to it. The same pointer must be passed back to `free` at some point. 

<!--{/johanndoc:jstdlib/allocator.jn}-->

<!--{johanndoc:jstdlib/ArrayList.jn}-->

### `ArrayList`

I am auto-resizing array-backed list structure. Elements are always 64-bit values with pass by value semantics. `ArrayList__new_owned` can if the elements are pointers to owned objects.

 The `push`, `peek`, and `pop` "methods" offer graceful use as a stack.

* `pub fn ArrayList__new(int capacity) ` - I create a new list with the specified capacity.
* `pub fn ArrayList__new_owned(int capacity, void* drop_el) ` - I create a new list with the specified capacity, and function pointer for dropping elements.
* `pub fn ArrayList_size(void* self) ` - I return the number of elements current in the list.
* `pub fn ArrayList_push(void* self, void el) ` - I add the passed element to the end of the list, extending it if needed.
* `pub fn ArrayList_get(void* self, int i) ` - I return the `i`th element in the list. If `i` < 0 or `i` >= size, panic.
* `pub fn ArrayList_into_array(void* self) ` - I consume the list and return a null-terminated array of its elements. The array may have unfreed capacity beyond the terminating null.
* `pub fn ArrayList_drop(void* self) ` - I drop the list, along with its elements (if they are owned).
* `pub fn ArrayList_pop(void* self) ` - I remove and return the last element on the stack (in the list), panicking if the stack is empty.
* `pub fn ArrayList_peek(void* self) ` - I return the last element on the stack (in the list), without removing it, panicking if the stack is empty.

<!--{/johanndoc:jstdlib/ArrayList.jn}-->

### `io`

No files, just STDIN and STDOUT. `EOF` is any negative number.

* `int getchar( )` - consume the next character from STDIN, or `EOF`.
* `bool iseof( )` - whether STDIN has reached EOF.
* `int peekchar( )` - peek at the next character from STDIN without consuming it, or `EOF`.
* `int printf( char* format, ... )` - converts args to strings based on the null-terminated `format`, and write to STDOUT.
* `int eprintf( char* format, ... )` - same as `printf`, but write to STDERR (without buffering).
* `int putchar( int ch )` - write `ch` to STDOUT and return the `char` written.
* `int puts( char* str )` - write the null-terminated byte string `str` _and a newline_ to STDOUT.

<!--{johanndoc:jstdlib/string.jn}-->

### `string`

Utilities for null-terminated byte string (NTBS) manipulation. Plus `memcpy`, because those C guys are weird. 

* `pub fn isdigit(char c) ` - is the passed character a decimal digit? 
* `pub fn isspace(char c) ` - is the passed character whitespace? 
* `pub fn isxdigit(char c) ` - is the passed character a hexidecimal digit? 
* `pub fn memcpy(void* dest, void* src, int count) ` - copy bytes between non-overlapping memory regions. 
* `pub fn strclone(char* src) ` - clone the passed string into a new allocation. 
* `pub fn strcmp(char* lhs, char* rhs) ` - I compare two null-terminated byte strings and return a negative number if `lhs` sorts lexicographically first, a positive number if `rhs` is first, and zero if they are equal. 
* `pub fn strlen(char* str) ` - I return the length of the passed string, not including the terminating null byte. 

<!--{/johanndoc:jstdlib/string.jn}-->

<!--{johanndoc:jstdlib/StringBuilder.jn}-->

### `StringBuilder`

I am a dynamically resizing builder for null-terminated byte strings. 

* `pub fn StringBuilder__new(int capacity) ` - I create new builder, with the given initial capacity. 
* `pub fn StringBuilder_push(void* buf, char c) ` - I push a single character into the buffer, which will be automatically extended if the character won't fit. 
* `pub fn StringBuilder_into_chars(void* buf) ` - I consume the builder and produce a null-terminated byte string from it. 

<!--{/johanndoc:jstdlib/StringBuilder.jn}-->

<!--{johanndoc:jstdlib/sys.jn}-->

### `sys`

Functions for interacting with the underlying operating system. `syscall` is the magic sledgehammer, since Johann's pretty thin on wrappers. 

* `pub fn exit(int status)` - Terminate the process, with the given exit status. 
* `pub fn panic(int status, char* buf, int nbytes)` - Print a character buffer to STDERR and terminate processing, as if by `exit`. 
* `pub fn syscall(int number)` - Make an arbitrary system call, by number. All additional arguments passed will be moved forward one "slot", so the second argument passed to `syscall` will be the first argument passed to the kernel. 

<!--{/johanndoc:jstdlib/sys.jn}-->

### `table`

A table/map/associative-array ADT, which has a reasonable interface (for a tree-based structure), and a linear-scan implementation. This is intended to eventually be a "class". Keys and values are arbitrary 64-bit values, with pass-by-value semantics, and otherwise generic/open-ended. The `Table_drop_owned` method can help if the keys and/or value are pointers to table-owned objects.

* `Table* Table__new( fn* comparator )` - create a new empty table, where `comparator` points to a function which defines both equality and total order over the table's keys.
* `bool Table_contains( Table* t, ? key )` - check whether `key` exists in `t`.
* `void Table_drop( Table* t )` - drops `t`, freeing all internal structure.
* `void Table_drop_owned( Table* t, fn* drop_key, fn* drop_value )` - drops `t`, freeing all internal structure, and passing each key & value to the corresponding drop-function's pointer (if non-`null`).
* `? Table_get( Table* t, ? key )` - return the value associated with `key` in `t`, otherwise `null`.
* `? Table_remove( Table* t, ? key )` - ensure `key` doesn't exist in `t`, returning its previous value (or `null`).
* `? Table_put( Table* t, ? key, ? value )` - associate `key` with `value` in `t`, returning its previous value (or `null`).
* `int Table_size( Table* t )` - return the number of keys in `t`.

### Obsolete

One obsolete function remains available, and will eventually be removed.

* `char* itoa( int n )` - no direct replacement, but `printf` can do it on the way to STDOUT
