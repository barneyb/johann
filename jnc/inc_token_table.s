; value token types (0x100)
    T_BOOL      = 0x100 + 'b'
    T_CHAR      = 0x100 + 'c'
    T_ID        = 0x100 + 'i'
    T_INT       = 0x100 + 'n'   ; not 'i'
    T_STRING    = 0x100 + 's'
; literal keywords never become tokens, they become value tokens.
; flow control keywords (0x200)
    T_KW_AGAIN  = 0x200 + 'A'
    T_KW_DONE   = 0x200 + 'D'
    T_KW_IF     = 0x200 + 'I'
    T_KW_RETURN = 0x200 + 'R'
    T_KW_WHILE  = 0x200 + 'W'
; type keywords (0x300)
    T_KW_BOOL   = 0x300 + 'B'
    T_KW_CHAR   = 0x300 + 'C'
    T_KW_INT    = 0x300 + 'I'
    T_KW_VOID   = 0x300 + 'V'
; definition keywords (0x400)
    T_KW_CONST  = 0x400 + 'C'
    T_KW_FN     = 0x400 + 'F'
    T_KW_LET    = 0x400 + 'L'
    T_KW_PUB    = 0x400 + 'P'
; ambiguous character tokens (ASCII, for now)
    T_ASSIGN    = '='           ; double-alias, for now
    T_BANG      = '!'
    T_EQ        = '='           ; double-alias, for now
    T_GT        = '>'
    T_LT        = '<'
    T_MINUS     = '-'
    T_PLUS      = '+'
; simple character tokens (ASCII)
    T_AMP       = '&'
    T_CBRACE    = '}'
    T_CBRACKET  = ']'
    T_COLON     = ':'
    T_COMMA     = ','
    T_CPAREN    = ')'
    T_DOT       = '.'
    T_HASH      = '#'
    T_OBRACE    = '{'
    T_OBRACKET  = '['
    T_OPAREN    = '('
    T_PERCENT   = '%'
    T_PIPE      = '|'
    T_QUESTION  = '?'
    T_SEMI      = ';'
    T_SLASH     = '/'
    T_STAR      = '*'
