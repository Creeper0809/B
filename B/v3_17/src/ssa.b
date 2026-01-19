// ssa.b - SSA data structures (v3_17)
//
// 제네릭 없이 SSA를 구성하기 위한 전용 자료구조 집합.
// - BlockList: BasicBlock 포인터 배열 (동적 확장)
// - Instruction: 침습적 연결 리스트 노드
// - SSAContext: 전체 SSA 그래프 컨텍스트

import std.io;
import std.vec;
import ast;

// ============================================
// Constants
// ============================================

const SIZEOF_SSA_INST = 48;   // 6 * u64 (op tagged in prev)
const SIZEOF_SSA_BLOCK = 88;  // 11 * u64
const SIZEOF_SSA_FUNC = 56;   // 7 * u64
const SIZEOF_SSA_CTX = 40;    // 5 * u64
const SIZEOF_SSA_PHI_ARG = 24; // 3 * u64

const SSA_OP_NOP = 0;
const SSA_OP_ENTRY = 1;
const SSA_OP_PHI = 2;

const SSA_OPR_VALUE_MASK = 9223372036854775807;

// ============================================
// SSA Core Types
// ============================================

packed struct InstMeta {
    op: u16;
}

struct SSAInstruction {
    prev: *tagged(InstMeta) u8;
    next: *SSAInstruction;
    id: u64;
    dest: u64; // virtual register id
    src1: u64; // tagged operand (const/reg) or phi args head
    src2: u64; // tagged operand (const/reg)
}

struct SSAPhiArg {
    val: u64;        // incoming value (virtual register id)
    block_id: u64;   // predecessor block id
    next: *SSAPhiArg;
}

struct SSABlock {
    id: u64;
    phi_head: *SSAInstruction;
    inst_head: *SSAInstruction;
    inst_tail: *SSAInstruction;
    preds_data: u64;
    preds_len: u64;
    preds_cap: u64;
    succs_data: u64;
    succs_len: u64;
    succs_cap: u64;
    dom_parent: *SSABlock;
}

struct SSAFunction {
    id: u64;
    name_ptr: u64;
    name_len: u64;
    blocks_data: u64; // *SSABlock (pointer array)
    blocks_len: u64;
    blocks_cap: u64;
    entry: *SSABlock;
}

struct SSAContext {
    funcs_data: u64; // *SSAFunction (pointer array)
    funcs_len: u64;
    funcs_cap: u64;
    next_block_id: u64;
    next_inst_id: u64;
}

// ============================================
// Block/Func List Helpers
// ============================================

func block_list_init(data_ptr: *u64, len_ptr: *u64, cap_ptr: *u64) -> u64 {
    *(*u64)(data_ptr) = 0;
    *(*u64)(len_ptr) = 0;
    *(*u64)(cap_ptr) = 0;
    return 0;
}

func block_list_push(data_ptr: *u64, len_ptr: *u64, cap_ptr: *u64, block: *SSABlock) -> u64 {
    var len: u64 = *(*u64)(len_ptr);
    var cap: u64 = *(*u64)(cap_ptr);
    var data: u64 = *(*u64)(data_ptr);

    if (len >= cap) {
        var new_cap: u64 = cap * 2;
        if (new_cap == 0) { new_cap = 8; }

        var new_data: u64 = heap_alloc(new_cap * 8);
        if (len > 0) {
            var i: u64 = 0;
            while (i < len) {
                *(*u64)(new_data + i * 8) = *(*u64)(data + i * 8);
                i = i + 1;
            }
        }
        data = new_data;
        cap = new_cap;
    }

    *(*u64)(data + len * 8) = block;
    len = len + 1;

    *(*u64)(data_ptr) = data;
    *(*u64)(len_ptr) = len;
    *(*u64)(cap_ptr) = cap;
    return 0;
}

func func_list_init(data_ptr: *u64, len_ptr: *u64, cap_ptr: *u64) -> u64 {
    *(*u64)(data_ptr) = 0;
    *(*u64)(len_ptr) = 0;
    *(*u64)(cap_ptr) = 0;
    return 0;
}

func func_list_push(data_ptr: *u64, len_ptr: *u64, cap_ptr: *u64, fn: *SSAFunction) -> u64 {
    var len: u64 = *(*u64)(len_ptr);
    var cap: u64 = *(*u64)(cap_ptr);
    var data: u64 = *(*u64)(data_ptr);

    if (len >= cap) {
        var new_cap: u64 = cap * 2;
        if (new_cap == 0) { new_cap = 8; }

        var new_data: u64 = heap_alloc(new_cap * 8);
        if (len > 0) {
            var i: u64 = 0;
            while (i < len) {
                *(*u64)(new_data + i * 8) = *(*u64)(data + i * 8);
                i = i + 1;
            }
        }
        data = new_data;
        cap = new_cap;
    }

    *(*u64)(data + len * 8) = fn;
    len = len + 1;

    *(*u64)(data_ptr) = data;
    *(*u64)(len_ptr) = len;
    *(*u64)(cap_ptr) = cap;
    return 0;
}
func ssa_block_list_push(fn: *SSAFunction, block: *SSABlock) -> u64 {
    var len: u64 = fn->blocks_len;
    var cap: u64 = fn->blocks_cap;
    var data: u64 = fn->blocks_data;

    if (len >= cap) {
        var new_cap: u64 = cap * 2;
        if (new_cap == 0) { new_cap = 8; }

        var new_data: u64 = heap_alloc(new_cap * 8);
        if (len > 0) {
            var i: u64 = 0;
            while (i < len) {
                *(*u64)(new_data + i * 8) = *(*u64)(data + i * 8);
                i = i + 1;
            }
        }
        data = new_data;
        cap = new_cap;
    }

    *(*u64)(data + len * 8) = block;
    len = len + 1;

    fn->blocks_data = data;
    fn->blocks_len = len;
    fn->blocks_cap = cap;
    return 0;
}

func ssa_func_list_push(ctx: *SSAContext, fn: *SSAFunction) -> u64 {
    var len: u64 = ctx->funcs_len;
    var cap: u64 = ctx->funcs_cap;
    var data: u64 = ctx->funcs_data;

    if (len >= cap) {
        var new_cap: u64 = cap * 2;
        if (new_cap == 0) { new_cap = 8; }

        var new_data: u64 = heap_alloc(new_cap * 8);
        if (len > 0) {
            var i: u64 = 0;
            while (i < len) {
                *(*u64)(new_data + i * 8) = *(*u64)(data + i * 8);
                i = i + 1;
            }
        }
        data = new_data;
        cap = new_cap;
    }

    *(*u64)(data + len * 8) = fn;
    len = len + 1;

    ctx->funcs_data = data;
    ctx->funcs_len = len;
    ctx->funcs_cap = cap;
    return 0;
}

// ============================================
// SSA Constructors
// ============================================

func ssa_context_new() -> u64 {
    var ctx: u64 = heap_alloc(SIZEOF_SSA_CTX);
    var c: *SSAContext = (*SSAContext)ctx;
    c->funcs_data = 0;
    c->funcs_len = 0;
    c->funcs_cap = 0;
    c->next_block_id = 0;
    c->next_inst_id = 0;
    return ctx;
}

func ssa_new_block(ctx: *SSAContext, fn: *SSAFunction) -> u64 {
    var b_ptr: u64 = heap_alloc(SIZEOF_SSA_BLOCK);
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
    b->dom_parent = 0;
    ssa_block_list_push(fn, b);
    return b_ptr;
}

func ssa_new_inst(ctx: *SSAContext, op: u64, dest: u64, src1: u64, src2: u64) -> u64 {
    var i_ptr: u64 = heap_alloc(SIZEOF_SSA_INST);
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

func ssa_inst_get_op(inst: *SSAInstruction) -> u64 {
    var p: *tagged(InstMeta) u8 = inst->prev;
    return (u64)p.op;
}

func ssa_inst_set_op(inst: *SSAInstruction, op: u64) -> u64 {
    var p: *tagged(InstMeta) u8 = inst->prev;
    p.op = (u16)op;
    inst->prev = p;
    return 0;
}

func ssa_phi_arg_new(val: u64, block_id: u64) -> u64 {
    var a_ptr: u64 = heap_alloc(SIZEOF_SSA_PHI_ARG);
    var a: *SSAPhiArg = (*SSAPhiArg)a_ptr;
    a->val = val;
    a->block_id = block_id;
    a->next = 0;
    return a_ptr;
}

func ssa_phi_arg_append(head: *SSAPhiArg, val: u64, block_id: u64) -> u64 {
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
    var inst_ptr: u64 = ssa_new_inst(ctx, SSA_OP_PHI, dest, (u64)args_head, 0);
    return inst_ptr;
}

func ssa_phi_add_arg(inst: *SSAInstruction, val: u64, block_id: u64) -> u64 {
    if (ssa_inst_get_op(inst) != SSA_OP_PHI) { return 0; }
    var head: *SSAPhiArg = (*SSAPhiArg)inst->src1;
    var new_head_ptr: u64 = ssa_phi_arg_append(head, val, block_id);
    inst->src1 = new_head_ptr;
    return 0;
}

func ssa_operand_const(val: u64) -> u64 {
    var mask: u64 = 1;
    mask = mask << 63;
    return val | mask;
}

func ssa_operand_reg(id: u64) -> u64 {
    return id & SSA_OPR_VALUE_MASK;
}

func ssa_operand_is_const(opr: u64) -> u64 {
    var mask: u64 = 1;
    mask = mask << 63;
    return (opr & mask) != 0;
}

func ssa_operand_value(opr: u64) -> u64 {
    return opr & SSA_OPR_VALUE_MASK;
}

func ssa_block_add_pred(block: *SSABlock, pred: *SSABlock) -> u64 {
    var len: u64 = block->preds_len;
    var cap: u64 = block->preds_cap;
    var data: u64 = block->preds_data;

    if (len >= cap) {
        var new_cap: u64 = cap * 2;
        if (new_cap == 0) { new_cap = 4; }
        var new_data: u64 = heap_alloc(new_cap * 8);
        if (len > 0) {
            var i: u64 = 0;
            while (i < len) {
                *(*u64)(new_data + i * 8) = *(*u64)(data + i * 8);
                i = i + 1;
            }
        }
        data = new_data;
        cap = new_cap;
    }

    *(*u64)(data + len * 8) = pred;
    len = len + 1;

    block->preds_data = data;
    block->preds_len = len;
    block->preds_cap = cap;
    return 0;
}

func ssa_block_add_succ(block: *SSABlock, succ: *SSABlock) -> u64 {
    var len: u64 = block->succs_len;
    var cap: u64 = block->succs_cap;
    var data: u64 = block->succs_data;

    if (len >= cap) {
        var new_cap: u64 = cap * 2;
        if (new_cap == 0) { new_cap = 4; }
        var new_data: u64 = heap_alloc(new_cap * 8);
        if (len > 0) {
            var i: u64 = 0;
            while (i < len) {
                *(*u64)(new_data + i * 8) = *(*u64)(data + i * 8);
                i = i + 1;
            }
        }
        data = new_data;
        cap = new_cap;
    }

    *(*u64)(data + len * 8) = succ;
    len = len + 1;

    block->succs_data = data;
    block->succs_len = len;
    block->succs_cap = cap;
    return 0;
}

func ssa_add_edge(src: *SSABlock, dst: *SSABlock) -> u64 {
    ssa_block_add_succ(src, dst);
    ssa_block_add_pred(dst, src);
    return 0;
}

func ssa_new_function(ctx: *SSAContext, name_ptr: u64, name_len: u64) -> u64 {
    var f_ptr: u64 = heap_alloc(SIZEOF_SSA_FUNC);
    var f: *SSAFunction = (*SSAFunction)f_ptr;
    f->id = ctx->funcs_len;
    f->name_ptr = name_ptr;
    f->name_len = name_len;
    f->blocks_data = 0;
    f->blocks_len = 0;
    f->blocks_cap = 0;
    f->entry = (*SSABlock)ssa_new_block(ctx, f);
    ssa_func_list_push(ctx, f);
    return f_ptr;
}

// ============================================
// SSA Build (Scaffold)
// ============================================

func ssa_build_func(ctx: *SSAContext, fn_ptr: u64) -> u64 {
    var fn: *AstFunc = (*AstFunc)fn_ptr;
    var ssa_fn_ptr: u64 = ssa_new_function(ctx, fn->name_ptr, fn->name_len);
    var ssa_fn: *SSAFunction = (*SSAFunction)ssa_fn_ptr;
    var entry: *SSABlock = ssa_fn->entry;

    // Entry marker (placeholder)
    var inst_ptr: u64 = ssa_new_inst(ctx, SSA_OP_ENTRY, 0, 0, 0);
    ssa_inst_append(entry, (*SSAInstruction)inst_ptr);
    return 0;
}

func ssa_build_program(prog: u64) -> u64 {
    var program: *AstProgram = (*AstProgram)prog;
    var funcs: u64 = program->funcs_vec;
    var count: u64 = vec_len(funcs);

    var ctx_ptr: u64 = ssa_context_new();
    var ctx: *SSAContext = (*SSAContext)ctx_ptr;

    var i: u64 = 0;
    while (i < count) {
        var fn_ptr: u64 = vec_get(funcs, i);
        ssa_build_func(ctx, fn_ptr);
        i = i + 1;
    }
    return ctx_ptr;
}
