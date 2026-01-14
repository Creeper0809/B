// ast.b - AST node constructors for v3.8

import std.io;
import types;

// ============================================
// Expression Nodes
// ============================================

// AST Literal node layout (16 bytes)
// NOTE: 기존 포인터 산술 레이아웃([kind, value])과 동일하게 유지한다.
struct AstLiteral {
    kind: u64;
    value: u64;
}

// AST_LITERAL: [kind, value]
func ast_literal(val: u64) -> u64 {
    var n: *AstLiteral = (*AstLiteral)(heap_alloc(16));
    n->kind = AST_LITERAL;
    n->value = val;
    return (u64)n;
}

// AST_IDENT: [kind, name_ptr, name_len]
func ast_ident(name_ptr: u64, name_len: u64) -> u64 {
    var n: u64 = heap_alloc(24);
    *(n) = AST_IDENT;
    *(n + 8) = name_ptr;
    *(n + 16) = name_len;
    return n;
}

// AST_STRING: [kind, str_ptr, str_len]
func ast_string(str_ptr: u64, str_len: u64) -> u64 {
    var n: u64 = heap_alloc(24);
    *(n) = AST_STRING;
    *(n + 8) = str_ptr;
    *(n + 16) = str_len;
    return n;
}

// AST_BINARY: [kind, op, left, right]
func ast_binary(op: u64, left: u64, right: u64) -> u64 {
    var n: u64 = heap_alloc(32);
    *(n) = AST_BINARY;
    *(n + 8) = op;
    *(n + 16) = left;
    *(n + 24) = right;
    return n;
}

// AST_UNARY: [kind, op, operand]
func ast_unary(op: u64, operand: u64) -> u64 {
    var n: u64 = heap_alloc(24);
    *(n) = AST_UNARY;
    *(n + 8) = op;
    *(n + 16) = operand;
    return n;
}

// AST_CALL: [kind, name_ptr, name_len, args_vec]
func ast_call(name_ptr: u64, name_len: u64, args: u64) -> u64 {
    var n: u64 = heap_alloc(32);
    *(n) = AST_CALL;
    *(n + 8) = name_ptr;
    *(n + 16) = name_len;
    *(n + 24) = args;
    return n;
}

// AST_ADDR_OF: [kind, operand]
func ast_addr_of(operand: u64) -> u64 {
    var n: u64 = heap_alloc(16);
    *(n) = AST_ADDR_OF;
    *(n + 8) = operand;
    return n;
}

// AST_DEREF: [kind, operand]
func ast_deref(operand: u64) -> u64 {
    var n: u64 = heap_alloc(16);
    *(n) = AST_DEREF;
    *(n + 8) = operand;
    return n;
}

// AST_DEREF8: [kind, operand] - byte dereference
func ast_deref8(operand: u64) -> u64 {
    var n: u64 = heap_alloc(16);
    *(n) = AST_DEREF8;
    *(n + 8) = operand;
    return n;
}

// AST_CAST: [kind, expr, target_type, target_ptr_depth]
func ast_cast(expr: u64, target_type: u64, ptr_depth: u64) -> u64 {
    var n: u64 = heap_alloc(32);
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
func ast_return(expr: u64) -> u64 {
    var n: u64 = heap_alloc(16);
    *(n) = AST_RETURN;
    *(n + 8) = expr;
    return n;
}

// AST_VAR_DECL: [kind, name_ptr, name_len, type_kind, ptr_depth, init_expr]
func ast_var_decl(name_ptr: u64, name_len: u64, type_kind: u64, ptr_depth: u64, init: u64) -> u64 {
    var n: u64 = heap_alloc(64);
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
func ast_const_decl(name_ptr: u64, name_len: u64, value: u64) -> u64 {
    var n: u64 = heap_alloc(32);
    *(n) = AST_CONST_DECL;
    *(n + 8) = name_ptr;
    *(n + 16) = name_len;
    *(n + 24) = value;
    return n;
}

// AST_ASSIGN: [kind, target, value]
func ast_assign(target: u64, value: u64) -> u64 {
    var n: u64 = heap_alloc(24);
    *(n) = AST_ASSIGN;
    *(n + 8) = target;
    *(n + 16) = value;
    return n;
}

// AST_EXPR_STMT: [kind, expr]
func ast_expr_stmt(expr: u64) -> u64 {
    var n: u64 = heap_alloc(16);
    *(n) = AST_EXPR_STMT;
    *(n + 8) = expr;
    return n;
}

// AST_IF: [kind, cond, then_block, else_block]
func ast_if(cond: u64, then_blk: u64, else_blk: u64) -> u64 {
    var n: u64 = heap_alloc(32);
    *(n) = AST_IF;
    *(n + 8) = cond;
    *(n + 16) = then_blk;
    *(n + 24) = else_blk;
    return n;
}

// AST_WHILE: [kind, cond, body]
func ast_while(cond: u64, body: u64) -> u64 {
    var n: u64 = heap_alloc(24);
    *(n) = AST_WHILE;
    *(n + 8) = cond;
    *(n + 16) = body;
    return n;
}

// AST_FOR: [kind, init, cond, update, body]
func ast_for(init: u64, cond: u64, update: u64, body: u64) -> u64 {
    var n: u64 = heap_alloc(40);
    *(n) = AST_FOR;
    *(n + 8) = init;
    *(n + 16) = cond;
    *(n + 24) = update;
    *(n + 32) = body;
    return n;
}

// AST_SWITCH: [kind, expr, cases_vec]
func ast_switch(expr: u64, cases: u64) -> u64 {
    var n: u64 = heap_alloc(24);
    *(n) = AST_SWITCH;
    *(n + 8) = expr;
    *(n + 16) = cases;
    return n;
}

// AST_CASE: [kind, value, body, is_default]
func ast_case(value: u64, body: u64, is_default: u64) -> u64 {
    var n: u64 = heap_alloc(32);
    *(n) = AST_CASE;
    *(n + 8) = value;
    *(n + 16) = body;
    *(n + 24) = is_default;
    return n;
}

// AST_BREAK: [kind]
func ast_break() -> u64 {
    var n: u64 = heap_alloc(8);
    *(n) = AST_BREAK;
    return n;
}
// AST_CONTINUE: [kind]
func ast_continue() -> u64 {
    var n: u64 = heap_alloc(8);
    *(n) = AST_CONTINUE;
    return n;
}
// AST_ASM: [kind, text_vec]
func ast_asm(text_vec: u64) -> u64 {
    var n: u64 = heap_alloc(16);
    *(n) = AST_ASM;
    *(n + 8) = text_vec;
    return n;
}

// AST_BLOCK: [kind, stmts_vec]
func ast_block(stmts: u64) -> u64 {
    var n: u64 = heap_alloc(16);
    *(n) = AST_BLOCK;
    *(n + 8) = stmts;
    return n;
}

// ============================================
// Top-level Nodes
// ============================================

// AST_FUNC: [kind, name_ptr, name_len, params_vec, ret_type, body]
// AST_FUNC: [kind, name_ptr, name_len, params, ret_type, body, ret_ptr_depth, ret_struct_name_ptr, ret_struct_name_len]
// Legacy ast_func() now creates 72-byte nodes with extra fields zeroed for compatibility
func ast_func(name_ptr: u64, name_len: u64, params: u64, ret_type: u64, body: u64) -> u64 {
    var n: u64 = heap_alloc(72);
    *(n) = AST_FUNC;
    *(n + 8) = name_ptr;
    *(n + 16) = name_len;
    *(n + 24) = params;
    *(n + 32) = ret_type;
    *(n + 40) = body;
    *(n + 48) = 0;  // ret_ptr_depth = 0
    *(n + 56) = 0;  // ret_struct_name_ptr = 0
    *(n + 64) = 0;  // ret_struct_name_len = 0
    return n;
}

// AST_FUNC (extended): [kind, name_ptr, name_len, params, ret_type, body, ret_ptr_depth, ret_struct_name_ptr, ret_struct_name_len]
func ast_func_ex(name_ptr: u64, name_len: u64, params: u64, ret_type: u64, ret_ptr_depth: u64, ret_struct_name_ptr: u64, ret_struct_name_len: u64, body: u64) -> u64 {
    var n: u64 = heap_alloc(72);
    *(n) = AST_FUNC;
    *(n + 8) = name_ptr;
    *(n + 16) = name_len;
    *(n + 24) = params;
    *(n + 32) = ret_type;
    *(n + 40) = body;
    *(n + 48) = ret_ptr_depth;
    *(n + 56) = ret_struct_name_ptr;
    *(n + 64) = ret_struct_name_len;
    return n;
}

// AST_PROGRAM: [kind, funcs_vec, consts_vec, imports_vec, globals_vec]
func ast_program(funcs: u64, consts: u64, imports: u64) -> u64 {
    var n: u64 = heap_alloc(48);
    *(n) = AST_PROGRAM;
    *(n + 8) = funcs;
    *(n + 16) = consts;
    *(n + 24) = imports;
    *(n + 32) = 0;    // globals (will be set by parse_program)
    *(n + 40) = 0;    // structs (will be set by parse_program)
    return n;
}

// AST_IMPORT: [kind, path_ptr, path_len]
func ast_import(path_ptr: u64, path_len: u64) -> u64 {
    var n: u64 = heap_alloc(24);
    *(n) = AST_IMPORT;
    *(n + 8) = path_ptr;
    *(n + 16) = path_len;
    return n;
}

// AST_STRUCT_DEF: [kind, name_ptr, name_len, fields_vec]
func ast_struct_def(name_ptr: u64, name_len: u64, fields: u64) -> u64 {
    var n: u64 = heap_alloc(32);
    *(n) = AST_STRUCT_DEF;
    *(n + 8) = name_ptr;
    *(n + 16) = name_len;
    *(n + 24) = fields;
    return n;
}

// AST_MEMBER_ACCESS: [kind, object, member_ptr, member_len]
func ast_member_access(object: u64, member_ptr: u64, member_len: u64) -> u64 {
    var n: u64 = heap_alloc(32);
    *(n) = AST_MEMBER_ACCESS;
    *(n + 8) = object;
    *(n + 16) = member_ptr;
    *(n + 24) = member_len;
    return n;
}

// AST_STRUCT_LITERAL: struct_def_ptr, values (vec of exprs)
// Layout: [kind:8][struct_def:8][values:8]
func ast_struct_literal(struct_def: u64, values: u64) -> u64 {
    var n: u64 = heap_alloc(24);
    *(n) = AST_STRUCT_LITERAL;
    *(n + 8) = struct_def;
    *(n + 16) = values;
    return n;
}

// ============================================
// AST Accessors
// ============================================

func ast_kind(n: u64) -> u64 { return *(n); }
