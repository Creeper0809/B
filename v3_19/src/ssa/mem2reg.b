// ssa_mem2reg.b - SSA mem2reg (v3_17)
//
// 단계:
// 1) Immediate Dominator 계산
// 2) Dominance Frontier 기반 Phi 삽입
// 3) Rename 스택 기반 Load/Store 제거

import std.io;
import std.util;
import std.vec;
import ssa.datastruct;
import ssa.core;
import ssa.mem2reg_df;

const MEM2REG_DEBUG = 0;

func _ssa_dom_undef() -> u64 {
    push_trace("_ssa_dom_undef", "ssa_mem2reg.b", __LINE__);
    pop_trace();
    var v: u64 = 0;
    v = v - 1;
    return v;
}

func _ssa_zero_u64(buf: u64, count: u64) -> u64 {
    push_trace("_ssa_zero_u64", "ssa_mem2reg.b", __LINE__);
    pop_trace();
    var i: u64 = 0;
    while (i < count) {
        *(*u64)(buf + i * 8) = 0;
        i = i + 1;
    }
    return 0;
}

func _ssa_dom_get(idom: u64, id: u64) -> u64 {
    push_trace("_ssa_dom_get", "ssa_mem2reg.b", __LINE__);
    pop_trace();
    return *(*u64)(idom + id * 8);
}

func _ssa_dom_set(idom: u64, id: u64, val: u64) -> u64 {
    push_trace("_ssa_dom_set", "ssa_mem2reg.b", __LINE__);
    pop_trace();
    *(*u64)(idom + id * 8) = val;
    return 0;
}

func _ssa_dom_is_set(idom: u64, id: u64) -> u64 {
    push_trace("_ssa_dom_is_set", "ssa_mem2reg.b", __LINE__);
    pop_trace();
    return _ssa_dom_get(idom, id) != _ssa_dom_undef();
}

func _ssa_dom_depth(idom: u64, id: u64, max_steps: u64) -> u64 {
    push_trace("_ssa_dom_depth", "ssa_mem2reg.b", __LINE__);
    pop_trace();
    var depth: u64 = 0;
    var cur: u64 = id;
    var steps: u64 = 0;

    var undef: u64 = _ssa_dom_undef();
    var parent: u64 = _ssa_dom_get(idom, cur);
    if (parent == undef) { return 0; }

    while (cur != parent) {
        depth = depth + 1;
        cur = parent;
        parent = _ssa_dom_get(idom, cur);
        steps = steps + 1;
        if (parent == undef) { return depth; }
        if (steps >= max_steps) { return depth; }
    }
    return depth;
}

func _ssa_dom_intersect(idom: u64, b1: u64, b2: u64, max_steps: u64) -> u64 {
    push_trace("_ssa_dom_intersect", "ssa_mem2reg.b", __LINE__);
    pop_trace();
    var n1: u64 = b1;
    var n2: u64 = b2;
    var steps: u64 = 0;
    var undef: u64 = _ssa_dom_undef();

    while (n1 != n2) {
        var d1: u64 = _ssa_dom_depth(idom, n1, max_steps);
        var d2: u64 = _ssa_dom_depth(idom, n2, max_steps);

        if (d1 > d2) {
            n1 = _ssa_dom_get(idom, n1);
        } else if (d2 > d1) {
            n2 = _ssa_dom_get(idom, n2);
        } else {
            n1 = _ssa_dom_get(idom, n1);
            n2 = _ssa_dom_get(idom, n2);
        }

        if (n1 == undef || n2 == undef) { return undef; }
        steps = steps + 1;
        if (steps >= max_steps) { return undef; }
    }
    return n1;
}

func _ssa_dom_build_block_map(ctx: *SSAContext, fn: *SSAFunction) -> u64 {
    push_trace("_ssa_dom_build_block_map", "ssa_mem2reg.b", __LINE__);
    pop_trace();
    var total: u64 = ctx->next_block_id;
    var map: u64 = heap_alloc(total * 8);
    _ssa_zero_u64(map, total);

    var blocks: u64 = fn->blocks_data;
    var n: u64 = fn->blocks_len;
    var i: u64 = 0;
    while (i < n) {
        var b_ptr: u64 = *(*u64)(blocks + i * 8);
        var b: *SSABlock = (*SSABlock)b_ptr;
        *(*u64)(map + b->id * 8) = b_ptr;
        i = i + 1;
    }
    return map;
}

func _ssa_mem2reg_max_var(fn: *SSAFunction) -> u64 {
    push_trace("_ssa_mem2reg_max_var", "ssa_mem2reg.b", __LINE__);
    pop_trace();
    var max_id: u64 = 0;
    var blocks: u64 = fn->blocks_data;
    var n: u64 = fn->blocks_len;
    var i: u64 = 0;
    while (i < n) {
        var b_ptr: u64 = *(*u64)(blocks + i * 8);
        var b: *SSABlock = (*SSABlock)b_ptr;

        var cur: *SSAInstruction = b->inst_head;
        while (cur != 0) {
            var op: u64 = ssa_inst_get_op(cur);
            if (op == SSA_OP_LOAD || op == SSA_OP_STORE) {
                var var_id: u64 = ssa_operand_value(cur->src1);
                if (var_id > max_id) { max_id = var_id; }
            }
            cur = cur->next;
        }

        i = i + 1;
    }
    return max_id;
}

func _ssa_mem2reg_max_reg(fn: *SSAFunction) -> u64 {
    push_trace("_ssa_mem2reg_max_reg", "ssa_mem2reg.b", __LINE__);
    pop_trace();
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
            phi = phi->next;
        }

        var cur: *SSAInstruction = b->inst_head;
        while (cur != 0) {
            if (cur->dest > max_id) { max_id = cur->dest; }
            cur = cur->next;
        }

        i = i + 1;
    }
    return max_id;
}

func _ssa_mem2reg_max_block_id(fn: *SSAFunction) -> u64 {
    push_trace("_ssa_mem2reg_max_block_id", "ssa_mem2reg.b", __LINE__);
    pop_trace();
    var max_id: u64 = 0;
    var blocks: u64 = fn->blocks_data;
    var n: u64 = fn->blocks_len;
    var i: u64 = 0;
    while (i < n) {
        var b_ptr: u64 = *(*u64)(blocks + i * 8);
        var b: *SSABlock = (*SSABlock)b_ptr;
        if (b->id > max_id) { max_id = b->id; }
        i = i + 1;
    }
    return max_id;
}

func _ssa_mem2reg_def_blocks(fn: *SSAFunction, var_id: u64) -> u64 {
    push_trace("_ssa_mem2reg_def_blocks", "ssa_mem2reg.b", __LINE__);
    pop_trace();
    var defs: u64 = vec_new(4);
    var blocks: u64 = fn->blocks_data;
    var n: u64 = fn->blocks_len;
    var i: u64 = 0;
    while (i < n) {
        var b_ptr: u64 = *(*u64)(blocks + i * 8);
        var b: *SSABlock = (*SSABlock)b_ptr;

        var cur: *SSAInstruction = b->inst_head;
        while (cur != 0) {
            var op: u64 = ssa_inst_get_op(cur);
            if (op == SSA_OP_STORE) {
                var v: u64 = ssa_operand_value(cur->src1);
                if (v == var_id) {
                    vec_push(defs, b_ptr);
                    break;
                }
            }
            cur = cur->next;
        }

        i = i + 1;
    }
    return defs;
}

func _ssa_mem2reg_insert_phi(ctx: *SSAContext, fn: *SSAFunction, max_var: u64, next_reg_ptr: *u64) -> u64 {
    push_trace("_ssa_mem2reg_insert_phi", "ssa_mem2reg.b", __LINE__);
    pop_trace();
    if (max_var == 0) { return 0; }

    var total_blocks: u64 = ctx->next_block_id;

    var v: u64 = 1;
    while (v <= max_var) {
        var defs: u64 = _ssa_mem2reg_def_blocks(fn, v);
        var def_mark: u64 = heap_alloc(total_blocks * 8);
        _ssa_zero_u64(def_mark, total_blocks);
        var phi_mark: u64 = heap_alloc(total_blocks * 8);
        _ssa_zero_u64(phi_mark, total_blocks);

        var wlist: u64 = vec_new(4);
        var dcount: u64 = vec_len(defs);
        var i: u64 = 0;
        while (i < dcount) {
            var b_ptr: u64 = vec_get(defs, i);
            var b: *SSABlock = (*SSABlock)b_ptr;
            *(*u64)(def_mark + b->id * 8) = 1;
            vec_push(wlist, b_ptr);
            i = i + 1;
        }

        while (vec_len(wlist) > 0) {
            var cur_ptr: u64 = vec_pop(wlist);
            var cur: *SSABlock = (*SSABlock)cur_ptr;

            var df: u64 = cur->df_data;
            var dflen: u64 = cur->df_len;
            var j: u64 = 0;
            while (j < dflen) {
                var y_ptr: u64 = *(*u64)(df + j * 8);
                var y: *SSABlock = (*SSABlock)y_ptr;
                if (*(*u64)(phi_mark + y->id * 8) == 0) {
                    var reg_id: u64 = *next_reg_ptr;
                    *next_reg_ptr = reg_id + 1;
                    var phi_ptr: u64 = ssa_new_inst(ctx, SSA_OP_PHI, reg_id, 0, ssa_operand_const(v));
                    ssa_phi_append(y, (*SSAInstruction)phi_ptr);
                    *(*u64)(phi_mark + y->id * 8) = 1;

                    if (*(*u64)(def_mark + y->id * 8) == 0) {
                        *(*u64)(def_mark + y->id * 8) = 1;
                        vec_push(wlist, y_ptr);
                    }
                }
                j = j + 1;
            }
        }

        v = v + 1;
    }

    return 0;
}

func _ssa_mem2reg_stack_top(stack: u64) -> u64 {
    push_trace("_ssa_mem2reg_stack_top", "ssa_mem2reg.b", __LINE__);
    pop_trace();
    var len: u64 = vec_len(stack);
    if (len == 0) { return 0; }
    return vec_get(stack, len - 1);
}

func _ssa_mem2reg_rewrite_opr(map_val: u64, map_set: u64, map_cap: u64, opr: u64) -> u64 {
    push_trace("_ssa_mem2reg_rewrite_opr", "ssa_mem2reg.b", __LINE__);
    pop_trace();
    if (ssa_operand_is_const(opr)) { return opr; }
    var reg: u64 = ssa_operand_value(opr);
    if (reg >= map_cap) { return opr; }
    if (*(*u64)(map_set + reg * 8) == 0) { return opr; }
    var mapped: u64 = *(*u64)(map_val + reg * 8);
    return ssa_operand_reg(mapped);
}

func _ssa_mem2reg_rename_block(fn: *SSAFunction, block: *SSABlock, max_var: u64, stack_arr: u64, reg_map_val: u64, reg_map_set: u64, reg_map_cap: u64, child_arr: u64) -> u64 {
    push_trace("_ssa_mem2reg_rename_block", "ssa_mem2reg.b", __LINE__);
    pop_trace();
    var pushed: u64 = vec_new(8);

    var phi: *SSAInstruction = block->phi_head;
    while (phi != 0) {
        var var_id: u64 = ssa_operand_value(phi->src2);
        if (var_id <= max_var) {
            var stack: u64 = *(*u64)(stack_arr + var_id * 8);
            vec_push(stack, phi->dest);
            vec_push(pushed, var_id);
        }
        phi = phi->next;
    }

    var cur: *SSAInstruction = block->inst_head;
    while (cur != 0) {
        var op: u64 = ssa_inst_get_op(cur);

        cur->src1 = _ssa_mem2reg_rewrite_opr(reg_map_val, reg_map_set, reg_map_cap, cur->src1);
        cur->src2 = _ssa_mem2reg_rewrite_opr(reg_map_val, reg_map_set, reg_map_cap, cur->src2);

        if (op == SSA_OP_CALL) {
            var info_ptr: u64 = ssa_operand_value(cur->src1);
            var args_vec: u64 = *(info_ptr + 16);
            var nargs: u64 = *(info_ptr + 24);
            if (nargs == 0 && args_vec != 0) { nargs = vec_len(args_vec); }
            var ai: u64 = 0;
            while (ai < nargs) {
                var r: u64 = vec_get(args_vec, ai);
                if (r < reg_map_cap && *(*u64)(reg_map_set + r * 8) != 0) {
                    var nr: u64 = *(*u64)(reg_map_val + r * 8);
                    if (nr != 0) { vec_set(args_vec, ai, nr); }
                }
                ai = ai + 1;
            }
        }
        if (op == SSA_OP_CALL_PTR) {
            var info_ptrp: u64 = ssa_operand_value(cur->src1);
            var callee_reg: u64 = *(info_ptrp);
            if (callee_reg < reg_map_cap && *(*u64)(reg_map_set + callee_reg * 8) != 0) {
                var ncallee: u64 = *(*u64)(reg_map_val + callee_reg * 8);
                if (ncallee != 0) { *(info_ptrp) = ncallee; }
            }
            var args_vecp: u64 = *(info_ptrp + 8);
            var nargsp: u64 = *(info_ptrp + 16);
            if (nargsp == 0 && args_vecp != 0) { nargsp = vec_len(args_vecp); }
            var aip: u64 = 0;
            while (aip < nargsp) {
                var r: u64 = vec_get(args_vecp, aip);
                if (r < reg_map_cap && *(*u64)(reg_map_set + r * 8) != 0) {
                    var nr: u64 = *(*u64)(reg_map_val + r * 8);
                    if (nr != 0) { vec_set(args_vecp, aip, nr); }
                }
                aip = aip + 1;
            }
        }

        if (op == SSA_OP_LOAD) {
            var var_id2: u64 = ssa_operand_value(cur->src1);
            if (var_id2 <= max_var) {
                var stack2: u64 = *(*u64)(stack_arr + var_id2 * 8);
                var val_reg: u64 = _ssa_mem2reg_stack_top(stack2);
                if (cur->dest < reg_map_cap) {
                    *(*u64)(reg_map_val + cur->dest * 8) = val_reg;
                    *(*u64)(reg_map_set + cur->dest * 8) = 1;
                }
            }
            ssa_inst_set_op(cur, SSA_OP_NOP);
        }

        if (op == SSA_OP_STORE) {
            var var_id3: u64 = ssa_operand_value(cur->src1);
            if (var_id3 <= max_var) {
                var stack3: u64 = *(*u64)(stack_arr + var_id3 * 8);
                var val_reg2: u64 = ssa_operand_value(cur->src2);
                vec_push(stack3, val_reg2);
                vec_push(pushed, var_id3);
            }
            ssa_inst_set_op(cur, SSA_OP_NOP);
        }

        cur = cur->next;
    }

    var succs: u64 = block->succs_data;
    var slen: u64 = block->succs_len;
    var si: u64 = 0;
    while (si < slen) {
        var s_ptr: u64 = *(*u64)(succs + si * 8);
        var succ: *SSABlock = (*SSABlock)s_ptr;

        var phi2: *SSAInstruction = succ->phi_head;
        while (phi2 != 0) {
            var var_id4: u64 = ssa_operand_value(phi2->src2);
            if (var_id4 <= max_var) {
                var stack4: u64 = *(*u64)(stack_arr + var_id4 * 8);
                var val_reg3: u64 = _ssa_mem2reg_stack_top(stack4);
                ssa_phi_add_arg(phi2, val_reg3, block->id);
            }
            phi2 = phi2->next;
        }

        si = si + 1;
    }

    var child_vec: u64 = *(*u64)(child_arr + block->id * 8);
    if (child_vec != 0) {
        var ccount: u64 = vec_len(child_vec);
        var ci: u64 = 0;
        while (ci < ccount) {
            var c_ptr: u64 = vec_get(child_vec, ci);
            _ssa_mem2reg_rename_block(fn, (*SSABlock)c_ptr, max_var, stack_arr, reg_map_val, reg_map_set, reg_map_cap, child_arr);
            ci = ci + 1;
        }
    }

    var pcount: u64 = vec_len(pushed);
    while (pcount > 0) {
        var var_id5: u64 = vec_pop(pushed);
        var stack5: u64 = *(*u64)(stack_arr + var_id5 * 8);
        vec_pop(stack5);
        pcount = pcount - 1;
    }

    return 0;
}

func _ssa_mem2reg_rename(fn: *SSAFunction, max_var: u64, max_reg: u64) -> u64 {
    push_trace("_ssa_mem2reg_rename", "ssa_mem2reg.b", __LINE__);
    pop_trace();
    if (max_var == 0) { return 0; }

    var stack_arr: u64 = heap_alloc((max_var + 1) * 8);
    var i: u64 = 0;
    while (i <= max_var) {
        var st: u64 = vec_new(4);
        *(*u64)(stack_arr + i * 8) = st;
        i = i + 1;
    }

    var reg_map_cap: u64 = max_reg + 1;
    var reg_map_val: u64 = heap_alloc(reg_map_cap * 8);
    var reg_map_set: u64 = heap_alloc(reg_map_cap * 8);
    _ssa_zero_u64(reg_map_val, reg_map_cap);
    _ssa_zero_u64(reg_map_set, reg_map_cap);

    var max_block_id: u64 = _ssa_mem2reg_max_block_id(fn);
    var child_cap: u64 = max_block_id + 1;
    var child_arr: u64 = heap_alloc(child_cap * 8);
    _ssa_zero_u64(child_arr, child_cap);

    var blocks: u64 = fn->blocks_data;
    var n: u64 = fn->blocks_len;
    var bi: u64 = 0;
    while (bi < n) {
        var b_ptr: u64 = *(*u64)(blocks + bi * 8);
        var b: *SSABlock = (*SSABlock)b_ptr;
        if (b->dom_parent != 0) {
            var pid: u64 = b->dom_parent->id;
            var cv: u64 = *(*u64)(child_arr + pid * 8);
            if (cv == 0) {
                cv = vec_new(4);
                *(*u64)(child_arr + pid * 8) = cv;
            }
            vec_push(cv, b_ptr);
        }
        bi = bi + 1;
    }

    _ssa_mem2reg_rename_block(fn, fn->entry, max_var, stack_arr, reg_map_val, reg_map_set, reg_map_cap, child_arr);
    return 0;
}

func ssa_mem2reg_compute_idom(ctx: *SSAContext, fn: *SSAFunction) -> u64 {
    push_trace("ssa_mem2reg_compute_idom", "ssa_mem2reg.b", __LINE__);
    pop_trace();
    if (fn == 0) { return 0; }

    var total: u64 = ctx->next_block_id;
    var idom: u64 = heap_alloc(total * 8);
    var undef: u64 = _ssa_dom_undef();
    var z: u64 = 0;
    while (z < total) {
        *(*u64)(idom + z * 8) = undef;
        z = z + 1;
    }

    var entry: *SSABlock = fn->entry;
    _ssa_dom_set(idom, entry->id, entry->id);

    var changed: u64 = 1;
    while (changed != 0) {
        changed = 0;

        var blocks: u64 = fn->blocks_data;
        var n: u64 = fn->blocks_len;
        var i: u64 = 0;
        while (i < n) {
            var b_ptr: u64 = *(*u64)(blocks + i * 8);
            var b: *SSABlock = (*SSABlock)b_ptr;
            if (b == entry) {
                i = i + 1;
                continue;
            }

            var preds: u64 = b->preds_data;
            var pcount: u64 = b->preds_len;
            var new_idom: u64 = undef;

            var j: u64 = 0;
            while (j < pcount) {
                var p_ptr: u64 = *(*u64)(preds + j * 8);
                var p: *SSABlock = (*SSABlock)p_ptr;
                if (_ssa_dom_is_set(idom, p->id)) {
                    new_idom = p->id;
                    break;
                }
                j = j + 1;
            }

            if (new_idom == undef) {
                i = i + 1;
                continue;
            }

            j = 0;
            while (j < pcount) {
                var p_ptr2: u64 = *(*u64)(preds + j * 8);
                var p2: *SSABlock = (*SSABlock)p_ptr2;
                if (_ssa_dom_is_set(idom, p2->id)) {
                    new_idom = _ssa_dom_intersect(idom, p2->id, new_idom, total);
                }
                j = j + 1;
            }

            if (_ssa_dom_get(idom, b->id) != new_idom) {
                _ssa_dom_set(idom, b->id, new_idom);
                changed = 1;
            }

            i = i + 1;
        }
    }

    var map: u64 = _ssa_dom_build_block_map(ctx, fn);

    var blocks2: u64 = fn->blocks_data;
    var n2: u64 = fn->blocks_len;
    var k: u64 = 0;
    while (k < n2) {
        var b_ptr3: u64 = *(*u64)(blocks2 + k * 8);
        var b3: *SSABlock = (*SSABlock)b_ptr3;

        if (b3 == entry) {
            b3->dom_parent = 0;
            k = k + 1;
            continue;
        }

        var idom_id: u64 = _ssa_dom_get(idom, b3->id);
        if (idom_id == undef) {
            b3->dom_parent = 0;
        } else {
            var parent_ptr: u64 = *(*u64)(map + idom_id * 8);
            b3->dom_parent = (*SSABlock)parent_ptr;
        }

        k = k + 1;
    }

    if (MEM2REG_DEBUG != 0) {
        println("[DEBUG] ssa_mem2reg_compute_idom: done", 40);
    }
    return 0;
}

func ssa_mem2reg_run(ctx: *SSAContext) -> u64 {
    push_trace("ssa_mem2reg_run", "ssa_mem2reg.b", __LINE__);
    pop_trace();
    if (ctx == 0) { return 0; }
    var funcs: u64 = ctx->funcs_data;
    var n: u64 = ctx->funcs_len;
    var i: u64 = 0;
    while (i < n) {
        var f_ptr: u64 = *(*u64)(funcs + i * 8);
        var fn: *SSAFunction = (*SSAFunction)f_ptr;
        if (MEM2REG_DEBUG != 0) {
            println("[DEBUG] ssa_mem2reg_run: fn", 31);
        }
        ssa_mem2reg_compute_idom(ctx, fn);
        if (MEM2REG_DEBUG != 0) {
            println("[DEBUG] ssa_mem2reg_run: idom", 38);
        }
        ssa_mem2reg_compute_df(fn);
        if (MEM2REG_DEBUG != 0) {
            println("[DEBUG] ssa_mem2reg_run: df", 35);
        }

        var max_var: u64 = _ssa_mem2reg_max_var(fn);
        var next_reg: u64 = _ssa_mem2reg_max_reg(fn) + 1;
        _ssa_mem2reg_insert_phi(ctx, fn, max_var, &next_reg);
        if (MEM2REG_DEBUG != 0) {
            println("[DEBUG] ssa_mem2reg_run: phi", 36);
        }

        var max_reg2: u64 = next_reg;
        _ssa_mem2reg_rename(fn, max_var, max_reg2);
        if (MEM2REG_DEBUG != 0) {
            println("[DEBUG] ssa_mem2reg_run: rename", 39);
        }
        i = i + 1;
    }
    return 0;
}
