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

    ssa_mem2reg_compute_idom(ctx, fn);

    if (b_then->dom_parent != entry) { return 1; }
    if (b_else->dom_parent != entry) { return 2; }
    if (b_merge->dom_parent != entry) { return 3; }

    return 0;
}
