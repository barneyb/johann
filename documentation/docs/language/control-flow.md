# Control Flow

Conditionals use the `if` keyword and loops use `while`. The conditional expression is not wrapped with parentheses (though you can, of course, wrap any expression with parens). Braces are required around the body. There is no `else`.

```johann
int i = 0;
int f = 0;
char c = getchar();
while c >= 0 {
    i = i + 1;
    if c == '(' {
        f = f + 1;
    }
    c = getchar();
}
```

You can use `done` and `again` within a `while` to ... say you're done looping or want to loop again. These two snippets are equivalent:

```johann
# the reasonable way
char c;
while c >= 0 {
    c = getchar();
}

# the silly way
while true {
    if c >= 0 {
        c = getchar();
        again;
    }
    done;
}
```

Only eight levels of nesting are supported. If you go deeper, you'll probably run into memory corruption. Break your function into smaller, simpler pieces.

Semicolons are required to terminate statements which don't take a block. Blocks are _not_ statements as is normal in C-family languages; they're parts of the `if` and `while` syntax. As well as not establishing scope, you can't have anonymous blocks (they would be of zero value). This will change, so don't abuse it.
