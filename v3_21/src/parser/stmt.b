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
    var is_tagged: u64 = 0;
    var struct_name_ptr: u64 = 0;
    var struct_name_len: u64 = 0;
    var tag_layout_ptr: u64 = 0;
    var tag_layout_len: u64 = 0;
    var elem_type_kind: u64 = 0;
    var elem_ptr_depth: u64 = 0;
    var array_len: u64 = 0;
    
    if (parse_match(p, TOKEN_COLON)) {
        var ty_info: *TypeInfo = (*TypeInfo)parse_type_ex(p);
        type_kind = ty_info->type_kind;
        ptr_depth = ty_info->ptr_depth;
        is_tagged = ty_info->is_tagged;
        elem_type_kind = ty_info->elem_type_kind;
        elem_ptr_depth = ty_info->elem_ptr_depth;
        array_len = ty_info->array_len;
        tag_layout_ptr = ty_info->tag_layout_ptr;
        tag_layout_len = ty_info->tag_layout_len;
        
        // If TYPE_STRUCT, get struct name from TypeInfo
        if (type_kind == TYPE_STRUCT) {
            struct_name_ptr = ty_info->struct_name_ptr;
            struct_name_len = ty_info->struct_name_len;
        }
        // If array/slice of struct pointer, store element struct name
        if (type_kind == TYPE_ARRAY || type_kind == TYPE_SLICE) {
            struct_name_ptr = ty_info->struct_name_ptr;
            struct_name_len = ty_info->struct_name_len;
        }
        // tagged layout name (non-struct base)
        if (is_tagged == 1 && tag_layout_ptr != 0 && type_kind != TYPE_STRUCT && type_kind != TYPE_ARRAY && type_kind != TYPE_SLICE) {
            struct_name_ptr = 0;
            struct_name_len = 0;
        }
    }
    
    var init: u64 = 0;
    
    if (parse_match(p, TOKEN_EQ)) {
        init = parse_expr(p);
    }
    
    parse_consume(p, TOKEN_SEMICOLON);
    
    var decl: *AstVarDecl = (*AstVarDecl)ast_var_decl(((*Token)name_tok)->ptr, ((*Token)name_tok)->len, type_kind, ptr_depth, init);
    decl->is_tagged = is_tagged;
    decl->struct_name_ptr = struct_name_ptr;
    decl->struct_name_len = struct_name_len;
    decl->tag_layout_ptr = tag_layout_ptr;
    decl->tag_layout_len = tag_layout_len;
    decl->elem_type_kind = elem_type_kind;
    decl->elem_ptr_depth = elem_ptr_depth;
    decl->array_len = array_len;
    return (u64)decl;
}

// ============================================
// Assignment Helpers
// ============================================

func is_assignable_expr(expr: u64) -> u64 {
    var k: u64 = ast_kind(expr);
    switch (k) {
        case AST_IDENT: return 1;
        case AST_DEREF: return 1;
        case AST_DEREF8: return 1;
        default: return 0;
    }
}

func make_incdec_rhs(incdec_kind: u64, target: u64) -> u64 {
    var one: u64 = ast_literal(1);
    switch (incdec_kind) {
        case TOKEN_PLUSPLUS:
            return ast_binary(TOKEN_PLUS, target, one);
        case TOKEN_MINUSMINUS:
            return ast_binary(TOKEN_MINUS, target, one);
        default:
            return ast_binary(TOKEN_MINUS, target, one);
    }
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
    switch (k) {
        case TOKEN_PLUSPLUS:
        case TOKEN_MINUSMINUS:
            break;
        default:
            return expr;
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

    // Compound assignment: x += 5  =>  x = x + 5
    var k: u64 = parse_peek_kind(p);
    var bin_op: u64 = 0;
    switch (k) {
        case TOKEN_PLUS_EQ: bin_op = TOKEN_PLUS; break;
        case TOKEN_MINUS_EQ: bin_op = TOKEN_MINUS; break;
        case TOKEN_STAR_EQ: bin_op = TOKEN_STAR; break;
        case TOKEN_SLASH_EQ: bin_op = TOKEN_SLASH; break;
        case TOKEN_PERCENT_EQ: bin_op = TOKEN_PERCENT; break;
        default: bin_op = 0; break;
    }
    if (bin_op != 0) {
        parse_consume(p, k);
        if (!is_assignable_expr(expr)) {
            emit_stderr("[ERROR] Compound assignment requires assignable expression\n", 60);
            panic("Parse error");
        }
        var rhs: u64 = parse_expr(p);
        
        var new_val: u64 = ast_binary(bin_op, expr, rhs);
        parse_consume(p, TOKEN_SEMICOLON);
        return ast_assign(expr, new_val);
    }

    // Postfix ++/-- statement sugar: x++; x--;  =>  x = x +/- 1;
    var post_k: u64 = parse_peek_kind(p);
    switch (post_k) {
        case TOKEN_PLUSPLUS:
        case TOKEN_MINUSMINUS:
            parse_consume(p, post_k);
            if (!is_assignable_expr(expr)) {
                emit_stderr("[ERROR] ++/-- requires assignable expression\n", 45);
                panic("Parse error");
            }
            var rhs: u64 = make_incdec_rhs(post_k, expr);
            parse_consume(p, TOKEN_SEMICOLON);
            return ast_assign(expr, rhs);
        default:
            break;
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
    switch (k) {
        case TOKEN_SEMICOLON:
            parse_consume(p, TOKEN_SEMICOLON);
            break;
        case TOKEN_VAR:
            init = parse_var_decl(p);
            break;
        case TOKEN_PLUSPLUS:
        case TOKEN_MINUSMINUS:
            init = parse_prefix_incdec_assign(p);
            parse_consume(p, TOKEN_SEMICOLON);
            break;
        default:
            var lhs: u64 = parse_expr(p);
            if (parse_match(p, TOKEN_EQ)) {
                var rhs: u64 = parse_expr(p);
                init = ast_assign(lhs, rhs);
            } else {
                init = parse_postfix_incdec_after_expr(p, lhs);
            }
            parse_consume(p, TOKEN_SEMICOLON);
            break;
    }
    
    var cond: u64 = 0;
    if (parse_peek_kind(p) != TOKEN_SEMICOLON) {
        cond = parse_expr(p);
    }
    parse_consume(p, TOKEN_SEMICOLON);
    
    var update: u64 = 0;
    k = parse_peek_kind(p);
    
    // Parse update clause
    switch (k) {
        case TOKEN_RPAREN:
            // No update clause
            break;
        case TOKEN_PLUSPLUS:
        case TOKEN_MINUSMINUS:
            update = parse_prefix_incdec_assign(p);
            break;
        default:
            var upd_lhs: u64 = parse_expr(p);
            if (parse_match(p, TOKEN_EQ)) {
                var upd_rhs: u64 = parse_expr(p);
                update = ast_assign(upd_lhs, upd_rhs);
            } else {
                update = parse_postfix_incdec_after_expr(p, upd_lhs);
            }
            break;
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
        var matched: u64 = 0;
        
        switch (parse_peek_kind(p)) {
            case TOKEN_CASE:
                parse_consume(p, TOKEN_CASE);
                value = parse_expr(p);
                matched = 1;
                break;
            case TOKEN_DEFAULT:
                parse_consume(p, TOKEN_DEFAULT);
                is_default = 1;
                matched = 1;
                break;
            default:
                break;
        }
        if (matched == 0) { break; }
        
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
    push_trace("parse_block", "parser/stmt.b", __LINE__);
    
    parse_consume(p, TOKEN_LBRACE);
    
    var stmts: u64 = vec_new(16);
    
    while (parse_peek_kind(p) != TOKEN_RBRACE) {
        if (parse_peek_kind(p) == TOKEN_EOF) { break; }
        vec_push(stmts, parse_stmt(p));
    }
    
    parse_consume(p, TOKEN_RBRACE);
    
    pop_trace();
    return ast_block(stmts);
}

func parse_stmt(p: u64) -> u64 {
    push_trace("parse_stmt", "parser/stmt.b", 383);
    var k: u64 = parse_peek_kind(p);
    switch (k) {
        case TOKEN_PLUSPLUS:
        case TOKEN_MINUSMINUS:
            var stmt: u64 = parse_prefix_incdec_assign(p);
            parse_consume(p, TOKEN_SEMICOLON);
            pop_trace();
            return stmt;
        case TOKEN_VAR:
            var result: u64 = parse_var_decl(p);
            pop_trace();
            return result;
        case TOKEN_IF:
            var result2: u64 = parse_if_stmt(p);
            pop_trace();
            return result2;
        case TOKEN_WHILE:
            var result3: u64 = parse_while_stmt(p);
            pop_trace();
            return result3;
        case TOKEN_FOR:
            var result4: u64 = parse_for_stmt(p);
            pop_trace();
            return result4;
        case TOKEN_SWITCH:
            var result5: u64 = parse_switch_stmt(p);
            pop_trace();
            return result5;
        case TOKEN_BREAK:
            var result6: u64 = parse_break_stmt(p);
            pop_trace();
            return result6;
        case TOKEN_CONTINUE:
            var result7: u64 = parse_continue_stmt(p);
            pop_trace();
            return result7;
        case TOKEN_ASM:
            var result8: u64 = parse_asm_stmt(p);
            pop_trace();
            return result8;
        case TOKEN_RETURN:
            var result9: u64 = parse_return_stmt(p);
            pop_trace();
            return result9;
        default:
            var result10: u64 = parse_assign_or_expr(p);
            pop_trace();
            return result10;
    }
}
