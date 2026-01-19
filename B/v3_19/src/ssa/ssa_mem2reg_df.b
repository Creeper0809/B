// ssa_mem2reg_df.b - Dominance Frontier computation (v3_17)
//
// DF 계산: 다중 predecessor 블록 b에 대해,
// 각 pred에서 idom[b]까지 거슬러 올라가며 runner의 DF에 b를 추가.

import std.io;
import std.util;
import ssa.ssa;
import ssa.ssa_core;

const MEM2REG_DF_DEBUG = 0;

func ssa_mem2reg_compute_df(fn: *SSAFunction) -> u64 {
    push_trace("ssa_mem2reg_compute_df", "ssa_mem2reg_df.b", __LINE__);
    if (fn == 0) { pop_trace(); return 0; }

    var blocks: u64 = fn->blocks_data;
    var n: u64 = fn->blocks_len;
    var i: u64 = 0;
    while (i < n) {
        var b_ptr: u64 = *(*u64)(blocks + i * 8);
        var b: *SSABlock = (*SSABlock)b_ptr;

        if (b->preds_len < 2) {
            i = i + 1;
            continue;
        }

        var idom_b: *SSABlock = b->dom_parent;
        var preds: u64 = b->preds_data;
        var pcount: u64 = b->preds_len;

        var j: u64 = 0;
        while (j < pcount) {
            var p_ptr: u64 = *(*u64)(preds + j * 8);
            var runner: *SSABlock = (*SSABlock)p_ptr;

            while (runner != 0 && runner != idom_b) {
                ssa_block_add_df(runner, b);
                runner = runner->dom_parent;
            }

            j = j + 1;
        }

        i = i + 1;
    }

    if (MEM2REG_DF_DEBUG != 0) {
        println("[DEBUG] ssa_mem2reg_compute_df: done", 41);
    }
    pop_trace();
    return 0;
}

func ssa_mem2reg_run_df(ctx: *SSAContext) -> u64 {
    push_trace("ssa_mem2reg_run_df", "ssa_mem2reg_df.b", __LINE__);
    if (ctx == 0) { pop_trace(); return 0; }
    var funcs: u64 = ctx->funcs_data;
    var n: u64 = ctx->funcs_len;
    var i: u64 = 0;
    while (i < n) {
        var f_ptr: u64 = *(*u64)(funcs + i * 8);
        ssa_mem2reg_compute_df((*SSAFunction)f_ptr);
        i = i + 1;
    }
    pop_trace();
    return 0;
}
