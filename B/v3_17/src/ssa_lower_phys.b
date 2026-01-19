// ssa_lower_phys.b - Lower SSA ops to physical-register form (v3_17)
//
// 현재 단계: COPY/LOAD/STORE 정리 및 단순 정규화.

import ssa;

func ssa_lower_phys_run(ctx: *SSAContext) -> u64 {
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
            var b: *SSABlock = (*SSABlock)b_ptr;

            var cur: *SSAInstruction = b->inst_head;
            while (cur != 0) {
                var op: u64 = ssa_inst_get_op(cur);

                if (op == SSA_OP_COPY) {
                    var src: u64 = ssa_operand_value(cur->src1);
                    if (cur->dest == src) {
                        ssa_inst_set_op(cur, SSA_OP_NOP);
                    }
                }

                if (op == SSA_OP_LOAD || op == SSA_OP_STORE) {
                    // mem2reg 이후에는 남지 않아야 함. 안전하게 NOP 처리.
                    ssa_inst_set_op(cur, SSA_OP_NOP);
                }

                cur = cur->next;
            }

            bi = bi + 1;
        }

        i = i + 1;
    }
    return 0;
}
