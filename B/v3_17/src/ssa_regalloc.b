// ssa_regalloc.b - SSA register allocation (graph coloring) (v3_17)
//
// This pass builds an interference graph using liveness analysis
// and assigns colors with a simple greedy algorithm.

import std.io;
import std.vec;
import ssa;

const SSA_REGALLOC_DEBUG = 0;

const SSA_PHYS_RAX = 1;
const SSA_PHYS_RBX = 2;
const SSA_PHYS_RCX = 3;
const SSA_PHYS_RDX = 4;
const SSA_PHYS_R8 = 5;
const SSA_PHYS_R9 = 6;

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
            if (cur->dest > max_id) { max_id = cur->dest; }
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

            if (!ssa_operand_is_const(cur->src1)) {
                var r1: u64 = ssa_operand_value(cur->src1);
                if (_ssa_bitset_test(def, r1) == 0) {
                    _ssa_bitset_set(use, r1);
                }
            }
            if (!ssa_operand_is_const(cur->src2)) {
                var r2: u64 = ssa_operand_value(cur->src2);
                if (_ssa_bitset_test(def, r2) == 0) {
                    _ssa_bitset_set(use, r2);
                }
            }

            if (cur->dest != 0) {
                _ssa_bitset_set(def, cur->dest);
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

            if (op != SSA_OP_NOP) {
                if (!ssa_operand_is_const(inst->src1)) {
                    _ssa_bitset_set(live, ssa_operand_value(inst->src1));
                }
                if (!ssa_operand_is_const(inst->src2)) {
                    _ssa_bitset_set(live, ssa_operand_value(inst->src2));
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
    if (ctx == 0) { return 0; }
    var funcs: u64 = ctx->funcs_data;
    var n: u64 = ctx->funcs_len;
    var i: u64 = 0;
    while (i < n) {
        var f_ptr: u64 = *(*u64)(funcs + i * 8);
        ssa_regalloc_map_fn((*SSAFunction)f_ptr, k);
        i = i + 1;
    }
    return 0;
}
