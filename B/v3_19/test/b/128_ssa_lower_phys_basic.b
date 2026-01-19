// Expect exit code: 0

import ssa;
import ssa_lower_phys;

func main() -> i64 {
    var ctx: *SSAContext = (*SSAContext)ssa_context_new();
    var fn: *SSAFunction = (*SSAFunction)ssa_new_function(ctx, "f", 1);
    var b0: *SSABlock = fn->entry;

    var c1_ptr: u64 = ssa_new_inst(ctx, SSA_OP_CONST, 1, ssa_operand_const(1), 0);
    var cp_ptr: u64 = ssa_new_inst(ctx, SSA_OP_COPY, 1, ssa_operand_reg(1), 0);
    var ld_ptr: u64 = ssa_new_inst(ctx, SSA_OP_LOAD, 2, ssa_operand_const(1), 0);
    var st_ptr: u64 = ssa_new_inst(ctx, SSA_OP_STORE, 0, ssa_operand_const(1), ssa_operand_reg(1));

    ssa_inst_append(b0, (*SSAInstruction)c1_ptr);
    ssa_inst_append(b0, (*SSAInstruction)cp_ptr);
    ssa_inst_append(b0, (*SSAInstruction)ld_ptr);
    ssa_inst_append(b0, (*SSAInstruction)st_ptr);

    ssa_lower_phys_run(ctx);

    if (ssa_inst_get_op((*SSAInstruction)cp_ptr) != SSA_OP_NOP) { return 1; }
    if (ssa_inst_get_op((*SSAInstruction)ld_ptr) != SSA_OP_NOP) { return 2; }
    if (ssa_inst_get_op((*SSAInstruction)st_ptr) != SSA_OP_NOP) { return 3; }

    return 0;
}
