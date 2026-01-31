// parse_expr.b - Expression parsing
//
// Pratt parser style with precedence climbing:
// - Primary expressions (literals, identifiers, calls)
// - Postfix expressions (array access, member access)
// - Unary expressions (*, -, !)
// - Binary expressions (arithmetic, comparison, logical)

import std.io;
import std.vec;
import std.util;
import std.str;
import types;
import lexer;
import ast;
import compiler;
import parser.util;
import parser.type;

// ============================================
// Primary Expression
// ============================================

func parse_primary(p: u64) -> u64 {
    push_trace("parse_primary", "parser/expr.b", 60);
    var k: u64 = parse_peek_kind(p);
    
    switch (k) {
        case TOKEN_NUMBER:
            var tok: u64 = parse_peek(p);
            parse_adv(p);
            pop_trace();
            return ast_literal(parse_num_val(tok));
        case TOKEN_LINE_MACRO:
            var tok2: u64 = parse_peek(p);
            parse_adv(p);
            var line: u64 = ((*Token)tok2)->line;
            pop_trace();
            return ast_literal(line);
        case TOKEN_TRUE:
            parse_adv(p);
            pop_trace();
            return ast_literal(1);
        case TOKEN_FALSE:
            parse_adv(p);
            pop_trace();
            return ast_literal(0);
        case TOKEN_STRING:
            var tok3: u64 = parse_peek(p);
            parse_adv(p);
            pop_trace();
            return ast_string(((*Token)tok3)->ptr, ((*Token)tok3)->len);
        case TOKEN_SIZEOF:
            parse_adv(p);
            parse_consume(p, TOKEN_LPAREN);

            var nk: u64 = parse_peek_kind(p);
            var is_type: u64 = 0;
            if (nk == TOKEN_STAR || nk == TOKEN_U8 || nk == TOKEN_U16 || nk == TOKEN_U32 || nk == TOKEN_U64 || nk == TOKEN_I64) {
                is_type = 1;
            } else if (nk == TOKEN_IDENTIFIER) {
                var t: u64 = parse_peek(p);
                var n_ptr: u64 = ((*Token)t)->ptr;
                var n_len: u64 = ((*Token)t)->len;
                if (is_struct_type(n_ptr, n_len) != 0) { is_type = 1; }
                else if (n_ptr != 0 && n_len > 0) {
                    var first_ch: u64 = *(*u8)(n_ptr);
                    if (first_ch >= 65 && first_ch <= 90) { is_type = 1; }
                }
            }

            if (is_type != 0) {
                // Parse type: sizeof(u64), sizeof(*u8), sizeof(StructName), sizeof(*StructName)
                var ty: *TypeInfo = (*TypeInfo)parse_type_ex(p);
                var type_kind: u64 = ty->type_kind;
                var ptr_depth: u64 = ty->ptr_depth;
                var struct_name_ptr: u64 = ty->struct_name_ptr;
                var struct_name_len: u64 = ty->struct_name_len;

                parse_consume(p, TOKEN_RPAREN);

                pop_trace();
                return ast_sizeof(type_kind, ptr_depth, struct_name_ptr, struct_name_len);
            }

            var expr: u64 = parse_expr(p);
            parse_consume(p, TOKEN_RPAREN);
            pop_trace();
            return ast_sizeof_expr(expr);
        case TOKEN_AMPERSAND:
            parse_adv(p);
            var operand: u64 = parse_unary(p);
            if (operand == 0) {
                emit_stderr("[ERROR] Expected expression after &\n", 37);
                pop_trace();
                return 0;
            }
            pop_trace();
            return ast_addr_of(operand);
        case TOKEN_STAR:
            parse_adv(p);
            var operand2: u64 = parse_unary(p);
            pop_trace();
            return ast_deref(operand2);
        case TOKEN_LPAREN:
            parse_adv(p);
            
            var next_k: u64 = parse_peek_kind(p);
            if (next_k == TOKEN_STAR || next_k == TOKEN_U8 || next_k == TOKEN_U16 || 
                next_k == TOKEN_U32 || next_k == TOKEN_U64 || next_k == TOKEN_I64) {
                // Use parse_type_ex to get struct name directly
                // TypeInfo layout: [type_kind:8][ptr_depth:8][is_tagged:8][struct_name_ptr:8][struct_name_len:8][tag_layout_ptr:8][tag_layout_len:8]
                var ty2: *TypeInfo = (*TypeInfo)parse_type_ex(p);
                var type_kind2: u64 = ty2->type_kind;
                var ptr_depth2: u64 = ty2->ptr_depth;
                var is_tagged2: u64 = ty2->is_tagged;
                var struct_name_ptr2: u64 = ty2->struct_name_ptr;
                var struct_name_len2: u64 = ty2->struct_name_len;
                var tag_layout_ptr2: u64 = ty2->tag_layout_ptr;
                var tag_layout_len2: u64 = ty2->tag_layout_len;
                
                parse_consume(p, TOKEN_RPAREN);
                var operand3: u64 = parse_unary(p);
                
                pop_trace();
                return ast_cast_ex(operand3, type_kind2, ptr_depth2, is_tagged2, struct_name_ptr2, struct_name_len2, tag_layout_ptr2, tag_layout_len2);
            }
            
            var expr2: u64 = parse_expr(p);
            parse_consume(p, TOKEN_RPAREN);
            // Handle postfix operators after parenthesized expression: (expr)->field, (expr).field, (expr)[idx]
            pop_trace();
            return parse_postfix_from(p, expr2);
        case TOKEN_IDENTIFIER:
            var tok4: u64 = parse_peek(p);
            parse_adv(p);

            // Slice literal: slice(ptr, len)
            if (((*Token)tok4)->len == 5) {
                if (str_eq(((*Token)tok4)->ptr, ((*Token)tok4)->len, "slice", 5)) {
                    if (parse_peek_kind(p) == TOKEN_LPAREN) {
                        parse_adv(p);
                        var ptr_expr: u64 = parse_expr(p);
                        parse_consume(p, TOKEN_COMMA);
                        var len_expr: u64 = parse_expr(p);
                        parse_consume(p, TOKEN_RPAREN);
                        pop_trace();
                        return ast_slice(ptr_expr, len_expr);
                    }
                }
            }
            
            // Check for struct literal: StructName { expr, expr, ... }
            if (parse_peek_kind(p) == TOKEN_LBRACE) {
                var name_ptr: u64 = ((*Token)tok4)->ptr;
                var name_len: u64 = ((*Token)tok4)->len;
                var struct_def: u64 = get_struct_def(name_ptr, name_len);
                if (struct_def == 0) {
                    var resolved: u64 = resolve_name(name_ptr, name_len);
                    if (resolved != 0) {
                        var resolved_info: *NameInfo = (*NameInfo)resolved;
                        var resolved_ptr: u64 = resolved_info->ptr;
                        var resolved_len: u64 = resolved_info->len;
                        struct_def = get_struct_def(resolved_ptr, resolved_len);
                    }
                }

                parse_adv(p);  // consume '{'

                var values: u64 = vec_new(8);
                if (parse_peek_kind(p) != TOKEN_RBRACE) {
                    vec_push(values, parse_expr(p));
                    while (parse_match(p, TOKEN_COMMA)) {
                        vec_push(values, parse_expr(p));
                    }
                }
                parse_consume(p, TOKEN_RBRACE);

                pop_trace();
                return ast_struct_literal(struct_def, values);
            }
            
            // Check for static method call: StructName.method(...)
            // Only process if IDENTIFIER is a known struct type, DOT is followed by IDENTIFIER and LPAREN
            if (parse_peek_kind(p) == TOKEN_DOT) {
                var struct_name_ptr: u64 = ((*Token)tok4)->ptr;
                var struct_name_len: u64 = ((*Token)tok4)->len;
                
                // Only treat as static method call if this is a struct type name
                if (is_struct_type(struct_name_ptr, struct_name_len) != 0) {
                    // Look ahead to check if this is a static method call
                    var saved_pos: u64 = parser_pos(p);
                    parse_adv(p);  // consume '.'
                    
                    if (parse_peek_kind(p) == TOKEN_IDENTIFIER) {
                        var method_tok: u64 = parse_peek(p);
                        parse_adv(p);  // consume method name
                        
                        if (parse_peek_kind(p) == TOKEN_LPAREN) {
                            // This is a static method call: StructName.method(...)
                            var method_name_ptr: u64 = ((*Token)method_tok)->ptr;
                            var method_name_len: u64 = ((*Token)method_tok)->len;
                            
                            // Create combined name: StructName_methodName
                            var combined_name: u64 = vec_new(64);
                            for (var i: u64 = 0; i < struct_name_len; i++) {
                                vec_push(combined_name, *(*u8)(struct_name_ptr + i));
                            }
                            vec_push(combined_name, 95);  // '_'
                            for (var i: u64 = 0; i < method_name_len; i++) {
                                vec_push(combined_name, *(*u8)(method_name_ptr + i));
                            }
                            
                            var combined_len: u64 = vec_len(combined_name);
                            var combined_ptr: u64 = heap_alloc((combined_len + 1) * sizeof(u8));
                            for (var i: u64 = 0; i < combined_len; i++) {
                                *(*u8)(combined_ptr + i) = vec_get(combined_name, i);
                            }
                            *(*u8)(combined_ptr + combined_len) = 0;
                            
                            parse_adv(p);  // consume '('
                            var args: u64 = vec_new(8);
                            if (parse_peek_kind(p) != TOKEN_RPAREN) {
                                vec_push(args, parse_expr(p));
                                while (parse_match(p, TOKEN_COMMA)) {
                                    vec_push(args, parse_expr(p));
                                }
                            }
                            parse_consume(p, TOKEN_RPAREN);
                            pop_trace();
                            return ast_call(combined_ptr, combined_len, args);
                        }
                    }
                    
                    // Not a static method call, restore position and let postfix handle it
                    parser_set_pos(p, saved_pos);
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
                pop_trace();
                return ast_call(((*Token)tok4)->ptr, ((*Token)tok4)->len, args);
            }
            
            pop_trace();
            return ast_ident(((*Token)tok4)->ptr, ((*Token)tok4)->len);
        default:
            pop_trace();
            return 0;
    }
}

// ============================================
// Postfix Expression
// ============================================

func parse_postfix_from(p: u64, left: u64) -> u64 {
    while (1) {
        var k: u64 = parse_peek_kind(p);
        
        switch (k) {
            case TOKEN_LBRACKET:
                parse_adv(p);
                var idx: u64 = parse_expr(p);
                parse_consume(p, TOKEN_RBRACKET);
                left = ast_index(left, idx);
                break;
            case TOKEN_LPAREN:
                parse_adv(p);
                var args: u64 = vec_new(4);

                if (parse_peek_kind(p) != TOKEN_RPAREN) {
                    vec_push(args, parse_expr(p));
                    while (parse_peek_kind(p) == TOKEN_COMMA) {
                        parse_adv(p);
                        vec_push(args, parse_expr(p));
                    }
                }

                parse_consume(p, TOKEN_RPAREN);
                left = ast_call_ptr(left, args);
                break;
            case TOKEN_DOT:
                parse_adv(p);
                var field_tok: u64 = parse_peek(p);
                parse_consume(p, TOKEN_IDENTIFIER);
                
                // Check if next token is '(' -> method call
                if (parse_peek_kind(p) == TOKEN_LPAREN) {
                    parse_adv(p);
                    var args2: u64 = vec_new(4);
                    
                    if (parse_peek_kind(p) != TOKEN_RPAREN) {
                        vec_push(args2, parse_expr(p));
                        while (parse_peek_kind(p) == TOKEN_COMMA) {
                            parse_adv(p);
                            vec_push(args2, parse_expr(p));
                        }
                    }
                    
                    parse_consume(p, TOKEN_RPAREN);
                    left = ast_method_call(left, ((*Token)field_tok)->ptr, ((*Token)field_tok)->len, args2);
                } else {
                    // Regular member access
                    left = ast_member_access(left, ((*Token)field_tok)->ptr, ((*Token)field_tok)->len);
                }
                break;
            case TOKEN_ARROW:
                parse_adv(p);
                var field_tok2: u64 = parse_peek(p);
                parse_consume(p, TOKEN_IDENTIFIER);
                
                // Check if next token is '(' -> method call
                if (parse_peek_kind(p) == TOKEN_LPAREN) {
                    parse_adv(p);
                    var args3: u64 = vec_new(4);
                    
                    if (parse_peek_kind(p) != TOKEN_RPAREN) {
                        vec_push(args3, parse_expr(p));
                        while (parse_peek_kind(p) == TOKEN_COMMA) {
                            parse_adv(p);
                            vec_push(args3, parse_expr(p));
                        }
                    }
                    
                    parse_consume(p, TOKEN_RPAREN);
                    // ptr->method() = (*ptr).method()
                    var deref: u64 = ast_deref(left);
                    left = ast_method_call(deref, ((*Token)field_tok2)->ptr, ((*Token)field_tok2)->len, args3);
                } else {
                    // Regular member access: ptr->field = (*ptr).field
                    var deref2: u64 = ast_deref(left);
                    left = ast_member_access(deref2, ((*Token)field_tok2)->ptr, ((*Token)field_tok2)->len);
                }
                break;
            default:
                return left;
        }
    }
}

func parse_postfix(p: u64) -> u64 {
    var left: u64 = parse_primary(p);
    return parse_postfix_from(p, left);
}

// ============================================
// Unary Expression
// ============================================

func parse_unary(p: u64) -> u64 {
    var k: u64 = parse_peek_kind(p);
    
    switch (k) {
        case TOKEN_STAR:
            parse_adv(p);
            var operand: u64 = parse_unary(p);
            return ast_deref(operand);
        case TOKEN_MINUS:
            parse_adv(p);
            var next_k: u64 = parse_peek_kind(p);
            if (next_k == TOKEN_NUMBER) {
                var tok: u64 = parse_peek(p);
                parse_adv(p);
                var val: u64 = parse_num_val(tok);
                return ast_literal(0 - val);
            }
            var operand2: u64 = parse_unary(p);
            return ast_unary(TOKEN_MINUS, operand2);
        case TOKEN_BANG:
            parse_adv(p);
            var operand3: u64 = parse_unary(p);
            return ast_unary(TOKEN_BANG, operand3);
        case TOKEN_TILDE:
            parse_adv(p);
            var operand4: u64 = parse_unary(p);
            return ast_unary(TOKEN_TILDE, operand4);
        default:
            return parse_postfix(p);
    }
}

// ============================================
// Binary Expressions (Precedence Climbing)
// ============================================

func parse_mul(p: u64) -> u64 {
    var left: u64 = parse_unary(p);
    
    while (1) {
        var k: u64 = parse_peek_kind(p);
        switch (k) {
            case TOKEN_STAR:
                parse_adv(p);
                var right: u64 = parse_unary(p);
                left = ast_binary(TOKEN_STAR, left, right);
                break;
            case TOKEN_SLASH:
                parse_adv(p);
                var right2: u64 = parse_unary(p);
                left = ast_binary(TOKEN_SLASH, left, right2);
                break;
            case TOKEN_PERCENT:
                parse_adv(p);
                var right3: u64 = parse_unary(p);
                left = ast_binary(TOKEN_PERCENT, left, right3);
                break;
            default:
                return left;
        }
    }
}

func parse_add(p: u64) -> u64 {
    var left: u64 = parse_mul(p);
    
    while (1) {
        var k: u64 = parse_peek_kind(p);
        switch (k) {
            case TOKEN_PLUS:
                parse_adv(p);
                var right: u64 = parse_mul(p);
                left = ast_binary(TOKEN_PLUS, left, right);
                break;
            case TOKEN_MINUS:
                parse_adv(p);
                var right2: u64 = parse_mul(p);
                left = ast_binary(TOKEN_MINUS, left, right2);
                break;
            default:
                return left;
        }
    }
}

func parse_shift(p: u64) -> u64 {
    var left: u64 = parse_add(p);
    
    while (1) {
        var k: u64 = parse_peek_kind(p);
        switch (k) {
            case TOKEN_LSHIFT:
                parse_adv(p);
                var right: u64 = parse_add(p);
                left = ast_binary(TOKEN_LSHIFT, left, right);
                break;
            case TOKEN_RSHIFT:
                parse_adv(p);
                var right2: u64 = parse_add(p);
                left = ast_binary(TOKEN_RSHIFT, left, right2);
                break;
            default:
                return left;
        }
    }
}

func parse_rel(p: u64) -> u64 {
    var left: u64 = parse_shift(p);
    
    while (1) {
        var k: u64 = parse_peek_kind(p);
        switch (k) {
            case TOKEN_LT:
                parse_adv(p);
                var right: u64 = parse_shift(p);
                left = ast_binary(TOKEN_LT, left, right);
                break;
            case TOKEN_GT:
                parse_adv(p);
                var right2: u64 = parse_shift(p);
                left = ast_binary(TOKEN_GT, left, right2);
                break;
            case TOKEN_LTEQ:
                parse_adv(p);
                var right3: u64 = parse_shift(p);
                left = ast_binary(TOKEN_LTEQ, left, right3);
                break;
            case TOKEN_GTEQ:
                parse_adv(p);
                var right4: u64 = parse_shift(p);
                left = ast_binary(TOKEN_GTEQ, left, right4);
                break;
            default:
                return left;
        }
    }
}

func parse_eq(p: u64) -> u64 {
    var left: u64 = parse_rel(p);
    
    while (1) {
        var k: u64 = parse_peek_kind(p);
        switch (k) {
            case TOKEN_EQEQ:
                parse_adv(p);
                var right: u64 = parse_rel(p);
                left = ast_binary(TOKEN_EQEQ, left, right);
                break;
            case TOKEN_BANGEQ:
                parse_adv(p);
                var right2: u64 = parse_rel(p);
                left = ast_binary(TOKEN_BANGEQ, left, right2);
                break;
            default:
                return left;
        }
    }
}

func parse_bitand(p: u64) -> u64 {
    var left: u64 = parse_eq(p);
    
    while (1) {
        var k: u64 = parse_peek_kind(p);
        switch (k) {
            case TOKEN_AMPERSAND:
                parse_adv(p);
                var right: u64 = parse_eq(p);
                left = ast_binary(TOKEN_AMPERSAND, left, right);
                break;
            default:
                return left;
        }
    }
}

func parse_bitxor(p: u64) -> u64 {
    var left: u64 = parse_bitand(p);
    
    while (1) {
        var k: u64 = parse_peek_kind(p);
        switch (k) {
            case TOKEN_CARET:
                parse_adv(p);
                var right: u64 = parse_bitand(p);
                left = ast_binary(TOKEN_CARET, left, right);
                break;
            default:
                return left;
        }
    }
}

func parse_bitor(p: u64) -> u64 {
    var left: u64 = parse_bitxor(p);
    
    while (1) {
        var k: u64 = parse_peek_kind(p);
        switch (k) {
            case TOKEN_PIPE:
                parse_adv(p);
                var right: u64 = parse_bitxor(p);
                left = ast_binary(TOKEN_PIPE, left, right);
                break;
            default:
                return left;
        }
    }
}

func parse_logand(p: u64) -> u64 {
    var left: u64 = parse_bitor(p);

    while (1) {
        var k: u64 = parse_peek_kind(p);
        switch (k) {
            case TOKEN_ANDAND:
                parse_adv(p);
                var right: u64 = parse_bitor(p);
                left = ast_binary(TOKEN_ANDAND, left, right);
                break;
            default:
                return left;
        }
    }
}

func parse_logor(p: u64) -> u64 {
    var left: u64 = parse_logand(p);

    while (1) {
        var k: u64 = parse_peek_kind(p);
        switch (k) {
            case TOKEN_OROR:
                parse_adv(p);
                var right: u64 = parse_logand(p);
                left = ast_binary(TOKEN_OROR, left, right);
                break;
            default:
                return left;
        }
    }
}

func parse_expr(p: u64) -> u64 {
    push_trace("parse_expr", "parser/expr.b", 528);
    var result: u64 = parse_logor(p);
    pop_trace();
    return result;
}
