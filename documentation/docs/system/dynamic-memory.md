# Dynamic Memory Allocation

The [allocator](../library/allocator.jn.md) only uses anonymously `mmap`ed pages, which are acquired on-demand, and never `unmmap`ed. Allocations passed back to `free` are marked for recycling in a best-fit fashion, and are neither coalesced nor re-chunked more finely. Recycling is always preferred to requesting more space from the OS.

Under the hood, the allocator maintains memory to recycle as a set of linked lists through the heap. There are a few for small allocations, plus one more where everything bigger goes. Each list is kept in sorted order as chunks are added, smallest first. The "small" lists only have chunks of a single size, so maintaining sorted order is trivial: adding at the head is always correct.

Stats from a sample run showing the 'big' list and the six small lists' are below:

|        | 'big' |        16 |        32 | 48 |  64 | 80 | 96 |     total |
|-------:|------:|----------:|----------:|---:|----:|---:|---:|----------:|
| allocs |   190 | 2,146,192 | 2,759,003 |  2 | 969 |  1 |  0 | 4,906.357 |
|  frees |   190 | 2,146,192 | 2,759,003 |  2 | 969 |  1 |  0 | 4,906.357 |
| chunks |    25 |       989 |   613,721 |  2 | 837 |  1 |  0 |   615.575 |

Separating the 16- and 32-byte lists from the rest reduced this program's runtime by over 95%!

## Warnings

When a program exits without panicking, the count of `malloc` and `free` calls over the life of the execution is compared, as are the total bytes allocated and free-d. If they don't match, a warning is printed to both STDOUT and STDERR with the details. This execution missed a single free:

    ; MEM: 7157 allocs (0xdc7b0 bytes)
    ;      7156 frees  (0xdc7a0 bytes) [-1 : -0x10 bytes]
    ;      3984 chunks (0xc2700 bytes)
    ;      52 mmaps  (52 pages)

STDERR will show a summary of the free lists as well. Collecting these stats cannot be disabled without modifying the source, but the cost is miniscule compared to how wasteful the compiled codes are. The columns in the table correspond to the different free lists mentioned above.

You can call the undocumented `mem_stats__(bool force)` function to force a warning to be printed while your program is running, which is occasionally helpful for debugging. 

## Errors

A small subset of alloc/free errors cause a `98` panic, but most do not. Both checks will eventually go away, once the language itself takes at least partial ownership of dynamic memory, instead of letting humans do it.
