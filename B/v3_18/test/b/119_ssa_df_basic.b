// Expect exit code: 0

import ssa;
import ssa_mem2reg;
import ssa_mem2reg_df;

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
    ssa_mem2reg_compute_df(fn);

    if (b_then->df_len != 1) { return 1; }
    if (b_else->df_len != 1) { return 2; }

    var df_then: u64 = *(*u64)(b_then->df_data);
    var df_else: u64 = *(*u64)(b_else->df_data);
    if (df_then != (u64)b_merge) { return 3; }
    if (df_else != (u64)b_merge) { return 4; }

    if (entry->df_len != 0) { return 5; }

    return 0;
}
