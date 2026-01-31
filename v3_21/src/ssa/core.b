// ssa_core.b - SSA core helpers and constructors
// 자료구조를 조립하기 위한 핵심 유틸/생성자/리스트 조작 함수 모음

import std.io;
import std.util;
import std.vec;
import ssa.datastruct;

// ============================================
// Pointer List Helpers
// ============================================

// _ssa_ptr_list_push - 구조체 내의 동적 포인터 목록에 포인터를 추가하는 헬퍼 함수입니다.
// 이 함수는 구조체 멤버의 오프셋을 사용하여 제네릭이 없는 언어에서 코드 중복을 줄입니다.
func _ssa_ptr_list_push(base_ptr: u64, data_offset: u64, len_offset: u64, cap_offset: u64, item: u64, initial_cap: u64) -> u64 {
    push_trace("_ssa_ptr_list_push", "ssa_core.b", __LINE__);
    pop_trace();
    var data_ptr: *u64 = (*u64)(base_ptr + data_offset);
    var len_ptr: *u64 = (*u64)(base_ptr + len_offset);
    var cap_ptr: *u64 = (*u64)(base_ptr + cap_offset);

    var len: u64 = *len_ptr;
    var cap: u64 = *cap_ptr;
    var data: u64 = *data_ptr;

    if (len >= cap) {
        var new_cap: u64 = cap * 2;
        if (new_cap == 0) { new_cap = initial_cap; }

        var new_data: u64 = heap_alloc(new_cap * sizeof(u64));
        if (len > 0) {
            var old_u64: *u64 = (*u64)data;
            var new_u64: *u64 = (*u64)new_data;
            for (var i: u64 = 0; i < len; i++) {
                *(new_u64 + i) = *(old_u64 + i);
            }
        }
        // TODO: 이전 'data' 블록을 해제해야 할 수 있습니다 (메모리 누수 가능성).
        data = new_data;
        cap = new_cap;
    }

    var data_u64: *u64 = (*u64)data;
    *(data_u64 + len) = item;
    len = len + 1;

    *data_ptr = data;
    *len_ptr = len;
    *cap_ptr = cap;
    return 0;
}

func ssa_block_list_push(fn: *SSAFunction, block: *SSABlock) -> u64 {
    push_trace("ssa_block_list_push", "ssa_core.b", __LINE__);
    pop_trace();
    // SSAFunction: id, name_ptr, name_len, blocks_data, blocks_len, blocks_cap, entry
    // Offsets: blocks_data=24, blocks_len=32, blocks_cap=40
    return _ssa_ptr_list_push((u64)fn, 24, 32, 40, (u64)block, 8);
}

func ssa_func_list_push(ctx: *SSAContext, fn: *SSAFunction) -> u64 {
    push_trace("ssa_func_list_push", "ssa_core.b", __LINE__);
    pop_trace();
    // SSAContext: funcs_data, funcs_len, funcs_cap, next_block_id, next_inst_id
    // Offsets: funcs_data=0, funcs_len=8, funcs_cap=16
    return _ssa_ptr_list_push((u64)ctx, 0, 8, 16, (u64)fn, 8);
}

// ============================================
// SSA Constructors
// ============================================

func ssa_context_new() -> u64 {
    push_trace("ssa_context_new", "ssa_core.b", __LINE__);
    pop_trace();
    var ctx: u64 = heap_alloc(sizeof(SSAContext));
    var c: *SSAContext = (*SSAContext)ctx;
    c->funcs_data = 0;
    c->funcs_len = 0;
    c->funcs_cap = 0;
    c->next_block_id = 0;
    c->next_inst_id = 0;
    return ctx;
}

func ssa_new_block(ctx: *SSAContext, fn: *SSAFunction) -> u64 {
    push_trace("ssa_new_block", "ssa_core.b", __LINE__);
    pop_trace();
    var b_ptr: u64 = heap_alloc(sizeof(SSABlock));
    var b: *SSABlock = (*SSABlock)b_ptr;
    b->id = ctx->next_block_id;
    ctx->next_block_id = ctx->next_block_id + 1;
    b->phi_head = 0;
    b->inst_head = 0;
    b->inst_tail = 0;
    b->preds_data = 0;
    b->preds_len = 0;
    b->preds_cap = 0;
    b->succs_data = 0;
    b->succs_len = 0;
    b->succs_cap = 0;
    b->df_data = 0;
    b->df_len = 0;
    b->df_cap = 0;
    b->dom_parent = 0;
    ssa_block_list_push(fn, b);
    return b_ptr;
}

func ssa_new_inst(ctx: *SSAContext, op: u64, dest: u64, src1: u64, src2: u64) -> u64 {
    push_trace("ssa_new_inst", "ssa_core.b", __LINE__);
    pop_trace();
    var i_ptr: u64 = heap_alloc(sizeof(SSAInstruction));
    var inst: *SSAInstruction = (*SSAInstruction)i_ptr;
    var p: *tagged(InstMeta) u8 = (*tagged(InstMeta) u8)0;
    p.op = (u16)op;
    inst->prev = p;
    inst->next = 0;
    inst->id = ctx->next_inst_id;
    ctx->next_inst_id = ctx->next_inst_id + 1;
    inst->dest = dest;
    inst->src1 = src1;
    inst->src2 = src2;
    return i_ptr;
}

func ssa_inst_append(block: *SSABlock, inst: *SSAInstruction) -> u64 {
    push_trace("ssa_inst_append", "ssa_core.b", __LINE__);
    pop_trace();
    var p: *tagged(InstMeta) u8 = inst->prev;
    var current_op: u16 = p.op;
    p = (*tagged(InstMeta) u8)block->inst_tail;
    p.op = current_op;
    inst->prev = p;
    inst->next = 0;
    if (block->inst_head == 0) {
        block->inst_head = inst;
        block->inst_tail = inst;
        return 0;
    }
    block->inst_tail->next = inst;
    block->inst_tail = inst;
    return 0;
}

func ssa_inst_insert_before_terminator(block: *SSABlock, inst: *SSAInstruction) -> u64 {
    push_trace("ssa_inst_insert_before_terminator", "ssa_core.b", __LINE__);
    pop_trace();
    if (block == 0 || inst == 0) { return 0; }

    var tail: *SSAInstruction = block->inst_tail;
    if (tail == 0) { return ssa_inst_append(block, inst); }

    var op: u64 = ssa_inst_get_op(tail);
    if (op != SSA_OP_JMP && op != SSA_OP_BR && op != SSA_OP_RET && op != SSA_OP_RET_SLICE_HEAP) {
        return ssa_inst_append(block, inst);
    }

    var prev: *SSAInstruction = 0;
    var cur: *SSAInstruction = block->inst_head;
    while (cur != 0 && cur != tail) {
        prev = cur;
        cur = cur->next;
    }
    if (cur == 0) { return ssa_inst_append(block, inst); }

    inst->next = tail;
    ssa_inst_set_prev(inst, prev);
    if (prev != 0) {
        prev->next = inst;
    } else {
        block->inst_head = inst;
    }
    ssa_inst_set_prev(tail, inst);
    return 0;
}

func ssa_phi_append(block: *SSABlock, phi: *SSAInstruction) -> u64 {
    push_trace("ssa_phi_append", "ssa_core.b", __LINE__);
    pop_trace();
    var next_phi: *SSAInstruction = block->phi_head;
    phi->next = next_phi;

    if (next_phi != 0) {
        var next_p: *tagged(InstMeta) u8 = next_phi->prev;
        var next_op: u16 = next_p.op;
        next_p = (*tagged(InstMeta) u8)phi;
        next_p.op = next_op;
        next_phi->prev = next_p;
    }

    var p: *tagged(InstMeta) u8 = phi->prev;
    var op: u16 = p.op;
    p = (*tagged(InstMeta) u8)0;
    p.op = op;
    phi->prev = p;

    block->phi_head = phi;
    return 0;
}

func ssa_inst_get_op(inst: *SSAInstruction) -> u64 {
    push_trace("ssa_inst_get_op", "ssa_core.b", __LINE__);
    pop_trace();
    var p: *tagged(InstMeta) u8 = inst->prev;
    return (u64)p.op;
}

func ssa_inst_set_op(inst: *SSAInstruction, op: u64) -> u64 {
    push_trace("ssa_inst_set_op", "ssa_core.b", __LINE__);
    pop_trace();
    var p: *tagged(InstMeta) u8 = inst->prev;
    p.op = (u16)op;
    inst->prev = p;
    return 0;
}

func ssa_inst_set_prev(inst: *SSAInstruction, prev: *SSAInstruction) -> u64 {
    push_trace("ssa_inst_set_prev", "ssa_core.b", __LINE__);
    pop_trace();
    var p: *tagged(InstMeta) u8 = inst->prev;
    var op: u16 = p.op;
    p = (*tagged(InstMeta) u8)prev;
    p.op = op;
    inst->prev = p;
    return 0;
}

func ssa_phi_arg_new(val: u64, block_id: u64) -> u64 {
    push_trace("ssa_phi_arg_new", "ssa_core.b", __LINE__);
    pop_trace();
    var a_ptr: u64 = heap_alloc(sizeof(SSAPhiArg));
    var a: *SSAPhiArg = (*SSAPhiArg)a_ptr;
    a->val = val;
    a->block_id = block_id;
    a->next = 0;
    return a_ptr;
}

func ssa_phi_arg_append(head: *SSAPhiArg, val: u64, block_id: u64) -> u64 {
    push_trace("ssa_phi_arg_append", "ssa_core.b", __LINE__);
    pop_trace();
    var node_ptr: u64 = ssa_phi_arg_new(val, block_id);
    if (head == 0) { return node_ptr; }

    var cur: *SSAPhiArg = head;
    while (cur->next != 0) {
        cur = cur->next;
    }
    cur->next = (*SSAPhiArg)node_ptr;
    return (u64)head;
}

func ssa_phi_new(ctx: *SSAContext, dest: u64, args_head: *SSAPhiArg) -> u64 {
    push_trace("ssa_phi_new", "ssa_core.b", __LINE__);
    pop_trace();
    var inst_ptr: u64 = ssa_new_inst(ctx, SSA_OP_PHI, dest, (u64)args_head, 0);
    return inst_ptr;
}

func ssa_phi_add_arg(inst: *SSAInstruction, val: u64, block_id: u64) -> u64 {
    push_trace("ssa_phi_add_arg", "ssa_core.b", __LINE__);
    pop_trace();
    if (ssa_inst_get_op(inst) != SSA_OP_PHI) { return 0; }
    var head: *SSAPhiArg = (*SSAPhiArg)inst->src1;
    var new_head_ptr: u64 = ssa_phi_arg_append(head, val, block_id);
    inst->src1 = new_head_ptr;
    return 0;
}

func ssa_operand_const(val: u64) -> u64 {
    push_trace("ssa_operand_const", "ssa_core.b", __LINE__);
    pop_trace();
    var mask: u64 = 1;
    mask = mask << 63;
    return val | mask;
}

func ssa_operand_reg(id: u64) -> u64 {
    push_trace("ssa_operand_reg", "ssa_core.b", __LINE__);
    pop_trace();
    return id & SSA_OPR_VALUE_MASK;
}

func ssa_operand_is_const(opr: u64) -> u64 {
    push_trace("ssa_operand_is_const", "ssa_core.b", __LINE__);
    pop_trace();
    var mask: u64 = 1;
    mask = mask << 63;
    return (opr & mask) != 0;
}

func ssa_operand_value(opr: u64) -> u64 {
    push_trace("ssa_operand_value", "ssa_core.b", __LINE__);
    pop_trace();
    return opr & SSA_OPR_VALUE_MASK;
}

var g_ret_slice_heap_map;
var g_ret_slice_heap_map_ex;

func ssa_ret_slice_heap_clear() -> u64 {
    g_ret_slice_heap_map = 0;
    g_ret_slice_heap_map_ex = 0;
    return 0;
}

func ssa_ret_slice_heap_set(inst_ptr: u64, elem_size: u64) -> u64 {
    if (g_ret_slice_heap_map == 0) { g_ret_slice_heap_map = vec_new(16); }
    vec_push(g_ret_slice_heap_map, inst_ptr);
    vec_push(g_ret_slice_heap_map, elem_size);
    return 0;
}

func ssa_ret_slice_heap_set_ex(inst_ptr: u64, elem_size: u64, ptr_val: u64, len_val: u64, ptr_is_reg: u64, len_is_reg: u64) -> u64 {
    if (g_ret_slice_heap_map_ex == 0) { g_ret_slice_heap_map_ex = vec_new(24); }
    vec_push(g_ret_slice_heap_map_ex, inst_ptr);
    vec_push(g_ret_slice_heap_map_ex, elem_size);
    vec_push(g_ret_slice_heap_map_ex, ptr_val);
    vec_push(g_ret_slice_heap_map_ex, len_val);
    vec_push(g_ret_slice_heap_map_ex, ptr_is_reg);
    vec_push(g_ret_slice_heap_map_ex, len_is_reg);
    return 0;
}

func ssa_ret_slice_heap_get(inst_ptr: u64) -> u64 {
    if (g_ret_slice_heap_map == 0) { return 0; }
    var n: u64 = vec_len(g_ret_slice_heap_map);
    for (var i: u64 = 0; i + 1 < n; i = i + 2) {
        if (vec_get(g_ret_slice_heap_map, i) == inst_ptr) { return vec_get(g_ret_slice_heap_map, i + 1); }
    }
    return 0;
}

func ssa_ret_slice_heap_get_ex(inst_ptr: u64, elem_out: u64, ptr_out: u64, len_out: u64, ptr_is_reg_out: u64, len_is_reg_out: u64) -> u64 {
    if (g_ret_slice_heap_map_ex == 0) { return 0; }
    var n: u64 = vec_len(g_ret_slice_heap_map_ex);
    for (var i: u64 = 0; i + 5 < n; i = i + 6) {
        if (vec_get(g_ret_slice_heap_map_ex, i) == inst_ptr) {
            *(*u64)(elem_out) = vec_get(g_ret_slice_heap_map_ex, i + 1);
            *(*u64)(ptr_out) = vec_get(g_ret_slice_heap_map_ex, i + 2);
            *(*u64)(len_out) = vec_get(g_ret_slice_heap_map_ex, i + 3);
            *(*u64)(ptr_is_reg_out) = vec_get(g_ret_slice_heap_map_ex, i + 4);
            *(*u64)(len_is_reg_out) = vec_get(g_ret_slice_heap_map_ex, i + 5);
            return 1;
        }
    }
    return 0;
}

func ssa_ret_slice_heap_remap_ex(inst_ptr: u64, map: u64, map_len: u64) -> u64 {
    if (g_ret_slice_heap_map_ex == 0) { return 0; }
    var n: u64 = vec_len(g_ret_slice_heap_map_ex);
    for (var i: u64 = 0; i + 5 < n; i = i + 6) {
        if (vec_get(g_ret_slice_heap_map_ex, i) == inst_ptr) {
            var ptr_val: u64 = vec_get(g_ret_slice_heap_map_ex, i + 2);
            var len_val: u64 = vec_get(g_ret_slice_heap_map_ex, i + 3);
            var ptr_is_reg: u64 = vec_get(g_ret_slice_heap_map_ex, i + 4);
            var len_is_reg: u64 = vec_get(g_ret_slice_heap_map_ex, i + 5);
            var map_u64: *u64 = (*u64)map;
            if (ptr_is_reg != 0 && ptr_val < map_len) {
                var pptr: u64 = *(map_u64 + ptr_val);
                if (pptr != 0) { vec_set(g_ret_slice_heap_map_ex, i + 2, pptr); }
            }
            if (len_is_reg != 0 && len_val < map_len) {
                var plen: u64 = *(map_u64 + len_val);
                if (plen != 0) { vec_set(g_ret_slice_heap_map_ex, i + 3, plen); }
            }
            return 1;
        }
    }
    return 0;
}

func ssa_block_add_pred(block: *SSABlock, pred: *SSABlock) -> u64 {
    push_trace("ssa_block_add_pred", "ssa_core.b", __LINE__);
    pop_trace();
    // SSABlock: id, phi_head, inst_head, inst_tail, preds_data, preds_len, preds_cap, succs_data, ...
    // Offsets: preds_data=32, preds_len=40, preds_cap=48
    return _ssa_ptr_list_push((u64)block, 32, 40, 48, (u64)pred, 4);
}

func ssa_block_add_succ(block: *SSABlock, succ: *SSABlock) -> u64 {
    push_trace("ssa_block_add_succ", "ssa_core.b", __LINE__);
    pop_trace();
    // SSABlock: ..., succs_data, succs_len, succs_cap, dom_parent
    // Offsets: succs_data=56, succs_len=64, succs_cap=72
    return _ssa_ptr_list_push((u64)block, 56, 64, 72, (u64)succ, 4);
}

func ssa_block_add_df(block: *SSABlock, target: *SSABlock) -> u64 {
    push_trace("ssa_block_add_df", "ssa_core.b", __LINE__);
    pop_trace();
    var data: u64 = block->df_data;
    var len: u64 = block->df_len;
    var data_u64: *u64 = (*u64)data;
    for (var i: u64 = 0; i < len; i++) {
        var cur: u64 = *(data_u64 + i);
        if (cur == (u64)target) { return 0; }
    }

    // SSABlock: ..., df_data, df_len, df_cap, dom_parent
    // Offsets: df_data=80, df_len=88, df_cap=96
    return _ssa_ptr_list_push((u64)block, 80, 88, 96, (u64)target, 4);
}

func ssa_block_replace_succ(block: *SSABlock, old_succ: *SSABlock, new_succ: *SSABlock) -> u64 {
    push_trace("ssa_block_replace_succ", "ssa_core.b", __LINE__);
    pop_trace();
    var data: u64 = block->succs_data;
    var len: u64 = block->succs_len;
    var data_u64: *u64 = (*u64)data;
    for (var i: u64 = 0; i < len; i++) {
        var cur: u64 = *(data_u64 + i);
        if (cur == (u64)old_succ) {
            *(data_u64 + i) = (u64)new_succ;
            return 1;
        }
    }
    return 0;
}

func ssa_block_replace_pred(block: *SSABlock, old_pred: *SSABlock, new_pred: *SSABlock) -> u64 {
    push_trace("ssa_block_replace_pred", "ssa_core.b", __LINE__);
    pop_trace();
    var data: u64 = block->preds_data;
    var len: u64 = block->preds_len;
    var data_u64: *u64 = (*u64)data;
    for (var i: u64 = 0; i < len; i++) {
        var cur: u64 = *(data_u64 + i);
        if (cur == (u64)old_pred) {
            *(data_u64 + i) = (u64)new_pred;
            return 1;
        }
    }
    return 0;
}

func ssa_add_edge(src: *SSABlock, dst: *SSABlock) -> u64 {
    push_trace("ssa_add_edge", "ssa_core.b", __LINE__);
    pop_trace();
    ssa_block_add_succ(src, dst);
    ssa_block_add_pred(dst, src);
    return 0;
}

func ssa_new_function(ctx: *SSAContext, name_ptr: u64, name_len: u64) -> u64 {
    push_trace("ssa_new_function", "ssa_core.b", __LINE__);
    pop_trace();
    var f_ptr: u64 = heap_alloc(sizeof(SSAFunction));
    var f: *SSAFunction = (*SSAFunction)f_ptr;
    f->id = ctx->funcs_len;
    f->name_ptr = name_ptr;
    f->name_len = name_len;
    f->blocks_data = 0;
    f->blocks_len = 0;
    f->blocks_cap = 0;
    f->entry = (*SSABlock)ssa_new_block(ctx, f);
    f->reg_map_data = 0;
    f->reg_map_len = 0;
    ssa_func_list_push(ctx, f);
    return f_ptr;
}
