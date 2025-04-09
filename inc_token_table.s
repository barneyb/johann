; value token types             0x111000
.set    T_BOOL      , 0x111000
.set    T_CHAR      , 0x111001
.set    T_ID        , 0x111002
.set    T_INT       , 0x111003
.set    T_STRING    , 0x111004
; literal keywords never become tokens, they become value tokens.
; flow control keywords         0x110000
.set    T_KW_AGAIN  , 0x110001
.set    T_KW_DONE   , 0x110002
.set    T_KW_IF     , 0x110003
.set    T_KW_RETURN , 0x110004
.set    T_KW_WHILE  , 0x110005
; type keywords                 0x120000
.set    T_KW_BOOL   , 0x120001
.set    T_KW_CHAR   , 0x120002
.set    T_KW_INT    , 0x120003
; definition keywords           0x130000
.set    T_KW_FN     , 0x130001
; ambiguous character tokens    0x100000
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
