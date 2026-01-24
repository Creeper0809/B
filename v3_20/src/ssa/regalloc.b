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
    var buf: u64 = heap_alloc(words * 8);
    var i: u64 = 0;
    while (i < words) {
        *(*u64)(buf + i * 8) = 0;
        i = i + 1;
    }
    return buf;
}

func _ssa_bitset_set(buf: u64, bit: u64) -> u64 {
    var idx: u64 = bit / 64;
    var off: u64 = bit % 64;
    var mask: u64 = 1;
    mask = mask << off;
    *(*u64)(buf + idx * 8) = *(*u64)(buf + idx * 8) | mask;
    return 0;
}

func _ssa_bitset_clear(buf: u64, bit: u64) -> u64 {
    var idx: u64 = bit / 64;
    var off: u64 = bit % 64;
    var mask: u64 = 1;
    mask = mask << off;
    var all: u64 = _ssa_all_ones();
    *(*u64)(buf + idx * 8) = *(*u64)(buf + idx * 8) & (all ^ mask);
    return 0;
}

func _ssa_bitset_test(buf: u64, bit: u64) -> u64 {
    var idx: u64 = bit / 64;
    var off: u64 = bit % 64;
    var mask: u64 = 1;
    mask = mask << off;
    var v: u64 = *(*u64)(buf + idx * 8);
    v = v & mask;
    if (v != 0) { return 1; }
    return 0;
}

func _ssa_bitset_or(dst: u64, src: u64, nbits: u64) -> u64 {
    var words: u64 = _ssa_bits_len(nbits);
    var i: u64 = 0;
    while (i < words) {
        *(*u64)(dst + i * 8) = *(*u64)(dst + i * 8) | *(*u64)(src + i * 8);
        i = i + 1;
    }
    return 0;
}

func _ssa_bitset_copy(dst: u64, src: u64, nbits: u64) -> u64 {
    var words: u64 = _ssa_bits_len(nbits);
    var i: u64 = 0;
    while (i < words) {
        *(*u64)(dst + i * 8) = *(*u64)(src + i * 8);
        i = i + 1;
    }
    return 0;
}

func _ssa_bitset_sub(dst: u64, sub: u64, nbits: u64) -> u64 {
    var words: u64 = _ssa_bits_len(nbits);
    var all: u64 = _ssa_all_ones();
    var i: u64 = 0;
    while (i < words) {
        *(*u64)(dst + i * 8) = *(*u64)(dst + i * 8) & (all ^ *(*u64)(sub + i * 8));
        i = i + 1;
    }
    return 0;
}

func _ssa_reg_max(fn: *SSAFunction) -> u64 {
    var max_id: u64 = 0;
    var blocks: u64 = fn->blocks_data;
    var n: u64 = fn->blocks_len;
    var i: u64 = 0;
    while (i < n) {
        var b_ptr: u64 = *(*u64)(blocks + i * 8);
        if (b_ptr == 0) { i = i + 1; continue; }
        var b: *SSABlock = (*SSABlock)b_ptr;

        var phi: *SSAInstruction = b->phi_head;
        while (phi != 0) {
            if (phi->dest > max_id) { max_id = phi->dest; }
            var arg: *SSAPhiArg = (*SSAPhiArg)phi->src1;
            while (arg != 0) {
                if (arg->val > max_id) { max_id = arg->val; }
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
                    if (cur->dest > max_id) { max_id = cur->dest; }
                }
            }
            if (op == SSA_OP_CALL || op == SSA_OP_CALL_SLICE_STORE) {
                var info_ptr: u64 = ssa_operand_value(cur->src1);
                var args_vec: u64 = *(info_ptr + 16);
                var nargs: u64 = *(info_ptr + 24);
                if (nargs == 0 && args_vec != 0) { nargs = vec_len(args_vec); }
                var ai: u64 = 0;
                while (ai < nargs) {
                    var r: u64 = vec_get(args_vec, ai);
                    if (r > max_id) { max_id = r; }
                    ai = ai + 1;
                }
            }
            if (op == SSA_OP_CALL_PTR) {
                var info_ptrp: u64 = ssa_operand_value(cur->src1);
                var callee_reg: u64 = *(info_ptrp);
                if (callee_reg > max_id) { max_id = callee_reg; }
                var args_vecp: u64 = *(info_ptrp + 8);
                var nargsp: u64 = *(info_ptrp + 16);
                if (nargsp == 0 && args_vecp != 0) { nargsp = vec_len(args_vecp); }
                var aip: u64 = 0;
                while (aip < nargsp) {
                    var rp: u64 = vec_get(args_vecp, aip);
                    if (rp > max_id) { max_id = rp; }
                    aip = aip + 1;
                }
            }
            if (op == SSA_OP_PHI) {
                cur = cur->next;
                continue;
            }
            if (!ssa_operand_is_const(cur->src1)) {
                var r1: u64 = ssa_operand_value(cur->src1);
                if (r1 > max_id) { max_id = r1; }
            }
            if (!ssa_operand_is_const(cur->src2)) {
                var r2: u64 = ssa_operand_value(cur->src2);
                if (r2 > max_id) { max_id = r2; }
            }
            cur = cur->next;
        }

        i = i + 1;
    }
    return max_id;
}

func _ssa_build_use_def(fn: *SSAFunction, max_reg: u64, use_arr: u64, def_arr: u64) -> u64 {
    var blocks: u64 = fn->blocks_data;
    var n: u64 = fn->blocks_len;
    var i: u64 = 0;
    while (i < n) {
        var b_ptr: u64 = *(*u64)(blocks + i * 8);
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
                var args_vec2: u64 = *(info_ptr2 + 16);
                var nargs2: u64 = *(info_ptr2 + 24);
                if (nargs2 == 0 && args_vec2 != 0) { nargs2 = vec_len(args_vec2); }
                var ai2: u64 = 0;
                while (ai2 < nargs2) {
                    var r3: u64 = vec_get(args_vec2, ai2);
                    if (r3 <= max_reg && _ssa_bitset_test(def, r3) == 0) {
                        _ssa_bitset_set(use, r3);
                    }
                    ai2 = ai2 + 1;
                }
            }
            if (op == SSA_OP_CALL_PTR) {
                var info_ptr2p: u64 = ssa_operand_value(cur->src1);
                var callee_reg: u64 = *(info_ptr2p);
                if (callee_reg <= max_reg && _ssa_bitset_test(def, callee_reg) == 0) {
                    _ssa_bitset_set(use, callee_reg);
                }
                var args_vec2p: u64 = *(info_ptr2p + 8);
                var nargs2p: u64 = *(info_ptr2p + 16);
                if (nargs2p == 0 && args_vec2p != 0) { nargs2p = vec_len(args_vec2p); }
                var ai2p: u64 = 0;
                while (ai2p < nargs2p) {
                    var r3p: u64 = vec_get(args_vec2p, ai2p);
                    if (r3p <= max_reg && _ssa_bitset_test(def, r3p) == 0) {
                        _ssa_bitset_set(use, r3p);
                    }
                    ai2p = ai2p + 1;
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

        *(*u64)(use_arr + i * 8) = use;
        *(*u64)(def_arr + i * 8) = def;
        i = i + 1;
    }
    return 0;
}

func _ssa_liveness(fn: *SSAFunction, max_reg: u64, live_in: u64, live_out: u64) -> u64 {
    var n: u64 = fn->blocks_len;
    var i: u64 = 0;
    while (i < n) {
        *(*u64)(live_in + i * 8) = _ssa_bitset_new(max_reg + 1);
        *(*u64)(live_out + i * 8) = _ssa_bitset_new(max_reg + 1);
        i = i + 1;
    }

    var use_arr: u64 = heap_alloc(n * 8);
    var def_arr: u64 = heap_alloc(n * 8);
    _ssa_build_use_def(fn, max_reg, use_arr, def_arr);

    var changed: u64 = 1;
    while (changed != 0) {
        changed = 0;
        var bi: u64 = 0;
        while (bi < n) {
            var b_ptr: u64 = *(*u64)(fn->blocks_data + bi * 8);
            var b: *SSABlock = (*SSABlock)b_ptr;

            var out: u64 = _ssa_bitset_new(max_reg + 1);
            var si: u64 = 0;
            while (si < b->succs_len) {
                var s_ptr: u64 = *(*u64)(b->succs_data + si * 8);
                var s: *SSABlock = (*SSABlock)s_ptr;
                var s_idx: u64 = 0;
                var bj: u64 = 0;
                while (bj < n) {
                    var bb_ptr: u64 = *(*u64)(fn->blocks_data + bj * 8);
                    var bb: *SSABlock = (*SSABlock)bb_ptr;
                    if (bb->id == s->id) { s_idx = bj; break; }
                    bj = bj + 1;
                }
                _ssa_bitset_or(out, *(*u64)(live_in + s_idx * 8), max_reg + 1);
                si = si + 1;
            }

            var in: u64 = _ssa_bitset_new(max_reg + 1);
            _ssa_bitset_copy(in, out, max_reg + 1);
            _ssa_bitset_sub(in, *(*u64)(def_arr + bi * 8), max_reg + 1);
            _ssa_bitset_or(in, *(*u64)(use_arr + bi * 8), max_reg + 1);

            var changed_local: u64 = 0;
            var words: u64 = _ssa_bits_len(max_reg + 1);
            var live_in_ptr: u64 = *(*u64)(live_in + bi * 8);
            var live_out_ptr: u64 = *(*u64)(live_out + bi * 8);
            var wi: u64 = 0;
            while (wi < words) {
                var old_in: u64 = *(*u64)(live_in_ptr + wi * 8);
                var old_out: u64 = *(*u64)(live_out_ptr + wi * 8);
                var new_in: u64 = *(*u64)(in + wi * 8);
                var new_out: u64 = *(*u64)(out + wi * 8);
                if (old_in != new_in || old_out != new_out) { changed_local = 1; }
                wi = wi + 1;
            }

            if (changed_local != 0) {
                _ssa_bitset_copy(*(*u64)(live_in + bi * 8), in, max_reg + 1);
                _ssa_bitset_copy(*(*u64)(live_out + bi * 8), out, max_reg + 1);
                changed = 1;
            }

            bi = bi + 1;
        }
    }

    return 0;
}

func _ssa_interference_build(fn: *SSAFunction, max_reg: u64) -> u64 {
    var nregs: u64 = max_reg + 1;
    var adj: u64 = heap_alloc(nregs * 8);
    var r: u64 = 0;
    while (r < nregs) {
        *(*u64)(adj + r * 8) = _ssa_bitset_new(nregs);
        r = r + 1;
    }

    var live_in: u64 = heap_alloc(fn->blocks_len * 8);
    var live_out: u64 = heap_alloc(fn->blocks_len * 8);
    _ssa_liveness(fn, max_reg, live_in, live_out);

    var bi: u64 = 0;
    while (bi < fn->blocks_len) {
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

        var ilen: u64 = vec_len(insts);
        while (ilen > 0) {
            ilen = ilen - 1;
            var iptr: u64 = vec_get(insts, ilen);
            var inst: *SSAInstruction = (*SSAInstruction)iptr;
            var op: u64 = ssa_inst_get_op(inst);

            if (inst->dest != 0) {
                var d: u64 = inst->dest;
                if (d < nregs && op != SSA_OP_BR && op != SSA_OP_JMP) {
                    var i2: u64 = 1;
                    while (i2 < nregs) {
                        if (_ssa_bitset_test(live, i2) != 0 && i2 != d) {
                            _ssa_bitset_set(*(*u64)(adj + d * 8), i2);
                            _ssa_bitset_set(*(*u64)(adj + i2 * 8), d);
                        }
                        i2 = i2 + 1;
                    }
                    _ssa_bitset_clear(live, d);
                }
            }

            if (op == SSA_OP_CALL || op == SSA_OP_CALL_SLICE_STORE) {
                var info_ptr: u64 = ssa_operand_value(inst->src1);
                var args_vec: u64 = *(info_ptr + 16);
                var nargs: u64 = *(info_ptr + 24);
                if (nargs == 0 && args_vec != 0) { nargs = vec_len(args_vec); }
                var ai: u64 = 0;
                while (ai < nargs) {
                    var r1: u64 = vec_get(args_vec, ai);
                    if (r1 < nregs) {
                        var aj: u64 = ai + 1;
                        while (aj < nargs) {
                            var r2: u64 = vec_get(args_vec, aj);
                            if (r2 < nregs && r2 != r1) {
                                _ssa_bitset_set(*(*u64)(adj + r1 * 8), r2);
                                _ssa_bitset_set(*(*u64)(adj + r2 * 8), r1);
                            }
                            aj = aj + 1;
                        }
                    }
                    ai = ai + 1;
                }
            }
            if (op == SSA_OP_CALL_PTR) {
                var info_ptrp: u64 = ssa_operand_value(inst->src1);
                var args_vecp: u64 = *(info_ptrp + 8);
                var nargsp: u64 = *(info_ptrp + 16);
                if (nargsp == 0 && args_vecp != 0) { nargsp = vec_len(args_vecp); }
                var aip: u64 = 0;
                while (aip < nargsp) {
                    var r1p: u64 = vec_get(args_vecp, aip);
                    if (r1p < nregs) {
                        var ajp: u64 = aip + 1;
                        while (ajp < nargsp) {
                            var r2p: u64 = vec_get(args_vecp, ajp);
                            if (r2p < nregs && r2p != r1p) {
                                _ssa_bitset_set(*(*u64)(adj + r1p * 8), r2p);
                                _ssa_bitset_set(*(*u64)(adj + r2p * 8), r1p);
                            }
                            ajp = ajp + 1;
                        }
                    }
                    aip = aip + 1;
                }
            }

            if (op != SSA_OP_NOP && op != SSA_OP_PHI) {
                if (op == SSA_OP_CALL || op == SSA_OP_CALL_SLICE_STORE) {
                    var info_ptr: u64 = ssa_operand_value(inst->src1);
                    var args_vec: u64 = *(info_ptr + 16);
                    var nargs: u64 = *(info_ptr + 24);
                    if (nargs == 0 && args_vec != 0) { nargs = vec_len(args_vec); }
                    var ai: u64 = 0;
                    while (ai < nargs) {
                        var r0: u64 = vec_get(args_vec, ai);
                        if (r0 < nregs) { _ssa_bitset_set(live, r0); }
                        ai = ai + 1;
                    }
                }
                if (op == SSA_OP_CALL_PTR) {
                    var info_ptrp2: u64 = ssa_operand_value(inst->src1);
                    var callee_reg: u64 = *(info_ptrp2);
                    if (callee_reg < nregs) { _ssa_bitset_set(live, callee_reg); }
                    var args_vecp2: u64 = *(info_ptrp2 + 8);
                    var nargsp2: u64 = *(info_ptrp2 + 16);
                    if (nargsp2 == 0 && args_vecp2 != 0) { nargsp2 = vec_len(args_vecp2); }
                    var aip2: u64 = 0;
                    while (aip2 < nargsp2) {
                        var r0p: u64 = vec_get(args_vecp2, aip2);
                        if (r0p < nregs) { _ssa_bitset_set(live, r0p); }
                        aip2 = aip2 + 1;
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

        bi = bi + 1;
    }

    return adj;
}

func ssa_regalloc_color_fn(fn: *SSAFunction, k: u64) -> u64 {
    var max_reg: u64 = _ssa_reg_max(fn);
    if (max_reg == 0) { return 0; }

    var adj: u64 = _ssa_interference_build(fn, max_reg);
    var colors: u64 = heap_alloc((max_reg + 1) * 8);
    var i: u64 = 0;
    while (i <= max_reg) {
        *(*u64)(colors + i * 8) = 0;
        i = i + 1;
    }

    var r: u64 = 1;
    while (r <= max_reg) {
        var used: u64 = heap_alloc((k + 1) * 8);
        var j: u64 = 0;
        while (j <= k) {
            *(*u64)(used + j * 8) = 0;
            j = j + 1;
        }

        var neigh: u64 = *(*u64)(adj + r * 8);
        var n: u64 = 1;
        while (n <= max_reg) {
            if (_ssa_bitset_test(neigh, n) != 0) {
                var c: u64 = *(*u64)(colors + n * 8);
                if (c <= k) { *(*u64)(used + c * 8) = 1; }
            }
            n = n + 1;
        }

        var color: u64 = 1;
        while (color <= k) {
            if (*(*u64)(used + color * 8) == 0) { break; }
            color = color + 1;
        }

        if (color > k) { color = 0; }
        *(*u64)(colors + r * 8) = color;
        r = r + 1;
    }

    if (SSA_REGALLOC_DEBUG != 0) {
        println("[DEBUG] ssa_regalloc_color_fn: done", 36);
    }

    return colors;
}

func _ssa_regalloc_color_to_phys(color: u64) -> u64 {
    if (color == 1) { return SSA_PHYS_RAX; }
    if (color == 2) { return SSA_PHYS_RBX; }
    if (color == 3) { return SSA_PHYS_RCX; }
    if (color == 4) { return SSA_PHYS_RDX; }
    if (color == 5) { return SSA_PHYS_R8; }
    if (color == 6) { return SSA_PHYS_R9; }
    if (color == 7) { return SSA_PHYS_R10; }
    if (color == 8) { return SSA_PHYS_R11; }
    return 0;
}

func ssa_regalloc_map_fn(fn: *SSAFunction, k: u64) -> u64 {
    var max_reg: u64 = _ssa_reg_max(fn);
    if (max_reg == 0) { return 0; }

    var colors: u64 = ssa_regalloc_color_fn(fn, k);
    if (colors == 0) { return 0; }

    var map: u64 = heap_alloc((max_reg + 1) * 8);
    var i: u64 = 0;
    while (i <= max_reg) {
        *(*u64)(map + i * 8) = 0;
        i = i + 1;
    }

    var r: u64 = 1;
    while (r <= max_reg) {
        var c: u64 = *(*u64)(colors + r * 8);
        *(*u64)(map + r * 8) = _ssa_regalloc_color_to_phys(c);
        r = r + 1;
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
    var i: u64 = 0;
    while (i < n) {
        var f_ptr: u64 = *(*u64)(funcs + i * 8);
        if (SSA_REGALLOC_DEBUG != 0) {
            println("[DEBUG] ssa_regalloc_run", 26);
        }
        var fn: *SSAFunction = (*SSAFunction)f_ptr;
        ssa_regalloc_map_fn(fn, k);
        ssa_regalloc_apply_fn(fn);
        i = i + 1;
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
    var i: u64 = 0;
    while (i < n) {
        var b_ptr: u64 = *(*u64)(blocks + i * 8);
        if (b_ptr == 0) { i = i + 1; continue; }
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
            var arg: *SSAPhiArg = (*SSAPhiArg)phi->src1;
            while (arg != 0) {
                if (arg->val < map_len) {
                    var p2: u64 = *(*u64)(map + arg->val * 8);
                    if (p2 != 0) { arg->val = p2; }
                }
                arg = arg->next;
            }
            phi = phi->next;
        }

        var cur: *SSAInstruction = b->inst_head;
        while (cur != 0) {
            var op2: u64 = ssa_inst_get_op(cur);
            if (op2 != SSA_OP_BR && op2 != SSA_OP_JMP) {
                if (cur->dest != 0 && cur->dest < map_len) {
                    var pd: u64 = *(*u64)(map + cur->dest * 8);
                    if (pd != 0) { cur->dest = pd; }
                }
            }
            if (op2 == SSA_OP_CALL || op2 == SSA_OP_CALL_SLICE_STORE) {
                var info_ptr: u64 = ssa_operand_value(cur->src1);
                var args_vec: u64 = *(info_ptr + 16);
                var nargs: u64 = *(info_ptr + 24);
                if (nargs == 0 && args_vec != 0) { nargs = vec_len(args_vec); }
                var ai: u64 = 0;
                while (ai < nargs) {
                    var r: u64 = vec_get(args_vec, ai);
                    if (r < map_len) {
                        var pr: u64 = *(*u64)(map + r * 8);
                        if (pr != 0) { vec_set(args_vec, ai, pr); }
                    }
                    ai = ai + 1;
                }
            }
            if (op2 == SSA_OP_CALL_PTR) {
                var info_ptrp: u64 = ssa_operand_value(cur->src1);
                var callee_reg: u64 = *(info_ptrp);
                if (callee_reg < map_len) {
                    var pcallee: u64 = *(*u64)(map + callee_reg * 8);
                    if (pcallee != 0) { *(info_ptrp) = pcallee; }
                }
                var args_vecp: u64 = *(info_ptrp + 8);
                var nargsp: u64 = *(info_ptrp + 16);
                if (nargsp == 0 && args_vecp != 0) { nargsp = vec_len(args_vecp); }
                var aip: u64 = 0;
                while (aip < nargsp) {
                    var r: u64 = vec_get(args_vecp, aip);
                    if (r < map_len) {
                        var pr: u64 = *(*u64)(map + r * 8);
                        if (pr != 0) { vec_set(args_vecp, aip, pr); }
                    }
                    aip = aip + 1;
                }
            }
            if (!ssa_operand_is_const(cur->src1)) {
                var r1: u64 = ssa_operand_value(cur->src1);
                if (r1 < map_len) {
                    var p1: u64 = *(*u64)(map + r1 * 8);
                    if (p1 != 0) { cur->src1 = ssa_operand_reg(p1); }
                }
            }
            if (!ssa_operand_is_const(cur->src2)) {
                var r2: u64 = ssa_operand_value(cur->src2);
                if (r2 < map_len) {
                    var p2: u64 = *(*u64)(map + r2 * 8);
                    if (p2 != 0) { cur->src2 = ssa_operand_reg(p2); }
                }
            }
            cur = cur->next;
        }

        i = i + 1;
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
    var i: u64 = 0;
    while (i < n) {
        var f_ptr: u64 = *(*u64)(funcs + i * 8);
        ssa_regalloc_apply_fn((*SSAFunction)f_ptr);
        i = i + 1;
    }
    pop_trace();
    return 0;
}
