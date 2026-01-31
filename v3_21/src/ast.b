// ast.b - AST node constructors for v3.8

import std.io;
import types;

// ============================================
// Expression Nodes
// ============================================

// AST Literal node layout (16 bytes)
const SIZEOF_AST_LITERAL = 16;
struct AstLiteral {
    kind: u64;
    value: u64;
}

// AST Identifier node layout (24 bytes)
const SIZEOF_AST_IDENT = 24;
struct AstIdent {
    kind: u64;
    name_ptr: u64;
    name_len: u64;
}

// AST String node layout (24 bytes)
const SIZEOF_AST_STRING = 24;
struct AstString {
    kind: u64;
    str_ptr: u64;
    str_len: u64;
}

// AST Binary operation node layout (32 bytes)
const SIZEOF_AST_BINARY = 32;
struct AstBinary {
    kind: u64;
    op: u64;
    left: u64;
    right: u64;
}

// AST Unary operation node layout (24 bytes)
const SIZEOF_AST_UNARY = 24;
struct AstUnary {
    kind: u64;
    op: u64;
    operand: u64;
}

// AST Function call node layout (32 bytes)
const SIZEOF_AST_CALL = 32;
struct AstCall {
    kind: u64;
    name_ptr: u64;
    name_len: u64;
    args_vec: u64;
}

// AST Function pointer call node layout (24 bytes)
const SIZEOF_AST_CALL_PTR = 24;
struct AstCallPtr {
    kind: u64;
    callee: u64;
    args_vec: u64;
}

// AST_LITERAL: [kind, value]
func ast_literal(val: u64) -> u64 {
    var n: *AstLiteral = (*AstLiteral)(heap_alloc(sizeof(AstLiteral)));
    n->kind = AST_LITERAL;
    n->value = val;
    return (u64)n;
}

// AST_IDENT: [kind, name_ptr, name_len]
func ast_ident(name_ptr: u64, name_len: u64) -> u64 {
    var n: *AstIdent = (*AstIdent)(heap_alloc(sizeof(AstIdent)));
    n->kind = AST_IDENT;
    n->name_ptr = name_ptr;
    n->name_len = name_len;
    return (u64)n;
}

// AST_STRING: [kind, str_ptr, str_len]
func ast_string(str_ptr: u64, str_len: u64) -> u64 {
    var n: *AstString = (*AstString)(heap_alloc(sizeof(AstString)));
    n->kind = AST_STRING;
    n->str_ptr = str_ptr;
    n->str_len = str_len;
    return (u64)n;
}

// AST_BINARY: [kind, op, left, right]
func ast_binary(op: u64, left: u64, right: u64) -> u64 {
    var n: *AstBinary = (*AstBinary)(heap_alloc(sizeof(AstBinary)));
    n->kind = AST_BINARY;
    n->op = op;
    n->left = left;
    n->right = right;
    return (u64)n;
}

// AST_UNARY: [kind, op, operand]
func ast_unary(op: u64, operand: u64) -> u64 {
    var n: *AstUnary = (*AstUnary)(heap_alloc(sizeof(AstUnary)));
    n->kind = AST_UNARY;
    n->op = op;
    n->operand = operand;
    return (u64)n;
}

// AST_CALL: [kind, name_ptr, name_len, args_vec]
func ast_call(name_ptr: u64, name_len: u64, args: u64) -> u64 {
    var n: *AstCall = (*AstCall)(heap_alloc(sizeof(AstCall)));
    n->kind = AST_CALL;
    n->name_ptr = name_ptr;
    n->name_len = name_len;
    n->args_vec = args;
    return (u64)n;
}

// AST Address-of node layout (16 bytes)

const SIZEOF_AST_ADDR_OF = 16;
struct AstAddrOf {
    kind: u64;
    operand: u64;
}

// AST Dereference node layout (16 bytes)
const SIZEOF_AST_DEREF = 16;
struct AstDeref {
    kind: u64;
    operand: u64;
}

// AST Byte dereference node layout (16 bytes)
const SIZEOF_AST_DEREF8 = 16;
struct AstDeref8 {
    kind: u64;
    operand: u64;
}

// AST Index node layout (24 bytes)
const SIZEOF_AST_INDEX = 24;
struct AstIndex {
    kind: u64;
    base: u64;
    index: u64;
}

// AST Slice literal node layout (24 bytes)
const SIZEOF_AST_SLICE = 24;
struct AstSlice {
    kind: u64;
    ptr_expr: u64;
    len_expr: u64;
}

// AST Cast node layout (72 bytes)
const SIZEOF_AST_CAST = 72;
struct AstCast {
    kind: u64;
    expr: u64;
    target_type: u64;
    target_ptr_depth: u64;
    target_is_tagged: u64;
    struct_name_ptr: u64;
    struct_name_len: u64;
    tag_layout_ptr: u64;
    tag_layout_len: u64;
}

// AST Sizeof node layout (40 bytes)
const SIZEOF_AST_SIZEOF = 40;
struct AstSizeof {
    kind: u64;
    type_kind: u64;
    ptr_depth: u64;
    struct_name_ptr: u64;
    struct_name_len: u64;
}

// AST Sizeof Expr node layout (16 bytes)
const SIZEOF_AST_SIZEOF_EXPR = 16;
struct AstSizeofExpr {
    kind: u64;
    expr: u64;
}

// AST_ADDR_OF: [kind, operand]
func ast_addr_of(operand: u64) -> u64 {
    var n: *AstAddrOf = (*AstAddrOf)(heap_alloc(sizeof(AstAddrOf)));
    n->kind = AST_ADDR_OF;
    n->operand = operand;
    return (u64)n;
}

// AST_DEREF: [kind, operand]
func ast_deref(operand: u64) -> u64 {
    var n: *AstDeref = (*AstDeref)(heap_alloc(sizeof(AstDeref)));
    n->kind = AST_DEREF;
    n->operand = operand;
    return (u64)n;
}

// AST_DEREF8: [kind, operand] - byte dereference
func ast_deref8(operand: u64) -> u64 {
    var n: *AstDeref8 = (*AstDeref8)(heap_alloc(sizeof(AstDeref8)));
    n->kind = AST_DEREF8;
    n->operand = operand;
    return (u64)n;
}

// AST_INDEX: [kind, base, index]
func ast_index(base: u64, index: u64) -> u64 {
    var n: *AstIndex = (*AstIndex)(heap_alloc(sizeof(AstIndex)));
    n->kind = AST_INDEX;
    n->base = base;
    n->index = index;
    return (u64)n;
}

// AST_SLICE: [kind, ptr_expr, len_expr]
func ast_slice(ptr_expr: u64, len_expr: u64) -> u64 {
    var n: *AstSlice = (*AstSlice)(heap_alloc(sizeof(AstSlice)));
    n->kind = AST_SLICE;
    n->ptr_expr = ptr_expr;
    n->len_expr = len_expr;
    return (u64)n;
}

// AST_CAST: [kind, expr, target_type, target_ptr_depth, target_is_tagged, struct_name_ptr, struct_name_len, tag_layout_ptr, tag_layout_len]
func ast_cast(expr: u64, target_type: u64, ptr_depth: u64) -> u64 {
    var n: *AstCast = (*AstCast)(heap_alloc(sizeof(AstCast)));
    n->kind = AST_CAST;
    n->expr = expr;
    n->target_type = target_type;
    n->target_ptr_depth = ptr_depth;
    n->target_is_tagged = 0;
    n->struct_name_ptr = 0;
    n->struct_name_len = 0;
    n->tag_layout_ptr = 0;
    n->tag_layout_len = 0;
    return (u64)n;
}

func ast_cast_ex(expr: u64, target_type: u64, ptr_depth: u64, is_tagged: u64, struct_name_ptr: u64, struct_name_len: u64, tag_layout_ptr: u64, tag_layout_len: u64) -> u64 {
    var n: *AstCast = (*AstCast)(heap_alloc(sizeof(AstCast)));
    n->kind = AST_CAST;
    n->expr = expr;
    n->target_type = target_type;
    n->target_ptr_depth = ptr_depth;
    n->target_is_tagged = is_tagged;
    n->struct_name_ptr = struct_name_ptr;
    n->struct_name_len = struct_name_len;
    n->tag_layout_ptr = tag_layout_ptr;
    n->tag_layout_len = tag_layout_len;
    return (u64)n;
}

// AST_SIZEOF: [kind, type_kind, ptr_depth, struct_name_ptr, struct_name_len]
func ast_sizeof(type_kind: u64, ptr_depth: u64, struct_name_ptr: u64, struct_name_len: u64) -> u64 {
    var n: *AstSizeof = (*AstSizeof)(heap_alloc(sizeof(AstSizeof)));
    n->kind = AST_SIZEOF;
    n->type_kind = type_kind;
    n->ptr_depth = ptr_depth;
    n->struct_name_ptr = struct_name_ptr;
    n->struct_name_len = struct_name_len;
    return (u64)n;
}

// AST_SIZEOF_EXPR: [kind, expr]
func ast_sizeof_expr(expr: u64) -> u64 {
    var n: *AstSizeofExpr = (*AstSizeofExpr)(heap_alloc(sizeof(AstSizeofExpr)));
    n->kind = AST_SIZEOF_EXPR;
    n->expr = expr;
    return (u64)n;
}

// ============================================
// Statement Nodes
// ============================================

// AST Return statement node layout (16 bytes)
const SIZEOF_AST_RETURN = 16;
struct AstReturn {
    kind: u64;
    expr: u64;
}

// AST Variable declaration node layout (112 bytes)
const SIZEOF_AST_VAR_DECL = 112;
struct AstVarDecl {
    kind: u64;
    name_ptr: u64;
    name_len: u64;
    type_kind: u64;
    ptr_depth: u64;
    is_tagged: u64;
    init_expr: u64;
    struct_name_ptr: u64;
    struct_name_len: u64;
    tag_layout_ptr: u64;
    tag_layout_len: u64;
    elem_type_kind: u64;
    elem_ptr_depth: u64;
    array_len: u64;
}

// AST Constant declaration node layout (32 bytes)
const SIZEOF_AST_CONST_DECL = 32;
struct AstConstDecl {
    kind: u64;
    name_ptr: u64;
    name_len: u64;
    value: u64;
}

// AST Assignment node layout (24 bytes)
const SIZEOF_AST_ASSIGN = 24;
struct AstAssign {
    kind: u64;
    target: u64;
    value: u64;
}

// AST_RETURN: [kind, expr]
func ast_return(expr: u64) -> u64 {
    var n: *AstReturn = (*AstReturn)(heap_alloc(sizeof(AstReturn)));
    n->kind = AST_RETURN;
    n->expr = expr;
    return (u64)n;
}

// AST_VAR_DECL: [kind, name_ptr, name_len, type_kind, ptr_depth, init_expr]
func ast_var_decl(name_ptr: u64, name_len: u64, type_kind: u64, ptr_depth: u64, init: u64) -> u64 {
    var n: *AstVarDecl = (*AstVarDecl)(heap_alloc(sizeof(AstVarDecl)));
    n->kind = AST_VAR_DECL;
    n->name_ptr = name_ptr;
    n->name_len = name_len;
    n->type_kind = type_kind;
    n->ptr_depth = ptr_depth;
    n->is_tagged = 0;
    n->init_expr = init;
    n->struct_name_ptr = 0;
    n->struct_name_len = 0;
    n->tag_layout_ptr = 0;
    n->tag_layout_len = 0;
    n->elem_type_kind = 0;
    n->elem_ptr_depth = 0;
    n->array_len = 0;
    return (u64)n;
}

// AST_CONST_DECL: [kind, name_ptr, name_len, value]
func ast_const_decl(name_ptr: u64, name_len: u64, value: u64) -> u64 {
    var n: *AstConstDecl = (*AstConstDecl)(heap_alloc(sizeof(AstConstDecl)));
    n->kind = AST_CONST_DECL;
    n->name_ptr = name_ptr;
    n->name_len = name_len;
    n->value = value;
    return (u64)n;
}

// AST_ASSIGN: [kind, target, value]
func ast_assign(target: u64, value: u64) -> u64 {
    var n: *AstAssign = (*AstAssign)(heap_alloc(sizeof(AstAssign)));
    n->kind = AST_ASSIGN;
    n->target = target;
    n->value = value;
    return (u64)n;
}

// AST Expression statement node layout (16 bytes)
const SIZEOF_AST_EXPR_STMT = 16;
struct AstExprStmt {
    kind: u64;
    expr: u64;
}

// AST If statement node layout (32 bytes)
const SIZEOF_AST_IF = 32;
struct AstIf {
    kind: u64;
    cond: u64;
    then_block: u64;
    else_block: u64;
}

// AST While loop node layout (24 bytes)
const SIZEOF_AST_WHILE = 24;
struct AstWhile {
    kind: u64;
    cond: u64;
    body: u64;
}

// AST For loop node layout (40 bytes)
const SIZEOF_AST_FOR = 40;
struct AstFor {
    kind: u64;
    init: u64;
    cond: u64;
    update: u64;
    body: u64;
}

// AST_EXPR_STMT: [kind, expr]
func ast_expr_stmt(expr: u64) -> u64 {
    var n: *AstExprStmt = (*AstExprStmt)(heap_alloc(sizeof(AstExprStmt)));
    n->kind = AST_EXPR_STMT;
    n->expr = expr;
    return (u64)n;
}

// AST_IF: [kind, cond, then_block, else_block]
func ast_if(cond: u64, then_blk: u64, else_blk: u64) -> u64 {
    var n: *AstIf = (*AstIf)(heap_alloc(sizeof(AstIf)));
    n->kind = AST_IF;
    n->cond = cond;
    n->then_block = then_blk;
    n->else_block = else_blk;
    return (u64)n;
}

// AST_WHILE: [kind, cond, body]
func ast_while(cond: u64, body: u64) -> u64 {
    var n: *AstWhile = (*AstWhile)(heap_alloc(sizeof(AstWhile)));
    n->kind = AST_WHILE;
    n->cond = cond;
    n->body = body;
    return (u64)n;
}

// AST_FOR: [kind, init, cond, update, body]
func ast_for(init: u64, cond: u64, update: u64, body: u64) -> u64 {
    var n: *AstFor = (*AstFor)(heap_alloc(sizeof(AstFor)));
    n->kind = AST_FOR;
    n->init = init;
    n->cond = cond;
    n->update = update;
    n->body = body;
    return (u64)n;
}

// AST Switch statement node layout (24 bytes)
const SIZEOF_AST_SWITCH = 24;
struct AstSwitch {
    kind: u64;
    expr: u64;
    cases_vec: u64;
}

// AST Case node layout (32 bytes)
const SIZEOF_AST_CASE = 32;
struct AstCase {
    kind: u64;
    value: u64;
    body: u64;
    is_default: u64;
}

// AST Break statement node layout (8 bytes)
const SIZEOF_AST_BREAK = 8;
struct AstBreak {
    kind: u64;
}

// AST Continue statement node layout (8 bytes)
const SIZEOF_AST_CONTINUE = 8;
struct AstContinue {
    kind: u64;
}

// AST Inline assembly node layout (16 bytes)
const SIZEOF_AST_ASM = 16;
struct AstAsm {
    kind: u64;
    text_vec: u64;
}

// AST Block node layout (16 bytes)
const SIZEOF_AST_BLOCK = 16;
struct AstBlock {
    kind: u64;
    stmts_vec: u64;
}

// AST_SWITCH: [kind, expr, cases_vec]
func ast_switch(expr: u64, cases: u64) -> u64 {
    var n: *AstSwitch = (*AstSwitch)(heap_alloc(sizeof(AstSwitch)));
    n->kind = AST_SWITCH;
    n->expr = expr;
    n->cases_vec = cases;
    return (u64)n;
}

// AST_CASE: [kind, value, body, is_default]
func ast_case(value: u64, body: u64, is_default: u64) -> u64 {
    var n: *AstCase = (*AstCase)(heap_alloc(sizeof(AstCase)));
    n->kind = AST_CASE;
    n->value = value;
    n->body = body;
    n->is_default = is_default;
    return (u64)n;
}

// AST_BREAK: [kind]
func ast_break() -> u64 {
    var n: *AstBreak = (*AstBreak)(heap_alloc(sizeof(AstBreak)));
    n->kind = AST_BREAK;
    return (u64)n;
}

// AST_CONTINUE: [kind]
func ast_continue() -> u64 {
    var n: *AstContinue = (*AstContinue)(heap_alloc(sizeof(AstContinue)));
    n->kind = AST_CONTINUE;
    return (u64)n;
}

// AST_ASM: [kind, text_vec]
func ast_asm(text_vec: u64) -> u64 {
    var n: *AstAsm = (*AstAsm)(heap_alloc(sizeof(AstAsm)));
    n->kind = AST_ASM;
    n->text_vec = text_vec;
    return (u64)n;
}

// AST_BLOCK: [kind, stmts_vec]
func ast_block(stmts: u64) -> u64 {
    var n: *AstBlock = (*AstBlock)(heap_alloc(sizeof(AstBlock)));
    n->kind = AST_BLOCK;
    n->stmts_vec = stmts;
    return (u64)n;
}

// ============================================
// Top-level Nodes
// ============================================

// AST Function definition node layout (96 bytes)
const SIZEOF_AST_FUNC = 96;
struct AstFunc {
    kind: u64;
    name_ptr: u64;
    name_len: u64;
    params_vec: u64;
    ret_type: u64;
    body: u64;
    ret_ptr_depth: u64;
    ret_is_tagged: u64;
    ret_struct_name_ptr: u64;
    ret_struct_name_len: u64;
    ret_tag_layout_ptr: u64;
    ret_tag_layout_len: u64;
}

// AST Program node layout (48 bytes)
const SIZEOF_AST_PROGRAM = 48;
struct AstProgram {
    kind: u64;
    funcs_vec: u64;
    consts_vec: u64;
    imports_vec: u64;
    globals_vec: u64;
    structs_vec: u64;
}

// AST Import statement node layout (56 bytes)
const SIZEOF_AST_IMPORT = 56;
struct AstImport {
    kind: u64;
    path_ptr: u64;
    path_len: u64;
    symbol_ptr: u64;
    symbol_len: u64;
    alias_ptr: u64;
    alias_len: u64;
}

// AST Struct definition node layout (40 bytes)
const SIZEOF_AST_STRUCT_DEF = 40;
struct AstStructDef {
    kind: u64;
    name_ptr: u64;
    name_len: u64;
    fields_vec: u64;
    is_packed: u64;
}

// AST Member access node layout (32 bytes)
const SIZEOF_AST_MEMBER_ACCESS = 32;
struct AstMemberAccess {
    kind: u64;
    object: u64;
    member_ptr: u64;
    member_len: u64;
}

// AST Method call node layout (40 bytes)
const SIZEOF_AST_METHOD_CALL = 40;
struct AstMethodCall {
    kind: u64;
    receiver: u64;
    method_ptr: u64;
    method_len: u64;
    args_vec: u64;
}

// AST Struct literal node layout (24 bytes)
const SIZEOF_AST_STRUCT_LITERAL = 24;
struct AstStructLiteral {
    kind: u64;
    struct_def: u64;
    values_vec: u64;
}

// AST_FUNC: [kind, name_ptr, name_len, params_vec, ret_type, body]
// Legacy ast_func() now creates 72-byte nodes with extra fields zeroed for compatibility
func ast_func(name_ptr: u64, name_len: u64, params: u64, ret_type: u64, body: u64) -> u64 {
    var n: *AstFunc = (*AstFunc)(heap_alloc(sizeof(AstFunc)));
    n->kind = AST_FUNC;
    n->name_ptr = name_ptr;
    n->name_len = name_len;
    n->params_vec = params;
    n->ret_type = ret_type;
    n->body = body;
    n->ret_ptr_depth = 0;
    n->ret_is_tagged = 0;
    n->ret_struct_name_ptr = 0;
    n->ret_struct_name_len = 0;
    n->ret_tag_layout_ptr = 0;
    n->ret_tag_layout_len = 0;
    return (u64)n;
}

// AST_FUNC (extended): [kind, name_ptr, name_len, params, ret_type, body, ret_ptr_depth, ret_is_tagged, ret_struct_name_ptr, ret_struct_name_len, ret_tag_layout_ptr, ret_tag_layout_len]
func ast_func_ex(name_ptr: u64, name_len: u64, params: u64, ret_type: u64, ret_ptr_depth: u64, ret_is_tagged: u64, ret_struct_name_ptr: u64, ret_struct_name_len: u64, ret_tag_layout_ptr: u64, ret_tag_layout_len: u64, body: u64) -> u64 {
    var n: *AstFunc = (*AstFunc)(heap_alloc(sizeof(AstFunc)));
    n->kind = AST_FUNC;
    n->name_ptr = name_ptr;
    n->name_len = name_len;
    n->params_vec = params;
    n->ret_type = ret_type;
    n->body = body;
    n->ret_ptr_depth = ret_ptr_depth;
    n->ret_is_tagged = ret_is_tagged;
    n->ret_struct_name_ptr = ret_struct_name_ptr;
    n->ret_struct_name_len = ret_struct_name_len;
    n->ret_tag_layout_ptr = ret_tag_layout_ptr;
    n->ret_tag_layout_len = ret_tag_layout_len;
    return (u64)n;
}

// AST_PROGRAM: [kind, funcs_vec, consts_vec, imports_vec, globals_vec]
func ast_program(funcs: u64, consts: u64, imports: u64) -> u64 {
    var n: *AstProgram = (*AstProgram)(heap_alloc(sizeof(AstProgram)));
    n->kind = AST_PROGRAM;
    n->funcs_vec = funcs;
    n->consts_vec = consts;
    n->imports_vec = imports;
    n->globals_vec = 0;
    n->structs_vec = 0;
    return (u64)n;
}

// AST_IMPORT: [kind, path_ptr, path_len, symbol_ptr, symbol_len, alias_ptr, alias_len]
func ast_import(path_ptr: u64, path_len: u64, symbol_ptr: u64, symbol_len: u64, alias_ptr: u64, alias_len: u64) -> u64 {
    var n: *AstImport = (*AstImport)(heap_alloc(sizeof(AstImport)));
    n->kind = AST_IMPORT;
    n->path_ptr = path_ptr;
    n->path_len = path_len;
    n->symbol_ptr = symbol_ptr;
    n->symbol_len = symbol_len;
    n->alias_ptr = alias_ptr;
    n->alias_len = alias_len;
    return (u64)n;
}

// AST_STRUCT_DEF: [kind, name_ptr, name_len, fields_vec, is_packed]
func ast_struct_def(name_ptr: u64, name_len: u64, fields: u64, is_packed: u64) -> u64 {
    var n: *AstStructDef = (*AstStructDef)(heap_alloc(sizeof(AstStructDef)));
    n->kind = AST_STRUCT_DEF;
    n->name_ptr = name_ptr;
    n->name_len = name_len;
    n->fields_vec = fields;
    n->is_packed = is_packed;
    return (u64)n;
}

// AST_MEMBER_ACCESS: [kind, object, member_ptr, member_len]
func ast_member_access(object: u64, member_ptr: u64, member_len: u64) -> u64 {
    var n: *AstMemberAccess = (*AstMemberAccess)(heap_alloc(sizeof(AstMemberAccess)));
    n->kind = AST_MEMBER_ACCESS;
    n->object = object;
    n->member_ptr = member_ptr;
    n->member_len = member_len;
    return (u64)n;
}

// AST_METHOD_CALL: [kind, receiver, method_ptr, method_len, args_vec]
func ast_method_call(receiver: u64, method_ptr: u64, method_len: u64, args: u64) -> u64 {
    var n: *AstMethodCall = (*AstMethodCall)(heap_alloc(sizeof(AstMethodCall)));
    n->kind = AST_METHOD_CALL;
    n->receiver = receiver;
    n->method_ptr = method_ptr;
    n->method_len = method_len;
    n->args_vec = args;
    return (u64)n;
}

// AST_CALL_PTR: [kind, callee, args_vec]
func ast_call_ptr(callee: u64, args: u64) -> u64 {
    var n: *AstCallPtr = (*AstCallPtr)(heap_alloc(sizeof(AstCallPtr)));
    n->kind = AST_CALL_PTR;
    n->callee = callee;
    n->args_vec = args;
    return (u64)n;
}

// AST_STRUCT_LITERAL: struct_def_ptr, values (vec of exprs)
// Layout: [kind:8][struct_def:8][values:8]
func ast_struct_literal(struct_def: u64, values: u64) -> u64 {
    var n: *AstStructLiteral = (*AstStructLiteral)(heap_alloc(sizeof(AstStructLiteral)));
    n->kind = AST_STRUCT_LITERAL;
    n->struct_def = struct_def;
    n->values_vec = values;
    return (u64)n;
}

// ============================================
// AST Accessors
// ============================================

func ast_kind(n: u64) -> u64 { return *(n); }
