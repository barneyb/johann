# The Johann Language

The most important function:

```johann
pub fn main() {
    puts("Hello, world!");
}
```

Johann source code is always plain text, encoded with UTF-8, and uses a `.jn` extension by convention. Multibyte characters are forbidden; only ASCII characters are supported. There is no locale/language awareness/support.

All keywords are case-sensitive. Comments are introduced with `#` and extend to end of line. Whitespace is merely a delimiter, not semantic, and braces are used for control flow blocks, but not scoping (yet). There is no exception handling.

## I'm Sorry, What?!

If this seems like it was designed by a kindergartener, you're half right. Johann started with tooling commensurate to "late 1960's", but without a library of already-coded assembly routines (e.g., regex, a BST, or a hashtable). Now it's somewhere around 1970, plus a handful of library routines. Kindergartener is apropos for synthetic progress of a few years.  
