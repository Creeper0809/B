// lexer.b - Lexer implementation for v3.8

import std.io;
import types;
import std.util;
import std.vec;

// Lexer structure: [src_ptr, src_len, pos, line, col]

func lex_new(src: u64, len: u64) -> u64 {
    var l: *Lexer = (*Lexer)heap_alloc(40);
    l->src_ptr = src;
    l->src_len = len;
    l->pos = 0;
    l->line = 1;
    l->col = 1;
    return (u64)l;
}

func lex_at_end(l: u64) -> u64 {
    var lex: *Lexer = (*Lexer)l;
    if (lex->pos >= lex->src_len) { return 1; }
    return 0;
}

func lex_peek(l: u64) -> u64 {
    if (lex_at_end(l)) { return 0; }
    var lex: *Lexer = (*Lexer)l;
    return *(*u8)(lex->src_ptr + lex->pos);
}

func lex_peek_next(l: u64) -> u64 {
    var lex: *Lexer = (*Lexer)l;
    if (lex->pos + 1 >= lex->src_len) { return 0; }
    return *(*u8)(lex->src_ptr + lex->pos + 1);
}

func lex_advance(l: u64) -> u64 {
    var c: u64 = lex_peek(l);
    var lex: *Lexer = (*Lexer)l;
    lex->pos = lex->pos + 1;
    if (c == 10) {
        lex->line = lex->line + 1;
        lex->col = 1;
    } else {
        lex->col = lex->col + 1;
    }
    return c;
}

func lex_skip_ws(l: u64) -> u64 {
    while (!lex_at_end(l)) {
        var c: u64 = lex_peek(l);
        if (!is_whitespace(c)) { break; }
        lex_advance(l);
    }
}

func lex_skip_comment(l: u64) -> u64 {
    if (lex_peek(l) == 47) {
        if (lex_peek_next(l) == 47) {
            lex_advance(l);
            lex_advance(l);
            while (!lex_at_end(l)) {
                var c: u64 = lex_peek(l);
                if (c == 10) {
                    lex_advance(l);
                    break;
                }
                lex_advance(l);
            }
        }
    }
}

func lex_skip_ws_and_comments(l: u64) -> u64 {
    while (!lex_at_end(l)) {
        lex_skip_ws(l);
        var c: u64 = lex_peek(l);
        if (c == 47) {
            if (lex_peek_next(l) == 47) {
                lex_skip_comment(l);
            } else {
                break;
            }
        } else {
            break;
        }
    }
}

func lex_check_keyword(ptr: u64, len: u64) -> u64 {
    if (str_eq(ptr, len, "func", 4)) { return TOKEN_FUNC; }
    if (str_eq(ptr, len, "var", 3)) { return TOKEN_VAR; }
    if (str_eq(ptr, len, "const", 5)) { return TOKEN_CONST; }
    if (str_eq(ptr, len, "return", 6)) { return TOKEN_RETURN; }
    if (str_eq(ptr, len, "if", 2)) { return TOKEN_IF; }
    if (str_eq(ptr, len, "else", 4)) { return TOKEN_ELSE; }
    if (str_eq(ptr, len, "true", 4)) { return TOKEN_TRUE; }
    if (str_eq(ptr, len, "false", 5)) { return TOKEN_FALSE; }
    if (str_eq(ptr, len, "struct", 6)) { return TOKEN_STRUCT; }
    if (str_eq(ptr, len, "enum", 4)) { return TOKEN_ENUM; }
    if (str_eq(ptr, len, "impl", 4)) { return TOKEN_IMPL; }
    if (str_eq(ptr, len, "while", 5)) { return TOKEN_WHILE; }
    if (str_eq(ptr, len, "for", 3)) { return TOKEN_FOR; }
    if (str_eq(ptr, len, "switch", 6)) { return TOKEN_SWITCH; }
    if (str_eq(ptr, len, "case", 4)) { return TOKEN_CASE; }
    if (str_eq(ptr, len, "default", 7)) { return TOKEN_DEFAULT; }
    if (str_eq(ptr, len, "break", 5)) { return TOKEN_BREAK; }
    if (str_eq(ptr, len, "continue", 8)) { return TOKEN_CONTINUE; }
    if (str_eq(ptr, len, "asm", 3)) { return TOKEN_ASM; }
    if (str_eq(ptr, len, "import", 6)) { return TOKEN_IMPORT; }
    if (str_eq(ptr, len, "u8", 2)) { return TOKEN_U8; }
    if (str_eq(ptr, len, "u16", 3)) { return TOKEN_U16; }
    if (str_eq(ptr, len, "u32", 3)) { return TOKEN_U32; }
    if (str_eq(ptr, len, "u64", 3)) { return TOKEN_U64; }
    if (str_eq(ptr, len, "i64", 3)) { return TOKEN_I64; }
    return TOKEN_IDENTIFIER;
}

// Token structure: [kind, ptr, len, line, col]

func tok_new(kind: u64, ptr: u64, len: u64, line: u64, col: u64) -> u64 {
    var t: *Token = (*Token)heap_alloc(40);
    t->kind = kind;
    t->ptr = ptr;
    t->len = len;
    t->line = line;
    t->col = col;
    return (u64)t;
}



func lex_next(l: u64) -> u64 {
    lex_skip_ws_and_comments(l);
    
    var lex: *Lexer = (*Lexer)l;
    var line: u64 = lex->line;
    var col: u64 = lex->col;
    
    if (lex_at_end(l)) {
        return tok_new(TOKEN_EOF, 0, 0, line, col);
    }
    
    var start: u64 = lex->pos;
    var c: u64 = lex_advance(l);
    var src: u64 = lex->src_ptr;
    
    // Identifier or keyword
    if (is_alpha(c)) {
        while (!lex_at_end(l)) {
            if (is_alnum(lex_peek(l))) {
                lex_advance(l);
            } else {
                break;
            }
        }
        lex = (*Lexer)l;
        var len: u64  = lex->pos - start;
        var kind: u64 = lex_check_keyword(src + start, len);
        return tok_new(kind, src + start, len, line, col);
    }
    
    // Number
    if (is_digit(c)) {
        while (!lex_at_end(l)) {
            if (is_digit(lex_peek(l))) {
                lex_advance(l);
            } else {
                break;
            }
        }
        lex = (*Lexer)l;
        var len: u64 = lex->pos - start;
        return tok_new(TOKEN_NUMBER, src + start, len, line, col);
    }
    
    // String literal
    if (c == 34) {
        while (!lex_at_end(l)) {
            var ch: u64 = lex_peek(l);
            if (ch == 34) {
                lex_advance(l);
                break;
            }
            if (ch == 92) {
                lex_advance(l);
                if (!lex_at_end(l)) {
                    lex_advance(l);
                }
            } else {
                lex_advance(l);
            }
        }
        lex = (*Lexer)l;
        var len: u64 = lex->pos - start;
        return tok_new(TOKEN_STRING, src + start, len, line, col);
    }
    
    // Two-char operators
    if (c == 61) {
        if (lex_peek(l) == 61) {
            lex_advance(l);
            return tok_new(TOKEN_EQEQ, src + start, 2, line, col);
        }
        return tok_new(TOKEN_EQ, src + start, 1, line, col);
    }
    if (c == 33) {
        if (lex_peek(l) == 61) {
            lex_advance(l);
            return tok_new(TOKEN_BANGEQ, src + start, 2, line, col);
        }
        return tok_new(TOKEN_BANG, src + start, 1, line, col);
    }
    if (c == 60) {
        if (lex_peek(l) == 61) {
            lex_advance(l);
            return tok_new(TOKEN_LTEQ, src + start, 2, line, col);
        }
        if (lex_peek(l) == 60) {
            lex_advance(l);
            return tok_new(TOKEN_LSHIFT, src + start, 2, line, col);
        }
        return tok_new(TOKEN_LT, src + start, 1, line, col);
    }
    if (c == 62) {
        if (lex_peek(l) == 61) {
            lex_advance(l);
            return tok_new(TOKEN_GTEQ, src + start, 2, line, col);
        }
        if (lex_peek(l) == 62) {
            lex_advance(l);
            return tok_new(TOKEN_RSHIFT, src + start, 2, line, col);
        }
        return tok_new(TOKEN_GT, src + start, 1, line, col);
    }

    if (c == 38) {
        if (lex_peek(l) == 38) {
            lex_advance(l);
            return tok_new(TOKEN_ANDAND, src + start, 2, line, col);
        }
        return tok_new(TOKEN_AMPERSAND, src + start, 1, line, col);
    }

    if (c == 124) {
        if (lex_peek(l) == 124) {
            lex_advance(l);
            return tok_new(TOKEN_OROR, src + start, 2, line, col);
        }
        return tok_new(TOKEN_PIPE, src + start, 1, line, col);
    }
    
    // Single-char tokens
    if (c == 40) { return tok_new(TOKEN_LPAREN, src + start, 1, line, col); }
    if (c == 41) { return tok_new(TOKEN_RPAREN, src + start, 1, line, col); }
    if (c == 123) { return tok_new(TOKEN_LBRACE, src + start, 1, line, col); }
    if (c == 125) { return tok_new(TOKEN_RBRACE, src + start, 1, line, col); }
    if (c == 91) { return tok_new(TOKEN_LBRACKET, src + start, 1, line, col); }
    if (c == 93) { return tok_new(TOKEN_RBRACKET, src + start, 1, line, col); }
    if (c == 59) { return tok_new(TOKEN_SEMICOLON, src + start, 1, line, col); }
    if (c == 58) { return tok_new(TOKEN_COLON, src + start, 1, line, col); }
    if (c == 44) { return tok_new(TOKEN_COMMA, src + start, 1, line, col); }
    if (c == 46) { return tok_new(TOKEN_DOT, src + start, 1, line, col); }
    if (c == 43) {
        if (lex_peek(l) == 43) {
            lex_advance(l);
            return tok_new(TOKEN_PLUSPLUS, src + start, 2, line, col);
        }
        return tok_new(TOKEN_PLUS, src + start, 1, line, col);
    }
    if (c == 45) {
        if (lex_peek(l) == 45) {
            lex_advance(l);
            return tok_new(TOKEN_MINUSMINUS, src + start, 2, line, col);
        }
        if (lex_peek(l) == 62) {
            lex_advance(l);
            return tok_new(TOKEN_ARROW, src + start, 2, line, col);
        }
        return tok_new(TOKEN_MINUS, src + start, 1, line, col);
    }
    if (c == 42) { return tok_new(TOKEN_STAR, src + start, 1, line, col); }
    if (c == 47) { return tok_new(TOKEN_SLASH, src + start, 1, line, col); }
    if (c == 37) { return tok_new(TOKEN_PERCENT, src + start, 1, line, col); }
    if (c == 94) { return tok_new(TOKEN_CARET, src + start, 1, line, col); }
    // NOTE: '&' and '|' are handled above to support &&/||.
    
    return tok_new(TOKEN_EOF, 0, 0, line, col);
}

func lex_all(src: u64, len: u64) -> u64 {
    var l: u64 = lex_new(src, len);
    var tokens: u64 = vec_new(256);
    while (1) {
        var tok: u64 = lex_next(l);
        vec_push(tokens, tok);
        if (((*Token)tok)->kind == TOKEN_EOF) { break; }
    }
    return tokens;
}
