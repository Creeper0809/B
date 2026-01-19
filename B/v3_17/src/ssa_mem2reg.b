// ssa_mem2reg.b - SSA mem2reg scaffolding (v3_17)
//
// 현재 단계: Dominator 계산(Immediate Dominator) 기반 구조만 구축.
// Load/Store 제거 및 Phi 삽입은 다음 단계에서 수행.

import std.io;
import ssa;

const MEM2REG_DEBUG = 0;

func _ssa_dom_undef() -> u64 {
    var v: u64 = 0;
    v = v - 1;
    return v;
}

func _ssa_zero_u64(buf: u64, count: u64) -> u64 {
    var i: u64 = 0;
    while (i < count) {
        *(*u64)(buf + i * 8) = 0;
        i = i + 1;
    }
    return 0;
}

func _ssa_dom_get(idom: u64, id: u64) -> u64 {
    return *(*u64)(idom + id * 8);
}

func _ssa_dom_set(idom: u64, id: u64, val: u64) -> u64 {
    *(*u64)(idom + id * 8) = val;
    return 0;
}

func _ssa_dom_is_set(idom: u64, id: u64) -> u64 {
    return _ssa_dom_get(idom, id) != _ssa_dom_undef();
}

func _ssa_dom_depth(idom: u64, id: u64, max_steps: u64) -> u64 {
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

func ssa_mem2reg_compute_idom(ctx: *SSAContext, fn: *SSAFunction) -> u64 {
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
    if (ctx == 0) { return 0; }
    var funcs: u64 = ctx->funcs_data;
    var n: u64 = ctx->funcs_len;
    var i: u64 = 0;
    while (i < n) {
        var f_ptr: u64 = *(*u64)(funcs + i * 8);
        ssa_mem2reg_compute_idom(ctx, (*SSAFunction)f_ptr);
        i = i + 1;
    }
    return 0;
}
