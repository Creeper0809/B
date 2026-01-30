// ssa.b - SSA entry points (outside ssa/)
// SSA 진입 지점을 외부로 분리한 모듈

import std.io;
import std.util;
import std.vec;
import ast;
import ssa.datastruct;
import ssa.core;
import compiler;
import ssa.builder;
import ssa.codegen;
import emitter.emitter;

// ============================================
// SSA Build (Scaffold)
// ============================================

func ssa_build_func(ctx: *SSAContext, fn_ptr: u64) -> u64 {
    push_trace("ssa_build_func", "ssa.b", __LINE__);

    var fn: *AstFunc = (*AstFunc)fn_ptr;
    var ssa_fn_ptr: u64 = ssa_new_function(ctx, fn->name_ptr, fn->name_len);
    var ssa_fn: *SSAFunction = (*SSAFunction)ssa_fn_ptr;
    var entry: *SSABlock = ssa_fn->entry;

    // Entry marker (placeholder)
    var inst_ptr: u64 = ssa_new_inst(ctx, SSA_OP_ENTRY, 0, 0, 0);
    ssa_inst_append(entry, (*SSAInstruction)inst_ptr);
    
    pop_trace();
    return 0;
}

func ssa_build_program(prog: u64) -> u64 {
    push_trace("ssa_build_program", "ssa.b", __LINE__);

    var program: *AstProgram = (*AstProgram)prog;
    var funcs: u64 = program->funcs_vec;
    var count: u64 = vec_len(funcs);

    var ctx_ptr: u64 = ssa_context_new();
    var ctx: *SSAContext = (*SSAContext)ctx_ptr;

    for (var i: u64 = 0; i < count; i++) {
        var fn_ptr: u64 = vec_get(funcs, i);
        ssa_build_func(ctx, fn_ptr);
    }
    pop_trace();
    return ctx_ptr;
}

// ============================================
// SSA Builder Entry
// ============================================

func ssa_builder_build_func(ctx: *BuilderCtx, fn_ptr: u64) -> u64 {
    push_trace("ssa_builder_build_func", "ssa.b", __LINE__);
    var fn: *AstFunc = (*AstFunc)fn_ptr;
    set_current_module_for_func(fn->name_ptr, fn->name_len);
    if (SSA_BUILDER_DEBUG != 0) {
        emit("[DEBUG] ssa_builder_build_func: ", 36);
        emit(fn->name_ptr, fn->name_len);
        emit("\n", 1);
    }
    var ssa_fn_ptr: u64 = ssa_new_function(ctx->ssa_ctx, fn->name_ptr, fn->name_len);
    ctx->cur_func = (*SSAFunction)ssa_fn_ptr;
    ctx->cur_block = ctx->cur_func->entry;
    emitter_set_ret_type(fn->ret_type);
    emitter_set_ret_ptr_depth(fn->ret_ptr_depth);
    emitter_set_ret_struct_name(fn->ret_struct_name_ptr, fn->ret_struct_name_len);
    builder_reset_func(ctx);
    builder_add_params(ctx, fn);
    build_block(ctx, fn->body);
    if (builder_block_is_terminated(ctx->cur_block) == 0) {
        var ret_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_RET, 0, 0, 0);
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)ret_ptr);
    }
    pop_trace();
    return 0;
}

func ssa_builder_build_program(prog: u64) -> u64 {
    push_trace("ssa_builder_build_program", "ssa.b", __LINE__);

    var program: *AstProgram = (*AstProgram)prog;
    var funcs: u64 = program->funcs_vec;
    var count: u64 = vec_len(funcs);

    var ssa_ctx_ptr: u64 = ssa_context_new();
    ssa_ret_slice_heap_clear();
    var bctx_ptr: u64 = builder_ctx_new((*SSAContext)ssa_ctx_ptr);
    var bctx: *BuilderCtx = (*BuilderCtx)bctx_ptr;

    for (var i: u64 = 0; i < count; i++) {
        var fn_ptr: u64 = vec_get(funcs, i);
        var fn: *AstFunc = (*AstFunc)fn_ptr;
        if (fn->body == 0) {
            ssa_new_function(bctx->ssa_ctx, fn->name_ptr, fn->name_len);
        } else if (ssa_codegen_is_supported_func(fn_ptr, program->globals_vec) == 0) {
            ssa_new_function(bctx->ssa_ctx, fn->name_ptr, fn->name_len);
        } else {
            ssa_builder_build_func(bctx, fn_ptr);
        }
    }
    pop_trace();
    return ssa_ctx_ptr;
}
