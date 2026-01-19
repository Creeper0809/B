// Expect exit code: 0

import std.vec;
import ast;
import types;
import ssa;
import ssa_builder;
import emitter.typeinfo;

func main() -> i64 {
    typeinfo_set_structs(0);

    var ssa_ctx: *SSAContext = (*SSAContext)ssa_context_new();
    var bctx_ptr: u64 = builder_ctx_new(ssa_ctx);
    var bctx: *BuilderCtx = (*BuilderCtx)bctx_ptr;

    var fn_ptr: u64 = ssa_new_function(ssa_ctx, "f", 1);
    var fn: *SSAFunction = (*SSAFunction)fn_ptr;
    bctx->cur_func = fn;
    bctx->cur_block = fn->entry;
    builder_reset_func(bctx);

    var e1: u64 = ast_unary(TOKEN_MINUS, ast_literal(7));
    var e2: u64 = ast_unary(TOKEN_BANG, ast_literal(0));
    var e3: u64 = ast_sizeof(TYPE_I64, 0, 0, 0);

    build_expr(bctx, e1);
    build_expr(bctx, e2);
    build_expr(bctx, e3);

    var sub_count: u64 = 0;
    var eq_count: u64 = 0;
    var cur: *SSAInstruction = fn->entry->inst_head;
    while (cur != 0) {
        var op: u64 = ssa_inst_get_op(cur);
        if (op == SSA_OP_SUB) { sub_count = sub_count + 1; }
        if (op == SSA_OP_EQ) { eq_count = eq_count + 1; }
        cur = cur->next;
    }

    if (sub_count == 0) { return 1; }
    if (eq_count == 0) { return 2; }
    return 0;
}
