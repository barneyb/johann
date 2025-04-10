; value token types             0x1000
.set    T_BOOL      , 0x1000
.set    T_CHAR      , 0x1001
.set    T_ID        , 0x1002
.set    T_INT       , 0x1003
.set    T_STRING    , 0x1004
; literal keywords never become tokens, they become value tokens.
; flow control keywords         0x2000
.set    T_KW_AGAIN  , 0x2001
.set    T_KW_DONE   , 0x2002
.set    T_KW_FOR    , 0x2003
.set    T_KW_IF     , 0x2004
.set    T_KW_RETURN , 0x2005
.set    T_KW_WHILE  , 0x2006
; type keywords                 0x3000
.set    T_KW_BOOL   , 0x3001
.set    T_KW_CHAR   , 0x3002
.set    T_KW_INT    , 0x3003
.set    T_KW_VOID   , 0x3004
; definition keywords           0x4000
.set    T_KW_CLASS  , 0x4001
.set    T_KW_FN     , 0x4002
; dynamic allocation keywords   0x5000
.set    T_KW_FREE   , 0x5001
.set    T_KW_NEW    , 0x5002
; ambiguous character tokens    ASCII (for now)
.set    T_ASSIGN    , '='
.set    T_BANG      , '!'
.set    T_GT        , '>'
.set    T_LT        , '<'
.set    T_MINUS     , '-'
.set    T_PLUS      , '+'
; simple character tokens       ASCII
.set    T_AMP       , '&'
.set    T_CBRACE    , '}'
.set    T_CBRACKET  , ']'
.set    T_COLON     , ':'
.set    T_COMMA     , ','
.set    T_CPAREN    , ')'
.set    T_DOT       , '.'
.set    T_HASH      , '#'
.set    T_OBRACE    , '{'
.set    T_OBRACKET  , '['
.set    T_OPAREN    , '('
.set    T_PERCENT   , '%'
.set    T_PIPE      , '|'
.set    T_QUESTION  , '?'
.set    T_SEMI      , ';'
.set    T_SLASH     , '/'
.set    T_STAR      , '*'
