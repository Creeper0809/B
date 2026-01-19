// Expect exit code: 0

import ssa;
import ssa_destroy;

func main() -> i64 {
    var ctx: *SSAContext = (*SSAContext)ssa_context_new();
    var fn: *SSAFunction = (*SSAFunction)ssa_new_function(ctx, "f", 1);

    var entry: *SSABlock = fn->entry;
    var b_other: *SSABlock = (*SSABlock)ssa_new_block(ctx, fn);
    var b_then: *SSABlock = (*SSABlock)ssa_new_block(ctx, fn);
    var b_merge: *SSABlock = (*SSABlock)ssa_new_block(ctx, fn);

    // entry has two succs, merge has two preds -> critical edge (entry -> merge)
    ssa_add_edge(entry, b_merge);
    ssa_add_edge(entry, b_other);
    ssa_add_edge(b_then, b_merge);

    var a1_ptr: u64 = ssa_phi_arg_new(1, entry->id);
    var head: *SSAPhiArg = (*SSAPhiArg)a1_ptr;
    var a2_ptr: u64 = ssa_phi_arg_append(head, 2, b_then->id);
    head = (*SSAPhiArg)a2_ptr;

    var phi_ptr: u64 = ssa_phi_new(ctx, 10, head);
    ssa_phi_append(b_merge, (*SSAInstruction)phi_ptr);

    ssa_destroy_run(ctx);

    // entry should no longer point directly to merge
    var sdata: u64 = entry->succs_data;
    var slen: u64 = entry->succs_len;
    var i: u64 = 0;
    while (i < slen) {
        var sp: u64 = *(*u64)(sdata + i * 8);
        var sb: *SSABlock = (*SSABlock)sp;
        if (sb->id == b_merge->id) { return 1; }
        i = i + 1;
    }

    // find split block: pred=entry, succ=merge, COPY present
    var blocks: u64 = fn->blocks_data;
    var n: u64 = fn->blocks_len;
    var found: u64 = 0;
    var bi: u64 = 0;
    while (bi < n) {
        var b_ptr: u64 = *(*u64)(blocks + bi * 8);
        var b: *SSABlock = (*SSABlock)b_ptr;
        if (b->preds_len == 1 && b->succs_len == 1) {
            var p0: *SSABlock = (*SSABlock)*(*u64)(b->preds_data);
            var s0: *SSABlock = (*SSABlock)*(*u64)(b->succs_data);
            if (p0 == entry && s0 == b_merge) {
                var t: *SSAInstruction = b->inst_tail;
                if (t == 0) { return 2; }
                if (ssa_inst_get_op(t) != SSA_OP_COPY) { return 3; }
                found = 1;
            }
        }
        bi = bi + 1;
    }

    if (found == 0) { return 4; }
    return 0;
}
