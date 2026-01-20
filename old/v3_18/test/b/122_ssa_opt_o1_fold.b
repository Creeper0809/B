// Expect exit code: 0

import ssa;
import ssa_opt_o1;

func main() -> i64 {
    var ctx: *SSAContext = (*SSAContext)ssa_context_new();
    var fn: *SSAFunction = (*SSAFunction)ssa_new_function(ctx, "f", 1);
    var b0: *SSABlock = fn->entry;

    var c1_ptr: u64 = ssa_new_inst(ctx, SSA_OP_CONST, 1, ssa_operand_const(2), 0);
    var c2_ptr: u64 = ssa_new_inst(ctx, SSA_OP_CONST, 2, ssa_operand_const(3), 0);
    var add_ptr: u64 = ssa_new_inst(ctx, SSA_OP_ADD, 3, ssa_operand_const(2), ssa_operand_const(3));
    var nop_ptr: u64 = ssa_new_inst(ctx, SSA_OP_NOP, 4, 0, 0);

    ssa_inst_append(b0, (*SSAInstruction)c1_ptr);
    ssa_inst_append(b0, (*SSAInstruction)c2_ptr);
    ssa_inst_append(b0, (*SSAInstruction)add_ptr);
    ssa_inst_append(b0, (*SSAInstruction)nop_ptr);

    ssa_opt_o1_run(ctx);

    var cur: *SSAInstruction = b0->inst_head;
    var found: u64 = 0;
    while (cur != 0) {
        var op: u64 = ssa_inst_get_op(cur);
        if (op == SSA_OP_NOP) { return 1; }
        if (cur->dest == 3 && op == SSA_OP_CONST) {
            if (ssa_operand_value(cur->src1) != 5) { return 2; }
            found = 1;
        }
        cur = cur->next;
    }

    if (found == 0) { return 3; }
    return 0;
}
