// Expect exit code: 0

import std.io;
import std.vec;
import ast;
import types;
import ssa;
import ssa_regalloc;
import ssa_codegen;
import emitter.emitter;

func main() -> i64 {
    emitter_init();

    var ctx: *SSAContext = (*SSAContext)ssa_context_new();
    var fn_ptr: u64 = ssa_new_function(ctx, "f", 1);
    var ssa_fn: *SSAFunction = (*SSAFunction)fn_ptr;
    var b0: *SSABlock = ssa_fn->entry;

    var p_ptr: u64 = ssa_new_inst(ctx, SSA_OP_PARAM, SSA_PHYS_RAX, ssa_operand_const(0), 0);
    var ret_ptr: u64 = ssa_new_inst(ctx, SSA_OP_RET, 0, ssa_operand_reg(SSA_PHYS_RAX), 0);

    ssa_inst_append(b0, (*SSAInstruction)p_ptr);
    ssa_inst_append(b0, (*SSAInstruction)ret_ptr);

    var params: u64 = vec_new(2);
    var p: *Param = (*Param)heap_alloc(SIZEOF_PARAM);
    p->name_ptr = "a";
    p->name_len = 1;
    p->type_kind = TYPE_I64;
    p->ptr_depth = 0;
    p->is_tagged = 0;
    p->struct_name_ptr = 0;
    p->struct_name_len = 0;
    p->tag_layout_ptr = 0;
    p->tag_layout_len = 0;
    p->elem_type_kind = 0;
    p->elem_ptr_depth = 0;
    p->array_len = 0;
    vec_push(params, (u64)p);

    var fn_ast_ptr: u64 = ast_func_ex("f", 1, params, TYPE_I64, 0, 0, 0, 0, 0, 0, 0, 0);

    ssa_codegen_emit_func(fn_ast_ptr, fn_ptr);
    return 0;
}
