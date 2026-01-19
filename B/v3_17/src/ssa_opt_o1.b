// ssa_opt_o1.b - SSA O1 optimizations (v3_17)

import std.io;
import ssa;

const SSA_O1_DEBUG = 0;

func _ssa_opt_is_foldable(op: u64) -> u64 {
    if (op == SSA_OP_ADD) { return 1; }
    if (op == SSA_OP_SUB) { return 1; }
    if (op == SSA_OP_MUL) { return 1; }
    if (op == SSA_OP_DIV) { return 1; }
    if (op == SSA_OP_EQ) { return 1; }
    if (op == SSA_OP_NE) { return 1; }
    if (op == SSA_OP_LT) { return 1; }
    if (op == SSA_OP_GT) { return 1; }
    if (op == SSA_OP_LE) { return 1; }
    if (op == SSA_OP_GE) { return 1; }
    return 0;
}

func _ssa_opt_fold_inst(inst: *SSAInstruction) -> u64 {
    var op: u64 = ssa_inst_get_op(inst);
    if (_ssa_opt_is_foldable(op) == 0) { return 0; }

    if (!ssa_operand_is_const(inst->src1)) { return 0; }
    if (!ssa_operand_is_const(inst->src2)) { return 0; }

    var a: u64 = ssa_operand_value(inst->src1);
    var b: u64 = ssa_operand_value(inst->src2);
    var res: u64 = 0;

    if (op == SSA_OP_ADD) { res = a + b; }
    else if (op == SSA_OP_SUB) { res = a - b; }
    else if (op == SSA_OP_MUL) { res = a * b; }
    else if (op == SSA_OP_DIV) {
        if (b == 0) { return 0; }
        res = a / b;
    }
    else if (op == SSA_OP_EQ) { res = (a == b); }
    else if (op == SSA_OP_NE) { res = (a != b); }
    else if (op == SSA_OP_LT) { res = (a < b); }
    else if (op == SSA_OP_GT) { res = (a > b); }
    else if (op == SSA_OP_LE) { res = (a <= b); }
    else if (op == SSA_OP_GE) { res = (a >= b); }
    else { return 0; }

    ssa_inst_set_op(inst, SSA_OP_CONST);
    inst->src1 = ssa_operand_const(res);
    inst->src2 = 0;
    return 1;
}

func _ssa_opt_remove_nops(block: *SSABlock) -> u64 {
    var cur: *SSAInstruction = block->inst_head;
    while (cur != 0) {
        var next: *SSAInstruction = cur->next;
        var op: u64 = ssa_inst_get_op(cur);

        if (op == SSA_OP_NOP) {
            var prev_inst: *SSAInstruction = (*SSAInstruction)cur->prev;

            if (prev_inst == 0) {
                block->inst_head = next;
            } else {
                prev_inst->next = next;
            }

            if (next != 0) {
                ssa_inst_set_prev(next, prev_inst);
            }

            if (next == 0) {
                block->inst_tail = prev_inst;
            }
        }

        cur = next;
    }

    return 0;
}

func ssa_opt_o1_run(ctx: *SSAContext) -> u64 {
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
                _ssa_opt_fold_inst(cur);
                cur = cur->next;
            }

            _ssa_opt_remove_nops(b);
            bi = bi + 1;
        }

        i = i + 1;
    }

    if (SSA_O1_DEBUG != 0) {
        println("[DEBUG] ssa_opt_o1_run: done", 32);
    }

    return 0;
}
