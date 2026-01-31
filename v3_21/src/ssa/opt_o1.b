// ssa_opt_o1.b - SSA O1 optimizations (v3_17)

import std.io;
import std.util;
import std.vec;
import ssa.datastruct;
import ssa.core;

const SSA_O1_DEBUG = 0;

// ============================================
// Const Propagation Helpers
// ============================================

func _ssa_opt_const_find(map: u64, key: u64) -> u64 {
    var n: u64 = vec_len(map);
    var k: u64 = key + 1;
    var i: u64 = 0;
    for (i = 0; i < n; i = i + 2) {
        var cur: u64 = vec_get(map, i);
        if (cur != 0 && cur == k) { return i + 1; }
    }
    return 0;
}

func _ssa_opt_const_set(map: u64, key: u64, val: u64) -> u64 {
    var idx: u64 = _ssa_opt_const_find(map, key);
    if (idx != 0) {
        vec_set(map, idx, val);
        return 0;
    }
    vec_push(map, key + 1);
    vec_push(map, val);
    return 0;
}

func _ssa_opt_const_clear(map: u64, key: u64) -> u64 {
    var idx: u64 = _ssa_opt_const_find(map, key);
    if (idx != 0) {
        vec_set(map, idx - 1, 0);
    }
    return 0;
}

func _ssa_opt_const_get(map: u64, key: u64) -> u64 {
    var idx: u64 = _ssa_opt_const_find(map, key);
    if (idx == 0) { return 0; }
    return vec_get(map, idx);
}

// ============================================
// DCE Helpers
// ============================================

func _ssa_opt_use_find(map: u64, key: u64) -> u64 {
    var n: u64 = vec_len(map);
    var k: u64 = key + 1;
    var i: u64 = 0;
    for (i = 0; i < n; i = i + 2) {
        var cur: u64 = vec_get(map, i);
        if (cur != 0 && cur == k) { return i + 1; }
    }
    return 0;
}

func _ssa_opt_use_inc(map: u64, key: u64) -> u64 {
    var idx: u64 = _ssa_opt_use_find(map, key);
    if (idx != 0) {
        var v: u64 = vec_get(map, idx);
        vec_set(map, idx, v + 1);
        return 0;
    }
    vec_push(map, key + 1);
    vec_push(map, 1);
    return 0;
}

func _ssa_opt_use_get(map: u64, key: u64) -> u64 {
    var idx: u64 = _ssa_opt_use_find(map, key);
    if (idx == 0) { return 0; }
    return vec_get(map, idx);
}

func _ssa_opt_is_dce_pure(op: u64) -> u64 {
    if (op == SSA_OP_CONST) { return 1; }
    if (op == SSA_OP_COPY) { return 1; }
    if (op == SSA_OP_ADD) { return 1; }
    if (op == SSA_OP_SUB) { return 1; }
    if (op == SSA_OP_MUL) { return 1; }
    if (op == SSA_OP_DIV) { return 1; }
    if (op == SSA_OP_MOD) { return 1; }
    if (op == SSA_OP_AND) { return 1; }
    if (op == SSA_OP_OR) { return 1; }
    if (op == SSA_OP_XOR) { return 1; }
    if (op == SSA_OP_SHL) { return 1; }
    if (op == SSA_OP_SHR) { return 1; }
    if (op == SSA_OP_EQ) { return 1; }
    if (op == SSA_OP_NE) { return 1; }
    if (op == SSA_OP_LT) { return 1; }
    if (op == SSA_OP_GT) { return 1; }
    if (op == SSA_OP_LE) { return 1; }
    if (op == SSA_OP_GE) { return 1; }
    if (op == SSA_OP_LEA_STR) { return 1; }
    if (op == SSA_OP_LEA_LOCAL) { return 1; }
    if (op == SSA_OP_LEA_GLOBAL) { return 1; }
    if (op == SSA_OP_LEA_FUNC) { return 1; }
    return 0;
}

func _ssa_opt_collect_uses(fn: *SSAFunction) -> u64 {
    var uses: u64 = vec_new(64);
    var blocks: u64 = fn->blocks_data;
    var bcount: u64 = fn->blocks_len;
    var blocks_u64: *u64 = (*u64)blocks;

    var bi: u64 = 0;
    for (bi = 0; bi < bcount; bi = bi + 1) {
        var b_ptr: u64 = *(blocks_u64 + bi);
        var b: *SSABlock = (*SSABlock)b_ptr;

        var phi: *SSAInstruction = b->phi_head;
        while (phi != 0) {
            var args: *SSAPhiArg = (*SSAPhiArg)phi->src1;
            while (args != 0) {
                _ssa_opt_use_inc(uses, args->val);
                args = args->next;
            }
            phi = phi->next;
        }

        var cur: *SSAInstruction = b->inst_head;
        while (cur != 0) {
            var op: u64 = ssa_inst_get_op(cur);

            if (op == SSA_OP_CALL) {
                var info: *SSACallInfo = (*SSACallInfo)ssa_operand_value(cur->src1);
                var arg_regs: u64 = info->args_vec;
                var total_regs: u64 = info->nargs;
                if (total_regs == 0 && arg_regs != 0) { total_regs = vec_len(arg_regs); }
                var i: u64 = 0;
                for (i = 0; i < total_regs; i = i + 1) {
                    _ssa_opt_use_inc(uses, vec_get(arg_regs, i));
                }
            } else if (op == SSA_OP_CALL_SLICE_STORE) {
                var info_slice: *SSACallSliceStoreInfo = (*SSACallSliceStoreInfo)ssa_operand_value(cur->src1);
                if (info_slice->is_ptr > 1) {
                    var info_call: *SSACallInfo = (*SSACallInfo)ssa_operand_value(cur->src1);
                    var arg_regs_slice: u64 = info_call->args_vec;
                    var total_regs_slice: u64 = info_call->nargs;
                    if (total_regs_slice == 0 && arg_regs_slice != 0) { total_regs_slice = vec_len(arg_regs_slice); }
                    var k: u64 = 0;
                    for (k = 0; k < total_regs_slice; k = k + 1) {
                        _ssa_opt_use_inc(uses, vec_get(arg_regs_slice, k));
                    }
                } else {
                    var arg_regs_slice: u64 = info_slice->args_vec;
                    var total_regs_slice: u64 = info_slice->nargs;
                    if (total_regs_slice == 0 && arg_regs_slice != 0) { total_regs_slice = vec_len(arg_regs_slice); }
                    var k2: u64 = 0;
                    for (k2 = 0; k2 < total_regs_slice; k2 = k2 + 1) {
                        _ssa_opt_use_inc(uses, vec_get(arg_regs_slice, k2));
                    }
                    if (info_slice->is_ptr != 0) {
                        _ssa_opt_use_inc(uses, info_slice->callee_reg);
                    }
                }
                if (cur->src2 != 0 && ssa_operand_is_const(cur->src2) == 0) {
                    _ssa_opt_use_inc(uses, ssa_operand_value(cur->src2));
                }
            } else if (op == SSA_OP_CALL_PTR) {
                var info2: *SSACallPtrInfo = (*SSACallPtrInfo)ssa_operand_value(cur->src1);
                _ssa_opt_use_inc(uses, info2->callee_reg);
                var arg_regs2: u64 = info2->args_vec;
                var total_regs2: u64 = info2->nargs;
                if (total_regs2 == 0 && arg_regs2 != 0) { total_regs2 = vec_len(arg_regs2); }
                var j: u64 = 0;
                for (j = 0; j < total_regs2; j = j + 1) {
                    _ssa_opt_use_inc(uses, vec_get(arg_regs2, j));
                }
            } else {
                if (cur->src1 != 0 && ssa_operand_is_const(cur->src1) == 0) {
                    _ssa_opt_use_inc(uses, ssa_operand_value(cur->src1));
                }
                if (cur->src2 != 0 && ssa_operand_is_const(cur->src2) == 0) {
                    _ssa_opt_use_inc(uses, ssa_operand_value(cur->src2));
                }
            }

            cur = cur->next;
        }
    }

    return uses;
}

func _ssa_opt_dce_run(fn: *SSAFunction) -> u64 {
    var changed: u64 = 1;
    while (changed != 0) {
        changed = 0;
        var uses: u64 = _ssa_opt_collect_uses(fn);

        var blocks: u64 = fn->blocks_data;
        var bcount: u64 = fn->blocks_len;
        var blocks_u64: *u64 = (*u64)blocks;
        var bi: u64 = 0;
        for (bi = 0; bi < bcount; bi = bi + 1) {
            var b_ptr: u64 = *(blocks_u64 + bi);
            var b: *SSABlock = (*SSABlock)b_ptr;

            var cur: *SSAInstruction = b->inst_head;
            while (cur != 0) {
                var op: u64 = ssa_inst_get_op(cur);

                if (cur->dest != 0 && _ssa_opt_is_dce_pure(op) != 0) {
                    if (_ssa_opt_use_get(uses, cur->dest) == 0) {
                        ssa_inst_set_op(cur, SSA_OP_NOP);
                        changed = 1;
                    }
                }

                cur = cur->next;
            }
        }
    }

    var blocks2: u64 = fn->blocks_data;
    var bcount2: u64 = fn->blocks_len;
    var blocks2_u64: *u64 = (*u64)blocks2;
    var bi2: u64 = 0;
    for (bi2 = 0; bi2 < bcount2; bi2 = bi2 + 1) {
        var b_ptr2: u64 = *(blocks2_u64 + bi2);
        var b2: *SSABlock = (*SSABlock)b_ptr2;
        _ssa_opt_remove_nops(b2);
    }
    return 0;
}

func _ssa_opt_is_foldable(op: u64) -> u64 {
    push_trace("_ssa_opt_is_foldable", "ssa_opt_o1.b", __LINE__);
    if (op == SSA_OP_ADD) { pop_trace(); return 1; }
    if (op == SSA_OP_SUB) { pop_trace(); return 1; }
    if (op == SSA_OP_MUL) { pop_trace(); return 1; }
    if (op == SSA_OP_DIV) { pop_trace(); return 1; }
    if (op == SSA_OP_MOD) { pop_trace(); return 1; }
    if (op == SSA_OP_AND) { pop_trace(); return 1; }
    if (op == SSA_OP_OR) { pop_trace(); return 1; }
    if (op == SSA_OP_XOR) { pop_trace(); return 1; }
    if (op == SSA_OP_SHL) { pop_trace(); return 1; }
    if (op == SSA_OP_SHR) { pop_trace(); return 1; }
    if (op == SSA_OP_EQ) { pop_trace(); return 1; }
    if (op == SSA_OP_NE) { pop_trace(); return 1; }
    if (op == SSA_OP_LT) { pop_trace(); return 1; }
    if (op == SSA_OP_GT) { pop_trace(); return 1; }
    if (op == SSA_OP_LE) { pop_trace(); return 1; }
    if (op == SSA_OP_GE) { pop_trace(); return 1; }
    pop_trace();
    return 0;
}

func _ssa_opt_fold_inst(inst: *SSAInstruction) -> u64 {
    push_trace("_ssa_opt_fold_inst", "ssa_opt_o1.b", __LINE__);
    pop_trace();
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
    else if (op == SSA_OP_MOD) {
        if (b == 0) { return 0; }
        res = a % b;
    }
    else if (op == SSA_OP_AND) { res = a & b; }
    else if (op == SSA_OP_OR) { res = a | b; }
    else if (op == SSA_OP_XOR) { res = a ^ b; }
    else if (op == SSA_OP_SHL) { res = a << b; }
    else if (op == SSA_OP_SHR) { res = a >> b; }
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
    push_trace("_ssa_opt_remove_nops", "ssa_opt_o1.b", __LINE__);
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

    pop_trace();
    return 0;
}

func ssa_opt_o1_run(ctx: *SSAContext) -> u64 {
    push_trace("ssa_opt_o1_run", "ssa_opt_o1.b", __LINE__);
    pop_trace();
    if (ctx == 0) { return 0; }

    var funcs: u64 = ctx->funcs_data;
    var n: u64 = ctx->funcs_len;
    var funcs_u64: *u64 = (*u64)funcs;
    var i: u64 = 0;
    for (i = 0; i < n; i = i + 1) {
        var f_ptr: u64 = *(funcs_u64 + i);
        var fn: *SSAFunction = (*SSAFunction)f_ptr;

        var blocks: u64 = fn->blocks_data;
        var bcount: u64 = fn->blocks_len;
        var blocks_u64: *u64 = (*u64)blocks;
        var bi: u64 = 0;
        for (bi = 0; bi < bcount; bi = bi + 1) {
            var b_ptr: u64 = *(blocks_u64 + bi);
            var b: *SSABlock = (*SSABlock)b_ptr;

            var reg_consts: u64 = vec_new(32);
            var var_consts: u64 = vec_new(32);

            var cur: *SSAInstruction = b->inst_head;
            while (cur != 0) {
                var op: u64 = ssa_inst_get_op(cur);

                if (op == SSA_OP_CONST) {
                    _ssa_opt_const_set(reg_consts, cur->dest, ssa_operand_value(cur->src1));
                    cur = cur->next;
                    continue;
                }

                if (op == SSA_OP_COPY) {
                    var v: u64 = 0;
                    var has: u64 = 0;
                    if (ssa_operand_is_const(cur->src1)) {
                        v = ssa_operand_value(cur->src1);
                        has = 1;
                    } else {
                        var idx_copy: u64 = _ssa_opt_const_find(reg_consts, ssa_operand_value(cur->src1));
                        if (idx_copy != 0) {
                            v = vec_get(reg_consts, idx_copy);
                            has = 1;
                        }
                    }
                    if (has != 0) {
                        ssa_inst_set_op(cur, SSA_OP_CONST);
                        cur->src1 = ssa_operand_const(v);
                        cur->src2 = 0;
                        _ssa_opt_const_set(reg_consts, cur->dest, v);
                    } else {
                        _ssa_opt_const_clear(reg_consts, cur->dest);
                    }
                    cur = cur->next;
                    continue;
                }

                if (op == SSA_OP_STORE) {
                    if (ssa_operand_is_const(cur->src1)) {
                        var var_id: u64 = ssa_operand_value(cur->src1);
                        var v2: u64 = 0;
                        var has: u64 = 0;
                        if (ssa_operand_is_const(cur->src2)) {
                            v2 = ssa_operand_value(cur->src2);
                            has = 1;
                        } else {
                            var idx_store: u64 = _ssa_opt_const_find(reg_consts, ssa_operand_value(cur->src2));
                            if (idx_store != 0) {
                                v2 = vec_get(reg_consts, idx_store);
                                has = 1;
                            }
                        }
                        if (has != 0) {
                            _ssa_opt_const_set(var_consts, var_id, v2);
                        } else {
                            _ssa_opt_const_clear(var_consts, var_id);
                        }
                    }
                    cur = cur->next;
                    continue;
                }

                if (op == SSA_OP_LOAD) {
                    if (ssa_operand_is_const(cur->src1)) {
                        var var_id2: u64 = ssa_operand_value(cur->src1);
                        var idx_load: u64 = _ssa_opt_const_find(var_consts, var_id2);
                        if (idx_load != 0) {
                            var v3: u64 = vec_get(var_consts, idx_load);
                            ssa_inst_set_op(cur, SSA_OP_CONST);
                            cur->src1 = ssa_operand_const(v3);
                            cur->src2 = 0;
                            _ssa_opt_const_set(reg_consts, cur->dest, v3);
                            cur = cur->next;
                            continue;
                        }
                    }
                    _ssa_opt_const_clear(reg_consts, cur->dest);
                    cur = cur->next;
                    continue;
                }

                if (_ssa_opt_is_foldable(op) != 0) {
                    if (!ssa_operand_is_const(cur->src1)) {
                        var idx1: u64 = _ssa_opt_const_find(reg_consts, ssa_operand_value(cur->src1));
                        if (idx1 != 0) {
                            var c1: u64 = vec_get(reg_consts, idx1);
                            cur->src1 = ssa_operand_const(c1);
                        }
                    }
                    if (!ssa_operand_is_const(cur->src2)) {
                        var idx2: u64 = _ssa_opt_const_find(reg_consts, ssa_operand_value(cur->src2));
                        if (idx2 != 0) {
                            var c2: u64 = vec_get(reg_consts, idx2);
                            cur->src2 = ssa_operand_const(c2);
                        }
                    }

                    if (_ssa_opt_fold_inst(cur) != 0) {
                        _ssa_opt_const_set(reg_consts, cur->dest, ssa_operand_value(cur->src1));
                    } else if (cur->dest != 0) {
                        _ssa_opt_const_clear(reg_consts, cur->dest);
                    }

                    cur = cur->next;
                    continue;
                }

                if (cur->dest != 0) {
                    _ssa_opt_const_clear(reg_consts, cur->dest);
                }

                cur = cur->next;
            }

            _ssa_opt_remove_nops(b);
        }

        _ssa_opt_dce_run(fn);
    }

    if (SSA_O1_DEBUG != 0) {
        println("[DEBUG] ssa_opt_o1_run: done", 32);
    }

    return 0;
}
