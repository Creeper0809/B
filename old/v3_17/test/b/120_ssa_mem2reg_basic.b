// Expect exit code: 0

import ssa;
import ssa_mem2reg;

func main() -> i64 {
    var ctx: *SSAContext = (*SSAContext)ssa_context_new();
    var fn: *SSAFunction = (*SSAFunction)ssa_new_function(ctx, "f", 1);

    var entry: *SSABlock = fn->entry;
    var b_then: *SSABlock = (*SSABlock)ssa_new_block(ctx, fn);
    var b_else: *SSABlock = (*SSABlock)ssa_new_block(ctx, fn);
    var b_merge: *SSABlock = (*SSABlock)ssa_new_block(ctx, fn);

    ssa_add_edge(entry, b_then);
    ssa_add_edge(entry, b_else);
    ssa_add_edge(b_then, b_merge);
    ssa_add_edge(b_else, b_merge);

    var c1_ptr: u64 = ssa_new_inst(ctx, SSA_OP_CONST, 1, ssa_operand_const(1), 0);
    ssa_inst_append(b_then, (*SSAInstruction)c1_ptr);
    var st1_ptr: u64 = ssa_new_inst(ctx, SSA_OP_STORE, 0, ssa_operand_const(1), ssa_operand_reg(1));
    ssa_inst_append(b_then, (*SSAInstruction)st1_ptr);

    var c2_ptr: u64 = ssa_new_inst(ctx, SSA_OP_CONST, 2, ssa_operand_const(2), 0);
    ssa_inst_append(b_else, (*SSAInstruction)c2_ptr);
    var st2_ptr: u64 = ssa_new_inst(ctx, SSA_OP_STORE, 0, ssa_operand_const(1), ssa_operand_reg(2));
    ssa_inst_append(b_else, (*SSAInstruction)st2_ptr);

    var ld_ptr: u64 = ssa_new_inst(ctx, SSA_OP_LOAD, 3, ssa_operand_const(1), 0);
    ssa_inst_append(b_merge, (*SSAInstruction)ld_ptr);

    ssa_mem2reg_run(ctx);

    var phi: *SSAInstruction = b_merge->phi_head;
    if (phi == 0) { return 1; }
    if (ssa_inst_get_op(phi) != SSA_OP_PHI) { return 2; }

    var a1: *SSAPhiArg = (*SSAPhiArg)phi->src1;
    if (a1 == 0) { return 3; }
    if (a1->next == 0) { return 4; }

    if (ssa_inst_get_op((*SSAInstruction)st1_ptr) != SSA_OP_NOP) { return 5; }
    if (ssa_inst_get_op((*SSAInstruction)st2_ptr) != SSA_OP_NOP) { return 6; }
    if (ssa_inst_get_op((*SSAInstruction)ld_ptr) != SSA_OP_NOP) { return 7; }

    return 0;
}
