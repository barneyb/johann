# Compiler Docs

Below are the generated docs for the compiler's internals. Not that much is
documented, but searching just declarations has advantages over searching the
full sources.

<!--{johanndoc:jnc/ast.jn}-->

## `ast`

I hold the compiler's AST implementation.

`pub int AST_LIT_BOOL    = 1;`

: [AST_LIT_BOOL, value]

`pub int AST_LIT_CHAR    = 2;`

: [AST_LIT_CHAR, value]

`pub int AST_LIT_INT     = 3;`

: [AST_LIT_INT, value]

`pub int AST_LIT_STRING  = 20;`

: [AST_LIT_STRING, value]

`pub int AST_ID          = 50;`

: [AST_ID, nameT]

`pub int AST_UNARY       = 101;`

: [AST_UNARY, op, operand]

`pub int AST_BINARY      = 102;`

: [AST_BINARY, op, left, right]

`pub int AST_ADDR_OP     = 103;`

: [AST_ADDR_OP, op, nameT]

`pub int AST_CALL        = 104;`

: [AST_CALL, callee, args[]]

`pub int AST_MEMBER      = 105;`

: [AST_MEMBER, rcvr, offset, width]

`pub int AST_PROGRAM     = 301;`

: [AST_PROGRAM, decls[]]

`pub int AST_DECL        = 302;`

: [AST_DECL, is_pub, fn_or_var]

`pub int AST_FN          = 303;`

: [AST_FN, nameT, params[], block?]

`pub int AST_STRUCT      = 306;`

: [AST_STRUCT, nameT, members?]

`pub int AST_VARIABLE    = 307;`

: [AST_VARIABLE, type, nameT? init?]

`pub int AST_EVAL        = 401;`

: [AST_EVAL, expr]

`pub int AST_ASSIGN      = 402;`

: [AST_ASSIGN, expr, rhs]

`pub int AST_IF          = 403;`

: [AST_IF, cond, block]

`pub int AST_WHILE       = 404;`

: [AST_WHILE, cond, block]

`pub int AST_DONE        = 405;`

: [AST_DONE, kwT]

`pub int AST_AGAIN       = 406;`

: [AST_AGAIN, kwT]

`pub int AST_RETURN      = 407;`

: [AST_RETURN, kwT, expr?]

`pub int AST_TYPE_BOOL   = 501;`

: [AST_TYPE_BOOL]

`pub int AST_TYPE_CHAR   = 502;`

: [AST_TYPE_CHAR]

`pub int AST_TYPE_INT    = 503;`

: [AST_TYPE_INT]

`pub int AST_TYPE_VOID   = 520;`

: [AST_TYPE_VOID]

`pub int AST_TYPE_PTR    = 521;`

: [AST_TYPE_PTR, type]

`pub int AST_TYPE_NAMED  = 550;`

: [AST_TYPE_NAMED, nameT]

`pub int AST_TYPE_STRUCT = 1002;`

: [AST_TYPE_STRUCT, alignof, sizeof, memberMap]

`pub int AST_TYPE_MEMBER = 1003;`

: [AST_TYPE_MEMBER, name, offset, width]

`pub fn ast1(int type) `

: [type] 1-tuple (silly, but uniform)

`pub fn ast2(int type, void value) `

: [type, value] 2-tuple

`pub fn ast3(int type, void value, void left) `

: [type, value, left] 3-tuple

`pub fn ast4(int type, void value, void left, void right) `

: [type, value, left, right] 4-tuple

`pub fn ast_sizeof(void* ast) `

: 

`pub fn ast_alignment(void* ast) `

: 

`pub fn drop_ast(void* ast) `

: 


<!--{/johanndoc:jnc/ast.jn}-->


<!--{johanndoc:jnc/Block.jn}-->

## `Block`

I store information about a block/scope. I used to be an implementation detail of Emitter, which still hard-codes some layout information.

`pub int SIZEOF_BLOCK = 0x20;`

: 

`pub fn Block_init(void* self, int type, int id) `

: 

`pub fn Block_drop(void* self) `

: 

`pub fn Block_type(void* self) `

: 

`pub fn Block_id(void* self) `

: 

`pub fn Block_symbols(void* self) `

: 


<!--{/johanndoc:jnc/Block.jn}-->


<!--{johanndoc:jnc/emitter.jn}-->

## `emitter`



`pub fn Emitter__new() `

: 

`pub fn Emitter_drop(void* self) `

: 

`pub fn Emitter_mark_global(void* nameT) `

: 

`pub fn Emitter_vardecl(void* self, void* nameT, int type, int nptr) `

: 

`pub fn Emitter_do_decl(void* self, void* nameT, int type, int nptr, void* expr) `

: 

`pub fn Emitter_do_fn_proto(void* self, void* nameT, void* args) `

: 

`pub fn Emitter_do_fn_intro(void* self, void* nameT, void* args) `

: 

`pub fn Emitter_do_fn_outro(void* self, void* nameT) `

: 

`pub fn Emitter_do_close_block(void* self) `

: 

`pub fn Emitter_do_return(void* self, void* token) `

: 

`pub fn Emitter_do_if(void* self, void* cond) `

: 

`pub fn Emitter_do_while(void* self, void* cond) `

: 

`pub fn Emitter_do_again(void* self, void* token) `

: 

`pub fn Emitter_do_done(void* self, void* token) `

: 

`pub fn Emitter_do_assign(void* self, void* nameT, void* expr) `

: 

`pub fn Emitter_do_assign_member(void* self, void* member, void* expr) `

: [AST_MEMBER, rcvr, offset, width]

`pub fn Emitter_do_assign_pointer(void* self, void* nameT, void* expr) `

: 

`pub fn Emitter_eval_const(void* self, void* expr) `

: 

`pub fn Emitter_eval_expr(void* self, void* expr) `

: 


<!--{/johanndoc:jnc/emitter.jn}-->


<!--{johanndoc:jnc/Env.jn}-->

## `Env`

I hold the environment during compilation, which is usually nested.

`pub fn Env__new(void* parent) `

: 

`pub fn Env_drop(void* self) `

: 

`pub fn Env_push(void* self) `

: 

`pub fn Env_pop(void* self) `

: 

`pub fn Env_register_symbol(void* self, void* nameT, void* type_ast) `

: 

`pub fn Env_typeof_symbol(void* self, char* name) `

: 

`pub fn Env_register_type(void* self, void* nameT, void* type_ast) `

: 

`pub fn Env_seed_type(void* self, char* name, void* type_ast) `

: I'm just for `jnc` to register the built-in types.

`pub fn Env_get_type(void* self, char* name) `

: 

`pub fn Env_is_type(void* self, char* name) `

: 

`pub fn Env_sizeof_type(void* self, char* name) `

: 

`pub fn Env_alignof_type(void* self, char* name) `

: 


<!--{/johanndoc:jnc/Env.jn}-->


<!--{johanndoc:jnc/jnc.jn}-->

## `jnc`



`pub fn main(int argc, char** argv) `

: 

`pub void ENV = null;`

: 

`pub fn jnc_panic(char* format, void* token, int status) `

: `token` is a `[val, line, col]` tuple to dissect for the format, which will be passed four values: `status`, `val`, `line`, and `col`;


<!--{/johanndoc:jnc/jnc.jn}-->


<!--{johanndoc:jnc/lexer.jn}-->

## `lexer`



`pub char* KW_BOOL   = "bool";`

: 

`pub char* KW_CHAR   = "char";`

: 

`pub char* KW_INT    = "int";`

: 

`pub char* KW_VOID   = "void";`

: 

`pub fn Lexer__new() `

: 

`pub fn Lexer_drop(void* self) `

: 

`pub fn Lexer_token(void* self) `

: 

`pub fn Lexer_peek(void* self) `

: 

`pub fn get_next_token(void* self) `

: 


<!--{/johanndoc:jnc/lexer.jn}-->


<!--{johanndoc:jnc/parser.jn}-->

## `parser`



`pub fn print_token(void* t) `

: 

`pub fn parse_program(void* lex) `

: 


<!--{/johanndoc:jnc/parser.jn}-->


<!--{johanndoc:jnc/Symbol.jn}-->

## `Symbol`

I store information about a symbol in a Johann program. I was originally an unencapsulated memory location, and there are still assumptions that the first and second quad of my layout are width and nptr.

`pub fn Symbol__new(int type, int nptr) `

: I create a new symbol, computing its width from its type (ick).

`pub fn Symbol_type(void* self) `

: 

`pub fn Symbol_width(void* self) `

: 

`pub fn Symbol_nptr(void* self) `

: 

`pub fn Symbol_offset(void* self) `

: 

`pub fn Symbol_set_offset(void* self, int offset) `

: 


<!--{/johanndoc:jnc/Symbol.jn}-->


<!--{johanndoc:jnc/to_emitter.jn}-->

## `to_emitter`



`pub fn to_emitter(void* emitter, void* ast) `

: 


<!--{/johanndoc:jnc/to_emitter.jn}-->


<!--{johanndoc:jnc/Token.jn}-->

## `Token`

I represent a token, lexed from the input stream.

`pub fn Token__new(int type) `

: I create a new token, with the given type.

`pub fn Token_drop(void* token) `

: 

`pub fn Token_type(void* token) `

: 

`pub fn Token_into_type(void* token) `

: 

`pub fn Token_set_type(void* token, int type) `

: 

`pub fn Token_line(void* token) `

: 

`pub fn Token_char(void* token) `

: 

`pub fn Token_set_coords(void* token, int line_num, int char_offset) `

: 

`pub fn Token_value(void* token) `

: 

`pub fn Token_into_value(void* token) `

: 

`pub fn Token_set_value(void* token, void value) `

: 


<!--{/johanndoc:jnc/Token.jn}-->


<!--{johanndoc:jnc/token_table.jn}-->

## `token_table`

I hold the lexer's token table

`pub int T_BOOL      = 0x162; # 0x100 + 'b';`

: 

`pub int T_CHAR      = 0x163; # 0x100 + 'c';`

: 

`pub int T_ID        = 0x169; # 0x100 + 'i';`

: 

`pub int T_INT       = 0x16e; # 0x100 + 'n';  # not 'i'`

: 

`pub int T_STRING    = 0x173; # 0x100 + 's';`

: 

`pub int T_KW_AGAIN  = 0x341; # 0x300 + 'A';`

: 

`pub int T_KW_DONE   = 0x344; # 0x300 + 'D';`

: 

`pub int T_KW_IF     = 0x349; # 0x300 + 'I';`

: 

`pub int T_KW_RETURN = 0x352; # 0x300 + 'R';`

: 

`pub int T_KW_WHILE  = 0x357; # 0x300 + 'W';`

: 

`pub int T_KW_BOOL   = 0x442; # 0x400 + 'B';`

: 

`pub int T_KW_CHAR   = 0x443; # 0x400 + 'C';`

: 

`pub int T_KW_INT    = 0x449; # 0x400 + 'I';`

: 

`pub int T_KW_SIZEOF = 0x453; # 0x400 + 'S';`

: 

`pub int T_KW_VOID   = 0x456; # 0x400 + 'V';`

: 

`pub int T_KW_CONST  = 0x543; # 0x500 + 'C';`

: 

`pub int T_KW_FN     = 0x546; # 0x500 + 'F';`

: 

`pub int T_KW_LET    = 0x54c; # 0x500 + 'L';`

: 

`pub int T_KW_PUB    = 0x550; # 0x500 + 'P';`

: 

`pub int T_KW_STRUCT = 0x553; # 0x500 + 'S';`

: 

`pub int T_EQ        = 0x23d; # 0x200 + '=';`

: 

`pub int T_GTE       = 0x23e; # 0x200 + '>';`

: 

`pub int T_LOG_AND   = 0x226; # 0x200 + '&';`

: 

`pub int T_LOG_OR    = 0x27c; # 0x200 + '|';`

: 

`pub int T_LTE       = 0x23c; # 0x200 + '<';`

: 

`pub int T_NEQ       = 0x221; # 0x200 + '!';`

: 

`pub int T_ARROW     = 0x261; # 0x200 + 'a';`

: 

`pub int T_MINUS_ASSIGN   = 0x22d; # 0x200 + '-';`

: 

`pub int T_PERCENT_ASSIGN = 0x225; # 0x200 + '%';`

: 

`pub int T_PLUS_ASSIGN    = 0x22b; # 0x200 + '+';`

: 

`pub int T_SLASH_ASSIGN   = 0x22f; # 0x200 + '/';`

: 

`pub int T_STAR_ASSIGN    = 0x22a; # 0x200 + '*';`

: 

`pub int T_AMP       = '&';`

: 

`pub int T_ASSIGN    = '=';`

: 

`pub int T_BANG      = '!';`

: 

`pub int T_GT        = '>';`

: 

`pub int T_LT        = '<';`

: 

`pub int T_MINUS     = '-';`

: 

`pub int T_PERCENT   = '%';`

: 

`pub int T_PLUS      = '+';`

: 

`pub int T_SLASH     = '/';`

: 

`pub int T_STAR      = '*';`

: 

`pub int T_CBRACE    = '}';`

: 

`pub int T_CBRACKET  = ']';`

: 

`pub int T_COLON     = ':';`

: 

`pub int T_COMMA     = ',';`

: 

`pub int T_CPAREN    = ')';`

: 

`pub int T_DOT       = '.';`

: 

`pub int T_HASH      = '#';`

: 

`pub int T_OBRACE    = '`

: 

`pub int T_OBRACKET  = '[';`

: 

`pub int T_OPAREN    = '(';`

: 

`pub int T_PIPE      = '|';`

: 

`pub int T_QUESTION  = '?';`

: 

`pub int T_SEMI      = ';';`

: 

`pub int T_SQUOTE    = 0x27;         # no escapes (yet)`

: 

`pub int T_DQUOTE    = '"';`

: 


<!--{/johanndoc:jnc/token_table.jn}-->


<!--{johanndoc:jnc/types.jn}-->

## `types`




<!--{/johanndoc:jnc/types.jn}-->

