// ssa_destroy.b - SSA destruction (v3_17)
//
// Phi 제거: 각 Phi의 인자를 predecessor에 COPY로 낮추고, Phi 리스트를 제거합니다.

import std.vec;
import ssa;

func _ssa_destroy_find_pred(block: *SSABlock, pred_id: u64) -> u64 {
    var preds: u64 = block->preds_data;
    var n: u64 = block->preds_len;
    var i: u64 = 0;
    while (i < n) {
        var p_ptr: u64 = *(*u64)(preds + i * 8);
        var p: *SSABlock = (*SSABlock)p_ptr;
        if (p->id == pred_id) { return p_ptr; }
        i = i + 1;
    }
    return 0;
}

func _ssa_destroy_get_split(map_pred: u64, map_block: u64, pred: *SSABlock, block: *SSABlock) -> u64 {
    var n: u64 = vec_len(map_pred);
    var i: u64 = 0;
    while (i < n) {
        var p_ptr: u64 = vec_get(map_pred, i);
        if (p_ptr == (u64)pred) {
            var b_ptr: u64 = vec_get(map_block, i);
            return b_ptr;
        }
        i = i + 1;
    }
    return 0;
}

func ssa_destroy_block(ctx: *SSAContext, fn: *SSAFunction, block: *SSABlock) -> u64 {
    var split_pred: u64 = vec_new(4);
    var split_block: u64 = vec_new(4);

    var phi: *SSAInstruction = block->phi_head;
    while (phi != 0) {
        var args: *SSAPhiArg = (*SSAPhiArg)phi->src1;
        while (args != 0) {
            var pred_ptr: u64 = _ssa_destroy_find_pred(block, args->block_id);
            if (pred_ptr != 0) {
                var pred: *SSABlock = (*SSABlock)pred_ptr;
                var critical: u64 = 0;
                if (pred->succs_len >= 2 && block->preds_len >= 2) { critical = 1; }

                if (critical == 1) {
                    var split_ptr: u64 = _ssa_destroy_get_split(split_pred, split_block, pred, block);
                    if (split_ptr == 0) {
                        split_ptr = ssa_new_block(ctx, fn);
                        var split: *SSABlock = (*SSABlock)split_ptr;

                        ssa_block_replace_succ(pred, block, split);
                        ssa_block_replace_pred(block, pred, split);
                        ssa_block_add_pred(split, pred);
                        ssa_block_add_succ(split, block);

                        vec_push(split_pred, (u64)pred);
                        vec_push(split_block, split_ptr);
                    }

                    var inst_ptr: u64 = ssa_new_inst(ctx, SSA_OP_COPY, phi->dest, ssa_operand_reg(args->val), 0);
                    ssa_inst_append((*SSABlock)split_ptr, (*SSAInstruction)inst_ptr);
                } else {
                    var inst_ptr2: u64 = ssa_new_inst(ctx, SSA_OP_COPY, phi->dest, ssa_operand_reg(args->val), 0);
                    ssa_inst_append(pred, (*SSAInstruction)inst_ptr2);
                }
            }
            args = args->next;
        }
        phi = phi->next;
    }

    block->phi_head = 0;
    return 0;
}

func ssa_destroy_run(ctx: *SSAContext) -> u64 {
    if (ctx == 0) { return 0; }
    var funcs: u64 = ctx->funcs_data;
    var n: u64 = ctx->funcs_len;
    var i: u64 = 0;
    while (i < n) {
        var f_ptr: u64 = *(*u64)(funcs + i * 8);
        var fn: *SSAFunction = (*SSAFunction)f_ptr;

        var blocks: u64 = fn->blocks_data;
        var bcount: u64 = fn->blocks_len;
        var bi: u64 = 0;
        while (bi < bcount) {
            var b_ptr: u64 = *(*u64)(blocks + bi * 8);
            ssa_destroy_block(ctx, fn, (*SSABlock)b_ptr);
            bi = bi + 1;
        }

        i = i + 1;
    }
    return 0;
}
