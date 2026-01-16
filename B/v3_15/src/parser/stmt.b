// parse_stmt.b - Statement parsing
//
// Parses all statement types:
// - Variable declarations
// - Assignments and expression statements
// - Control flow (if, while, for, switch)
// - break, continue, return
// - Inline assembly blocks

import std.io;
import std.vec;
import std.util;
import types;
import lexer;
import ast;
import parser.util;
import parser.type;
import parser.expr;

// ============================================
// Variable Declaration
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
        var ty_info: *TypeInfo = (*TypeInfo)parse_type_ex(p);
        type_kind = ty_info->type_kind;
        ptr_depth = ty_info->ptr_depth;
        
        // If TYPE_STRUCT, get struct name from TypeInfo
        if (type_kind == TYPE_STRUCT) {
            struct_name_ptr = ty_info->struct_name_ptr;
            struct_name_len = ty_info->struct_name_len;
        }
    }
    
    var init: u64 = 0;
    
    if (parse_match(p, TOKEN_EQ)) {
        init = parse_expr(p);
    }
    
    parse_consume(p, TOKEN_SEMICOLON);
    
    var decl: *AstVarDecl = (*AstVarDecl)ast_var_decl(((*Token)name_tok)->ptr, ((*Token)name_tok)->len, type_kind, ptr_depth, init);
    decl->struct_name_ptr = struct_name_ptr;
    decl->struct_name_len = struct_name_len;
    return (u64)decl;
}

// ============================================
// Assignment Helpers
// ============================================

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

// ============================================
// Control Flow Statements
// ============================================

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
    var k: u64 = parse_peek_kind(p);
    
    // Parse init clause
    if (k == TOKEN_SEMICOLON) {
        parse_consume(p, TOKEN_SEMICOLON);
    } else if (k == TOKEN_VAR) {
        init = parse_var_decl(p);
    } else if (k == TOKEN_PLUSPLUS || k == TOKEN_MINUSMINUS) {
        init = parse_prefix_incdec_assign(p);
        parse_consume(p, TOKEN_SEMICOLON);
    } else {
        var lhs: u64 = parse_expr(p);
        if (parse_match(p, TOKEN_EQ)) {
            var rhs: u64 = parse_expr(p);
            init = ast_assign(lhs, rhs);
        } else {
            init = parse_postfix_incdec_after_expr(p, lhs);
        }
        parse_consume(p, TOKEN_SEMICOLON);
    }
    
    var cond: u64 = 0;
    if (parse_peek_kind(p) != TOKEN_SEMICOLON) {
        cond = parse_expr(p);
    }
    parse_consume(p, TOKEN_SEMICOLON);
    
    var update: u64 = 0;
    k = parse_peek_kind(p);
    
    // Parse update clause
    if (k == TOKEN_RPAREN) {
        // No update clause
    } else if (k == TOKEN_PLUSPLUS || k == TOKEN_MINUSMINUS) {
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
    
    parse_consume(p, TOKEN_RPAREN);
    
    var body: u64 = parse_block(p);
    
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

// ============================================
// Jump Statements
// ============================================

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

func parse_return_stmt(p: u64) -> u64 {
    parse_consume(p, TOKEN_RETURN);
    
    var expr: u64 = 0;
    if (parse_peek_kind(p) != TOKEN_SEMICOLON) {
        expr = parse_expr(p);
    }
    
    parse_consume(p, TOKEN_SEMICOLON);
    return ast_return(expr);
}

// ============================================
// ASM Block
// ============================================

func parse_asm_stmt(p: u64) -> u64 {
    parse_consume(p, TOKEN_ASM);
    parse_consume(p, TOKEN_LBRACE);
    
    var asm_text: u64 = vec_new(256);
    
    var prev_line: u64 = -1;
    
    while (parse_peek_kind(p) != TOKEN_RBRACE) {
        if (parse_peek_kind(p) == TOKEN_EOF) {
            emit_stderr("[ERROR] Unexpected EOF in asm block\n", 38);
            panic();
        }
        
        var tok: u64 = parse_peek(p);
        var cur_line: u64 = ((*Token)tok)->line;
        
        if (prev_line >= 0) {
            if (cur_line > prev_line) {
                vec_push(asm_text, 10);
            } else {
                vec_push(asm_text, 32);
            }
        }
        prev_line = cur_line;
        
        var ptr: u64 = ((*Token)tok)->ptr;
        var len: u64 = ((*Token)tok)->len;

        for (var i: u64 = 0; i < len; i++) {
            vec_push(asm_text, *(*u8)(ptr + i));
        }
        parse_adv(p);
    }
    
    parse_consume(p, TOKEN_RBRACE);
    
    return ast_asm(asm_text);
}

// ============================================
// Block and Generic Statement
// ============================================

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
