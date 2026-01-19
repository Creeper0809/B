// Expect exit code: 0

import ssa;
import ssa_destroy;

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

    var a1_ptr: u64 = ssa_phi_arg_new(1, b_then->id);
    var head: *SSAPhiArg = (*SSAPhiArg)a1_ptr;
    var a2_ptr: u64 = ssa_phi_arg_append(head, 2, b_else->id);
    head = (*SSAPhiArg)a2_ptr;

    var phi_ptr: u64 = ssa_phi_new(ctx, 10, head);
    ssa_phi_append(b_merge, (*SSAInstruction)phi_ptr);

    ssa_destroy_run(ctx);

    if (b_merge->phi_head != 0) { return 1; }

    var t_tail: *SSAInstruction = b_then->inst_tail;
    var e_tail: *SSAInstruction = b_else->inst_tail;
    if (t_tail == 0 || e_tail == 0) { return 2; }

    if (ssa_inst_get_op(t_tail) != SSA_OP_COPY) { return 3; }
    if (ssa_inst_get_op(e_tail) != SSA_OP_COPY) { return 4; }

    if (t_tail->dest != 10) { return 5; }
    if (e_tail->dest != 10) { return 6; }

    return 0;
}
