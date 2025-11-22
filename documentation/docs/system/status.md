# Development Status

## Language Features

- [x] `fn` / `return` constructs
- [x] `if` / `while` constructs
- [x] arbitrary variable names
- [x] read/write global variables
- [x] compound expressions with precedence
- [x] address-of and dereference operators
- [x] function pointers
- [x] structs
- [ ] typechecking
- [x] array indexing
- [ ] array types
- [ ] blocks/scopes
- [x] unconstrained local variables
- [ ] unconstrained parameter passing (and varargs?)
- [ ] logical operators
- [x] shift operators
- [ ] non-shift bitwise operators
- [ ] conditional/ternary operator
- [ ] `+=` and friends
- [ ] implicit types in declarations
- [ ] methods
- [ ] `const` support
- [ ] compound literals
- [ ] traits
- [ ] forward declarations
- [ ] import/include
- [ ] automatic memory management
- [ ] `for` loops/iterators
- [ ] `enum` support

## Library Features

- [x] buffered StdOut & `printf`
- [x] tree-based symbol table
- [x] string builder type
- [x] dynamic memory recycling
- [x] array-backed list type
- [ ] balanced tree-based symbol table
- [x] sorting arrays
- [ ] buffered StdIn & StdErr
- [ ] read/write files
- [ ] regular expressions
- [x] hash-based symbol table
- [x] a queue data type
- [ ] binary search of arrays

## Compilation Stages

Below is a sketch of the compiler's current state (green), along with a sketch of the target structure (gray). Initially, it emitted straight from the parts of the token stream it recognized, ignoring the rest, and relying on the programmer to ensure referenced symbols would resolve.

```mermaid
flowchart TB
    in((prog.jn)) 
    lex(Lexer)
    parse(Parser)
    raz(Raz Generation)
    emit(Emitter)
    out((prog.s))
    
    subgraph sem [Semantic Analysis]
        idres(ID resolution)
        tc(Type Checking)
        lbl(Labeling)
    end
    subgraph opt [Code Optimization]
        const(Constant Folding)
        noreach(Unreachable Code)
        dead(Dead Stores)
    end
    subgraph gen [Code Generation]
        ins(Instruction Selection)
        regalloc(Register Allocation)
        temps(Replace Temporaries)
        fixup(Instruction Fixup?)
    end
    
    classDef partial stroke-width:0.5px,stroke-dasharray:5;
    class idres,lbl,tc,ins partial;
    classDef future fill:none,stroke:#808080,stroke-width:0.5px,stroke-dasharray:5 5;
    class sem,gen,raz,const,noreach,dead,regalloc,temps,fixup future;
    
    parse ---|AST| sem
    sem ---|AST| raz ---|RAZ| opt  ---|RAZ| gen
    gen ---|Assembly| out
    
    linkStyle 0,1,2,3,4 stroke:#808080,stroke-dasharray:5;
    
    in -->|text| lex
    lex -->|tokens| parse
    parse -->|AST| emit ---->|Assembly| out
    
    %% force unlinked subgraphs to lay out horizontally
    idres ~~~ tc ~~~ lbl
    const ~~~ noreach ~~~ dead
    ins ~~~ regalloc ~~~ temps ~~~ fixup
```
