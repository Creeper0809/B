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

    var colors: u64 = ssa_regalloc_color_fn(fn, 2);
    if (colors == 0) { return 1; }

    var c1: u64 = *(*u64)(colors + 1 * 8);
    var c2: u64 = *(*u64)(colors + 2 * 8);
    if (c1 == 0 || c2 == 0) { return 2; }
    if (c1 == c2) { return 3; }

    return 0;
}
