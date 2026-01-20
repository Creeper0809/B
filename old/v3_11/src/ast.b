// ast.b - AST node constructors for v3.8

import std.io;
import types;

// ============================================
// Expression Nodes
// ============================================

// AST_LITERAL: [kind, value]
func ast_literal(val) {
    var n = heap_alloc(16);
    *(n) = AST_LITERAL;
    *(n + 8) = val;
    return n;
}

// AST_IDENT: [kind, name_ptr, name_len]
func ast_ident(name_ptr, name_len) {
    var n = heap_alloc(24);
    *(n) = AST_IDENT;
    *(n + 8) = name_ptr;
    *(n + 16) = name_len;
    return n;
}

// AST_STRING: [kind, str_ptr, str_len]
func ast_string(str_ptr, str_len) {
    var n = heap_alloc(24);
    *(n) = AST_STRING;
    *(n + 8) = str_ptr;
    *(n + 16) = str_len;
    return n;
}

// AST_BINARY: [kind, op, left, right]
func ast_binary(op, left, right) {
    var n = heap_alloc(32);
    *(n) = AST_BINARY;
    *(n + 8) = op;
    *(n + 16) = left;
    *(n + 24) = right;
    return n;
}

// AST_UNARY: [kind, op, operand]
func ast_unary(op, operand) {
    var n = heap_alloc(24);
    *(n) = AST_UNARY;
    *(n + 8) = op;
    *(n + 16) = operand;
    return n;
}

// AST_CALL: [kind, name_ptr, name_len, args_vec]
func ast_call(name_ptr, name_len, args) {
    var n = heap_alloc(32);
    *(n) = AST_CALL;
    *(n + 8) = name_ptr;
    *(n + 16) = name_len;
    *(n + 24) = args;
    return n;
}

// AST_ADDR_OF: [kind, operand]
func ast_addr_of(operand) {
    var n = heap_alloc(16);
    *(n) = AST_ADDR_OF;
    *(n + 8) = operand;
    return n;
}

// AST_DEREF: [kind, operand]
func ast_deref(operand) {
    var n = heap_alloc(16);
    *(n) = AST_DEREF;
    *(n + 8) = operand;
    return n;
}

// AST_DEREF8: [kind, operand] - byte dereference
func ast_deref8(operand) {
    var n = heap_alloc(16);
    *(n) = AST_DEREF8;
    *(n + 8) = operand;
    return n;
}

// AST_CAST: [kind, expr, target_type, target_ptr_depth]
func ast_cast(expr, target_type, ptr_depth) {
    var n = heap_alloc(32);
    *(n) = AST_CAST;
    *(n + 8) = expr;
    *(n + 16) = target_type;
    *(n + 24) = ptr_depth;
    return n;
}

// ============================================
// Statement Nodes
// ============================================

// AST_RETURN: [kind, expr]
func ast_return(expr) {
    var n = heap_alloc(16);
    *(n) = AST_RETURN;
    *(n + 8) = expr;
    return n;
}

// AST_VAR_DECL: [kind, name_ptr, name_len, type_kind, ptr_depth, init_expr]
func ast_var_decl(name_ptr, name_len, type_kind, ptr_depth, init) {
    var n = heap_alloc(64);
    *(n) = AST_VAR_DECL;
    *(n + 8) = name_ptr;
    *(n + 16) = name_len;
    *(n + 24) = type_kind;
    *(n + 32) = ptr_depth;
    *(n + 40) = init;
    *(n + 48) = 0;  // struct_name_ptr (will be set if TYPE_STRUCT)
    *(n + 56) = 0;  // struct_name_len
    return n;
}

// AST_CONST_DECL: [kind, name_ptr, name_len, value]
func ast_const_decl(name_ptr, name_len, value) {
    var n = heap_alloc(32);
    *(n) = AST_CONST_DECL;
    *(n + 8) = name_ptr;
    *(n + 16) = name_len;
    *(n + 24) = value;
    return n;
}

// AST_ASSIGN: [kind, target, value]
func ast_assign(target, value) {
    var n = heap_alloc(24);
    *(n) = AST_ASSIGN;
    *(n + 8) = target;
    *(n + 16) = value;
    return n;
}

// AST_EXPR_STMT: [kind, expr]
func ast_expr_stmt(expr) {
    var n = heap_alloc(16);
    *(n) = AST_EXPR_STMT;
    *(n + 8) = expr;
    return n;
}

// AST_IF: [kind, cond, then_block, else_block]
func ast_if(cond, then_blk, else_blk) {
    var n = heap_alloc(32);
    *(n) = AST_IF;
    *(n + 8) = cond;
    *(n + 16) = then_blk;
    *(n + 24) = else_blk;
    return n;
}

// AST_WHILE: [kind, cond, body]
func ast_while(cond, body) {
    var n = heap_alloc(24);
    *(n) = AST_WHILE;
    *(n + 8) = cond;
    *(n + 16) = body;
    return n;
}

// AST_FOR: [kind, init, cond, update, body]
func ast_for(init, cond, update, body) {
    var n = heap_alloc(40);
    *(n) = AST_FOR;
    *(n + 8) = init;
    *(n + 16) = cond;
    *(n + 24) = update;
    *(n + 32) = body;
    return n;
}

// AST_SWITCH: [kind, expr, cases_vec]
func ast_switch(expr, cases) {
    var n = heap_alloc(24);
    *(n) = AST_SWITCH;
    *(n + 8) = expr;
    *(n + 16) = cases;
    return n;
}

// AST_CASE: [kind, value, body, is_default]
func ast_case(value, body, is_default) {
    var n = heap_alloc(32);
    *(n) = AST_CASE;
    *(n + 8) = value;
    *(n + 16) = body;
    *(n + 24) = is_default;
    return n;
}

// AST_BREAK: [kind]
func ast_break() {
    var n = heap_alloc(8);
    *(n) = AST_BREAK;
    return n;
}
// AST_CONTINUE: [kind]
func ast_continue() {
    var n = heap_alloc(8);
    *(n) = AST_CONTINUE;
    return n;
}
// AST_ASM: [kind, text_vec]
func ast_asm(text_vec) {
    var n = heap_alloc(16);
    *(n) = AST_ASM;
    *(n + 8) = text_vec;
    return n;
}

// AST_BLOCK: [kind, stmts_vec]
func ast_block(stmts) {
    var n = heap_alloc(16);
    *(n) = AST_BLOCK;
    *(n + 8) = stmts;
    return n;
}

// ============================================
// Top-level Nodes
// ============================================

// AST_FUNC: [kind, name_ptr, name_len, params_vec, ret_type, body]
func ast_func(name_ptr, name_len, params, ret_type, body) {
    var n = heap_alloc(48);
    *(n) = AST_FUNC;
    *(n + 8) = name_ptr;
    *(n + 16) = name_len;
    *(n + 24) = params;
    *(n + 32) = ret_type;
    *(n + 40) = body;
    return n;
}

// AST_PROGRAM: [kind, funcs_vec, consts_vec, imports_vec, globals_vec]
func ast_program(funcs, consts, imports) {
    var n = heap_alloc(48);
    *(n) = AST_PROGRAM;
    *(n + 8) = funcs;
    *(n + 16) = consts;
    *(n + 24) = imports;
    *(n + 32) = 0;    // globals (will be set by parse_program)
    *(n + 40) = 0;    // structs (will be set by parse_program)
    return n;
}

// AST_IMPORT: [kind, path_ptr, path_len]
func ast_import(path_ptr, path_len) {
    var n = heap_alloc(24);
    *(n) = AST_IMPORT;
    *(n + 8) = path_ptr;
    *(n + 16) = path_len;
    return n;
}

// AST_STRUCT_DEF: [kind, name_ptr, name_len, fields_vec]
func ast_struct_def(name_ptr, name_len, fields) {
    var n = heap_alloc(32);
    *(n) = AST_STRUCT_DEF;
    *(n + 8) = name_ptr;
    *(n + 16) = name_len;
    *(n + 24) = fields;
    return n;
}

// AST_MEMBER_ACCESS: [kind, object, member_ptr, member_len]
func ast_member_access(object, member_ptr, member_len) {
    var n = heap_alloc(32);
    *(n) = AST_MEMBER_ACCESS;
    *(n + 8) = object;
    *(n + 16) = member_ptr;
    *(n + 24) = member_len;
    return n;
}

// AST_STRUCT_LITERAL: struct_def_ptr, values (vec of exprs)
// Layout: [kind:8][struct_def:8][values:8]
func ast_struct_literal(struct_def, values) {
    var n = heap_alloc(24);
    *(n) = AST_STRUCT_LITERAL;
    *(n + 8) = struct_def;
    *(n + 16) = values;
    return n;
}

// ============================================
// AST Accessors
// ============================================

func ast_kind(n) { return *(n); }
