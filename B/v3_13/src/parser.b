// parser.b - Parser implementation for v3.8

import std.io;
import types;
import std.util;
import std.vec;
import lexer;
import ast;

// Parser structure: [tokens_vec, cur]

func parse_new(tokens: u64) -> u64 {
    var p: u64 = heap_alloc(16);
    *(p) = tokens;
    *(p + 8) = 0;
    return p;
}

func parse_peek(p: u64) -> u64 {
    var vec: u64 = *(p);
    var cur: u64 = *(p + 8);
    if (cur >= vec_len(vec)) { return 0; }
    return vec_get(vec, cur);
}

func parse_peek_kind(p: u64) -> u64 {
    var tok: u64 = parse_peek(p);
    if (tok == 0) { return TOKEN_EOF; }
    return tok_kind(tok);
}

func parse_adv(p: u64) -> u64 {
    *(p + 8) = *(p + 8) + 1;
}

func parse_prev(p: u64) -> u64 {
    var vec: u64 = *(p);
    var cur: u64 = *(p + 8);
    if (cur == 0) { return 0; }
    return vec_get(vec, cur - 1);
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
        emit_stderr("[ERROR] Expected token kind ", 29);
        emit_u64(kind);
        emit(" but got ", 9);
        var got: u64 = parse_peek_kind(p);
        emit_u64(got);

        var tok: u64 = parse_peek(p);
        if (tok != 0) {
            emit(" at ", 4);
            emit_u64(tok_line(tok));
            emit(":", 1);
            emit_u64(tok_col(tok));
            emit(" token=", 7);
            if (got == TOKEN_EOF) {
                emit("<eof>", 5);
            } else {
                emit(tok_ptr(tok), tok_len(tok));
            }
        }
        emit_nl();
        panic();
    }
}

// ============================================
// Type Parsing
// ============================================

func parse_base_type(p: u64) -> u64 {
    var k: u64 = parse_peek_kind(p);
    if (k == TOKEN_U8) { parse_adv(p); return TYPE_U8; }
    if (k == TOKEN_U16) { parse_adv(p); return TYPE_U16; }
    if (k == TOKEN_U32) { parse_adv(p); return TYPE_U32; }
    if (k == TOKEN_U64) { parse_adv(p); return TYPE_U64; }
    if (k == TOKEN_I64) { parse_adv(p); return TYPE_I64; }
    
    // Check for struct type name
    if (k == TOKEN_IDENTIFIER) {
        var tok: u64 = parse_peek(p);
        var name_ptr: u64 = tok_ptr(tok);
        var name_len: u64 = tok_len(tok);
        
        // Call is_struct_type (defined in main.b)
        if (is_struct_type(name_ptr, name_len) != 0) {
            parse_adv(p);
            return TYPE_STRUCT;
        }
    }
    
    return TYPE_VOID;
}

func parse_type(p: u64) -> u64 {
    var depth: u64 = 0;
    while (parse_match(p, TOKEN_STAR)) {
        depth = depth + 1;
    }
    var base: u64 = parse_base_type(p);
    var result: u64 = heap_alloc(16);
    *(result) = base;
    *(result + 8) = depth;
    return result;
}

// Extended type parsing that also captures struct type name.
// Layout: [base:8][ptr_depth:8][struct_name_ptr:8][struct_name_len:8]
func parse_type_ex(p: u64) -> u64 {
    var depth: u64 = 0;
    while (parse_match(p, TOKEN_STAR)) {
        depth = depth + 1;
    }

    var base: u64 = 0;
    var struct_name_ptr: u64 = 0;
    var struct_name_len: u64 = 0;

    var k: u64 = parse_peek_kind(p);
    if (k == TOKEN_U8) { parse_adv(p); base = TYPE_U8; }
    else if (k == TOKEN_U16) { parse_adv(p); base = TYPE_U16; }
    else if (k == TOKEN_U32) { parse_adv(p); base = TYPE_U32; }
    else if (k == TOKEN_U64) { parse_adv(p); base = TYPE_U64; }
    else if (k == TOKEN_I64) { parse_adv(p); base = TYPE_I64; }
    else if (k == TOKEN_IDENTIFIER) {
        var tok: u64 = parse_peek(p);
        var name_ptr: u64 = tok_ptr(tok);
        var name_len: u64 = tok_len(tok);
        if (is_struct_type(name_ptr, name_len) != 0) {
            parse_adv(p);
            base = TYPE_STRUCT;
            struct_name_ptr = name_ptr;
            struct_name_len = name_len;
        }
    }

    var result: u64 = heap_alloc(32);
    *(result) = base;
    *(result + 8) = depth;
    *(result + 16) = struct_name_ptr;
    *(result + 24) = struct_name_len;
    return result;
}

// ============================================
// Expression Parsing
// ============================================

func parse_num_val(tok: u64) -> u64 {
    var ptr: u64 = tok_ptr(tok);
    var len: u64 = tok_len(tok);
    var val: u64 = 0;

    // i64 max = 9223372036854775807
    var max_div10: u64 = 922337203685477580;
    var max_mod10: u64 = 7;

    for (var i: u64 = 0; i<len;i++){
         var c: u64 = *(*u8)(ptr + i);
        var digit: u64 = c - 48;

        if (val > max_div10) {
            emit_stderr("[ERROR] Integer literal overflow at ", 38);
            emit_u64(tok_line(tok));
            emit_stderr(":", 1);
            emit_u64(tok_col(tok));
            emit_stderr(" literal=", 9);
            emit_stderr(ptr, len);
            emit_nl();
            panic();
        }
        if (val == max_div10) {
            if (digit > max_mod10) {
                emit_stderr("[ERROR] Integer literal overflow at ", 38);
                emit_u64(tok_line(tok));
                emit_stderr(":", 1);
                emit_u64(tok_col(tok));
                emit_stderr(" literal=", 9);
                emit_stderr(ptr, len);
                emit_nl();
                panic();
            }
        }

        val = val * 10 + digit;
    }
    return val;
}

func is_ptr_keyword(ptr: u64, len: u64) -> u64 {
    if (len == 5 && *(*u8)ptr == 112 && *(*u8)(ptr+1) == 116 && *(*u8)(ptr+2) == 114 && *(*u8)(ptr+3) == 54 &&*(*u8)(ptr+4) == 52) {
        return 64;
    }
    if (len == 4&&*(*u8)ptr == 112&&*(*u8)(ptr+1) == 116&&*(*u8)(ptr+2) == 114&&*(*u8)(ptr+3) == 56) {
        return 8;
    }
    return 0;
}

func parse_ptr_access(p: u64) -> u64 {
    var tok: u64 = parse_peek(p);
    var ptr_kind: u64 = is_ptr_keyword(tok_ptr(tok), tok_len(tok));
    
    if (ptr_kind > 0) {
        parse_adv(p);
        if (parse_peek_kind(p) == TOKEN_LBRACKET) {
            parse_adv(p);
            var idx: u64 = parse_expr(p);
            parse_consume(p, TOKEN_RBRACKET);
            if (ptr_kind == 64) {
                return ast_deref(idx);
            } else {
                return ast_deref8(idx);
            }
        } else {
            return ast_ident(tok_ptr(tok), tok_len(tok));
        }
    }
    return 0;
}

func parse_primary(p: u64) -> u64 {
    var k: u64 = parse_peek_kind(p);
    
    if (k == TOKEN_NUMBER) {
        var tok: u64 = parse_peek(p);
        parse_adv(p);
        return ast_literal(parse_num_val(tok));
    }

    if (k == TOKEN_TRUE) {
        parse_adv(p);
        return ast_literal(1);
    }

    if (k == TOKEN_FALSE) {
        parse_adv(p);
        return ast_literal(0);
    }
    
    if (k == TOKEN_STRING) {
        var tok: u64 = parse_peek(p);
        parse_adv(p);
        return ast_string(tok_ptr(tok), tok_len(tok));
    }
    
    if (k == TOKEN_AMPERSAND) {
        parse_adv(p);
        var tok: u64 = parse_peek(p);
        if (parse_peek_kind(p) != TOKEN_IDENTIFIER) {
            emit_stderr("[ERROR] Expected identifier after &\n", 37);
            return 0;
        }
        parse_adv(p);
        var ident: u64 = ast_ident(tok_ptr(tok), tok_len(tok));
        return ast_addr_of(ident);
    }
    
    if (k == TOKEN_STAR) {
        parse_adv(p);
        var operand: u64 = parse_unary(p);
        return ast_deref(operand);
    }
    
    if (k == TOKEN_LPAREN) {
        parse_adv(p);
        
        var next_k: u64 = parse_peek_kind(p);
        if (next_k == TOKEN_STAR) {
            var ty: u64 = parse_type(p);
            parse_consume(p, TOKEN_RPAREN);
            var operand: u64 = parse_unary(p);
            return ast_cast(operand, *(ty), *(ty + 8));
        }
        if (next_k == TOKEN_U8) {
            var ty: u64 = parse_type(p);
            parse_consume(p, TOKEN_RPAREN);
            var operand: u64 = parse_unary(p);
            return ast_cast(operand, *(ty), *(ty + 8));
        }
        if (next_k == TOKEN_U16) {
            var ty: u64 = parse_type(p);
            parse_consume(p, TOKEN_RPAREN);
            var operand: u64 = parse_unary(p);
            return ast_cast(operand, *(ty), *(ty + 8));
        }
        if (next_k == TOKEN_U32) {
            var ty: u64 = parse_type(p);
            parse_consume(p, TOKEN_RPAREN);
            var operand: u64 = parse_unary(p);
            return ast_cast(operand, *(ty), *(ty + 8));
        }
        if (next_k == TOKEN_U64) {
            var ty: u64 = parse_type(p);
            parse_consume(p, TOKEN_RPAREN);
            var operand: u64 = parse_unary(p);
            return ast_cast(operand, *(ty), *(ty + 8));
        }
        if (next_k == TOKEN_I64) {
            var ty: u64 = parse_type(p);
            parse_consume(p, TOKEN_RPAREN);
            var operand: u64 = parse_unary(p);
            return ast_cast(operand, *(ty), *(ty + 8));
        }
        
        var expr: u64 = parse_expr(p);
        parse_consume(p, TOKEN_RPAREN);
        return expr;
    }
    
    if (k == TOKEN_IDENTIFIER) {
        var tok: u64= parse_peek(p);
        var ptr_kind: u64 = is_ptr_keyword(tok_ptr(tok), tok_len(tok));
        if (ptr_kind > 0) {
            var result: u64 = parse_ptr_access(p);
            if (result != 0) {
                return result;
            }
        }
    }
    
    if (k == TOKEN_IDENTIFIER) {
        var tok: u64 = parse_peek(p);
        parse_adv(p);
        
        // Check for struct literal: StructName { expr, expr, ... }
        if (parse_peek_kind(p) == TOKEN_LBRACE) {
            var name_ptr: u64 = tok_ptr(tok);
            var name_len: u64 = tok_len(tok);
            
            // Look up struct type
            if (is_struct_type(name_ptr, name_len) != 0) {
                var struct_def: u64 = get_struct_def(name_ptr, name_len);
                parse_adv(p);  // consume '{'
                
                var values: u64 = vec_new(8);
                if (parse_peek_kind(p) != TOKEN_RBRACE) {
                    vec_push(values, parse_expr(p));
                    while (parse_match(p, TOKEN_COMMA)) {
                        vec_push(values, parse_expr(p));
                    }
                }
                parse_consume(p, TOKEN_RBRACE);
                
                return ast_struct_literal(struct_def, values);
            }
        }
        
        if (parse_peek_kind(p) == TOKEN_LPAREN) {
            parse_adv(p);
            var args: u64 = vec_new(8);
            if (parse_peek_kind(p) != TOKEN_RPAREN) {
                vec_push(args, parse_expr(p));
                while (parse_match(p, TOKEN_COMMA)) {
                    vec_push(args, parse_expr(p));
                }
            }
            parse_consume(p, TOKEN_RPAREN);
            return ast_call(tok_ptr(tok), tok_len(tok), args);
        }
        
        return ast_ident(tok_ptr(tok), tok_len(tok));
    }
    
    return 0;
}

func parse_postfix(p: u64) -> u64 {
    var left: u64 = parse_primary(p);
    
    while (1) {
        var k: u64 = parse_peek_kind(p);
        
        if (k == TOKEN_LBRACKET) {
            parse_adv(p);
            var idx: u64 = parse_expr(p);
            parse_consume(p, TOKEN_RBRACKET);
            left = ast_deref(ast_binary(TOKEN_PLUS, left, idx));
        } else if (k == TOKEN_DOT) {
            parse_adv(p);
            var field_tok: u64 = parse_peek(p);
            parse_consume(p, TOKEN_IDENTIFIER);
            left = ast_member_access(left, tok_ptr(field_tok), tok_len(field_tok));
        } else if (k == TOKEN_ARROW) {
            parse_adv(p);
            var field_tok: u64 = parse_peek(p);
            parse_consume(p, TOKEN_IDENTIFIER);
            // ptr->field = (*ptr).field
            var deref: u64 = ast_deref(left);
            left = ast_member_access(deref, tok_ptr(field_tok), tok_len(field_tok));
        } else {
            break;
        }
    }
    
    return left;
}

func parse_unary(p: u64) -> u64 {
    var k: u64 = parse_peek_kind(p);
    
    if (k == TOKEN_STAR) {
        parse_adv(p);
        var operand: u64= parse_unary(p);
        return ast_deref(operand);
    }
    
    if (k == TOKEN_MINUS) {
        parse_adv(p);
        var next_k: u64 = parse_peek_kind(p);
        if (next_k == TOKEN_NUMBER) {
            var tok: u64 = parse_peek(p);
            parse_adv(p);
            var val: u64 = parse_num_val(tok);
            return ast_literal(0 - val);
        }
        var operand: u64 = parse_unary(p);
        return ast_unary(TOKEN_MINUS, operand);
    }
    
    if (k == TOKEN_BANG) {
        parse_adv(p);
        var operand: u64 = parse_unary(p);
        return ast_unary(TOKEN_BANG, operand);
    }
    
    return parse_postfix(p);
}

func parse_mul(p: u64) -> u64 {
    var left: u64 = parse_unary(p);
    
    while (1) {
        var k: u64 = parse_peek_kind(p);
        if (k == TOKEN_STAR) {
            parse_adv(p);
            var right: u64 = parse_unary(p);
            left = ast_binary(TOKEN_STAR, left, right);
        } else if (k == TOKEN_SLASH) {
            parse_adv(p);
            var right: u64 = parse_unary(p);
            left = ast_binary(TOKEN_SLASH, left, right);
        } else if (k == TOKEN_PERCENT) {
            parse_adv(p);
            var right: u64 = parse_unary(p);
            left = ast_binary(TOKEN_PERCENT, left, right);
        } else {
            break;
        }
    }
    
    return left;
}

func parse_add(p: u64) -> u64 {
    var left: u64 = parse_mul(p);
    
    while (1) {
        var k: u64= parse_peek_kind(p);
        if (k == TOKEN_PLUS) {
            parse_adv(p);
            var right: u64 = parse_mul(p);
            left = ast_binary(TOKEN_PLUS, left, right);
        } else if (k == TOKEN_MINUS) {
            parse_adv(p);
            var right: u64 = parse_mul(p);
            left = ast_binary(TOKEN_MINUS, left, right);
        } else {
            break;
        }
    }
    
    return left;
}

func parse_shift(p: u64) -> u64 {
    var left: u64 = parse_add(p);
    
    while (1) {
        var k: u64 = parse_peek_kind(p);
        if (k == TOKEN_LSHIFT) {
            parse_adv(p);
            var right: u64 = parse_add(p);
            left = ast_binary(TOKEN_LSHIFT, left, right);
        } else if (k == TOKEN_RSHIFT) {
            parse_adv(p);
            var right: u64 = parse_add(p);
            left = ast_binary(TOKEN_RSHIFT, left, right);
        } else {
            break;
        }
    }
    
    return left;
}

func parse_rel(p: u64) -> u64 {
    var left: u64 = parse_shift(p);
    
    while (1) {
        var k: u64 = parse_peek_kind(p);
        if (k == TOKEN_LT) {
            parse_adv(p);
            var right: u64 = parse_shift(p);
            left = ast_binary(TOKEN_LT, left, right);
        } else if (k == TOKEN_GT) {
            parse_adv(p);
            var right: u64 = parse_shift(p);
            left = ast_binary(TOKEN_GT, left, right);
        } else if (k == TOKEN_LTEQ) {
            parse_adv(p);
            var right: u64 = parse_shift(p);
            left = ast_binary(TOKEN_LTEQ, left, right);
        } else if (k == TOKEN_GTEQ) {
            parse_adv(p);
            var right: u64 = parse_shift(p);
            left = ast_binary(TOKEN_GTEQ, left, right);
        } else {
            break;
        }
    }
    
    return left;
}

func parse_eq(p: u64) -> u64 {
    var left: u64 = parse_rel(p);
    
    while (1) {
        var k: u64 = parse_peek_kind(p);
        if (k == TOKEN_EQEQ) {
            parse_adv(p);
            var right: u64 = parse_rel(p);
            left = ast_binary(TOKEN_EQEQ, left, right);
        } else if (k == TOKEN_BANGEQ) {
            parse_adv(p);
            var right: u64 = parse_rel(p);
            left = ast_binary(TOKEN_BANGEQ, left, right);
        } else {
            break;
        }
    }
    
    return left;
}

func parse_bitand(p: u64) -> u64 {
    var left: u64 = parse_eq(p);
    
    while (1) {
        var k: u64 = parse_peek_kind(p);
        if (k == TOKEN_AMPERSAND) {
            parse_adv(p);
            var right: u64  = parse_eq(p);
            left = ast_binary(TOKEN_AMPERSAND, left, right);
        } else {
            break;
        }
    }
    
    return left;
}

func parse_bitxor(p: u64) -> u64 {
    var left: u64 = parse_bitand(p);
    
    while (1) {
        var k: u64 = parse_peek_kind(p);
        if (k == TOKEN_CARET) {
            parse_adv(p);
            var right: u64 = parse_bitand(p);
            left = ast_binary(TOKEN_CARET, left, right);
        } else {
            break;
        }
    }
    
    return left;
}

func parse_bitor(p: u64) -> u64 {
    var left: u64 = parse_bitxor(p);
    
    while (1) {
        var k: u64 = parse_peek_kind(p);
        if (k == TOKEN_PIPE) {
            parse_adv(p);
            var right: u64 = parse_bitxor(p);
            left = ast_binary(TOKEN_PIPE, left, right);
        } else {
            break;
        }
    }
    
    return left;
}

func parse_logand(p: u64) -> u64 {
    var left: u64 = parse_bitor(p);

    while (1) {
        var k: u64 = parse_peek_kind(p);
        if (k == TOKEN_ANDAND) {
            parse_adv(p);
            var right: u64 = parse_bitor(p);
            left = ast_binary(TOKEN_ANDAND, left, right);
        } else {
            break;
        }
    }

    return left;
}

func parse_logor(p: u64) -> u64 {
    var left: u64 = parse_logand(p);

    while (1) {
        var k: u64 = parse_peek_kind(p);
        if (k == TOKEN_OROR) {
            parse_adv(p);
            var right: u64 = parse_logand(p);
            left = ast_binary(TOKEN_OROR, left, right);
        } else {
            break;
        }
    }

    return left;
}

func parse_expr(p: u64) -> u64 {
    return parse_logor(p);
}

// ============================================
// Statement Parsing
// ============================================

func parse_var_decl(p: u64) -> u64 {
    parse_consume(p, TOKEN_VAR);
    
    var name_tok: u64 = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    var type_kind: u64 = TYPE_I64;
    var ptr_depth: u64 = 0;
    var struct_name_ptr: u64 = 0;
    var struct_name_len: u64 = 0;
    
    if (parse_match(p, TOKEN_COLON)) {
        var before_type_idx: u64 = *(p + 8);  // Save position
        
        var ty: u64 = parse_type(p);
        type_kind = *(ty);
        ptr_depth = *(ty + 8);
        
        // If TYPE_STRUCT, get the struct name from previous token
        // This applies to both direct structs and pointers to structs
        if (type_kind == TYPE_STRUCT) {
            var tok_vec: u64 = *(p);
            var prev_idx: u64 = *(p + 8) - 1;
            if (prev_idx >= 0) {
                if (prev_idx < vec_len(tok_vec)) {
                    var prev_tok: u64 = vec_get(tok_vec, prev_idx);
                    struct_name_ptr = tok_ptr(prev_tok);
                    struct_name_len = tok_len(prev_tok);
                }
            }
        }
    }
    
    var init: u64 = 0;
    
    if (parse_match(p, TOKEN_EQ)) {
        init = parse_expr(p);
    }
    
    parse_consume(p, TOKEN_SEMICOLON);
    
    var decl: u64 = ast_var_decl(tok_ptr(name_tok), tok_len(name_tok), type_kind, ptr_depth, init);
    *(decl + 48) = struct_name_ptr;
    *(decl + 56) = struct_name_len;
    return decl;
}

func parse_assign_or_expr(p: u64) -> u64 {
    var expr: u64 = parse_expr(p);
    
    if (parse_match(p, TOKEN_EQ)) {
        var val: u64 = parse_expr(p);
        parse_consume(p, TOKEN_SEMICOLON);
        return ast_assign(expr, val);
    }

    // Postfix ++/-- statement sugar: x++; x--;  =>  x = x +/- 1;
    var post_k: u64 = parse_peek_kind(p);
    if (post_k == TOKEN_PLUSPLUS) {
        parse_consume(p, post_k);
        if (!is_assignable_expr(expr)) {
            emit_stderr("[ERROR] ++/-- requires assignable expression\n", 45);
            panic("Parse error");
        }
        var rhs: u64 = make_incdec_rhs(post_k, expr);
        parse_consume(p, TOKEN_SEMICOLON);
        return ast_assign(expr, rhs);
    }
    if (post_k == TOKEN_MINUSMINUS) {
        parse_consume(p, post_k);
        if (!is_assignable_expr(expr)) {
            emit_stderr("[ERROR] ++/-- requires assignable expression\n", 45);
            panic("Parse error");
        }
        var rhs: u64 = make_incdec_rhs(post_k, expr);
        parse_consume(p, TOKEN_SEMICOLON);
        return ast_assign(expr, rhs);
    }
    
    parse_consume(p, TOKEN_SEMICOLON);
    return ast_expr_stmt(expr);
}

func is_assignable_expr(expr: u64) -> u64 {
    var k: u64 = ast_kind(expr);
    if (k == AST_IDENT) { return 1; }
    if (k == AST_DEREF) { return 1; }
    if (k == AST_DEREF8) { return 1; }
    return 0;
}

func make_incdec_rhs(incdec_kind: u64, target: u64) -> u64 {
    var one: u64 = ast_literal(1);
    if (incdec_kind == TOKEN_PLUSPLUS) {
        return ast_binary(TOKEN_PLUS, target, one);
    }
    return ast_binary(TOKEN_MINUS, target, one);
}

func parse_prefix_incdec_assign(p: u64) -> u64 {
    var k: u64 = parse_peek_kind(p);
    parse_consume(p, k);
    var target: u64 = parse_unary(p);
    if (!is_assignable_expr(target)) {
        emit_stderr("[ERROR] ++/-- requires assignable expression\n", 45);
        panic("Parse error");
    }
    var rhs: u64 = make_incdec_rhs(k, target);
    return ast_assign(target, rhs);
}

func parse_postfix_incdec_after_expr(p: u64, expr: u64) -> u64 {
    var k: u64 = parse_peek_kind(p);
    if (k != TOKEN_PLUSPLUS) {
        if (k != TOKEN_MINUSMINUS) {
            return expr;
        }
    }
    parse_consume(p, k);
    if (!is_assignable_expr(expr)) {
        emit_stderr("[ERROR] ++/-- requires assignable expression\n", 45);
        panic("Parse error");
    }
    var rhs: u64 = make_incdec_rhs(k, expr);
    return ast_assign(expr, rhs);
}

func parse_if_stmt(p: u64) -> u64 {
    parse_consume(p, TOKEN_IF);
    parse_consume(p, TOKEN_LPAREN);
    var cond: u64 = parse_expr(p);
    parse_consume(p, TOKEN_RPAREN);
    
    var then_blk: u64 = parse_block(p);
    
    var else_blk: u64 = 0;
    if (parse_match(p, TOKEN_ELSE)) {
        if (parse_peek_kind(p) == TOKEN_IF) {
            var else_stmt: u64 = parse_if_stmt(p);
            var stmts: u64 = vec_new(1);
            vec_push(stmts, else_stmt);
            else_blk = ast_block(stmts);
        } else {
            else_blk = parse_block(p);
        }
    }
    
    return ast_if(cond, then_blk, else_blk);
}

func parse_while_stmt(p: u64) -> u64 {
    parse_consume(p, TOKEN_WHILE);
    parse_consume(p, TOKEN_LPAREN);
    var cond: u64 = parse_expr(p);
    parse_consume(p, TOKEN_RPAREN);
    
    var body: u64 = parse_block(p);
    
    return ast_while(cond, body);
}

func parse_for_stmt(p: u64) -> u64 {
    parse_consume(p, TOKEN_FOR);
    parse_consume(p, TOKEN_LPAREN);
    
    var init: u64 = 0;
    if (parse_peek_kind(p) != TOKEN_SEMICOLON) {
        if (parse_peek_kind(p) == TOKEN_VAR) {
            init = parse_var_decl(p);
        } else {
            if (parse_peek_kind(p) == TOKEN_PLUSPLUS) {
                init = parse_prefix_incdec_assign(p);
            } else {
                if (parse_peek_kind(p) == TOKEN_MINUSMINUS) {
                    init = parse_prefix_incdec_assign(p);
                } else {
                var lhs: u64 = parse_expr(p);
                if (parse_match(p, TOKEN_EQ)) {
                    var rhs: u64 = parse_expr(p);
                    init = ast_assign(lhs, rhs);
                } else {
                    init = parse_postfix_incdec_after_expr(p, lhs);
                }
                }
            }
            parse_consume(p, TOKEN_SEMICOLON);
        }
    } else {
        parse_consume(p, TOKEN_SEMICOLON);
    }
    
    var cond: u64 = 0;
    if (parse_peek_kind(p) != TOKEN_SEMICOLON) {
        cond = parse_expr(p);
    }
    parse_consume(p, TOKEN_SEMICOLON);
    
    var update: u64 = 0;
    if (parse_peek_kind(p) != TOKEN_RPAREN) {
        if (parse_peek_kind(p) == TOKEN_PLUSPLUS) {
            update = parse_prefix_incdec_assign(p);
        } else {
            if (parse_peek_kind(p) == TOKEN_MINUSMINUS) {
                update = parse_prefix_incdec_assign(p);
            } else {
            var upd_lhs: u64 = parse_expr(p);
            if (parse_match(p, TOKEN_EQ)) {
                var upd_rhs: u64 = parse_expr(p);
                update = ast_assign(upd_lhs, upd_rhs);
            } else {
                update = parse_postfix_incdec_after_expr(p, upd_lhs);
            }
            }
        }
    }
    parse_consume(p, TOKEN_RPAREN);
    
    var body: u64  = parse_block(p);
    
    return ast_for(init, cond, update, body);
}

func parse_switch_stmt(p: u64) -> u64 {
    parse_consume(p, TOKEN_SWITCH);
    parse_consume(p, TOKEN_LPAREN);
    var expr: u64 = parse_expr(p);
    parse_consume(p, TOKEN_RPAREN);
    parse_consume(p, TOKEN_LBRACE);
    
    var cases: u64 = vec_new(16);
    
    while (parse_peek_kind(p) != TOKEN_RBRACE) {
        if (parse_peek_kind(p) == TOKEN_EOF) { break; }
        
        var is_default: u64 = 0;
        var value: u64 = 0;
        
        if (parse_peek_kind(p) == TOKEN_CASE) {
            parse_consume(p, TOKEN_CASE);
            value = parse_expr(p);
        } else {
            if (parse_peek_kind(p) == TOKEN_DEFAULT) {
                parse_consume(p, TOKEN_DEFAULT);
                is_default = 1;
            } else {
                break;
            }
        }
        
        parse_consume(p, TOKEN_COLON);
        
        var stmts: u64 = vec_new(8);
        while (parse_peek_kind(p) != TOKEN_CASE) {
            if (parse_peek_kind(p) == TOKEN_DEFAULT) { break; }
            if (parse_peek_kind(p) == TOKEN_RBRACE) { break; }
            if (parse_peek_kind(p) == TOKEN_EOF) { break; }
            vec_push(stmts, parse_stmt(p));
        }
        
        var case_body: u64 = ast_block(stmts);
        vec_push(cases, ast_case(value, case_body, is_default));
    }
    
    parse_consume(p, TOKEN_RBRACE);
    return ast_switch(expr, cases);
}

func parse_break_stmt(p: u64) -> u64 {
    parse_consume(p, TOKEN_BREAK);
    parse_consume(p, TOKEN_SEMICOLON);
    return ast_break();
}

func parse_continue_stmt(p: u64) -> u64 {
    parse_consume(p, TOKEN_CONTINUE);
    parse_consume(p, TOKEN_SEMICOLON);
    return ast_continue();
}

func parse_asm_stmt(p: u64) -> u64 {
    parse_consume(p, TOKEN_ASM);
    parse_consume(p, TOKEN_LBRACE);
    
    var asm_text: u64 = vec_new(256);
    
    var prev_line: u64 = 0 - 1;
    
    while (parse_peek_kind(p) != TOKEN_RBRACE) {
        if (parse_peek_kind(p) == TOKEN_EOF) {
            emit_stderr("[ERROR] Unexpected EOF in asm block\n", 38);
            panic();
        }
        
        var tok: u64 = parse_peek(p);
        var cur_line: u64  = tok_line(tok);
        
        if (prev_line >= 0) {
            if (cur_line > prev_line) {
                vec_push(asm_text, 10);
            } else {
                vec_push(asm_text, 32);
            }
        }
        prev_line = cur_line;
        
        var ptr: u64 = tok_ptr(tok);
        var len: u64 = tok_len(tok);

        for (var i: u64 = 0; i<len ;i++){
            vec_push(asm_text, *(*u8)(ptr + i));
        }
        parse_adv(p);
    }
    
    parse_consume(p, TOKEN_RBRACE);
    
    return ast_asm(asm_text);
}

func parse_return_stmt(p: u64) -> u64 {
    parse_consume(p, TOKEN_RETURN);
    
    var expr: u64 = 0;
    if (parse_peek_kind(p) != TOKEN_SEMICOLON) {
        expr = parse_expr(p);
    }
    
    parse_consume(p, TOKEN_SEMICOLON);
    return ast_return(expr);
}

func parse_const_decl(p: u64) -> u64 {
    parse_consume(p, TOKEN_CONST);
    
    var name_tok: u64 = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    parse_consume(p, TOKEN_EQ);
    
    var val_tok: u64 = parse_peek(p);
    parse_consume(p, TOKEN_NUMBER);
    
    var value: u64 = parse_num_val(val_tok);
    
    parse_consume(p, TOKEN_SEMICOLON);
    
    return ast_const_decl(tok_ptr(name_tok), tok_len(name_tok), value);
}

func parse_import_decl(p: u64) -> u64 {
    parse_consume(p, TOKEN_IMPORT);
    
    var first_tok: u64 = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    var path_ptr: u64  = tok_ptr(first_tok);
    var path_len: u64 = tok_len(first_tok);
    
    while (parse_match(p, TOKEN_DOT)) {
        var next_tok: u64 = parse_peek(p);
        parse_consume(p, TOKEN_IDENTIFIER);
        
        var slash: u64 = heap_alloc(1);
        *(*u8)slash = 47;
        
        var tmp: u64 = str_concat(path_ptr, path_len, slash, 1);
        path_ptr = str_concat(tmp, path_len + 1, tok_ptr(next_tok), tok_len(next_tok));
        path_len = path_len + 1 + tok_len(next_tok);
    }
    
    parse_consume(p, TOKEN_SEMICOLON);
    
    return ast_import(path_ptr, path_len);
}

func parse_stmt(p: u64) -> u64 {
    var k: u64 = parse_peek_kind(p);

    if (k == TOKEN_PLUSPLUS) {
        var stmt: u64 = parse_prefix_incdec_assign(p);
        parse_consume(p, TOKEN_SEMICOLON);
        return stmt;
    }
    if (k == TOKEN_MINUSMINUS) {
        var stmt: u64 = parse_prefix_incdec_assign(p);
        parse_consume(p, TOKEN_SEMICOLON);
        return stmt;
    }
    
    if (k == TOKEN_VAR) { return parse_var_decl(p); }
    if (k == TOKEN_IF) { return parse_if_stmt(p); }
    if (k == TOKEN_WHILE) { return parse_while_stmt(p); }
    if (k == TOKEN_FOR) { return parse_for_stmt(p); }
    if (k == TOKEN_SWITCH) { return parse_switch_stmt(p); }
    if (k == TOKEN_BREAK) { return parse_break_stmt(p); }
    if (k == TOKEN_CONTINUE) { return parse_continue_stmt(p); }
    if (k == TOKEN_ASM) { return parse_asm_stmt(p); }
    if (k == TOKEN_RETURN) { return parse_return_stmt(p); }
    
    return parse_assign_or_expr(p);
}

func parse_block(p: u64) -> u64 {
    parse_consume(p, TOKEN_LBRACE);
    
    var stmts: u64 = vec_new(16);
    
    while (parse_peek_kind(p) != TOKEN_RBRACE) {
        if (parse_peek_kind(p) == TOKEN_EOF) { break; }
        vec_push(stmts, parse_stmt(p));
    }
    
    parse_consume(p, TOKEN_RBRACE);
    return ast_block(stmts);
}

// ============================================
// Function Parsing
// ============================================

func parse_param(p: u64) -> u64 {
    var name_tok: u64 = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    var type_kind: u64 = 0;
    var ptr_depth: u64 = 0;
    var struct_name_ptr: u64 = 0;
    var struct_name_len: u64 = 0;
    
    if (parse_match(p, TOKEN_COLON)) {
        var ty: u64 = parse_type_ex(p);
        type_kind = *(ty);
        ptr_depth = *(ty + 8);
        struct_name_ptr = *(ty + 16);
        struct_name_len = *(ty + 24);
    }
    
    // Layout: [name_ptr:8][name_len:8][type_kind:8][ptr_depth:8][struct_name_ptr:8][struct_name_len:8]
    var param: u64 = heap_alloc(48);
    *(param) = tok_ptr(name_tok);
    *(param + 8) = tok_len(name_tok);
    *(param + 16) = type_kind;
    *(param + 24) = ptr_depth;
    *(param + 32) = struct_name_ptr;
    *(param + 40) = struct_name_len;
    return param;
}

func parse_func_decl(p: u64) -> u64 {
    parse_consume(p, TOKEN_FUNC);
    
    var name_tok: u64 = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    parse_consume(p, TOKEN_LPAREN);
    
    var params: u64 = vec_new(8);
    
    if (parse_peek_kind(p) != TOKEN_RPAREN) {
        vec_push(params, parse_param(p));
        while (parse_match(p, TOKEN_COMMA)) {
            vec_push(params, parse_param(p));
        }
    }
    
    parse_consume(p, TOKEN_RPAREN);
    
    var ret_type: u64 = TYPE_VOID;
    var ret_ptr_depth: u64 = 0;
    var ret_struct_name_ptr: u64 = 0;
    var ret_struct_name_len: u64 = 0;
    
    if (parse_match(p, TOKEN_ARROW)) {
        var ty: u64 = parse_type_ex(p);
        ret_type = *(ty);
        ret_ptr_depth = *(ty + 8);
        ret_struct_name_ptr = *(ty + 16);
        ret_struct_name_len = *(ty + 24);
    }
    
    var body: u64 = parse_block(p);
    
    return ast_func_ex(tok_ptr(name_tok), tok_len(name_tok), params, ret_type, ret_ptr_depth, ret_struct_name_ptr, ret_struct_name_len, body);
}

// ============================================
// Program Parsing
// ============================================

func parse_program(p: u64) -> u64 {
    var funcs: u64 = vec_new(16);
    var consts: u64 = vec_new(64);
    var imports: u64 = vec_new(16);
    var globals: u64 = vec_new(32);
    var structs: u64 = vec_new(16);
    
    while (parse_peek_kind(p) != TOKEN_EOF) {
        var k: u64 = parse_peek_kind(p);
        if (k == TOKEN_FUNC) {
            vec_push(funcs, parse_func_decl(p));
        } else if (k == TOKEN_CONST) {
            vec_push(consts, parse_const_decl(p));
        } else if (k == TOKEN_ENUM) {
            // Enum을 여러 const로 변환
            var enum_consts: u64 = parse_enum_def(p);
            var num_enum_consts: u64 = vec_len(enum_consts);
            for (var i: u64 = 0; i < num_enum_consts; i++) {
                vec_push(consts, vec_get(enum_consts, i));
            }
        } else if (k == TOKEN_STRUCT) {
            var struct_def: u64 = parse_struct_def(p);
            vec_push(structs, struct_def);
            register_struct_type(struct_def);  // Register immediately for type checking
        } else if (k == TOKEN_IMPL) {
            // impl 블록: 내부 함수들을 StructName_methodName으로 변환
            var impl_funcs: u64 = parse_impl_block(p);
            var num_impl_funcs: u64 = vec_len(impl_funcs);
            for (var i: u64 = 0; i < num_impl_funcs; i++) {
                vec_push(funcs, vec_get(impl_funcs, i));
            }
        } else if (k == TOKEN_VAR) {
            parse_consume(p, TOKEN_VAR);
            var tok: u64 = parse_peek(p);
            var name_ptr: u64 = tok_ptr(tok);
            var name_len: u64 = tok_len(tok);
            parse_consume(p, TOKEN_IDENTIFIER);
            parse_consume(p, TOKEN_SEMICOLON);
            var ginfo: u64 = heap_alloc(16);
            *(ginfo) = name_ptr;
            *(ginfo + 8) = name_len;
            vec_push(globals, ginfo);
        } else if (k == TOKEN_IMPORT) {
            vec_push(imports, parse_import_decl(p));
        } else {
            emit_stderr("[ERROR] Expected function, const, or import\n", 45);
            break;
        }
    }
    
    var prog: u64  = ast_program(funcs, consts, imports);
    *(prog + 32) = globals;
    *(prog + 40) = structs;  // structs 추가
    return prog;
}

// ============================================
// Struct Parsing
// ============================================

func parse_struct_def(p: u64) -> u64 {
    parse_consume(p, TOKEN_STRUCT);
    
    var name_tok: u64 = parse_peek(p);
    var name_ptr: u64 = tok_ptr(name_tok);
    var name_len: u64 = tok_len(name_tok);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    parse_consume(p, TOKEN_LBRACE);
    
    var fields: u64 = vec_new(8);
    
    // Parse fields: field_name : type ;
    while (parse_peek_kind(p) != TOKEN_RBRACE) {
        var field_name_tok: u64 = parse_peek(p);
        var field_name_ptr: u64 = tok_ptr(field_name_tok);
        var field_name_len: u64 = tok_len(field_name_tok);
        parse_consume(p, TOKEN_IDENTIFIER);
        
        parse_consume(p, TOKEN_COLON);
        
        var field_type: u64 = parse_type(p);
        var field_type_kind: u64 = *(field_type);
        var field_ptr_depth: u64 = *(field_type + 8);
        
        // If the field is a struct type, capture the struct name
        var field_struct_name_ptr: u64 = 0;
        var field_struct_name_len: u64 = 0;
        if (field_type_kind == TYPE_STRUCT) {
            var tok_vec: u64 = *(p);
            var prev_idx: u64 = *(p + 8) - 1;
            if (prev_idx >= 0 && prev_idx < vec_len(tok_vec)) {
                var prev_tok: u64 = vec_get(tok_vec, prev_idx);
                field_struct_name_ptr = tok_ptr(prev_tok);
                field_struct_name_len = tok_len(prev_tok);
            }
        }
        
        parse_consume(p, TOKEN_SEMICOLON);
        
        // field_desc = [name_ptr:8][name_len:8][type:8][struct_name_ptr:8][struct_name_len:8][ptr_depth:8]
        var field_desc: u64 = heap_alloc(48);
        *(field_desc) = field_name_ptr;
        *(field_desc + 8) = field_name_len;
        *(field_desc + 16) = field_type_kind;
        *(field_desc + 24) = field_struct_name_ptr;
        *(field_desc + 32) = field_struct_name_len;
        *(field_desc + 40) = field_ptr_depth;
        
        vec_push(fields, field_desc);
    }
    
    parse_consume(p, TOKEN_RBRACE);
    
    var struct_def: u64 = ast_struct_def(name_ptr, name_len, fields);
    return struct_def;
}

// ============================================
// Enum Parsing
// ============================================

func parse_enum_def(p: u64) -> u64 {
    parse_consume(p, TOKEN_ENUM);
    
    var enum_name_tok: u64 = parse_peek(p);
    var enum_name_ptr: u64 = tok_ptr(enum_name_tok);
    var enum_name_len: u64 = tok_len(enum_name_tok);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    parse_consume(p, TOKEN_LBRACE);
    
    var consts: u64 = vec_new(16);
    var current_value: u64 = 0;
    
    while (parse_peek_kind(p) != TOKEN_RBRACE) {
        if (parse_peek_kind(p) == TOKEN_EOF) { break; }
        
        var member_tok: u64 = parse_peek(p);
        var member_ptr: u64 = tok_ptr(member_tok);
        var member_len: u64 = tok_len(member_tok);
        parse_consume(p, TOKEN_IDENTIFIER);
        
        // Check for explicit value
        if (parse_match(p, TOKEN_EQ)) {
            var val_tok: u64 = parse_peek(p);
            parse_consume(p, TOKEN_NUMBER);
            current_value = parse_num_val(val_tok);
        }
        
        // Create EnumName_MemberName
        var full_name: u64 = vec_new(64);
        for (var i: u64 = 0; i < enum_name_len; i++) {
            vec_push(full_name, *(*u8)(enum_name_ptr + i));
        }
        vec_push(full_name, 95);  // '_'
        for (var i: u64 = 0; i < member_len; i++) {
            vec_push(full_name, *(*u8)(member_ptr + i));
        }
        
        // Copy to permanent heap storage
        var full_name_len: u64 = vec_len(full_name);
        var full_name_ptr: u64 = heap_alloc(full_name_len);
        var full_name_buf: u64 = *(full_name);  // vec buf_ptr (array of i64)
        for (var i: u64 = 0; i < full_name_len; i++) {
            var ch: u64 = vec_get(full_name, i);  // Get i64 value
            *(*u8)(full_name_ptr + i) = ch;  // Store as u8
        }
        
        var const_node: u64 = ast_const_decl(full_name_ptr, full_name_len, current_value);
        vec_push(consts, const_node);
        
        current_value = current_value + 1;
        
        // Optional comma
        if (parse_peek_kind(p) == TOKEN_COMMA) {
            parse_consume(p, TOKEN_COMMA);
        }
    }
    
    parse_consume(p, TOKEN_RBRACE);
    
    return consts;
}

// ============================================
// Impl Block Parsing
// ============================================

func parse_impl_block(p: u64) -> u64 {
    parse_consume(p, TOKEN_IMPL);
    
    // Get struct name
    var struct_name_tok: u64 = parse_peek(p);
    var struct_name_ptr: u64 = tok_ptr(struct_name_tok);
    var struct_name_len: u64 = tok_len(struct_name_tok);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    parse_consume(p, TOKEN_LBRACE);
    
    var funcs: u64 = vec_new(8);
    
    // Parse all functions in impl block
    while (parse_peek_kind(p) != TOKEN_RBRACE) {
        if (parse_peek_kind(p) == TOKEN_EOF) { break; }
        
        if (parse_peek_kind(p) == TOKEN_FUNC) {
            var func_node: u64 = parse_func_decl(p);
            
            // Rename function: methodName -> StructName_methodName
            var original_name_ptr: u64 = *(func_node + 8);
            var original_name_len: u64 = *(func_node + 16);
            
            // Create new name: StructName_methodName
            var new_name: u64 = vec_new(64);
            for (var i: u64 = 0; i < struct_name_len; i++) {
                vec_push(new_name, *(*u8)(struct_name_ptr + i));
            }
            vec_push(new_name, 95);  // '_'
            for (var i: u64 = 0; i < original_name_len; i++) {
                vec_push(new_name, *(*u8)(original_name_ptr + i));
            }
            
            // Copy to permanent heap storage
            var new_name_len: u64 = vec_len(new_name);
            var new_name_ptr: u64 = heap_alloc(new_name_len);
            for (var i: u64 = 0; i < new_name_len; i++) {
                var ch: u64 = vec_get(new_name, i);
                *(*u8)(new_name_ptr + i) = ch;
            }
            
            // Update function name
            *(func_node + 8) = new_name_ptr;
            *(func_node + 16) = new_name_len;
            
            vec_push(funcs, func_node);
        } else {
            emit_stderr("[ERROR] impl block can only contain functions\n", 48);
            break;
        }
    }
    
    parse_consume(p, TOKEN_RBRACE);
    
    return funcs;
}
    }
    
    parse_consume(p, TOKEN_RBRACE);
    
    return ast_struct_def(name_ptr, name_len, fields);
}
