// Expect exit code: 0

import ssa;

func main() -> i64 {
    var ctx: *SSAContext = (*SSAContext)ssa_context_new();
    var fn: *SSAFunction = (*SSAFunction)ssa_new_function(ctx, "f", 1);
    var b0: *SSABlock = fn->entry;
    var b1: *SSABlock = (*SSABlock)ssa_new_block(ctx, fn);

    var h_ptr: u64 = ssa_phi_arg_new(1, b0->id);
    var head: *SSAPhiArg = (*SSAPhiArg)h_ptr;
    var h2_ptr: u64 = ssa_phi_arg_append(head, 2, b1->id);
    head = (*SSAPhiArg)h2_ptr;

    var phi_ptr: u64 = ssa_phi_new(ctx, 10, head);
    var phi: *SSAInstruction = (*SSAInstruction)phi_ptr;

    if (ssa_inst_get_op(phi) != SSA_OP_PHI) { return 1; }
    if (phi->dest != 10) { return 2; }

    var arg1: *SSAPhiArg = (*SSAPhiArg)phi->src1;
    if (arg1->val != 1) { return 3; }
    if (arg1->block_id != b0->id) { return 4; }

    var arg2: *SSAPhiArg = arg1->next;
    if (arg2 == 0) { return 5; }
    if (arg2->val != 2) { return 6; }
    if (arg2->block_id != b1->id) { return 7; }

    return 0;
}
