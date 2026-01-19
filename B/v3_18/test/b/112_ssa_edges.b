// Expect exit code: 0

import ssa;

func main() -> i64 {
    var ctx: *SSAContext = (*SSAContext)ssa_context_new();
    var fn: *SSAFunction = (*SSAFunction)ssa_new_function(ctx, "f", 1);

    var entry: *SSABlock = fn->entry;
    var b2: *SSABlock = (*SSABlock)ssa_new_block(ctx, fn);

    ssa_add_edge(entry, b2);

    if (entry->succs_len != 1) { return 1; }
    if (b2->preds_len != 1) { return 2; }

    var opr_c: u64 = ssa_operand_const(10);
    var opr_r: u64 = ssa_operand_reg(3);

    if (!ssa_operand_is_const(opr_c)) { return 3; }
    if (ssa_operand_is_const(opr_r)) { return 4; }
    if (ssa_operand_value(opr_c) != 10) { return 5; }
    if (ssa_operand_value(opr_r) != 3) { return 6; }

    return 0;
}
