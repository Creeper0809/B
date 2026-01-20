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

// ============================================
// Primary Expression
// ============================================

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
        if (next_k == TOKEN_STAR || next_k == TOKEN_U8 || next_k == TOKEN_U16 || 
            next_k == TOKEN_U32 || next_k == TOKEN_U64 || next_k == TOKEN_I64) {
            var ty: *TypeInfo = (*TypeInfo)parse_type(p);
            parse_consume(p, TOKEN_RPAREN);
            var operand: u64 = parse_unary(p);
            
            // If struct type, get struct name from TypeInfo (parse_type doesn't set it, so lookup)
            var struct_name_ptr: u64 = 0;
            var struct_name_len: u64 = 0;
            if (ty->type_kind == TYPE_STRUCT) {
                // Get struct name from previous token
                var parser: *Parser = (*Parser)p;
                var prev_idx: u64 = parser->cur - 1;
                if (prev_idx >= 0 && prev_idx < vec_len(parser->tokens_vec)) {
                    var prev_tok: u64 = vec_get(parser->tokens_vec, prev_idx);
                    struct_name_ptr = tok_ptr(prev_tok);
                    struct_name_len = tok_len(prev_tok);
                }
            }
            
            return ast_cast_ex(operand, ty->type_kind, ty->ptr_depth, struct_name_ptr, struct_name_len);
        }
        
        var expr: u64 = parse_expr(p);
        parse_consume(p, TOKEN_RPAREN);
        return expr;
    }
    
    if (k == TOKEN_IDENTIFIER) {
        var tok: u64 = parse_peek(p);
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

// ============================================
// Postfix Expression
// ============================================

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
    return parse_logor(p);
}
