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

// ============================================
// Error Reporting Helpers
// ============================================

func report_parse_error(expected_kind: u64, actual_kind: u64, tok: u64) -> u64 {
    begin_error_capture();
    set_error_context("Token mismatch", 14);
    
    emit_stderr("[ERROR] Expected token kind ", 29);
    emit_u64_stderr(expected_kind);
    emit_stderr(" but got ", 9);
    emit_u64_stderr(actual_kind);

    if (tok != 0) {
        emit_stderr(" at ", 4);
        emit_u64_stderr(((*Token)tok)->line);
        emit_stderr(":", 1);
        emit_u64_stderr(((*Token)tok)->col);
        emit_stderr(" token=", 7);
        if (actual_kind == TOKEN_EOF) {
            emit_stderr("<eof>", 5);
        } else {
            emit_stderr(((*Token)tok)->ptr, ((*Token)tok)->len);
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
    var p: *Parser = (*Parser)heap_alloc(16);
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
