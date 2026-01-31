// parse_util.b - Parser utility functions
//
// Core parser operations:
// - Parser state management (new, peek, advance, prev)
// - Token matching and consuming
// - Error reporting

import std.io;
import std.vec;
import std.util;
import lexer;
import compiler;

// Local layout mirror for sizeof (avoid sizeof on imported types during bootstrap).
struct ParserLocal { tokens_vec: u64; cur: u64; }

// ============================================
// Error Reporting Helpers
// ============================================

func token_kind_name(kind: u64) -> u64 {
    if (kind == TOKEN_EOF) { return "EOF"; }
    if (kind == TOKEN_NUMBER) { return "number"; }
    if (kind == TOKEN_IDENTIFIER) { return "identifier"; }
    if (kind == TOKEN_STRING) { return "string"; }
    if (kind == TOKEN_LPAREN) { return "'('"; }
    if (kind == TOKEN_RPAREN) { return "')'"; }
    if (kind == TOKEN_LBRACE) { return "'{'"; }
    if (kind == TOKEN_RBRACE) { return "'}'"; }
    if (kind == TOKEN_LBRACKET) { return "'['"; }
    if (kind == TOKEN_RBRACKET) { return "']'"; }
    if (kind == TOKEN_SEMICOLON) { return "';'"; }
    if (kind == TOKEN_COLON) { return "':'"; }
    if (kind == TOKEN_COMMA) { return "','"; }
    if (kind == TOKEN_DOT) { return "'.'"; }
    if (kind == TOKEN_ARROW) { return "'->'"; }
    if (kind == TOKEN_PLUS) { return "'+'"; }
    if (kind == TOKEN_MINUS) { return "'-'"; }
    if (kind == TOKEN_STAR) { return "'*'"; }
    if (kind == TOKEN_SLASH) { return "'/'"; }
    if (kind == TOKEN_PERCENT) { return "'%'"; }
    if (kind == TOKEN_EQ) { return "'='"; }
    if (kind == TOKEN_EQEQ) { return "'=='"; }
    if (kind == TOKEN_BANGEQ) { return "'!='"; }
    if (kind == TOKEN_LT) { return "'<'"; }
    if (kind == TOKEN_LE) { return "'<='"; }
    if (kind == TOKEN_GT) { return "'>'"; }
    if (kind == TOKEN_GE) { return "'>='"; }
    if (kind == TOKEN_AMPERSAND) { return "'&'"; }
    if (kind == TOKEN_PIPE) { return "'|'"; }
    if (kind == TOKEN_CARET) { return "'^'"; }
    if (kind == TOKEN_ANDAND) { return "'&&'"; }
    if (kind == TOKEN_OROR) { return "'||'"; }
    if (kind == TOKEN_BANG) { return "'!'"; }
    if (kind == TOKEN_PLUSPLUS) { return "'++'"; }
    if (kind == TOKEN_MINUSMINUS) { return "'--'"; }
    if (kind == TOKEN_PLUS_EQ) { return "'+='"; }
    if (kind == TOKEN_MINUS_EQ) { return "'-='"; }
    if (kind == TOKEN_STAR_EQ) { return "'*='"; }
    if (kind == TOKEN_SLASH_EQ) { return "'/='"; }
    if (kind == TOKEN_PERCENT_EQ) { return "'%='"; }
    if (kind == TOKEN_TILDE) { return "'~'"; }
    if (kind == TOKEN_VAR) { return "'var'"; }
    if (kind == TOKEN_FUNC) { return "'func'"; }
    if (kind == TOKEN_RETURN) { return "'return'"; }
    if (kind == TOKEN_IF) { return "'if'"; }
    if (kind == TOKEN_ELSE) { return "'else'"; }
    if (kind == TOKEN_WHILE) { return "'while'"; }
    if (kind == TOKEN_FOR) { return "'for'"; }
    if (kind == TOKEN_BREAK) { return "'break'"; }
    if (kind == TOKEN_CONTINUE) { return "'continue'"; }
    if (kind == TOKEN_IMPORT) { return "'import'"; }
    if (kind == TOKEN_STRUCT) { return "'struct'"; }
    if (kind == TOKEN_ENUM) { return "'enum'"; }
    if (kind == TOKEN_CONST) { return "'const'"; }
    if (kind == TOKEN_TRUE) { return "'true'"; }
    if (kind == TOKEN_FALSE) { return "'false'"; }
    if (kind == TOKEN_SIZEOF) { return "'sizeof'"; }
    if (kind == TOKEN_CHAR) { return "'char'"; }
    return "unknown token";
}

func token_kind_name_len(kind: u64) -> u64 {
    if (kind == TOKEN_EOF) { return 3; }
    if (kind == TOKEN_NUMBER) { return 6; }
    if (kind == TOKEN_IDENTIFIER) { return 10; }
    if (kind == TOKEN_STRING) { return 6; }
    if (kind == TOKEN_LPAREN) { return 3; }
    if (kind == TOKEN_RPAREN) { return 3; }
    if (kind == TOKEN_LBRACE) { return 3; }
    if (kind == TOKEN_RBRACE) { return 3; }
    if (kind == TOKEN_LBRACKET) { return 3; }
    if (kind == TOKEN_RBRACKET) { return 3; }
    if (kind == TOKEN_SEMICOLON) { return 3; }
    if (kind == TOKEN_COLON) { return 3; }
    if (kind == TOKEN_COMMA) { return 3; }
    if (kind == TOKEN_DOT) { return 3; }
    if (kind == TOKEN_ARROW) { return 4; }
    if (kind == TOKEN_PLUS) { return 3; }
    if (kind == TOKEN_MINUS) { return 3; }
    if (kind == TOKEN_STAR) { return 3; }
    if (kind == TOKEN_SLASH) { return 3; }
    if (kind == TOKEN_PERCENT) { return 3; }
    if (kind == TOKEN_EQ) { return 3; }
    if (kind == TOKEN_EQEQ) { return 4; }
    if (kind == TOKEN_BANGEQ) { return 4; }
    if (kind == TOKEN_LT) { return 3; }
    if (kind == TOKEN_LE) { return 4; }
    if (kind == TOKEN_GT) { return 3; }
    if (kind == TOKEN_GE) { return 4; }
    if (kind == TOKEN_AMPERSAND) { return 3; }
    if (kind == TOKEN_PIPE) { return 3; }
    if (kind == TOKEN_CARET) { return 3; }
    if (kind == TOKEN_ANDAND) { return 4; }
    if (kind == TOKEN_OROR) { return 4; }
    if (kind == TOKEN_BANG) { return 3; }
    if (kind == TOKEN_PLUSPLUS) { return 4; }
    if (kind == TOKEN_MINUSMINUS) { return 4; }
    if (kind == TOKEN_PLUS_EQ) { return 4; }
    if (kind == TOKEN_MINUS_EQ) { return 4; }
    if (kind == TOKEN_STAR_EQ) { return 4; }
    if (kind == TOKEN_SLASH_EQ) { return 4; }
    if (kind == TOKEN_PERCENT_EQ) { return 4; }
    if (kind == TOKEN_TILDE) { return 3; }
    if (kind == TOKEN_VAR) { return 5; }
    if (kind == TOKEN_FUNC) { return 6; }
    if (kind == TOKEN_RETURN) { return 8; }
    if (kind == TOKEN_IF) { return 4; }
    if (kind == TOKEN_ELSE) { return 6; }
    if (kind == TOKEN_WHILE) { return 7; }
    if (kind == TOKEN_FOR) { return 5; }
    if (kind == TOKEN_BREAK) { return 7; }
    if (kind == TOKEN_CONTINUE) { return 10; }
    if (kind == TOKEN_IMPORT) { return 8; }
    if (kind == TOKEN_STRUCT) { return 8; }
    if (kind == TOKEN_ENUM) { return 6; }
    if (kind == TOKEN_CONST) { return 7; }
    if (kind == TOKEN_TRUE) { return 6; }
    if (kind == TOKEN_FALSE) { return 7; }
    if (kind == TOKEN_SIZEOF) { return 8; }
    if (kind == TOKEN_CHAR) { return 6; }
    return 13;  // "unknown token"
}

func get_source_ptr() -> u64 {
    return compiler_get_source_ptr();
}

func get_source_len() -> u64 {
    return compiler_get_source_len();
}

func report_parse_error(expected_kind: u64, actual_kind: u64, tok: u64) -> u64 {
    begin_error_capture();
    set_error_context("Token mismatch", 14);
    
    emit_stderr("\n[ERROR] Parse error at line ", 30);
    if (tok != 0) {
        emit_u64_stderr(((*Token)tok)->line);
        emit_stderr(", column ", 9);
        emit_u64_stderr(((*Token)tok)->col);
    }
    emit_stderr_nl();
    
    emit_stderr("  Expected: ", 12);
    emit_stderr(token_kind_name(expected_kind), token_kind_name_len(expected_kind));
    emit_stderr_nl();
    
    emit_stderr("  Got:      ", 12);
    emit_stderr(token_kind_name(actual_kind), token_kind_name_len(actual_kind));
    
    if (tok != 0) {
        if (actual_kind != TOKEN_EOF) {
            if (actual_kind == TOKEN_IDENTIFIER) {
                emit_stderr(" ", 1);
                emit_stderr(((*Token)tok)->ptr, ((*Token)tok)->len);
            } else if (actual_kind == TOKEN_NUMBER) {
                emit_stderr(" ", 1);
                emit_stderr(((*Token)tok)->ptr, ((*Token)tok)->len);
            }
        }
    }
    emit_stderr_nl();
    panic();
}

func report_integer_overflow_error(tok: u64) -> u64 {
    set_error_context("Integer overflow", 16);
    emit_stderr("[ERROR] Integer literal overflow at ", 38);
    emit_u64(((*Token)tok)->line);
    emit_stderr(":", 1);
    emit_u64(((*Token)tok)->col);
    emit_stderr(" literal=", 9);
    emit_stderr(((*Token)tok)->ptr, ((*Token)tok)->len);
    emit_nl();
    panic();
}

// Parser structure: [tokens_vec, cur]

func parse_new(tokens: u64) -> u64 {
    var p: *Parser = (*Parser)heap_alloc(sizeof(ParserLocal));
    p->tokens_vec = tokens;
    p->cur = 0;
    return (u64)p;
}

func parse_peek(p: u64) -> u64 {
    var parser: *Parser = (*Parser)p;
    if (parser->cur >= vec_len(parser->tokens_vec)) { return 0; }
    return vec_get(parser->tokens_vec, parser->cur);
}

func parse_peek_kind(p: u64) -> u64 {
    var tok: u64 = parse_peek(p);
    if (tok == 0) { return TOKEN_EOF; }
    return ((*Token)tok)->kind;
}

func parse_adv(p: u64) -> u64 {
    var parser: *Parser = (*Parser)p;
    parser->cur = parser->cur + 1;
}

func parser_pos(p: u64) -> u64 {
    var parser: *Parser = (*Parser)p;
    return parser->cur;
}

func parser_set_pos(p: u64, pos: u64) {
    var parser: *Parser = (*Parser)p;
    parser->cur = pos;
}

func parse_prev(p: u64) -> u64 {
    var parser: *Parser = (*Parser)p;
    if (parser->cur == 0) { return 0; }
    return vec_get(parser->tokens_vec, parser->cur - 1);
}

func parse_match(p: u64, kind: u64) -> u64 {
    if (parse_peek_kind(p) == kind) {
        parse_adv(p);
        return 1;
    }
    return 0;
}

func parse_consume(p: u64, kind: u64) -> u64 {
    if (!parse_match(p, kind)) {
        var tok: u64 = parse_peek(p);
        var got: u64 = parse_peek_kind(p);
        report_parse_error(kind, got, tok);
    }
}

// ============================================
// Number parsing helper
// ============================================

func parse_num_val(tok: u64) -> u64 {
    var ptr: u64 = ((*Token)tok)->ptr;
    var len: u64 = ((*Token)tok)->len;
    var val: u64 = 0;

    // i64 max = 9223372036854775807
    var max_div10: u64 = 922337203685477580;
    var max_mod10: u64 = 7;

    for (var i: u64 = 0; i < len; i++) {
        var c: u64 = *(*u8)(ptr + i);
        var digit: u64 = c - 48;

        if (val > max_div10) {
            report_integer_overflow_error(tok);
        }
        if (val == max_div10) {
            if (digit > max_mod10) {
                report_integer_overflow_error(tok);
            }
        }

        val = val * 10 + digit;
    }
    return val;
}
