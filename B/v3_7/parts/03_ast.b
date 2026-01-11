// v3.6 Compiler - Part 3: AST Node Constructors
// All AST nodes use heap-allocated arrays

// ============================================
// Expression Nodes
// ============================================

// AST_LITERAL: [kind, value]
func ast_literal(val: i64) -> i64 {
    var n;
    n = heap_alloc(16);
    ptr64[n] = AST_LITERAL;
    ptr64[n + 8] = val;
    return n;
}

// AST_IDENT: [kind, name_ptr, name_len]
func ast_ident(name_ptr: i64, name_len: i64) -> i64 {
    var n;
    n = heap_alloc(24);
    ptr64[n] = AST_IDENT;
    ptr64[n + 8] = name_ptr;
    ptr64[n + 16] = name_len;
    return n;
}

// AST_STRING: [kind, str_ptr, str_len]
// str_ptr points to the opening quote, str_len includes quotes
func ast_string(str_ptr: i64, str_len: i64) -> i64 {
    var n;
    n = heap_alloc(24);
    ptr64[n] = AST_STRING;
    ptr64[n + 8] = str_ptr;
    ptr64[n + 16] = str_len;
    return n;
}

// AST_BINARY: [kind, op, left, right]
func ast_binary(op: i64, left: i64, right: i64) -> i64 {
    var n;
    n = heap_alloc(32);
    ptr64[n] = AST_BINARY;
    ptr64[n + 8] = op;
    ptr64[n + 16] = left;
    ptr64[n + 24] = right;
    return n;
}

// AST_UNARY: [kind, op, operand]
func ast_unary(op: i64, operand: i64) -> i64 {
    var n;
    n = heap_alloc(24);
    ptr64[n] = AST_UNARY;
    ptr64[n + 8] = op;
    ptr64[n + 16] = operand;
    return n;
}

// AST_CALL: [kind, name_ptr, name_len, args_vec]
func ast_call(name_ptr: i64, name_len: i64, args: i64) -> i64 {
    var n;
    n = heap_alloc(32);
    ptr64[n] = AST_CALL;
    ptr64[n + 8] = name_ptr;
    ptr64[n + 16] = name_len;
    ptr64[n + 24] = args;
    return n;
}

// AST_ADDR_OF: [kind, operand]
func ast_addr_of(operand: i64) -> i64 {
    var n;
    n = heap_alloc(16);
    ptr64[n] = AST_ADDR_OF;
    ptr64[n + 8] = operand;
    return n;
}

// AST_DEREF: [kind, operand]
func ast_deref(operand: i64) -> i64 {
    var n;
    n = heap_alloc(16);
    ptr64[n] = AST_DEREF;
    ptr64[n + 8] = operand;
    return n;
}

// AST_DEREF8: [kind, operand] - byte dereference
func ast_deref8(operand: i64) -> i64 {
    var n;
    n = heap_alloc(16);
    ptr64[n] = AST_DEREF8;
    ptr64[n + 8] = operand;
    return n;
}

// ast_index removed - use *ptr dereference instead

// AST_CAST: [kind, expr, target_type, target_ptr_depth]
func ast_cast(expr: i64, target_type: i64, ptr_depth: i64) -> i64 {
    var n;
    n = heap_alloc(32);
    ptr64[n] = AST_CAST;
    ptr64[n + 8] = expr;
    ptr64[n + 16] = target_type;
    ptr64[n + 24] = ptr_depth;
    return n;
}

// ============================================
// Statement Nodes
// ============================================

// AST_RETURN: [kind, expr]
func ast_return(expr: i64) -> i64 {
    var n;
    n = heap_alloc(16);
    ptr64[n] = AST_RETURN;
    ptr64[n + 8] = expr;
    return n;
}

// AST_VAR_DECL: [kind, name_ptr, name_len, type_kind, ptr_depth, init_expr]
func ast_var_decl(name_ptr: i64, name_len: i64, type_kind: i64, ptr_depth: i64, init: i64) -> i64 {
    var n;
    n = heap_alloc(48);
    ptr64[n] = AST_VAR_DECL;
    ptr64[n + 8] = name_ptr;
    ptr64[n + 16] = name_len;
    ptr64[n + 24] = type_kind;
    ptr64[n + 32] = ptr_depth;
    ptr64[n + 40] = init;
    return n;
}

// AST_CONST_DECL: [kind, name_ptr, name_len, value]
func ast_const_decl(name_ptr: i64, name_len: i64, value: i64) -> i64 {
    var n;
    n = heap_alloc(32);
    ptr64[n] = AST_CONST_DECL;
    ptr64[n + 8] = name_ptr;
    ptr64[n + 16] = name_len;
    ptr64[n + 24] = value;
    return n;
}

// AST_ASSIGN: [kind, target, value]
func ast_assign(target: i64, value: i64) -> i64 {
    var n;
    n = heap_alloc(24);
    ptr64[n] = AST_ASSIGN;
    ptr64[n + 8] = target;
    ptr64[n + 16] = value;
    return n;
}

// AST_EXPR_STMT: [kind, expr]
func ast_expr_stmt(expr: i64) -> i64 {
    var n;
    n = heap_alloc(16);
    ptr64[n] = AST_EXPR_STMT;
    ptr64[n + 8] = expr;
    return n;
}

// AST_IF: [kind, cond, then_block, else_block]
func ast_if(cond: i64, then_blk: i64, else_blk: i64) -> i64 {
    var n;
    n = heap_alloc(32);
    ptr64[n] = AST_IF;
    ptr64[n + 8] = cond;
    ptr64[n + 16] = then_blk;
    ptr64[n + 24] = else_blk;
    return n;
}

// AST_WHILE: [kind, cond, body]
func ast_while(cond: i64, body: i64) -> i64 {
    var n;
    n = heap_alloc(24);
    ptr64[n] = AST_WHILE;
    ptr64[n + 8] = cond;
    ptr64[n + 16] = body;
    return n;
}

// AST_FOR: [kind, init, cond, update, body]
func ast_for(init: i64, cond: i64, update: i64, body: i64) -> i64 {
    var n;
    n = heap_alloc(40);
    ptr64[n] = AST_FOR;
    ptr64[n + 8] = init;
    ptr64[n + 16] = cond;
    ptr64[n + 24] = update;
    ptr64[n + 32] = body;
    return n;
}

// AST_SWITCH: [kind, expr, cases_vec]
func ast_switch(expr: i64, cases: i64) -> i64 {
    var n;
    n = heap_alloc(24);
    ptr64[n] = AST_SWITCH;
    ptr64[n + 8] = expr;
    ptr64[n + 16] = cases;
    return n;
}

// AST_CASE: [kind, value, body, is_default]
func ast_case(value: i64, body: i64, is_default: i64) -> i64 {
    var n;
    n = heap_alloc(32);
    ptr64[n] = AST_CASE;
    ptr64[n + 8] = value;
    ptr64[n + 16] = body;
    ptr64[n + 24] = is_default;
    return n;
}

// AST_BREAK: [kind]
func ast_break() -> i64 {
    var n;
    n = heap_alloc(8);
    ptr64[n] = AST_BREAK;
    return n;
}

// AST_ASM: [kind, text_vec]
func ast_asm(text_vec: i64) -> i64 {
    var n;
    n = heap_alloc(16);
    ptr64[n] = AST_ASM;
    ptr64[n + 8] = text_vec;
    return n;
}

// AST_BLOCK: [kind, stmts_vec]
func ast_block(stmts: i64) -> i64 {
    var n;
    n = heap_alloc(16);
    ptr64[n] = AST_BLOCK;
    ptr64[n + 8] = stmts;
    return n;
}

// ============================================
// Top-level Nodes
// ============================================

// AST_FUNC: [kind, name_ptr, name_len, params_vec, ret_type, body]
func ast_func(name_ptr: i64, name_len: i64, params: i64, ret_type: i64, body: i64) -> i64 {
    var n;
    n = heap_alloc(48);
    ptr64[n] = AST_FUNC;
    ptr64[n + 8] = name_ptr;
    ptr64[n + 16] = name_len;
    ptr64[n + 24] = params;
    ptr64[n + 32] = ret_type;
    ptr64[n + 40] = body;
    return n;
}

// AST_PROGRAM: [kind, funcs_vec, consts_vec, imports_vec, globals_vec]
func ast_program(funcs: i64, consts: i64, imports: i64) -> i64 {
    var n;
    n = heap_alloc(40);
    ptr64[n] = AST_PROGRAM;
    ptr64[n + 8] = funcs;
    ptr64[n + 16] = consts;
    ptr64[n + 24] = imports;
    ptr64[n + 32] = 0;  // globals (set by caller if needed)
    return n;
}

// AST_IMPORT: [kind, path_ptr, path_len]
// path is like "io" or "std/io"
func ast_import(path_ptr: i64, path_len: i64) -> i64 {
    var n;
    n = heap_alloc(24);
    ptr64[n] = AST_IMPORT;
    ptr64[n + 8] = path_ptr;
    ptr64[n + 16] = path_len;
    return n;
}

// ============================================
// AST Accessors
// ============================================

func ast_kind(n: i64) -> i64 { return ptr64[n]; }

