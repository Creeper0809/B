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
import types;
import lexer;
import ast;
import parser.util;
import parser.type;

// ============================================
// Pointer Access Helpers
// ============================================

func is_ptr_keyword(ptr: u64, len: u64) -> u64 {
    if (len == 5 && *(*u8)ptr == 112 && *(*u8)(ptr+1) == 116 && *(*u8)(ptr+2) == 114 && *(*u8)(ptr+3) == 54 && *(*u8)(ptr+4) == 52) {
        return 64;  // ptr64
    }
    if (len == 4 && *(*u8)ptr == 112 && *(*u8)(ptr+1) == 116 && *(*u8)(ptr+2) == 114 && *(*u8)(ptr+3) == 56) {
        return 8;   // ptr8
    }
    return 0;
}

func parse_ptr_access(p: u64) -> u64 {
    var tok: u64 = parse_peek(p);
    var ptr_kind: u64 = is_ptr_keyword(((*Token)tok)->ptr, ((*Token)tok)->len);
    
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
            return ast_ident(((*Token)tok)->ptr, ((*Token)tok)->len);
        }
    }
    return 0;
}

// ============================================
// Primary Expression
// ============================================

func parse_primary(p: u64) -> u64 {
    push_trace("parse_primary", "parser/expr.b", 60);
    var k: u64 = parse_peek_kind(p);
    
    if (k == TOKEN_NUMBER) {
        var tok: u64 = parse_peek(p);
        parse_adv(p);
        pop_trace();
        return ast_literal(parse_num_val(tok));
    }

    if (k == TOKEN_LINE_MACRO) {
        var tok: u64 = parse_peek(p);
        parse_adv(p);
        var line: u64 = ((*Token)tok)->line;
        pop_trace();
        return ast_literal(line);
    }

    if (k == TOKEN_TRUE) {
        parse_adv(p);
        pop_trace();
        return ast_literal(1);
    }

    if (k == TOKEN_FALSE) {
        parse_adv(p);
        pop_trace();
        return ast_literal(0);
    }
    
    if (k == TOKEN_STRING) {
        var tok: u64 = parse_peek(p);
        parse_adv(p);
        pop_trace();
        return ast_string(((*Token)tok)->ptr, ((*Token)tok)->len);
    }
    
    if (k == TOKEN_SIZEOF) {
        parse_adv(p);
        parse_consume(p, TOKEN_LPAREN);
        
        // Parse type: sizeof(u64), sizeof(*u8), sizeof(StructName), sizeof(*StructName)
        var ty: u64 = parse_type_ex(p);
        var type_kind: u64 = *(*u64)ty;
        var ptr_depth: u64 = *(*u64)(ty + 8);
        var struct_name_ptr: u64 = *(*u64)(ty + 16);
        var struct_name_len: u64 = *(*u64)(ty + 24);
        
        parse_consume(p, TOKEN_RPAREN);
        
        pop_trace();
        return ast_sizeof(type_kind, ptr_depth, struct_name_ptr, struct_name_len);
    }
    
    if (k == TOKEN_AMPERSAND) {
        parse_adv(p);
        var tok: u64 = parse_peek(p);
        if (parse_peek_kind(p) != TOKEN_IDENTIFIER) {
            emit_stderr("[ERROR] Expected identifier after &\n", 37);
            pop_trace();
            return 0;
        }
        parse_adv(p);
        var ident: u64 = ast_ident(((*Token)tok)->ptr, ((*Token)tok)->len);
        pop_trace();
        return ast_addr_of(ident);
    }
    
    if (k == TOKEN_STAR) {
        parse_adv(p);
        var operand: u64 = parse_unary(p);
        pop_trace();
        return ast_deref(operand);
    }
    
    if (k == TOKEN_LPAREN) {
        parse_adv(p);
        
        var next_k: u64 = parse_peek_kind(p);
        if (next_k == TOKEN_STAR || next_k == TOKEN_U8 || next_k == TOKEN_U16 || 
            next_k == TOKEN_U32 || next_k == TOKEN_U64 || next_k == TOKEN_I64) {
            // Use parse_type_ex to get struct name directly
            // TypeInfo layout: [type_kind:8][ptr_depth:8][struct_name_ptr:8][struct_name_len:8]
            var ty: u64 = parse_type_ex(p);
            var type_kind: u64 = *(*u64)ty;
            var ptr_depth: u64 = *(*u64)(ty + 8);
            var struct_name_ptr: u64 = *(*u64)(ty + 16);
            var struct_name_len: u64 = *(*u64)(ty + 24);
            
            parse_consume(p, TOKEN_RPAREN);
            var operand: u64 = parse_unary(p);
            
            pop_trace();
            return ast_cast_ex(operand, type_kind, ptr_depth, struct_name_ptr, struct_name_len);
        }
        
        var expr: u64 = parse_expr(p);
        parse_consume(p, TOKEN_RPAREN);
        // Handle postfix operators after parenthesized expression: (expr)->field, (expr).field, (expr)[idx]
        pop_trace();
        return parse_postfix_from(p, expr);
    }
    
    if (k == TOKEN_IDENTIFIER) {
        var tok: u64 = parse_peek(p);
        var ptr_kind: u64 = is_ptr_keyword(((*Token)tok)->ptr, ((*Token)tok)->len);
        if (ptr_kind > 0) {
            var result: u64 = parse_ptr_access(p);
            if (result != 0) {
                pop_trace();
                return result;
            }
        }
    }
    
    if (k == TOKEN_IDENTIFIER) {
        var tok: u64 = parse_peek(p);
        parse_adv(p);

        // Slice literal: slice(ptr, len)
        if (((*Token)tok)->len == 5) {
            if (str_eq(((*Token)tok)->ptr, ((*Token)tok)->len, "slice", 5)) {
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
            var name_ptr: u64 = ((*Token)tok)->ptr;
            var name_len: u64 = ((*Token)tok)->len;
            
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
                
                pop_trace();
                return ast_struct_literal(struct_def, values);
            }
        }
        
        // Check for static method call: StructName.method(...)
        // Only process if IDENTIFIER is a known struct type, DOT is followed by IDENTIFIER and LPAREN
        if (parse_peek_kind(p) == TOKEN_DOT) {
            var struct_name_ptr: u64 = ((*Token)tok)->ptr;
            var struct_name_len: u64 = ((*Token)tok)->len;
            
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
                    var combined_ptr: u64 = heap_alloc(combined_len);
                    for (var i: u64 = 0; i < combined_len; i++) {
                        *(*u8)(combined_ptr + i) = vec_get(combined_name, i);
                    }
                    
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
            return ast_call(((*Token)tok)->ptr, ((*Token)tok)->len, args);
        }
        
        pop_trace();
        return ast_ident(((*Token)tok)->ptr, ((*Token)tok)->len);
    }
    
    pop_trace();
    return 0;
}

// ============================================
// Postfix Expression
// ============================================

func parse_postfix_from(p: u64, left: u64) -> u64 {
    while (1) {
        var k: u64 = parse_peek_kind(p);
        
        if (k == TOKEN_LBRACKET) {
            parse_adv(p);
            var idx: u64 = parse_expr(p);
            parse_consume(p, TOKEN_RBRACKET);
            left = ast_index(left, idx);
        } else if (k == TOKEN_DOT) {
            parse_adv(p);
            var field_tok: u64 = parse_peek(p);
            parse_consume(p, TOKEN_IDENTIFIER);
            
            // Check if next token is '(' -> method call
            if (parse_peek_kind(p) == TOKEN_LPAREN) {
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
                left = ast_method_call(left, ((*Token)field_tok)->ptr, ((*Token)field_tok)->len, args);
            } else {
                // Regular member access
                left = ast_member_access(left, ((*Token)field_tok)->ptr, ((*Token)field_tok)->len);
            }
        } else if (k == TOKEN_ARROW) {
            parse_adv(p);
            var field_tok: u64 = parse_peek(p);
            parse_consume(p, TOKEN_IDENTIFIER);
            
            // Check if next token is '(' -> method call
            if (parse_peek_kind(p) == TOKEN_LPAREN) {
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
                // ptr->method() = (*ptr).method()
                var deref: u64 = ast_deref(left);
                left = ast_method_call(deref, ((*Token)field_tok)->ptr, ((*Token)field_tok)->len, args);
            } else {
                // Regular member access: ptr->field = (*ptr).field
                var deref: u64 = ast_deref(left);
                left = ast_member_access(deref, ((*Token)field_tok)->ptr, ((*Token)field_tok)->len);
            }
        } else {
            break;
        }
    }
    
    return left;
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
    
    if (k == TOKEN_STAR) {
        parse_adv(p);
        var operand: u64 = parse_unary(p);
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

// ============================================
// Binary Expressions (Precedence Climbing)
// ============================================

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
        var k: u64 = parse_peek_kind(p);
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
            var right: u64 = parse_eq(p);
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
    push_trace("parse_expr", "parser/expr.b", 528);
    var result: u64 = parse_logor(p);
    pop_trace();
    return result;
}
