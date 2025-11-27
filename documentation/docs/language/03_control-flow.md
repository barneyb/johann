# Control Flow

Conditionals use the `if` and `else` keywords, and loops use `while`. The conditional expression is not wrapped with parentheses (though you can, of course, wrap any expression with parens). Braces are required around the body, with one exception for `else` (discussed below). We _love_ counting parentheses:

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

Semicolons are required to terminate statements which don't take a block. Blocks are _not_ statements as is normal in C-family languages; they're parts of the `if` and `while` syntax. As well as not establishing scope, you can't have anonymous blocks (they would be of zero value). This will change, so don't abuse it.

## Conditionals

An isolated `if` statement: 

```johann
int f = 0;
char c = getchar();
if c == '+' {
    f = f + 1;
}
```

You can use `else` to do something else if the `if`'s condition evaluates to `false`:

```johann
int f = 0;
char c = getchar();
if c == '+' {
    f = f + 1;
} else {
    eprintf("Unrecognized '%c'\n", c);
}
```

If an `else`'s body is a single `if` statement, you can omit the braces. All the braces in the example below are required. There is an implied `{` after the _first_ `else`, and an implied `}` at the very end. In English, the second `else` is "part of" the second `if`, which is the single `if` comprising the body of the first `if`'s `else`. No dangling-else ambiguity!  

```johann
int f = 0;
char c = getchar();
if c == '+' {
    f = f + 1;
} else if c == '-' {
    f = f - 1;
} else {
    eprintf("Unrecognized '%c'\n", c);
}
```

## Loops

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

Nesting depth is no longer constrained, but don't abuse it. Future you will thank you.
