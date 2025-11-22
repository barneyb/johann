# Dynamic Memory Allocation

The [allocator](../library/allocator.jn.md) only uses anonymously `mmap`ed pages, which are acquired on-demand, and never `unmmap`ed. Allocations passed back to `free` are marked for recycling in a best-fit fashion, and are neither coalesced nor re-chunked more finely. Recycling is always preferred to requesting more space from the OS.

When a program exits without panicking, the count of `malloc` and `free` calls over the life of the execution is compared, as are the total bytes allocated and free-d. If they don't match, a warning is printed to both STDOUT and STDERR with the details. This execution missed a single free:

    ; MEM: 7157 allocs (0xdc7b0 bytes)
    ;      7156 frees  (0xdc7a0 bytes) [-1 : -0x10 bytes]
    ;      3984 chunks (0xc2700 bytes)
    ;      52 mmaps  (52 pages)

A small subset of alloc/free errors cause a `98` panic, but most do not. Both checks will eventually go away, once the language itself takes at least partial ownership of dynamic memory, instead of letting humans do it.
