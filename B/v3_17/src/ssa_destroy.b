// ssa_destroy.b - SSA destruction (v3_17)
//
// Phi 제거: 각 Phi의 인자를 predecessor에 COPY로 낮추고, Phi 리스트를 제거합니다.

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

func ssa_destroy_block(ctx: *SSAContext, block: *SSABlock) -> u64 {
    var phi: *SSAInstruction = block->phi_head;
    while (phi != 0) {
        var args: *SSAPhiArg = (*SSAPhiArg)phi->src1;
        while (args != 0) {
            var pred_ptr: u64 = _ssa_destroy_find_pred(block, args->block_id);
            if (pred_ptr != 0) {
                var pred: *SSABlock = (*SSABlock)pred_ptr;
                var inst_ptr: u64 = ssa_new_inst(ctx, SSA_OP_COPY, phi->dest, ssa_operand_reg(args->val), 0);
                ssa_inst_append(pred, (*SSAInstruction)inst_ptr);
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
            ssa_destroy_block(ctx, (*SSABlock)b_ptr);
            bi = bi + 1;
        }

        i = i + 1;
    }
    return 0;
}
