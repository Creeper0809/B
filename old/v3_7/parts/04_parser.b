// v3.6 Compiler - Part 4: Parser
// Parser structure: [tokens_vec, cur]

// ============================================
// Parser Core
// ============================================

func parse_new(tokens: i64) -> i64 {
    var p;
    p = heap_alloc(16);
    ptr64[p] = tokens;
    ptr64[p + 8] = 0;
    return p;
}

func parse_peek(p: i64) -> i64 {
    var vec;
    vec = ptr64[p];
    var cur;
    cur = ptr64[p + 8];
    if (cur >= vec_len(vec)) { return 0; }
    return vec_get(vec, cur);
}

func parse_peek_kind(p: i64) -> i64 {
    var tok;
    tok = parse_peek(p);
    if (tok == 0) { return TOKEN_EOF; }
    return tok_kind(tok);
}

func parse_adv(p: i64) -> i64 {
    ptr64[p + 8] = ptr64[p + 8] + 1;
}

func parse_prev(p: i64) -> i64 {
    var vec;
    vec = ptr64[p];
    var cur;
    cur = ptr64[p + 8];
    if (cur == 0) { return 0; }
    return vec_get(vec, cur - 1);
}

func parse_match(p: i64, kind: i64) -> i64 {
    if (parse_peek_kind(p) == kind) {
        parse_adv(p);
        return 1;
    }
    return 0;
}

func parse_consume(p: i64, kind: i64) -> i64 {
    if (!parse_match(p, kind)) {
        emit_stderr("[ERROR] Expected token kind ", 29);
        emit_u64(kind);
        emit(" but got ", 9);
        emit_u64(parse_peek_kind(p));
        emit_nl();
        panic();
    }
}

// ============================================
// Type Parsing
// ============================================

func parse_base_type(p: i64) -> i64 {
    var k;
    k = parse_peek_kind(p);
    if (k == TOKEN_U8) { parse_adv(p); return TYPE_U8; }
    if (k == TOKEN_U16) { parse_adv(p); return TYPE_U16; }
    if (k == TOKEN_U32) { parse_adv(p); return TYPE_U32; }
    if (k == TOKEN_U64) { parse_adv(p); return TYPE_U64; }
    if (k == TOKEN_I64) { parse_adv(p); return TYPE_I64; }
    return TYPE_VOID;
}

// Parse type with pointers: *u8, **i64, etc.
// Returns [base_type, ptr_depth]
func parse_type(p: i64) -> i64 {
    var depth;
    depth = 0;
    while (parse_match(p, TOKEN_STAR)) {
        depth = depth + 1;
    }
    var base;
    base = parse_base_type(p);
    var result;
    result = heap_alloc(16);
    ptr64[result] = base;
    ptr64[result + 8] = depth;
    return result;
}

// ============================================
// Expression Parsing
// ============================================

func parse_num_val(tok: i64) -> i64 {
    var ptr;
    ptr = tok_ptr(tok);
    var len;
    len = tok_len(tok);
    var val;
    val = 0;
    var i;
    i = 0;
    while (i < len) {
        var c;
        c = ptr8[ptr + i];
        val = val * 10 + (c - 48);
        i = i + 1;
    }
    return val;
}

// primary := NUMBER | STRING | IDENT | '(' expr ')' | '&' IDENT | '*' unary
func parse_primary(p: i64) -> i64 {
    var k;
    k = parse_peek_kind(p);
    
    // Number literal
    if (k == TOKEN_NUMBER) {
        var tok;
        tok = parse_peek(p);
        parse_adv(p);
        return ast_literal(parse_num_val(tok));
    }
    
    // String literal
    if (k == TOKEN_STRING) {
        var tok;
        tok = parse_peek(p);
        parse_adv(p);
        return ast_string(tok_ptr(tok), tok_len(tok));
    }
    
    // Address-of: &ident
    if (k == TOKEN_AMPERSAND) {
        parse_adv(p);
        var tok;
        tok = parse_peek(p);
        if (parse_peek_kind(p) != TOKEN_IDENTIFIER) {
            emit_stderr("[ERROR] Expected identifier after &\n", 37);
            return 0;
        }
        parse_adv(p);
        var ident;
        ident = ast_ident(tok_ptr(tok), tok_len(tok));
        return ast_addr_of(ident);
    }
    
    // Dereference: *expr
    if (k == TOKEN_STAR) {
        parse_adv(p);
        var operand;
        operand = parse_unary(p);
        return ast_deref(operand);
    }
    
    // Parenthesized expression or cast: (type)expr or (expr)
    if (k == TOKEN_LPAREN) {
        parse_adv(p);
        
        // Check if next token is a type (cast) or * (pointer type cast)
        var next_k;
        next_k = parse_peek_kind(p);
        if (next_k == TOKEN_STAR) {
            // Pointer type cast: (*i64)expr, (**u8)expr
            var ty;
            ty = parse_type(p);
            parse_consume(p, TOKEN_RPAREN);
            var operand;
            operand = parse_unary(p);
            return ast_cast(operand, ptr64[ty], ptr64[ty + 8]);
        }
        if (next_k == TOKEN_U8) {
            var ty;
            ty = parse_type(p);
            parse_consume(p, TOKEN_RPAREN);
            var operand;
            operand = parse_unary(p);
            return ast_cast(operand, ptr64[ty], ptr64[ty + 8]);
        }
        if (next_k == TOKEN_U16) {
            var ty;
            ty = parse_type(p);
            parse_consume(p, TOKEN_RPAREN);
            var operand;
            operand = parse_unary(p);
            return ast_cast(operand, ptr64[ty], ptr64[ty + 8]);
        }
        if (next_k == TOKEN_U32) {
            var ty;
            ty = parse_type(p);
            parse_consume(p, TOKEN_RPAREN);
            var operand;
            operand = parse_unary(p);
            return ast_cast(operand, ptr64[ty], ptr64[ty + 8]);
        }
        if (next_k == TOKEN_U64) {
            var ty;
            ty = parse_type(p);
            parse_consume(p, TOKEN_RPAREN);
            var operand;
            operand = parse_unary(p);
            return ast_cast(operand, ptr64[ty], ptr64[ty + 8]);
        }
        if (next_k == TOKEN_I64) {
            var ty;
            ty = parse_type(p);
            parse_consume(p, TOKEN_RPAREN);
            var operand;
            operand = parse_unary(p);
            return ast_cast(operand, ptr64[ty], ptr64[ty + 8]);
        }
        
        // Regular parenthesized expression
        var expr;
        expr = parse_expr(p);
        parse_consume(p, TOKEN_RPAREN);
        return expr;
    }
    
    // Check for ptr64[expr] or ptr8[expr] special syntax first
    if (k == TOKEN_IDENTIFIER) {
        var tok;
        tok = parse_peek(p);
        var ptr_kind;
        ptr_kind = is_ptr_keyword(tok_ptr(tok), tok_len(tok));
        if (ptr_kind > 0) {
            var result;
            result = parse_ptr_access(p);
            if (result != 0) {
                return result;
            }
        }
    }
    
    // Identifier or function call
    if (k == TOKEN_IDENTIFIER) {
        var tok;
        tok = parse_peek(p);
        parse_adv(p);
        
        // Check for function call
        if (parse_peek_kind(p) == TOKEN_LPAREN) {
            parse_adv(p);
            var args;
            args = vec_new(8);
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

// postfix := primary ('[' expr ']')*
func parse_postfix(p: i64) -> i64 {
    var left;
    left = parse_primary(p);
    
    // Handle arr[expr] index syntax - treat as *(arr + expr)
    while (parse_peek_kind(p) == TOKEN_LBRACKET) {
        parse_adv(p);  // consume '['
        var idx;
        idx = parse_expr(p);
        parse_consume(p, TOKEN_RBRACKET);
        // Treat as *(left + idx) - dereference at (base + index)
        left = ast_deref(ast_binary(TOKEN_PLUS, left, idx));
    }
    
    return left;
}

// Check if identifier is ptr64 or ptr8 special syntax
func is_ptr_keyword(ptr: i64, len: i64) -> i64 {
    if (len == 5) {
        if (ptr8[ptr] == 112) {     // 'p'
            if (ptr8[ptr+1] == 116) { // 't'
                if (ptr8[ptr+2] == 114) { // 'r'
                    if (ptr8[ptr+3] == 54) { // '6'
                        if (ptr8[ptr+4] == 52) { // '4'
                            return 64;
                        }
                    }
                }
            }
        }
    }
    if (len == 4) {
        if (ptr8[ptr] == 112) {     // 'p'
            if (ptr8[ptr+1] == 116) { // 't'
                if (ptr8[ptr+2] == 114) { // 'r'
                    if (ptr8[ptr+3] == 56) { // '8'
                        return 8;
                    }
                }
            }
        }
    }
    return 0;
}

// Parse ptr64[expr] or ptr8[expr] as special syntax
func parse_ptr_access(p: i64) -> i64 {
    var tok;
    tok = parse_peek(p);
    var ptr_kind;
    ptr_kind = is_ptr_keyword(tok_ptr(tok), tok_len(tok));
    
    if (ptr_kind > 0) {
        // Check if next token is [
        var next;
        parse_adv(p);  // consume ptr64/ptr8
        if (parse_peek_kind(p) == TOKEN_LBRACKET) {
            parse_adv(p);  // consume '['
            var idx;
            idx = parse_expr(p);
            parse_consume(p, TOKEN_RBRACKET);
            // For ptr64[x], treat as *(x) - deref at x
            // For ptr8[x], use AST_DEREF8
            if (ptr_kind == 64) {
                return ast_deref(idx);
            } else {
                // ptr8[x] - byte dereference
                return ast_deref8(idx);
            }
        } else {
            // Not followed by [, treat as regular identifier
            return ast_ident(tok_ptr(tok), tok_len(tok));
        }
    }
    return 0;  // Not a ptr keyword
}

// unary := ('*' | '&' | '-' | '!') unary | postfix
func parse_unary(p: i64) -> i64 {
    var k;
    k = parse_peek_kind(p);
    
    if (k == TOKEN_STAR) {
        parse_adv(p);
        var operand;
        operand = parse_unary(p);
        return ast_deref(operand);
    }
    
    if (k == TOKEN_MINUS) {
        parse_adv(p);
        var operand;
        operand = parse_unary(p);
        return ast_unary(TOKEN_MINUS, operand);
    }
    
    if (k == TOKEN_BANG) {
        parse_adv(p);
        var operand;
        operand = parse_unary(p);
        return ast_unary(TOKEN_BANG, operand);
    }
    
    return parse_postfix(p);
}

// mul := unary (('*' | '/') unary)*
func parse_mul(p: i64) -> i64 {
    var left;
    left = parse_unary(p);
    
    while (1) {
        var k;
        k = parse_peek_kind(p);
        if (k == TOKEN_STAR) {
            parse_adv(p);
            var right;
            right = parse_unary(p);
            left = ast_binary(TOKEN_STAR, left, right);
        } else if (k == TOKEN_SLASH) {
            parse_adv(p);
            var right;
            right = parse_unary(p);
            left = ast_binary(TOKEN_SLASH, left, right);
        } else if (k == TOKEN_PERCENT) {
            parse_adv(p);
            var right;
            right = parse_unary(p);
            left = ast_binary(TOKEN_PERCENT, left, right);
        } else {
            break;
        }
    }
    
    return left;
}

// add := mul (('+' | '-') mul)*
func parse_add(p: i64) -> i64 {
    var left;
    left = parse_mul(p);
    
    while (1) {
        var k;
        k = parse_peek_kind(p);
        if (k == TOKEN_PLUS) {
            parse_adv(p);
            var right;
            right = parse_mul(p);
            left = ast_binary(TOKEN_PLUS, left, right);
        } else if (k == TOKEN_MINUS) {
            parse_adv(p);
            var right;
            right = parse_mul(p);
            left = ast_binary(TOKEN_MINUS, left, right);
        } else {
            break;
        }
    }
    
    return left;
}

// bitxor := add (('^') add)*
func parse_bitxor(p: i64) -> i64 {
    var left;
    left = parse_add(p);
    
    while (1) {
        var k;
        k = parse_peek_kind(p);
        if (k == TOKEN_CARET) {
            parse_adv(p);
            var right;
            right = parse_add(p);
            left = ast_binary(TOKEN_CARET, left, right);
        } else {
            break;
        }
    }
    
    return left;
}

// rel := bitxor (('<' | '>' | '<=' | '>=') bitxor)*
func parse_rel(p: i64) -> i64 {
    var left;
    left = parse_bitxor(p);
    
    while (1) {
        var k;
        k = parse_peek_kind(p);
        if (k == TOKEN_LT) {
            parse_adv(p);
            var right;
            right = parse_bitxor(p);
            left = ast_binary(TOKEN_LT, left, right);
        } else if (k == TOKEN_GT) {
            parse_adv(p);
            var right;
            right = parse_bitxor(p);
            left = ast_binary(TOKEN_GT, left, right);
        } else if (k == TOKEN_LTEQ) {
            parse_adv(p);
            var right;
            right = parse_bitxor(p);
            left = ast_binary(TOKEN_LTEQ, left, right);
        } else if (k == TOKEN_GTEQ) {
            parse_adv(p);
            var right;
            right = parse_bitxor(p);
            left = ast_binary(TOKEN_GTEQ, left, right);
        } else {
            break;
        }
    }
    
    return left;
}

// eq := rel (('==' | '!=') rel)*
func parse_eq(p: i64) -> i64 {
    var left;
    left = parse_rel(p);
    
    while (1) {
        var k;
        k = parse_peek_kind(p);
        if (k == TOKEN_EQEQ) {
            parse_adv(p);
            var right;
            right = parse_rel(p);
            left = ast_binary(TOKEN_EQEQ, left, right);
        } else if (k == TOKEN_BANGEQ) {
            parse_adv(p);
            var right;
            right = parse_rel(p);
            left = ast_binary(TOKEN_BANGEQ, left, right);
        } else {
            break;
        }
    }
    
    return left;
}

func parse_expr(p: i64) -> i64 {
    return parse_eq(p);
}

// ============================================
// Statement Parsing
// ============================================

// var_decl := 'var' IDENT (':' type)? ('=' expr)? ';'
func parse_var_decl(p: i64) -> i64 {
    parse_consume(p, TOKEN_VAR);
    
    var name_tok;
    name_tok = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    var type_kind;
    type_kind = TYPE_I64;
    var ptr_depth;
    ptr_depth = 0;
    
    // Optional type annotation
    if (parse_match(p, TOKEN_COLON)) {
        var ty;
        ty = parse_type(p);
        type_kind = ptr64[ty];
        ptr_depth = ptr64[ty + 8];
    }
    
    var init;
    init = 0;
    
    // Optional initializer
    if (parse_match(p, TOKEN_EQ)) {
        init = parse_expr(p);
    }
    
    parse_consume(p, TOKEN_SEMICOLON);
    
    return ast_var_decl(tok_ptr(name_tok), tok_len(name_tok), type_kind, ptr_depth, init);
}

// assign_or_expr := expr ('=' expr)? ';'
func parse_assign_or_expr(p: i64) -> i64 {
    var expr;
    expr = parse_expr(p);
    
    if (parse_match(p, TOKEN_EQ)) {
        var val;
        val = parse_expr(p);
        parse_consume(p, TOKEN_SEMICOLON);
        return ast_assign(expr, val);
    }
    
    parse_consume(p, TOKEN_SEMICOLON);
    return ast_expr_stmt(expr);
}

// if_stmt := 'if' '(' expr ')' block ('else' (block | if_stmt))?
func parse_if_stmt(p: i64) -> i64 {
    parse_consume(p, TOKEN_IF);
    parse_consume(p, TOKEN_LPAREN);
    var cond;
    cond = parse_expr(p);
    parse_consume(p, TOKEN_RPAREN);
    
    var then_blk;
    then_blk = parse_block(p);
    
    var else_blk;
    else_blk = 0;
    if (parse_match(p, TOKEN_ELSE)) {
        // Support `else if (...) { ... }` by parsing the nested if-statement and
        // wrapping it into a single-statement block.
        if (parse_peek_kind(p) == TOKEN_IF) {
            var else_stmt;
            else_stmt = parse_if_stmt(p);
            var stmts;
            stmts = vec_new(1);
            vec_push(stmts, else_stmt);
            else_blk = ast_block(stmts);
        } else {
            else_blk = parse_block(p);
        }
    }
    
    return ast_if(cond, then_blk, else_blk);
}

// while_stmt := 'while' '(' expr ')' block
func parse_while_stmt(p: i64) -> i64 {
    parse_consume(p, TOKEN_WHILE);
    parse_consume(p, TOKEN_LPAREN);
    var cond;
    cond = parse_expr(p);
    parse_consume(p, TOKEN_RPAREN);
    
    var body;
    body = parse_block(p);
    
    return ast_while(cond, body);
}

// for_stmt := 'for' '(' init? ';' cond? ';' update? ')' block
func parse_for_stmt(p: i64) -> i64 {
    parse_consume(p, TOKEN_FOR);
    parse_consume(p, TOKEN_LPAREN);
    
    var init;
    init = 0;
    if (parse_peek_kind(p) != TOKEN_SEMICOLON) {
        if (parse_peek_kind(p) == TOKEN_VAR) {
            init = parse_var_decl(p);
            // parse_var_decl already consumed semicolon
        } else {
            // Parse assignment or expression
            var lhs;
            lhs = parse_expr(p);
            if (parse_match(p, TOKEN_EQ)) {
                var rhs;
                rhs = parse_expr(p);
                init = ast_assign(lhs, rhs);
            } else {
                init = lhs;
            }
            parse_consume(p, TOKEN_SEMICOLON);
        }
    } else {
        parse_consume(p, TOKEN_SEMICOLON);
    }
    
    var cond;
    cond = 0;
    if (parse_peek_kind(p) != TOKEN_SEMICOLON) {
        cond = parse_expr(p);
    }
    parse_consume(p, TOKEN_SEMICOLON);
    
    var update;
    update = 0;
    if (parse_peek_kind(p) != TOKEN_RPAREN) {
        var upd_lhs;
        upd_lhs = parse_expr(p);
        if (parse_match(p, TOKEN_EQ)) {
            var upd_rhs;
            upd_rhs = parse_expr(p);
            update = ast_assign(upd_lhs, upd_rhs);
        } else {
            update = upd_lhs;
        }
    }
    parse_consume(p, TOKEN_RPAREN);
    
    var body;
    body = parse_block(p);
    
    return ast_for(init, cond, update, body);
}

// switch_stmt := 'switch' '(' expr ')' '{' case* '}'
// case := ('case' NUMBER ':' stmt*) | ('default' ':' stmt*)
func parse_switch_stmt(p: i64) -> i64 {
    parse_consume(p, TOKEN_SWITCH);
    parse_consume(p, TOKEN_LPAREN);
    var expr;
    expr = parse_expr(p);
    parse_consume(p, TOKEN_RPAREN);
    parse_consume(p, TOKEN_LBRACE);
    
    var cases;
    cases = vec_new(16);
    
    while (parse_peek_kind(p) != TOKEN_RBRACE) {
        if (parse_peek_kind(p) == TOKEN_EOF) { break; }
        
        var is_default;
        is_default = 0;
        var value;
        value = 0;
        
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
        
        var stmts;
        stmts = vec_new(8);
        while (parse_peek_kind(p) != TOKEN_CASE) {
            if (parse_peek_kind(p) == TOKEN_DEFAULT) { break; }
            if (parse_peek_kind(p) == TOKEN_RBRACE) { break; }
            if (parse_peek_kind(p) == TOKEN_EOF) { break; }
            vec_push(stmts, parse_stmt(p));
        }
        
        var case_body;
        case_body = ast_block(stmts);
        vec_push(cases, ast_case(value, case_body, is_default));
    }
    
    parse_consume(p, TOKEN_RBRACE);
    return ast_switch(expr, cases);
}

// break_stmt := 'break' ';'
func parse_break_stmt(p: i64) -> i64 {
    parse_consume(p, TOKEN_BREAK);
    parse_consume(p, TOKEN_SEMICOLON);
    return ast_break();
}

// asm_stmt := 'asm' '{' ... '}'
// Parses inline assembly block and stores raw assembly text with newlines
func parse_asm_stmt(p: i64) -> i64 {
    parse_consume(p, TOKEN_ASM);
    parse_consume(p, TOKEN_LBRACE);
    
    // Collect all tokens until closing brace as raw text
    var asm_text;
    asm_text = vec_new(256);
    
    var prev_line;
    prev_line = -1;
    
    while (parse_peek_kind(p) != TOKEN_RBRACE) {
        if (parse_peek_kind(p) == TOKEN_EOF) {
            emit_stderr("[ERROR] Unexpected EOF in asm block\n", 38);
            panic();
        }
        
        var tok;
        tok = parse_peek(p);
        var cur_line;
        cur_line = tok_line(tok);
        
        // Add newline if we moved to a new line
        if (prev_line >= 0) {
            if (cur_line > prev_line) {
                vec_push(asm_text, 10);  // newline
            } else {
                vec_push(asm_text, 32);  // space
            }
        }
        prev_line = cur_line;
        
        // Add token text
        var ptr;
        ptr = tok_ptr(tok);
        var len;
        len = tok_len(tok);
        var i;
        i = 0;
        while (i < len) {
            vec_push(asm_text, ptr8[ptr + i]);
            i = i + 1;
        }
        
        parse_adv(p);
    }
    
    parse_consume(p, TOKEN_RBRACE);
    
    return ast_asm(asm_text);
}

// return_stmt := 'return' expr? ';'
func parse_return_stmt(p: i64) -> i64 {
    parse_consume(p, TOKEN_RETURN);
    
    var expr;
    expr = 0;
    if (parse_peek_kind(p) != TOKEN_SEMICOLON) {
        expr = parse_expr(p);
    }
    
    parse_consume(p, TOKEN_SEMICOLON);
    return ast_return(expr);
}

// const_decl := 'const' IDENT '=' NUMBER ';'
func parse_const_decl(p: i64) -> i64 {
    parse_consume(p, TOKEN_CONST);
    
    var name_tok;
    name_tok = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    parse_consume(p, TOKEN_EQ);
    
    var val_tok;
    val_tok = parse_peek(p);
    parse_consume(p, TOKEN_NUMBER);
    
    var value;
    value = parse_num_val(val_tok);
    
    parse_consume(p, TOKEN_SEMICOLON);
    
    return ast_const_decl(tok_ptr(name_tok), tok_len(name_tok), value);
}

// import_decl := 'import' IDENT ('.' IDENT)* ';'
// Returns AST_IMPORT with path like "io" or "std/io"
func parse_import_decl(p: i64) -> i64 {
    parse_consume(p, TOKEN_IMPORT);
    
    // First identifier
    var first_tok;
    first_tok = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    var path_ptr;
    path_ptr = tok_ptr(first_tok);
    var path_len;
    path_len = tok_len(first_tok);
    
    // Handle dotted path: io.file -> io/file
    while (parse_match(p, TOKEN_DOT)) {
        var next_tok;
        next_tok = parse_peek(p);
        parse_consume(p, TOKEN_IDENTIFIER);
        
        // Concatenate: path + "/" + next
        var slash;
        slash = heap_alloc(1);
        ptr8[slash] = 47;  // '/'
        
        var tmp;
        tmp = str_concat(path_ptr, path_len, slash, 1);
        path_ptr = str_concat(tmp, path_len + 1, tok_ptr(next_tok), tok_len(next_tok));
        path_len = path_len + 1 + tok_len(next_tok);
    }
    
    parse_consume(p, TOKEN_SEMICOLON);
    
    return ast_import(path_ptr, path_len);
}

func parse_stmt(p: i64) -> i64 {
    var k;
    k = parse_peek_kind(p);
    
    if (k == TOKEN_VAR) { return parse_var_decl(p); }
    if (k == TOKEN_IF) { return parse_if_stmt(p); }
    if (k == TOKEN_WHILE) { return parse_while_stmt(p); }
    if (k == TOKEN_FOR) { return parse_for_stmt(p); }
    if (k == TOKEN_SWITCH) { return parse_switch_stmt(p); }
    if (k == TOKEN_BREAK) { return parse_break_stmt(p); }
    if (k == TOKEN_ASM) { return parse_asm_stmt(p); }
    if (k == TOKEN_RETURN) { return parse_return_stmt(p); }
    
    return parse_assign_or_expr(p);
}

func parse_block(p: i64) -> i64 {
    parse_consume(p, TOKEN_LBRACE);
    
    var stmts;
    stmts = vec_new(16);
    
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

// param := IDENT (':' type)?
func parse_param(p: i64) -> i64 {
    var name_tok;
    name_tok = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    var type_kind;
    var ptr_depth;
    type_kind = 0;  // default: i64
    ptr_depth = 0;
    
    // Type annotation is optional
    if (parse_match(p, TOKEN_COLON)) {
        var ty;
        ty = parse_type(p);
        type_kind = ptr64[ty];
        ptr_depth = ptr64[ty + 8];
    }
    
    // Return: [name_ptr, name_len, type_kind, ptr_depth]
    var param;
    param = heap_alloc(32);
    ptr64[param] = tok_ptr(name_tok);
    ptr64[param + 8] = tok_len(name_tok);
    ptr64[param + 16] = type_kind;
    ptr64[param + 24] = ptr_depth;
    return param;
}

// func := 'func' IDENT '(' params? ')' ('->' type)? block
func parse_func_decl(p: i64) -> i64 {
    parse_consume(p, TOKEN_FUNC);
    
    var name_tok;
    name_tok = parse_peek(p);
    parse_consume(p, TOKEN_IDENTIFIER);
    
    parse_consume(p, TOKEN_LPAREN);
    
    var params;
    params = vec_new(8);
    
    if (parse_peek_kind(p) != TOKEN_RPAREN) {
        vec_push(params, parse_param(p));
        while (parse_match(p, TOKEN_COMMA)) {
            vec_push(params, parse_param(p));
        }
    }
    
    parse_consume(p, TOKEN_RPAREN);
    
    // Optional return type: -> type
    var ret_type;
    var ret_ptr_depth;
    ret_type = TYPE_VOID;
    ret_ptr_depth = 0;
    
    if (parse_match(p, TOKEN_ARROW)) {
        var ty;
        ty = parse_type(p);
        ret_type = ptr64[ty];
        ret_ptr_depth = ptr64[ty + 8];
    }
    
    var body;
    body = parse_block(p);
    
    return ast_func(tok_ptr(name_tok), tok_len(name_tok), params, ret_type, body);
}

// ============================================
// Program Parsing
// ============================================

func parse_program(p) {
    var funcs;
    funcs = vec_new(16);
    var consts;
    consts = vec_new(64);
    var imports;
    imports = vec_new(16);
    var globals;
    globals = vec_new(32);
    
    while (parse_peek_kind(p) != TOKEN_EOF) {
        var k;
        k = parse_peek_kind(p);
        if (k == TOKEN_FUNC) {
            vec_push(funcs, parse_func_decl(p));
        } else if (k == TOKEN_CONST) {
            vec_push(consts, parse_const_decl(p));
        } else if (k == TOKEN_VAR) {
            // Parse global var declaration
            parse_consume(p, TOKEN_VAR);
            var tok;
            tok = parse_peek(p);
            var name_ptr;
            name_ptr = tok_ptr(tok);
            var name_len;
            name_len = tok_len(tok);
            parse_consume(p, TOKEN_IDENTIFIER);
            parse_consume(p, TOKEN_SEMICOLON);
            // Store global var info: [name_ptr, name_len]
            var ginfo;
            ginfo = heap_alloc(16);
            ptr64[ginfo] = name_ptr;
            ptr64[ginfo + 8] = name_len;
            vec_push(globals, ginfo);
        } else if (k == TOKEN_IMPORT) {
            vec_push(imports, parse_import_decl(p));
        } else {
            emit_stderr("[ERROR] Expected function, const, or import\n", 45);
            break;
        }
    }
    
    var prog;
    prog = ast_program(funcs, consts, imports);
    ptr64[prog + 32] = globals;
    return prog;
}

