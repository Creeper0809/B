// Expect exit code: 0

import ssa;
import ssa_regalloc;

func main() -> i64 {
    var ctx: *SSAContext = (*SSAContext)ssa_context_new();
    var fn: *SSAFunction = (*SSAFunction)ssa_new_function(ctx, "f", 1);
    var b0: *SSABlock = fn->entry;

    var c1_ptr: u64 = ssa_new_inst(ctx, SSA_OP_CONST, 1, ssa_operand_const(1), 0);
    var c2_ptr: u64 = ssa_new_inst(ctx, SSA_OP_CONST, 2, ssa_operand_const(2), 0);
    var add_ptr: u64 = ssa_new_inst(ctx, SSA_OP_ADD, 3, ssa_operand_reg(1), ssa_operand_reg(2));

    ssa_inst_append(b0, (*SSAInstruction)c1_ptr);
    ssa_inst_append(b0, (*SSAInstruction)c2_ptr);
    ssa_inst_append(b0, (*SSAInstruction)add_ptr);

    ssa_regalloc_run(ctx, 2);
    ssa_regalloc_apply_run(ctx);

    var map: u64 = fn->reg_map_data;
    if (map == 0) { return 1; }

    var p1: u64 = *(*u64)(map + 1 * 8);
    var p2: u64 = *(*u64)(map + 2 * 8);
    var p3: u64 = *(*u64)(map + 3 * 8);

    if (p1 == 0 || p2 == 0 || p3 == 0) { return 2; }

    var inst: *SSAInstruction = (*SSAInstruction)add_ptr;
    if (inst->dest != p3) { return 3; }
    if (ssa_operand_value(inst->src1) != p1) { return 4; }
    if (ssa_operand_value(inst->src2) != p2) { return 5; }

    return 0;
}
