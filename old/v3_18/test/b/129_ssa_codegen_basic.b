// Expect exit code: 0

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

    var c1_ptr: u64 = ssa_new_inst(ctx, SSA_OP_CONST, SSA_PHYS_RAX, ssa_operand_const(7), 0);
    var c2_ptr: u64 = ssa_new_inst(ctx, SSA_OP_CONST, SSA_PHYS_RBX, ssa_operand_const(5), 0);
    var add_ptr: u64 = ssa_new_inst(ctx, SSA_OP_ADD, SSA_PHYS_RAX, ssa_operand_reg(SSA_PHYS_RAX), ssa_operand_reg(SSA_PHYS_RBX));
    var ret_ptr: u64 = ssa_new_inst(ctx, SSA_OP_RET, 0, ssa_operand_reg(SSA_PHYS_RAX), 0);

    ssa_inst_append(b0, (*SSAInstruction)c1_ptr);
    ssa_inst_append(b0, (*SSAInstruction)c2_ptr);
    ssa_inst_append(b0, (*SSAInstruction)add_ptr);
    ssa_inst_append(b0, (*SSAInstruction)ret_ptr);

    var params: u64 = vec_new(2);
    var fn_ast_ptr: u64 = ast_func_ex("f", 1, params, TYPE_I64, 0, 0, 0, 0, 0, 0, 0, 0);

    ssa_codegen_emit_func(fn_ast_ptr, fn_ptr);
    return 0;
}
