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

const SIZEOF_SSA_INST = 56;   // 7 * u64
const SIZEOF_SSA_BLOCK = 32;  // 4 * u64
const SIZEOF_SSA_FUNC = 56;   // 7 * u64
const SIZEOF_SSA_CTX = 40;    // 5 * u64

const SSA_OP_NOP = 0;
const SSA_OP_ENTRY = 1;

// ============================================
// SSA Core Types
// ============================================

struct SSAInstruction {
    prev: *SSAInstruction;
    next: *SSAInstruction;
    id: u64;
    op: u64;
    dest: u64;
    src1: u64;
    src2: u64;
}

struct SSABlock {
    id: u64;
    inst_head: *SSAInstruction;
    inst_tail: *SSAInstruction;
    next_block: *SSABlock;
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
    b->inst_head = 0;
    b->inst_tail = 0;
    b->next_block = 0;
    ssa_block_list_push(fn, b);
    return b_ptr;
}

func ssa_new_inst(ctx: *SSAContext, op: u64, dest: u64, src1: u64, src2: u64) -> u64 {
    var i_ptr: u64 = heap_alloc(SIZEOF_SSA_INST);
    var inst: *SSAInstruction = (*SSAInstruction)i_ptr;
    inst->prev = 0;
    inst->next = 0;
    inst->id = ctx->next_inst_id;
    ctx->next_inst_id = ctx->next_inst_id + 1;
    inst->op = op;
    inst->dest = dest;
    inst->src1 = src1;
    inst->src2 = src2;
    return i_ptr;
}

func ssa_inst_append(block: *SSABlock, inst: *SSAInstruction) -> u64 {
    inst->prev = block->inst_tail;
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
