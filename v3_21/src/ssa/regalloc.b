// ssa_regalloc.b - SSA register allocation (graph coloring) (v3_17)
//
// This pass builds an interference graph using liveness analysis
// and assigns colors with a simple greedy algorithm.

import std.io;
import std.util;
import std.vec;
import ssa.datastruct;
import ssa.core;

const SSA_REGALLOC_DEBUG = 0;

const SSA_PHYS_RAX = 1;
const SSA_PHYS_RBX = 2;
const SSA_PHYS_RCX = 3;
const SSA_PHYS_RDX = 4;
const SSA_PHYS_R8 = 5;
const SSA_PHYS_R9 = 6;
const SSA_PHYS_R10 = 7;
const SSA_PHYS_R11 = 8;

const SSA_REG_MAX_LIMIT = 1048576;

var g_regalloc_ctx;

func _ssa_all_ones() -> u64 {
    var v: u64 = 0;
    v = v - 1;
    return v;
}


func _ssa_bits_len(nbits: u64) -> u64 {
    var words: u64 = nbits / 64;
    if ((nbits % 64) != 0) { words = words + 1; }
    return words;
}

func _ssa_bitset_new(nbits: u64) -> u64 {
    var words: u64 = _ssa_bits_len(nbits);
    var buf: u64 = heap_alloc(words * sizeof(u64));
    var buf_u64: *u64 = (*u64)buf;
    for (var i: u64 = 0; i < words; i++) {
        *(buf_u64 + i) = 0;
    }
    return buf;
}

func _ssa_bitset_set(buf: u64, bit: u64) -> u64 {
    var idx: u64 = bit / 64;
    var off: u64 = bit % 64;
    var mask: u64 = 1;
    mask = mask << off;
    var buf_u64: *u64 = (*u64)buf;
    *(buf_u64 + idx) = *(buf_u64 + idx) | mask;
    return 0;
}

func _ssa_bitset_clear(buf: u64, bit: u64) -> u64 {
    var idx: u64 = bit / 64;
    var off: u64 = bit % 64;
    var mask: u64 = 1;
    mask = mask << off;
    var all: u64 = _ssa_all_ones();
    var buf_u64: *u64 = (*u64)buf;
    *(buf_u64 + idx) = *(buf_u64 + idx) & (all ^ mask);
    return 0;
}

func _ssa_bitset_test(buf: u64, bit: u64) -> u64 {
    var idx: u64 = bit / 64;
    var off: u64 = bit % 64;
    var mask: u64 = 1;
    mask = mask << off;
    var buf_u64: *u64 = (*u64)buf;
    var v: u64 = *(buf_u64 + idx);
    v = v & mask;
    if (v != 0) { return 1; }
    return 0;
}

func _ssa_bitset_or(dst: u64, src: u64, nbits: u64) -> u64 {
    var words: u64 = _ssa_bits_len(nbits);
    var dst_u64: *u64 = (*u64)dst;
    var src_u64: *u64 = (*u64)src;
    for (var i: u64 = 0; i < words; i++) {
        *(dst_u64 + i) = *(dst_u64 + i) | *(src_u64 + i);
    }
    return 0;
}

func _ssa_bitset_copy(dst: u64, src: u64, nbits: u64) -> u64 {
    var words: u64 = _ssa_bits_len(nbits);
    var dst_u64: *u64 = (*u64)dst;
    var src_u64: *u64 = (*u64)src;
    for (var i: u64 = 0; i < words; i++) {
        *(dst_u64 + i) = *(src_u64 + i);
    }
    return 0;
}

func _ssa_bitset_sub(dst: u64, sub: u64, nbits: u64) -> u64 {
    var words: u64 = _ssa_bits_len(nbits);
    var all: u64 = _ssa_all_ones();
    var dst_u64: *u64 = (*u64)dst;
    var sub_u64: *u64 = (*u64)sub;
    for (var i: u64 = 0; i < words; i++) {
        *(dst_u64 + i) = *(dst_u64 + i) & (all ^ *(sub_u64 + i));
    }
    return 0;
}

func _ssa_reg_is_reasonable(id: u64) -> u64 {
    if (id == 0) { return 0; }
    var mask: u64 = 1;
    mask = mask << 63;
    if ((id & mask) != 0) { return 0; }
    if (id > SSA_REG_MAX_LIMIT) { return 0; }
    return 1;
}

func _ssa_reg_max(fn: *SSAFunction) -> u64 {
    var max_id: u64 = 0;
    var blocks: u64 = fn->blocks_data;
    var n: u64 = fn->blocks_len;
    var blocks_u64: *u64 = (*u64)blocks;
    for (var i: u64 = 0; i < n; i++) {
        var b_ptr: u64 = *(blocks_u64 + i);
        if (b_ptr == 0) { continue; }
        var b: *SSABlock = (*SSABlock)b_ptr;

        var phi: *SSAInstruction = b->phi_head;
        while (phi != 0) {
            if (_ssa_reg_is_reasonable(phi->dest) != 0 && phi->dest > max_id) { max_id = phi->dest; }
            var arg: *SSAPhiArg = (*SSAPhiArg)phi->src1;
            while (arg != 0) {
                if (_ssa_reg_is_reasonable(arg->val) != 0 && arg->val > max_id) { max_id = arg->val; }
                arg = arg->next;
            }
            phi = phi->next;
        }

        var cur: *SSAInstruction = b->inst_head;
        while (cur != 0) {
            var op: u64 = ssa_inst_get_op(cur);
            if (op != SSA_OP_BR && op != SSA_OP_JMP && op != SSA_OP_RET_SLICE_HEAP) {
                var mask: u64 = 1;
                mask = mask << 63;
                if ((cur->dest & mask) == 0) {
                    if (_ssa_reg_is_reasonable(cur->dest) != 0 && cur->dest > max_id) { max_id = cur->dest; }
                }
            }
            if (op == SSA_OP_CALL || op == SSA_OP_CALL_SLICE_STORE) {
                var info_ptr: u64 = ssa_operand_value(cur->src1);
                if (op == SSA_OP_CALL) {
                    var info: *SSACallInfo = (*SSACallInfo)info_ptr;
                    var args_vec: u64 = info->args_vec;
                    var nargs: u64 = info->nargs;
                    if (nargs == 0 && args_vec != 0) { nargs = vec_len(args_vec); }
                    for (var ai: u64 = 0; ai < nargs; ai++) {
                        var r: u64 = vec_get(args_vec, ai);
                        if (_ssa_reg_is_reasonable(r) != 0 && r > max_id) { max_id = r; }
                    }
                } else {
                    var info_s: *SSACallSliceStoreInfo = (*SSACallSliceStoreInfo)info_ptr;
                    if (info_s->is_ptr > 1) {
                        var info_call: *SSACallInfo = (*SSACallInfo)info_ptr;
                        var args_vec2: u64 = info_call->args_vec;
                        var nargs2: u64 = info_call->nargs;
                        if (nargs2 == 0 && args_vec2 != 0) { nargs2 = vec_len(args_vec2); }
                        for (var ai2: u64 = 0; ai2 < nargs2; ai2++) {
                            var r2: u64 = vec_get(args_vec2, ai2);
                            if (_ssa_reg_is_reasonable(r2) != 0 && r2 > max_id) { max_id = r2; }
                        }
                    } else {
                        if (info_s->is_ptr != 0) {
                            var callee_reg2: u64 = info_s->callee_reg;
                            if (_ssa_reg_is_reasonable(callee_reg2) != 0 && callee_reg2 > max_id) { max_id = callee_reg2; }
                        }
                        var args_vec2: u64 = info_s->args_vec;
                        var nargs2: u64 = info_s->nargs;
                        if (nargs2 == 0 && args_vec2 != 0) { nargs2 = vec_len(args_vec2); }
                        for (var ai2: u64 = 0; ai2 < nargs2; ai2++) {
                            var r2: u64 = vec_get(args_vec2, ai2);
                            if (_ssa_reg_is_reasonable(r2) != 0 && r2 > max_id) { max_id = r2; }
                        }
                    }
                }
            }
            if (op == SSA_OP_CALL_PTR) {
                var info_ptrp: u64 = ssa_operand_value(cur->src1);
                var info_ptrp_info: *SSACallPtrInfo = (*SSACallPtrInfo)info_ptrp;
                var callee_reg: u64 = info_ptrp_info->callee_reg;
                if (_ssa_reg_is_reasonable(callee_reg) != 0 && callee_reg > max_id) { max_id = callee_reg; }
                var args_vecp: u64 = info_ptrp_info->args_vec;
                var nargsp: u64 = info_ptrp_info->nargs;
                if (nargsp == 0 && args_vecp != 0) { nargsp = vec_len(args_vecp); }
                for (var aip: u64 = 0; aip < nargsp; aip++) {
                    var rp: u64 = vec_get(args_vecp, aip);
                    if (_ssa_reg_is_reasonable(rp) != 0 && rp > max_id) { max_id = rp; }
                }
            }
            if (op == SSA_OP_PHI) {
                cur = cur->next;
                continue;
            }
            if (!ssa_operand_is_const(cur->src1)) {
                var r1: u64 = ssa_operand_value(cur->src1);
                if (_ssa_reg_is_reasonable(r1) != 0 && r1 > max_id) { max_id = r1; }
            }
            if (!ssa_operand_is_const(cur->src2)) {
                var r2: u64 = ssa_operand_value(cur->src2);
                if (_ssa_reg_is_reasonable(r2) != 0 && r2 > max_id) { max_id = r2; }
            }
            cur = cur->next;
        }

    }
    return max_id;
}

func _ssa_build_use_def(fn: *SSAFunction, max_reg: u64, use_arr: u64, def_arr: u64) -> u64 {
    var blocks: u64 = fn->blocks_data;
    var n: u64 = fn->blocks_len;
    var blocks_u64: *u64 = (*u64)blocks;
    var use_arr_u64: *u64 = (*u64)use_arr;
    var def_arr_u64: *u64 = (*u64)def_arr;
    for (var i: u64 = 0; i < n; i++) {
        var b_ptr: u64 = *(blocks_u64 + i);
        var b: *SSABlock = (*SSABlock)b_ptr;

        var use: u64 = _ssa_bitset_new(max_reg + 1);
        var def: u64 = _ssa_bitset_new(max_reg + 1);

        var cur: *SSAInstruction = b->inst_head;
        while (cur != 0) {
            var op: u64 = ssa_inst_get_op(cur);
            if (op == SSA_OP_NOP) {
                cur = cur->next;
                continue;
            }

            if (op == SSA_OP_PHI) {
                if (cur->dest != 0 && cur->dest <= max_reg) {
                    _ssa_bitset_set(def, cur->dest);
                }
                cur = cur->next;
                continue;
            }

            if (op == SSA_OP_CALL || op == SSA_OP_CALL_SLICE_STORE) {
                var info_ptr2: u64 = ssa_operand_value(cur->src1);
                if (op == SSA_OP_CALL) {
                    var info2: *SSACallInfo = (*SSACallInfo)info_ptr2;
                    var args_vec2: u64 = info2->args_vec;
                    var nargs2: u64 = info2->nargs;
                    if (nargs2 == 0 && args_vec2 != 0) { nargs2 = vec_len(args_vec2); }
                    for (var ai2: u64 = 0; ai2 < nargs2; ai2++) {
                        var r3: u64 = vec_get(args_vec2, ai2);
                        if (r3 <= max_reg && _ssa_bitset_test(def, r3) == 0) {
                            _ssa_bitset_set(use, r3);
                        }
                    }
                } else {
                    var info_s2: *SSACallSliceStoreInfo = (*SSACallSliceStoreInfo)info_ptr2;
                    if (info_s2->is_ptr > 1) {
                        var info_call2: *SSACallInfo = (*SSACallInfo)info_ptr2;
                        var args_vec2a: u64 = info_call2->args_vec;
                        var nargs2a: u64 = info_call2->nargs;
                        if (nargs2a == 0 && args_vec2a != 0) { nargs2a = vec_len(args_vec2a); }
                        for (var ai2a: u64 = 0; ai2a < nargs2a; ai2a++) {
                            var r3a: u64 = vec_get(args_vec2a, ai2a);
                            if (r3a <= max_reg && _ssa_bitset_test(def, r3a) == 0) {
                                _ssa_bitset_set(use, r3a);
                            }
                        }
                    } else {
                        if (info_s2->is_ptr != 0) {
                            var callee_reg2: u64 = info_s2->callee_reg;
                            if (callee_reg2 <= max_reg && _ssa_bitset_test(def, callee_reg2) == 0) {
                                _ssa_bitset_set(use, callee_reg2);
                            }
                        }
                        var args_vec2b: u64 = info_s2->args_vec;
                        var nargs2b: u64 = info_s2->nargs;
                        if (nargs2b == 0 && args_vec2b != 0) { nargs2b = vec_len(args_vec2b); }
                        for (var ai2b: u64 = 0; ai2b < nargs2b; ai2b++) {
                            var r3b: u64 = vec_get(args_vec2b, ai2b);
                            if (r3b <= max_reg && _ssa_bitset_test(def, r3b) == 0) {
                                _ssa_bitset_set(use, r3b);
                            }
                        }
                    }
                }
            }
            if (op == SSA_OP_CALL_PTR) {
                var info_ptr2p: u64 = ssa_operand_value(cur->src1);
                var info_ptr2p_info: *SSACallPtrInfo = (*SSACallPtrInfo)info_ptr2p;
                var callee_reg: u64 = info_ptr2p_info->callee_reg;
                if (callee_reg <= max_reg && _ssa_bitset_test(def, callee_reg) == 0) {
                    _ssa_bitset_set(use, callee_reg);
                }
                var args_vec2p: u64 = info_ptr2p_info->args_vec;
                var nargs2p: u64 = info_ptr2p_info->nargs;
                if (nargs2p == 0 && args_vec2p != 0) { nargs2p = vec_len(args_vec2p); }
                for (var ai2p: u64 = 0; ai2p < nargs2p; ai2p++) {
                    var r3p: u64 = vec_get(args_vec2p, ai2p);
                    if (r3p <= max_reg && _ssa_bitset_test(def, r3p) == 0) {
                        _ssa_bitset_set(use, r3p);
                    }
                }
            }

            if (!(op == SSA_OP_CALL || op == SSA_OP_CALL_PTR)) {
                if (!ssa_operand_is_const(cur->src1)) {
                    var r1: u64 = ssa_operand_value(cur->src1);
                    if (r1 <= max_reg && _ssa_bitset_test(def, r1) == 0) {
                        _ssa_bitset_set(use, r1);
                    }
                }
                if (!ssa_operand_is_const(cur->src2)) {
                    var r2: u64 = ssa_operand_value(cur->src2);
                    if (r2 <= max_reg && _ssa_bitset_test(def, r2) == 0) {
                        _ssa_bitset_set(use, r2);
                    }
                }
            }

            if (cur->dest != 0) {
                if (op != SSA_OP_BR && op != SSA_OP_JMP && op != SSA_OP_RET_SLICE_HEAP) {
                    var mask2: u64 = 1;
                    mask2 = mask2 << 63;
                    if ((cur->dest & mask2) == 0 && cur->dest <= max_reg) {
                        _ssa_bitset_set(def, cur->dest);
                    }
                }
            }
            if (op == SSA_OP_CALL || op == SSA_OP_CALL_PTR) {
                if (cur->src2 != 0 && ssa_operand_is_const(cur->src2) == 0) {
                    var extra_def: u64 = ssa_operand_value(cur->src2);
                    if (extra_def <= max_reg) { _ssa_bitset_set(def, extra_def); }
                }
            }

            cur = cur->next;
        }

        *(use_arr_u64 + i) = use;
        *(def_arr_u64 + i) = def;
    }
    return 0;
}

func _ssa_liveness(fn: *SSAFunction, max_reg: u64, live_in: u64, live_out: u64) -> u64 {
    var n: u64 = fn->blocks_len;
    for (var i: u64 = 0; i < n; i++) {
        *(*u64)(live_in + i * 8) = _ssa_bitset_new(max_reg + 1);
        *(*u64)(live_out + i * 8) = _ssa_bitset_new(max_reg + 1);
    }

    var use_arr: u64 = heap_alloc(n * sizeof(u64));
    var def_arr: u64 = heap_alloc(n * sizeof(u64));
    _ssa_build_use_def(fn, max_reg, use_arr, def_arr);

    var changed: u64 = 1;
    while (changed != 0) {
        changed = 0;
        for (var bi: u64 = 0; bi < n; bi++) {
            var b_ptr: u64 = *(*u64)(fn->blocks_data + bi * 8);
            var b: *SSABlock = (*SSABlock)b_ptr;

            var out: u64 = _ssa_bitset_new(max_reg + 1);
            for (var si: u64 = 0; si < b->succs_len; si++) {
                var s_ptr: u64 = *(*u64)(b->succs_data + si * 8);
                var s: *SSABlock = (*SSABlock)s_ptr;
                var s_idx: u64 = 0;
                for (var bj: u64 = 0; bj < n; bj++) {
                    var bb_ptr: u64 = *(*u64)(fn->blocks_data + bj * 8);
                    var bb: *SSABlock = (*SSABlock)bb_ptr;
                    if (bb->id == s->id) { s_idx = bj; break; }
                }
                _ssa_bitset_or(out, *(*u64)(live_in + s_idx * 8), max_reg + 1);
            }

            var in: u64 = _ssa_bitset_new(max_reg + 1);
            _ssa_bitset_copy(in, out, max_reg + 1);
            _ssa_bitset_sub(in, *(*u64)(def_arr + bi * 8), max_reg + 1);
            _ssa_bitset_or(in, *(*u64)(use_arr + bi * 8), max_reg + 1);

            var changed_local: u64 = 0;
            var words: u64 = _ssa_bits_len(max_reg + 1);
            var live_in_ptr: u64 = *(*u64)(live_in + bi * 8);
            var live_out_ptr: u64 = *(*u64)(live_out + bi * 8);
            for (var wi: u64 = 0; wi < words; wi++) {
                var old_in: u64 = *(*u64)(live_in_ptr + wi * 8);
                var old_out: u64 = *(*u64)(live_out_ptr + wi * 8);
                var new_in: u64 = *(*u64)(in + wi * 8);
                var new_out: u64 = *(*u64)(out + wi * 8);
                if (old_in != new_in || old_out != new_out) { changed_local = 1; }
            }

            if (changed_local != 0) {
                _ssa_bitset_copy(*(*u64)(live_in + bi * 8), in, max_reg + 1);
                _ssa_bitset_copy(*(*u64)(live_out + bi * 8), out, max_reg + 1);
                changed = 1;
            }

        }
    }

    return 0;
}

func _ssa_interference_build(fn: *SSAFunction, max_reg: u64) -> u64 {
    var nregs: u64 = max_reg + 1;
    var adj: u64 = heap_alloc(nregs * sizeof(u64));
    for (var r: u64 = 0; r < nregs; r++) {
        *(*u64)(adj + r * 8) = _ssa_bitset_new(nregs);
    }

    var live_in: u64 = heap_alloc(fn->blocks_len * sizeof(u64));
    var live_out: u64 = heap_alloc(fn->blocks_len * sizeof(u64));
    _ssa_liveness(fn, max_reg, live_in, live_out);

    for (var bi: u64 = 0; bi < fn->blocks_len; bi++) {
        var b_ptr: u64 = *(*u64)(fn->blocks_data + bi * 8);
        var b: *SSABlock = (*SSABlock)b_ptr;
        var live: u64 = _ssa_bitset_new(nregs);
        _ssa_bitset_copy(live, *(*u64)(live_out + bi * 8), nregs);

        var insts: u64 = vec_new(8);
        var cur: *SSAInstruction = b->inst_head;
        while (cur != 0) {
            vec_push(insts, (u64)cur);
            cur = cur->next;
        }

        for (var ilen: u64 = vec_len(insts); ilen > 0; ilen = ilen - 1) {
            var iptr: u64 = vec_get(insts, ilen - 1);
            var inst: *SSAInstruction = (*SSAInstruction)iptr;
            var op: u64 = ssa_inst_get_op(inst);

            if (inst->dest != 0) {
                var d: u64 = inst->dest;
                if (d < nregs && op != SSA_OP_BR && op != SSA_OP_JMP && op != SSA_OP_RET_SLICE_HEAP) {
                    for (var i2: u64 = 1; i2 < nregs; i2++) {
                        if (_ssa_bitset_test(live, i2) != 0 && i2 != d) {
                            _ssa_bitset_set(*(*u64)(adj + d * 8), i2);
                            _ssa_bitset_set(*(*u64)(adj + i2 * 8), d);
                        }
                    }
                    _ssa_bitset_clear(live, d);
                }
            }

            if (op == SSA_OP_CALL || op == SSA_OP_CALL_SLICE_STORE) {
                var info_ptr: u64 = ssa_operand_value(inst->src1);
                if (op == SSA_OP_CALL) {
                    var info: *SSACallInfo = (*SSACallInfo)info_ptr;
                    var args_vec: u64 = info->args_vec;
                    var nargs: u64 = info->nargs;
                    if (nargs == 0 && args_vec != 0) { nargs = vec_len(args_vec); }
                    for (var ai: u64 = 0; ai < nargs; ai++) {
                        var r1: u64 = vec_get(args_vec, ai);
                        if (r1 < nregs) {
                            for (var aj: u64 = ai + 1; aj < nargs; aj++) {
                                var r2: u64 = vec_get(args_vec, aj);
                                if (r2 < nregs && r2 != r1) {
                                    _ssa_bitset_set(*(*u64)(adj + r1 * 8), r2);
                                    _ssa_bitset_set(*(*u64)(adj + r2 * 8), r1);
                                }
                            }
                        }
                    }
                } else {
                    var info_s: *SSACallSliceStoreInfo = (*SSACallSliceStoreInfo)info_ptr;
                    if (info_s->is_ptr > 1) {
                        var info_call: *SSACallInfo = (*SSACallInfo)info_ptr;
                        var args_vec2: u64 = info_call->args_vec;
                        var nargs2: u64 = info_call->nargs;
                        if (nargs2 == 0 && args_vec2 != 0) { nargs2 = vec_len(args_vec2); }
                        for (var ai2: u64 = 0; ai2 < nargs2; ai2++) {
                            var r1b: u64 = vec_get(args_vec2, ai2);
                            if (r1b < nregs) {
                                for (var aj2: u64 = ai2 + 1; aj2 < nargs2; aj2++) {
                                    var r2b: u64 = vec_get(args_vec2, aj2);
                                    if (r2b < nregs && r2b != r1b) {
                                        _ssa_bitset_set(*(*u64)(adj + r1b * 8), r2b);
                                        _ssa_bitset_set(*(*u64)(adj + r2b * 8), r1b);
                                    }
                                }
                            }
                        }
                    } else {
                        var args_vec2: u64 = info_s->args_vec;
                        var nargs2: u64 = info_s->nargs;
                        if (nargs2 == 0 && args_vec2 != 0) { nargs2 = vec_len(args_vec2); }
                        for (var ai2: u64 = 0; ai2 < nargs2; ai2++) {
                            var r1b: u64 = vec_get(args_vec2, ai2);
                            if (r1b < nregs) {
                                for (var aj2: u64 = ai2 + 1; aj2 < nargs2; aj2++) {
                                    var r2b: u64 = vec_get(args_vec2, aj2);
                                    if (r2b < nregs && r2b != r1b) {
                                        _ssa_bitset_set(*(*u64)(adj + r1b * 8), r2b);
                                        _ssa_bitset_set(*(*u64)(adj + r2b * 8), r1b);
                                    }
                                }
                            }
                        }
                    }
                }
            }
            if (op == SSA_OP_CALL_PTR) {
                var info_ptrp: u64 = ssa_operand_value(inst->src1);
                var info_ptrp_info: *SSACallPtrInfo = (*SSACallPtrInfo)info_ptrp;
                var args_vecp: u64 = info_ptrp_info->args_vec;
                var nargsp: u64 = info_ptrp_info->nargs;
                if (nargsp == 0 && args_vecp != 0) { nargsp = vec_len(args_vecp); }
                for (var aip: u64 = 0; aip < nargsp; aip++) {
                    var r1p: u64 = vec_get(args_vecp, aip);
                    if (r1p < nregs) {
                        for (var ajp: u64 = aip + 1; ajp < nargsp; ajp++) {
                            var r2p: u64 = vec_get(args_vecp, ajp);
                            if (r2p < nregs && r2p != r1p) {
                                _ssa_bitset_set(*(*u64)(adj + r1p * 8), r2p);
                                _ssa_bitset_set(*(*u64)(adj + r2p * 8), r1p);
                            }
                        }
                    }
                }
            }

            if (op == SSA_OP_RET || op == SSA_OP_RET_SLICE_HEAP) {
                if (ssa_operand_is_const(inst->src1) == 0 && ssa_operand_is_const(inst->src2) == 0) {
                    var r1: u64 = ssa_operand_value(inst->src1);
                    var r2: u64 = ssa_operand_value(inst->src2);
                    if (r1 < nregs && r2 < nregs && r1 != r2) {
                        _ssa_bitset_set(*(*u64)(adj + r1 * 8), r2);
                        _ssa_bitset_set(*(*u64)(adj + r2 * 8), r1);
                    }
                }
            }
            if (op != SSA_OP_NOP && op != SSA_OP_PHI) {
                if (op == SSA_OP_CALL || op == SSA_OP_CALL_SLICE_STORE) {
                    var info_ptr: u64 = ssa_operand_value(inst->src1);
                    if (op == SSA_OP_CALL) {
                        var info: *SSACallInfo = (*SSACallInfo)info_ptr;
                        var args_vec: u64 = info->args_vec;
                        var nargs: u64 = info->nargs;
                        if (nargs == 0 && args_vec != 0) { nargs = vec_len(args_vec); }
                        for (var ai: u64 = 0; ai < nargs; ai++) {
                            var r0: u64 = vec_get(args_vec, ai);
                            if (r0 < nregs) { _ssa_bitset_set(live, r0); }
                        }
                    } else {
                        var info_s: *SSACallSliceStoreInfo = (*SSACallSliceStoreInfo)info_ptr;
                        if (info_s->is_ptr > 1) {
                            var info_call: *SSACallInfo = (*SSACallInfo)info_ptr;
                            var args_vec2: u64 = info_call->args_vec;
                            var nargs2: u64 = info_call->nargs;
                            if (nargs2 == 0 && args_vec2 != 0) { nargs2 = vec_len(args_vec2); }
                            for (var ai2: u64 = 0; ai2 < nargs2; ai2++) {
                                var r0b: u64 = vec_get(args_vec2, ai2);
                                if (r0b < nregs) { _ssa_bitset_set(live, r0b); }
                            }
                        } else {
                            if (info_s->is_ptr != 0) {
                                var callee_reg2: u64 = info_s->callee_reg;
                                if (callee_reg2 < nregs) { _ssa_bitset_set(live, callee_reg2); }
                            }
                            var args_vec2: u64 = info_s->args_vec;
                            var nargs2: u64 = info_s->nargs;
                            if (nargs2 == 0 && args_vec2 != 0) { nargs2 = vec_len(args_vec2); }
                            for (var ai2: u64 = 0; ai2 < nargs2; ai2++) {
                                var r0b: u64 = vec_get(args_vec2, ai2);
                                if (r0b < nregs) { _ssa_bitset_set(live, r0b); }
                            }
                        }
                    }
                }
                if (op == SSA_OP_CALL_PTR) {
                    var info_ptrp2: u64 = ssa_operand_value(inst->src1);
                    var info_ptrp2_info: *SSACallPtrInfo = (*SSACallPtrInfo)info_ptrp2;
                    var callee_reg: u64 = info_ptrp2_info->callee_reg;
                    if (callee_reg < nregs) { _ssa_bitset_set(live, callee_reg); }
                    var args_vecp2: u64 = info_ptrp2_info->args_vec;
                    var nargsp2: u64 = info_ptrp2_info->nargs;
                    if (nargsp2 == 0 && args_vecp2 != 0) { nargsp2 = vec_len(args_vecp2); }
                    for (var aip2: u64 = 0; aip2 < nargsp2; aip2++) {
                        var r0p: u64 = vec_get(args_vecp2, aip2);
                        if (r0p < nregs) { _ssa_bitset_set(live, r0p); }
                    }
                }
                if (!ssa_operand_is_const(inst->src1)) {
                    var r1b: u64 = ssa_operand_value(inst->src1);
                    if (r1b < nregs) { _ssa_bitset_set(live, r1b); }
                }
                if (!ssa_operand_is_const(inst->src2)) {
                    var r2b: u64 = ssa_operand_value(inst->src2);
                    if (r2b < nregs) { _ssa_bitset_set(live, r2b); }
                }
            }
        }

    }

    return adj;
}

func ssa_regalloc_color_fn(fn: *SSAFunction, k: u64) -> u64 {
    var max_reg: u64 = _ssa_reg_max(fn);
    if (max_reg == 0) { return 0; }

    var adj: u64 = _ssa_interference_build(fn, max_reg);
    var colors: u64 = heap_alloc((max_reg + 1) * sizeof(u64));
    for (var i: u64 = 0; i <= max_reg; i++) {
        *(*u64)(colors + i * 8) = 0;
    }

    for (var r: u64 = 1; r <= max_reg; r++) {
        var used: u64 = heap_alloc((k + 1) * sizeof(u64));
        for (var j: u64 = 0; j <= k; j++) {
            *(*u64)(used + j * 8) = 0;
        }

        var neigh: u64 = *(*u64)(adj + r * 8);
        for (var n: u64 = 1; n <= max_reg; n++) {
            if (_ssa_bitset_test(neigh, n) != 0) {
                var c: u64 = *(*u64)(colors + n * 8);
                if (c <= k) { *(*u64)(used + c * 8) = 1; }
            }
        }

        var color: u64 = k + 1;
        for (var c: u64 = 1; c <= k; c++) {
            if (*(*u64)(used + c * 8) == 0) { color = c; break; }
        }

        if (color > k) { color = 0; }
        *(*u64)(colors + r * 8) = color;
    }

    if (SSA_REGALLOC_DEBUG != 0) {
        println("[DEBUG] ssa_regalloc_color_fn: done", 36);
    }

    return colors;
}

func _ssa_regalloc_color_to_phys(color: u64) -> u64 {
    switch (color) {
        case 1: return SSA_PHYS_RAX;
        case 2: return SSA_PHYS_RBX;
        case 3: return SSA_PHYS_RCX;
        case 4: return SSA_PHYS_RDX;
        case 5: return SSA_PHYS_R8;
        case 6: return SSA_PHYS_R9;
        case 7: return SSA_PHYS_R10;
        case 8: return SSA_PHYS_R11;
        default: return 0;
    }
}

func ssa_regalloc_map_fn(fn: *SSAFunction, k: u64) -> u64 {
    var max_reg: u64 = _ssa_reg_max(fn);
    if (max_reg == 0) { return 0; }

    var colors: u64 = ssa_regalloc_color_fn(fn, k);
    if (colors == 0) { return 0; }

    var map: u64 = heap_alloc((max_reg + 1) * sizeof(u64));
    for (var i: u64 = 0; i <= max_reg; i++) {
        *(*u64)(map + i * 8) = 0;
    }

    for (var r: u64 = 1; r <= max_reg; r++) {
        var c: u64 = *(*u64)(colors + r * 8);
        *(*u64)(map + r * 8) = _ssa_regalloc_color_to_phys(c);
    }

    fn->reg_map_data = map;
    fn->reg_map_len = max_reg + 1;
    return map;
}

func ssa_regalloc_run(ctx: *SSAContext, k: u64) -> u64 {
    push_trace("ssa_regalloc_run", "ssa_regalloc.b", __LINE__);
    if (ctx == 0) { pop_trace(); return 0; }
    g_regalloc_ctx = (u64)ctx;
    var funcs: u64 = ctx->funcs_data;
    var n: u64 = ctx->funcs_len;
    for (var i: u64 = 0; i < n; i++) {
        var f_ptr: u64 = *(*u64)(funcs + i * 8);
        if (SSA_REGALLOC_DEBUG != 0) {
            println("[DEBUG] ssa_regalloc_run", 26);
        }
        var fn: *SSAFunction = (*SSAFunction)f_ptr;
        ssa_regalloc_map_fn(fn, k);
        ssa_regalloc_apply_fn(fn);
    }
    pop_trace();
    return 0;
}

func ssa_regalloc_apply_fn(fn: *SSAFunction) -> u64 {
    push_trace("ssa_regalloc_apply_fn", "ssa_regalloc.b", __LINE__);
    if (fn == 0) { pop_trace(); return 0; }
    if (fn->reg_map_data == 0) { pop_trace(); return 0; }

    var blocks: u64 = fn->blocks_data;
    var n: u64 = fn->blocks_len;
    if (blocks == 0 || n == 0) { pop_trace(); return 0; }

    var map: u64 = fn->reg_map_data;
    var map_len: u64 = fn->reg_map_len;
    if (SSA_REGALLOC_DEBUG != 0) {
        println("[DEBUG] ssa_regalloc_apply_fn", 30);
        print("  fn=", 5);
        print_u64((u64)fn);
        print(" blocks_len=", 12);
        print_u64(n);
        print(" map_len=", 9);
        print_u64(map_len);
        print_nl();
    }
    for (var i: u64 = 0; i < n; i++) {
        var b_ptr: u64 = *(*u64)(blocks + i * 8);
        if (b_ptr == 0) { continue; }
        var b: *SSABlock = (*SSABlock)b_ptr;
        if (SSA_REGALLOC_DEBUG != 0) {
            print("  block idx=", 12);
            print_u64(i);
            print(" ptr=", 5);
            print_u64(b_ptr);
            print(" id=", 4);
            print_u64(b->id);
            print(" phi=", 5);
            print_u64((u64)b->phi_head);
            print(" inst=", 6);
            print_u64((u64)b->inst_head);
            print_nl();
        }

        var phi: *SSAInstruction = b->phi_head;
        while (phi != 0) {
            if (phi->dest < map_len) {
                var p: u64 = *(*u64)(map + phi->dest * 8);
                if (p != 0) { phi->dest = p; }
            }
            var args: *SSAPhiArg = (*SSAPhiArg)phi->src1;
            while (args != 0) {
                if (args->val < map_len) {
                    var p2: u64 = *(*u64)(map + args->val * 8);
                    if (p2 != 0) { args->val = p2; }
                }
                args = args->next;
            }
            phi = phi->next;
        }

        var cur: *SSAInstruction = b->inst_head;
        while (cur != 0) {
            var op2: u64 = ssa_inst_get_op(cur);
            if (op2 != SSA_OP_BR && op2 != SSA_OP_JMP && op2 != SSA_OP_RET_SLICE_HEAP) {
                if (cur->dest != 0 && cur->dest < map_len) {
                    var pd: u64 = *(*u64)(map + cur->dest * 8);
                    if (pd != 0) { cur->dest = pd; }
                }
            }
            if (op2 == SSA_OP_CALL || op2 == SSA_OP_CALL_SLICE_STORE) {
                var info_ptr: u64 = ssa_operand_value(cur->src1);
                if (op2 == SSA_OP_CALL) {
                    var info: *SSACallInfo = (*SSACallInfo)info_ptr;
                    var args_vec: u64 = info->args_vec;
                    var nargs: u64 = info->nargs;
                    if (nargs == 0 && args_vec != 0) { nargs = vec_len(args_vec); }
                    for (var ai: u64 = 0; ai < nargs; ai++) {
                        var r: u64 = vec_get(args_vec, ai);
                        if (r < map_len) {
                            var pr: u64 = *(*u64)(map + r * 8);
                            if (pr != 0) { vec_set(args_vec, ai, pr); }
                        }
                    }
                } else {
                    var info_s: *SSACallSliceStoreInfo = (*SSACallSliceStoreInfo)info_ptr;
                    if (info_s->is_ptr > 1) {
                        var info_call: *SSACallInfo = (*SSACallInfo)info_ptr;
                        var args_vec2: u64 = info_call->args_vec;
                        var nargs2: u64 = info_call->nargs;
                        if (nargs2 == 0 && args_vec2 != 0) { nargs2 = vec_len(args_vec2); }
                        for (var ai2: u64 = 0; ai2 < nargs2; ai2++) {
                            var r2: u64 = vec_get(args_vec2, ai2);
                            if (r2 < map_len) {
                                var pr2: u64 = *(*u64)(map + r2 * 8);
                                if (pr2 != 0) { vec_set(args_vec2, ai2, pr2); }
                            }
                        }
                    } else {
                        if (info_s->is_ptr != 0) {
                            var callee_reg2: u64 = info_s->callee_reg;
                            if (callee_reg2 < map_len) {
                                var pcallee2: u64 = *(*u64)(map + callee_reg2 * 8);
                                if (pcallee2 != 0) { info_s->callee_reg = pcallee2; }
                            }
                        }
                        var args_vec2: u64 = info_s->args_vec;
                        var nargs2: u64 = info_s->nargs;
                        if (nargs2 == 0 && args_vec2 != 0) { nargs2 = vec_len(args_vec2); }
                        for (var ai2: u64 = 0; ai2 < nargs2; ai2++) {
                            var r2: u64 = vec_get(args_vec2, ai2);
                            if (r2 < map_len) {
                                var pr2: u64 = *(*u64)(map + r2 * 8);
                                if (pr2 != 0) { vec_set(args_vec2, ai2, pr2); }
                            }
                        }
                    }
                }
            }
            if (op2 == SSA_OP_CALL_PTR) {
                var info_ptrp: u64 = ssa_operand_value(cur->src1);
                var info_ptrp_info: *SSACallPtrInfo = (*SSACallPtrInfo)info_ptrp;
                var callee_reg: u64 = info_ptrp_info->callee_reg;
                if (callee_reg < map_len) {
                    var pcallee: u64 = *(*u64)(map + callee_reg * 8);
                    if (pcallee != 0) { info_ptrp_info->callee_reg = pcallee; }
                }
                var args_vecp: u64 = info_ptrp_info->args_vec;
                var nargsp: u64 = info_ptrp_info->nargs;
                if (nargsp == 0 && args_vecp != 0) { nargsp = vec_len(args_vecp); }
                for (var aip: u64 = 0; aip < nargsp; aip++) {
                    var r: u64 = vec_get(args_vecp, aip);
                    if (r < map_len) {
                        var pr: u64 = *(*u64)(map + r * 8);
                        if (pr != 0) { vec_set(args_vecp, aip, pr); }
                    }
                }
            }
            if (!ssa_operand_is_const(cur->src1)) {
                var r1: u64 = ssa_operand_value(cur->src1);
                if (r1 < map_len) {
                    var p: u64 = *(*u64)(map + r1 * 8);
                    if (p != 0) { cur->src1 = ssa_operand_reg(p); }
                }
            }
            if (!ssa_operand_is_const(cur->src2)) {
                var r2: u64 = ssa_operand_value(cur->src2);
                if (r2 < map_len) {
                    var p2: u64 = *(*u64)(map + r2 * 8);
                    if (p2 != 0) { cur->src2 = ssa_operand_reg(p2); }
                }
            }
            if (op2 == SSA_OP_RET_SLICE_HEAP) {
                ssa_ret_slice_heap_remap_ex((u64)cur, map, map_len);
            }
            cur = cur->next;
        }

    }

    pop_trace();
    return 0;
}

func ssa_regalloc_apply_run(ctx: *SSAContext) -> u64 {
    push_trace("ssa_regalloc_apply_run", "ssa_regalloc.b", __LINE__);
    if (ctx == 0 && g_regalloc_ctx != 0) {
        ctx = (*SSAContext)g_regalloc_ctx;
    }
    if (ctx == 0) { pop_trace(); return 0; }
    if (ctx->funcs_data == 0 && g_regalloc_ctx != 0) {
        ctx = (*SSAContext)g_regalloc_ctx;
    }
    var funcs: u64 = ctx->funcs_data;
    var n: u64 = ctx->funcs_len;
    for (var i: u64 = 0; i < n; i++) {
        var f_ptr: u64 = *(*u64)(funcs + i * 8);
        ssa_regalloc_apply_fn((*SSAFunction)f_ptr);
    }
    pop_trace();
    return 0;
}
