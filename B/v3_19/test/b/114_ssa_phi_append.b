// Expect exit code: 0

import ssa;

func main() -> i64 {
    var ctx: *SSAContext = (*SSAContext)ssa_context_new();
    var fn: *SSAFunction = (*SSAFunction)ssa_new_function(ctx, "f", 1);
    var b0: *SSABlock = fn->entry;

    var phi1_ptr: u64 = ssa_new_inst(ctx, SSA_OP_PHI, 1, 0, 0);
    var phi2_ptr: u64 = ssa_new_inst(ctx, SSA_OP_PHI, 2, 0, 0);
    var phi1: *SSAInstruction = (*SSAInstruction)phi1_ptr;
    var phi2: *SSAInstruction = (*SSAInstruction)phi2_ptr;

    ssa_phi_append(b0, phi1);
    ssa_phi_append(b0, phi2);

    if (b0->phi_head != phi2) { return 1; }
    if (phi2->next != phi1) { return 2; }
    if (ssa_inst_get_op(phi1) != SSA_OP_PHI) { return 3; }
    if (ssa_inst_get_op(phi2) != SSA_OP_PHI) { return 4; }

    return 0;
}
