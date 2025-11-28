# Dynamic Memory Allocation

The [allocator](../library/allocator.jn.md) only uses anonymously `mmap`ed pages, which are acquired on-demand, and never `unmmap`ed. Allocations passed back to `free` are marked for recycling in a best-fit fashion, and are neither coalesced nor re-chunked more finely. Recycling is always preferred to requesting more space from the OS.

Under the hood, the allocator maintains memory to recycle as a set of doubly-linked lists through the heap. There are a few for small allocations, plus one for everything larger. Each list is kept in sorted order as chunks are added, smallest first. The "small" lists only have chunks of a single size, so maintaining sorted order is trivial: adding at the head is always correct.

The per-list stats from a sample run of compiling `parser.jn` from `jnc`:

|        | 'big' |        16 |        32 | 48 |  64 | 80 | 96 |     total |
|-------:|------:|----------:|----------:|---:|----:|---:|---:|----------:|
| allocs |   141 |      6080 |     13835 | 29 | 381 |  0 |  0 |     20466 |
|  frees |   141 |      6080 |     13835 | 29 | 381 |  0 |  0 |     20466 |
| chunks |    26 |      4638 |      4997 | 29 | 176 |  0 |  0 |      9866 |


The choice of six "small" lists was arbitrary, and has served well in practice. The single 'big' list is simple, and has also served well enough. Some sort of logarithmic progression of sized buckets seems like the way out, but it hasn't mattered yet. Initially, there was just one list for everything, and performance was _terrible_.  

## Warnings

When a program exits without panicking, the count of `malloc` and `free` calls over the life of the execution is compared, as are the total bytes allocated and free-d. If they don't match, a warning is printed to both STDOUT and STDERR with the details. This execution missed a single free:

    ; MEM: 7157 allocs (0xdc7b0 bytes)
    ;      7156 frees  (0xdc7a0 bytes) [-1 : -0x10 bytes]
    ;      3984 chunks (0xc2700 bytes)
    ;      52 mmaps  (52 pages)

STDERR will show a summary of the free lists as well. Collecting these stats cannot be disabled without modifying the source, but the cost is miniscule compared to how wasteful the compiled codes are.

You can call the undocumented `mem_stats__(bool force)` function to force a warning to be printed while your program is running, which is occasionally helpful for debugging. 

## Errors

A small subset of alloc/free errors cause a `98` panic, but most do not. Both checks will eventually go away, once the language itself takes at least partial ownership of dynamic memory, instead of letting humans do it.
