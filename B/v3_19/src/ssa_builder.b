// ssa_builder.b - SSA CFG builder (v3_17)
//
// AST를 순회하며 기본 블록/엣지 연결과 명령어 생성까지 처리합니다.
// (SSA Rename은 다음 단계)

import std.io;
import std.vec;
import std.hashmap;
import types;
import ast;
import ssa;
import emitter.typeinfo;

// ============================================
// Builder Context
// ============================================

struct BuilderCtx {
    ssa_ctx: *SSAContext;
    cur_func: *SSAFunction;
    cur_block: *SSABlock;
    break_stack: u64;    // vec of *SSABlock
    continue_stack: u64; // vec of *SSABlock
    var_map: u64;         // hashmap: name -> var_id
    next_reg: u64;
    next_var_id: u64;
}

func builder_ctx_new(ssa_ctx: *SSAContext) -> u64 {
    var p: u64 = heap_alloc(64);
    var ctx: *BuilderCtx = (*BuilderCtx)p;
    ctx->ssa_ctx = ssa_ctx;
    ctx->cur_func = 0;
    ctx->cur_block = 0;
    ctx->break_stack = vec_new(8);
    ctx->continue_stack = vec_new(8);
    ctx->var_map = 0;
    ctx->next_reg = 1;
    ctx->next_var_id = 1;
    return p;
}

func builder_set_block(ctx: *BuilderCtx, block: *SSABlock) -> u64 {
    ctx->cur_block = block;
    return 0;
}

func builder_push_loop(ctx: *BuilderCtx, break_bb: *SSABlock, continue_bb: *SSABlock) -> u64 {
    vec_push(ctx->break_stack, (u64)break_bb);
    vec_push(ctx->continue_stack, (u64)continue_bb);
    return 0;
}

func builder_pop_loop(ctx: *BuilderCtx) -> u64 {
    var blen: u64 = vec_len(ctx->break_stack);
    var clen: u64 = vec_len(ctx->continue_stack);
    if (blen > 0) { vec_pop(ctx->break_stack); }
    if (clen > 0) { vec_pop(ctx->continue_stack); }
    return 0;
}

func builder_top_break(ctx: *BuilderCtx) -> u64 {
    var blen: u64 = vec_len(ctx->break_stack);
    if (blen == 0) { return 0; }
    return vec_get(ctx->break_stack, blen - 1);
}

func builder_top_continue(ctx: *BuilderCtx) -> u64 {
    var clen: u64 = vec_len(ctx->continue_stack);
    if (clen == 0) { return 0; }
    return vec_get(ctx->continue_stack, clen - 1);
}

func builder_reset_func(ctx: *BuilderCtx) -> u64 {
    ctx->var_map = hashmap_new(16);
    ctx->next_reg = 1;
    ctx->next_var_id = 1;
    *(*u64)(ctx->break_stack + 8) = 0;
    *(*u64)(ctx->continue_stack + 8) = 0;
    return 0;
}

func builder_new_reg(ctx: *BuilderCtx) -> u64 {
    var id: u64 = ctx->next_reg;
    ctx->next_reg = ctx->next_reg + 1;
    return id;
}

func builder_new_var_id(ctx: *BuilderCtx) -> u64 {
    var id: u64 = ctx->next_var_id;
    ctx->next_var_id = ctx->next_var_id + 1;
    return id;
}

func builder_get_var_id(ctx: *BuilderCtx, name_ptr: u64, name_len: u64) -> u64 {
    if (ctx->var_map == 0) {
        ctx->var_map = hashmap_new(16);
    }

    var found: u64 = hashmap_get(ctx->var_map, name_ptr, name_len);
    if (found != 0) { return found; }

    var new_id: u64 = builder_new_var_id(ctx);
    hashmap_put(ctx->var_map, name_ptr, name_len, new_id);
    return new_id;
}

func builder_add_params(ctx: *BuilderCtx, fn: *AstFunc) -> u64 {
    if (fn == 0) { return 0; }
    var params: u64 = fn->params_vec;
    if (params == 0) { return 0; }

    var n: u64 = vec_len(params);
    var i: u64 = 0;
    while (i < n) {
        var p: *Param = (*Param)vec_get(params, i);
        var var_id: u64 = builder_get_var_id(ctx, p->name_ptr, p->name_len);
        var reg_id: u64 = builder_new_reg(ctx);
        var inst_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_PARAM, reg_id, ssa_operand_const(i), 0);
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr);
        var st_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_STORE, 0, ssa_operand_const(var_id), ssa_operand_reg(reg_id));
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)st_ptr);
        i = i + 1;
    }
    return 0;
}

// ============================================
// Builder Helpers
// ============================================

func builder_block_is_terminated(block: *SSABlock) -> u64 {
    if (block == 0) { return 1; }
    var tail: *SSAInstruction = block->inst_tail;
    if (tail == 0) { return 0; }
    var op: u64 = ssa_inst_get_op(tail);
    if (op == SSA_OP_JMP || op == SSA_OP_BR || op == SSA_OP_RET) { return 1; }
    return 0;
}

func builder_block_is_reachable(block: *SSABlock) -> u64 {
    if (block == 0) { return 0; }
    if (block->preds_len > 0) { return 1; }
    return 0;
}

func builder_stmt_or_expr(ctx: *BuilderCtx, node: u64) -> u64 {
    if (node == 0) { return 0; }
    var k: u64 = ast_kind(node);
    if (k == AST_VAR_DECL || k == AST_CONST_DECL || k == AST_ASSIGN || k == AST_EXPR_STMT) {
        build_stmt(ctx, node);
        return 0;
    }
    build_expr(ctx, node);
    return 0;
}

func builder_binop_to_ssa_op(op: u64) -> u64 {
    if (op == TOKEN_PLUS) { return SSA_OP_ADD; }
    if (op == TOKEN_MINUS) { return SSA_OP_SUB; }
    if (op == TOKEN_STAR) { return SSA_OP_MUL; }
    if (op == TOKEN_SLASH) { return SSA_OP_DIV; }
    if (op == TOKEN_PERCENT) { return SSA_OP_MOD; }
    if (op == TOKEN_AMPERSAND) { return SSA_OP_AND; }
    if (op == TOKEN_PIPE) { return SSA_OP_OR; }
    if (op == TOKEN_CARET) { return SSA_OP_XOR; }
    if (op == TOKEN_LSHIFT) { return SSA_OP_SHL; }
    if (op == TOKEN_RSHIFT) { return SSA_OP_SHR; }
    if (op == TOKEN_EQEQ) { return SSA_OP_EQ; }
    if (op == TOKEN_BANGEQ) { return SSA_OP_NE; }
    if (op == TOKEN_LT) { return SSA_OP_LT; }
    if (op == TOKEN_GT) { return SSA_OP_GT; }
    if (op == TOKEN_LTEQ) { return SSA_OP_LE; }
    if (op == TOKEN_GTEQ) { return SSA_OP_GE; }
    return SSA_OP_NOP;
}

func build_const(ctx: *BuilderCtx, val: u64) -> u64 {
    var reg_id: u64 = builder_new_reg(ctx);
    var inst_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_CONST, reg_id, ssa_operand_const(val), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr);
    return reg_id;
}

func build_bool_from_reg(ctx: *BuilderCtx, reg: u64) -> u64 {
    var zero_reg: u64 = build_const(ctx, 0);
    var dst: u64 = builder_new_reg(ctx);
    var inst_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_NE, dst, ssa_operand_reg(reg), ssa_operand_reg(zero_reg));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr);
    return dst;
}

func build_short_circuit(ctx: *BuilderCtx, op: u64, left: u64, right: u64) -> u64 {
    var entry_bb: *SSABlock = ctx->cur_block;
    var left_reg: u64 = build_expr(ctx, left);

    var right_bb: *SSABlock = (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func);
    var merge_bb: *SSABlock = (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func);

    var entry_val: u64 = 0;
    if (op == TOKEN_ANDAND) {
        entry_val = build_const(ctx, 0);
        var br_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_BR, ssa_operand_const(merge_bb->id), ssa_operand_reg(left_reg), ssa_operand_const(right_bb->id));
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)br_ptr);
        ssa_add_edge(ctx->cur_block, right_bb);
        ssa_add_edge(ctx->cur_block, merge_bb);
    } else {
        entry_val = build_const(ctx, 1);
        var br_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_BR, ssa_operand_const(right_bb->id), ssa_operand_reg(left_reg), ssa_operand_const(merge_bb->id));
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)br_ptr2);
        ssa_add_edge(ctx->cur_block, merge_bb);
        ssa_add_edge(ctx->cur_block, right_bb);
    }

    builder_set_block(ctx, right_bb);
    var right_reg: u64 = build_expr(ctx, right);
    var right_bool: u64 = build_bool_from_reg(ctx, right_reg);
    var jmp_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_JMP, 0, ssa_operand_const(merge_bb->id), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)jmp_ptr);
    ssa_add_edge(ctx->cur_block, merge_bb);

    builder_set_block(ctx, merge_bb);
    var head_ptr: u64 = ssa_phi_arg_new(entry_val, entry_bb->id);
    var head: *SSAPhiArg = (*SSAPhiArg)head_ptr;
    var head2: u64 = ssa_phi_arg_append(head, right_bool, right_bb->id);
    head = (*SSAPhiArg)head2;
    var dest: u64 = builder_new_reg(ctx);
    var phi_ptr: u64 = ssa_phi_new(ctx->ssa_ctx, dest, head);
    ssa_phi_append(merge_bb, (*SSAInstruction)phi_ptr);
    return dest;
}

func build_expr(ctx: *BuilderCtx, node: u64) -> u64 {
    if (node == 0) { return 0; }
    var kind: u64 = ast_kind(node);

    if (kind == AST_LITERAL) {
        var lit: *AstLiteral = (*AstLiteral)node;
        return build_const(ctx, lit->value);
    }

    if (kind == AST_IDENT) {
        var idn: *AstIdent = (*AstIdent)node;
        var var_id: u64 = builder_get_var_id(ctx, idn->name_ptr, idn->name_len);
        var reg_id: u64 = builder_new_reg(ctx);
        var inst_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_LOAD, reg_id, ssa_operand_const(var_id), 0);
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr);
        return reg_id;
    }

    if (kind == AST_BINARY) {
        var bin: *AstBinary = (*AstBinary)node;
        if (bin->op == TOKEN_ANDAND || bin->op == TOKEN_OROR) {
            return build_short_circuit(ctx, bin->op, bin->left, bin->right);
        }
        var lhs_reg: u64 = build_expr(ctx, bin->left);
        var rhs_reg: u64 = build_expr(ctx, bin->right);
        var op: u64 = builder_binop_to_ssa_op(bin->op);
        if (op == SSA_OP_NOP) {
            return build_const(ctx, 0);
        }
        var reg_id2: u64 = builder_new_reg(ctx);
        var inst_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, op, reg_id2, ssa_operand_reg(lhs_reg), ssa_operand_reg(rhs_reg));
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr2);
        return reg_id2;
    }

    if (kind == AST_UNARY) {
        var un: *AstUnary = (*AstUnary)node;
        var op: u64 = un->op;
        var val_reg: u64 = build_expr(ctx, un->operand);

        if (op == TOKEN_MINUS) {
            var zero_reg: u64 = build_const(ctx, 0);
            var dst: u64 = builder_new_reg(ctx);
            var inst_ptr3: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_SUB, dst, ssa_operand_reg(zero_reg), ssa_operand_reg(val_reg));
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr3);
            return dst;
        }

        if (op == TOKEN_BANG) {
            var zero_reg2: u64 = build_const(ctx, 0);
            var dst2: u64 = builder_new_reg(ctx);
            var inst_ptr4: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_EQ, dst2, ssa_operand_reg(val_reg), ssa_operand_reg(zero_reg2));
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr4);
            return dst2;
        }

        return val_reg;
    }

    if (kind == AST_SIZEOF) {
        var sz: *AstSizeof = (*AstSizeof)node;
        var size_val: u64 = sizeof_type(sz->type_kind, sz->ptr_depth, sz->struct_name_ptr, sz->struct_name_len);
        return build_const(ctx, size_val);
    }

    return build_const(ctx, 0);
}

// ============================================
// CFG Builders
// ============================================

func build_block(ctx: *BuilderCtx, block_node: u64) -> u64 {
    if (block_node == 0) { return 0; }
    var blk: *AstBlock = (*AstBlock)block_node;
    var stmts: u64 = blk->stmts_vec;
    var n: u64 = vec_len(stmts);
    for (var i: u64 = 0; i < n; i++) {
        var stmt: u64 = vec_get(stmts, i);
        build_stmt(ctx, stmt);
    }
    return 0;
}

func build_for(ctx: *BuilderCtx, node: u64) -> u64 {
    var f: *AstFor = (*AstFor)node;

    if (f->init != 0) {
        builder_stmt_or_expr(ctx, f->init);
    }

    var cond_bb: *SSABlock = (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func);
    var body_bb: *SSABlock = (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func);
    var update_bb: *SSABlock = (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func);
    var exit_bb: *SSABlock = (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func);

    var jmp_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_JMP, 0, ssa_operand_const(cond_bb->id), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)jmp_ptr);
    ssa_add_edge(ctx->cur_block, cond_bb);

    builder_set_block(ctx, cond_bb);
    var cond_reg: u64 = 0;
    if (f->cond != 0) {
        cond_reg = build_expr(ctx, f->cond);
    } else {
        cond_reg = build_const(ctx, 1);
    }
    var br_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_BR, ssa_operand_const(exit_bb->id), ssa_operand_reg(cond_reg), ssa_operand_const(body_bb->id));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)br_ptr);
    ssa_add_edge(ctx->cur_block, body_bb);
    ssa_add_edge(ctx->cur_block, exit_bb);

    builder_push_loop(ctx, exit_bb, update_bb);
    builder_set_block(ctx, body_bb);
    build_block(ctx, f->body);
    if (builder_block_is_reachable(ctx->cur_block) != 0 && builder_block_is_terminated(ctx->cur_block) == 0) {
        var jmp_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_JMP, 0, ssa_operand_const(update_bb->id), 0);
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)jmp_ptr2);
        ssa_add_edge(ctx->cur_block, update_bb);
    }
    builder_pop_loop(ctx);

    builder_set_block(ctx, update_bb);
    if (f->update != 0) {
        builder_stmt_or_expr(ctx, f->update);
    }
    if (builder_block_is_reachable(ctx->cur_block) != 0 && builder_block_is_terminated(ctx->cur_block) == 0) {
        var jmp_ptr3: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_JMP, 0, ssa_operand_const(cond_bb->id), 0);
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)jmp_ptr3);
        ssa_add_edge(ctx->cur_block, cond_bb);
    }

    builder_set_block(ctx, exit_bb);
    return 0;
}

func build_switch(ctx: *BuilderCtx, node: u64) -> u64 {
    var sw: *AstSwitch = (*AstSwitch)node;
    var cases: u64 = sw->cases_vec;
    var count: u64 = 0;
    if (cases != 0) { count = vec_len(cases); }

    var exit_bb: *SSABlock = (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func);
    if (count == 0) {
        var jmp_ptr0: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_JMP, 0, ssa_operand_const(exit_bb->id), 0);
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)jmp_ptr0);
        ssa_add_edge(ctx->cur_block, exit_bb);
        builder_set_block(ctx, exit_bb);
        return 0;
    }

    var expr_reg: u64 = build_expr(ctx, sw->expr);

    var case_blocks: u64 = vec_new(count);
    var case_nodes: u64 = vec_new(count);
    var default_bb: *SSABlock = exit_bb;

    var i: u64 = 0;
    while (i < count) {
        var c_ptr: u64 = vec_get(cases, i);
        var c: *AstCase = (*AstCase)c_ptr;
        var case_bb: *SSABlock = (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func);
        vec_push(case_blocks, (u64)case_bb);
        vec_push(case_nodes, c_ptr);
        if (c->is_default != 0) {
            default_bb = case_bb;
        }
        i = i + 1;
    }

    i = 0;
    while (i < count) {
        var c_ptr2: u64 = vec_get(case_nodes, i);
        var c2: *AstCase = (*AstCase)c_ptr2;
        if (c2->is_default == 0) {
            var case_bb2: *SSABlock = (*SSABlock)vec_get(case_blocks, i);
            var val_reg: u64 = build_expr(ctx, c2->value);
            var cmp_reg: u64 = builder_new_reg(ctx);
            var cmp_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_EQ, cmp_reg, ssa_operand_reg(expr_reg), ssa_operand_reg(val_reg));
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)cmp_ptr);

            var next_bb: *SSABlock = (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func);
            var br_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_BR, ssa_operand_const(next_bb->id), ssa_operand_reg(cmp_reg), ssa_operand_const(case_bb2->id));
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)br_ptr);
            ssa_add_edge(ctx->cur_block, case_bb2);
            ssa_add_edge(ctx->cur_block, next_bb);
            builder_set_block(ctx, next_bb);
        }
        i = i + 1;
    }

    var jmp_ptr1: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_JMP, 0, ssa_operand_const(default_bb->id), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)jmp_ptr1);
    ssa_add_edge(ctx->cur_block, default_bb);

    builder_push_loop(ctx, exit_bb, 0);
    i = 0;
    while (i < count) {
        var case_bb3: *SSABlock = (*SSABlock)vec_get(case_blocks, i);
        var c_ptr3: u64 = vec_get(case_nodes, i);
        var c3: *AstCase = (*AstCase)c_ptr3;
        builder_set_block(ctx, case_bb3);
        build_block(ctx, c3->body);

        if (builder_block_is_reachable(ctx->cur_block) != 0 && builder_block_is_terminated(ctx->cur_block) == 0) {
            var next_bb2: *SSABlock = exit_bb;
            if (i + 1 < count) {
                next_bb2 = (*SSABlock)vec_get(case_blocks, i + 1);
            }
            var jmp_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_JMP, 0, ssa_operand_const(next_bb2->id), 0);
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)jmp_ptr2);
            ssa_add_edge(ctx->cur_block, next_bb2);
        }
        i = i + 1;
    }
    builder_pop_loop(ctx);

    builder_set_block(ctx, exit_bb);
    return 0;
}

func build_if(ctx: *BuilderCtx, node: u64) -> u64 {
    var ifn: *AstIf = (*AstIf)node;
    var has_else: u64 = 0;
    if (ifn->else_block != 0) { has_else = 1; }

    var cond_reg: u64 = build_expr(ctx, ifn->cond);

    var then_bb: *SSABlock = (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func);
    var merge_bb: *SSABlock = (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func);
    var else_bb: *SSABlock = merge_bb;
    if (has_else == 1) {
        else_bb = (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func);
    }

    var br_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_BR, ssa_operand_const(else_bb->id), ssa_operand_reg(cond_reg), ssa_operand_const(then_bb->id));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)br_ptr);

    ssa_add_edge(ctx->cur_block, then_bb);
    ssa_add_edge(ctx->cur_block, else_bb);

    builder_set_block(ctx, then_bb);
    build_block(ctx, ifn->then_block);
    var jmp_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_JMP, 0, ssa_operand_const(merge_bb->id), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)jmp_ptr);
    ssa_add_edge(ctx->cur_block, merge_bb);

    if (has_else == 1) {
        builder_set_block(ctx, else_bb);
        build_block(ctx, ifn->else_block);
        var jmp_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_JMP, 0, ssa_operand_const(merge_bb->id), 0);
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)jmp_ptr2);
        ssa_add_edge(ctx->cur_block, merge_bb);
    }

    builder_set_block(ctx, merge_bb);
    return 0;
}

func build_while(ctx: *BuilderCtx, node: u64) -> u64 {
    var w: *AstWhile = (*AstWhile)node;

    var cond_bb: *SSABlock = (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func);
    var body_bb: *SSABlock = (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func);
    var exit_bb: *SSABlock = (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func);

    var jmp_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_JMP, 0, ssa_operand_const(cond_bb->id), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)jmp_ptr);
    ssa_add_edge(ctx->cur_block, cond_bb);

    builder_set_block(ctx, cond_bb);
    var cond_reg: u64 = build_expr(ctx, w->cond);
    var br_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_BR, ssa_operand_const(exit_bb->id), ssa_operand_reg(cond_reg), ssa_operand_const(body_bb->id));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)br_ptr);
    ssa_add_edge(ctx->cur_block, body_bb);
    ssa_add_edge(ctx->cur_block, exit_bb);

    builder_push_loop(ctx, exit_bb, cond_bb);
    builder_set_block(ctx, body_bb);
    build_block(ctx, w->body);
    var jmp_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_JMP, 0, ssa_operand_const(cond_bb->id), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)jmp_ptr2);
    ssa_add_edge(ctx->cur_block, cond_bb);
    builder_pop_loop(ctx);

    builder_set_block(ctx, exit_bb);
    return 0;
}

func build_stmt(ctx: *BuilderCtx, node: u64) -> u64 {
    var kind: u64 = ast_kind(node);

    if (kind == AST_BLOCK) {
        build_block(ctx, node);
        return 0;
    }

    if (kind == AST_IF) {
        build_if(ctx, node);
        return 0;
    }

    if (kind == AST_WHILE) {
        build_while(ctx, node);
        return 0;
    }

    if (kind == AST_FOR) {
        build_for(ctx, node);
        return 0;
    }

    if (kind == AST_SWITCH) {
        build_switch(ctx, node);
        return 0;
    }

    if (kind == AST_EXPR_STMT) {
        var es: *AstExprStmt = (*AstExprStmt)node;
        build_expr(ctx, es->expr);
        return 0;
    }

    if (kind == AST_VAR_DECL) {
        var vd: *AstVarDecl = (*AstVarDecl)node;
        var var_id: u64 = builder_get_var_id(ctx, vd->name_ptr, vd->name_len);
        if (vd->init_expr != 0) {
            var val_reg: u64 = build_expr(ctx, vd->init_expr);
            var st_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_STORE, 0, ssa_operand_const(var_id), ssa_operand_reg(val_reg));
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)st_ptr);
        }
        return 0;
    }

    if (kind == AST_CONST_DECL) {
        var cd: *AstConstDecl = (*AstConstDecl)node;
        var var_id2: u64 = builder_get_var_id(ctx, cd->name_ptr, cd->name_len);
        var val_reg2: u64 = build_const(ctx, cd->value);
        var st_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_STORE, 0, ssa_operand_const(var_id2), ssa_operand_reg(val_reg2));
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)st_ptr2);
        return 0;
    }

    if (kind == AST_ASSIGN) {
        var asn: *AstAssign = (*AstAssign)node;
        var target_kind: u64 = ast_kind(asn->target);
        if (target_kind == AST_IDENT) {
            var idn: *AstIdent = (*AstIdent)asn->target;
            var var_id3: u64 = builder_get_var_id(ctx, idn->name_ptr, idn->name_len);
            var val_reg3: u64 = build_expr(ctx, asn->value);
            var st_ptr3: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_STORE, 0, ssa_operand_const(var_id3), ssa_operand_reg(val_reg3));
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)st_ptr3);
        }
        return 0;
    }

    if (kind == AST_RETURN) {
        var ret: *AstReturn = (*AstReturn)node;
        var val_reg4: u64 = 0;
        if (ret->expr != 0) {
            val_reg4 = build_expr(ctx, ret->expr);
        }
        var ret_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_RET, 0, ssa_operand_reg(val_reg4), 0);
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)ret_ptr);
        return 0;
    }

    if (kind == AST_BREAK) {
        var target: u64 = builder_top_break(ctx);
        if (target != 0) {
            var jmp_ptr3: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_JMP, 0, ssa_operand_const(((*SSABlock)target)->id), 0);
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)jmp_ptr3);
            ssa_add_edge(ctx->cur_block, (*SSABlock)target);
            builder_set_block(ctx, (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func));
        }
        return 0;
    }

    if (kind == AST_CONTINUE) {
        var target2: u64 = builder_top_continue(ctx);
        if (target2 != 0) {
            var jmp_ptr4: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_JMP, 0, ssa_operand_const(((*SSABlock)target2)->id), 0);
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)jmp_ptr4);
            ssa_add_edge(ctx->cur_block, (*SSABlock)target2);
            builder_set_block(ctx, (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func));
        }
        return 0;
    }

    return 0;
}

// ============================================
// Entry Points
// ============================================

func ssa_builder_build_func(ctx: *BuilderCtx, fn_ptr: u64) -> u64 {
    var fn: *AstFunc = (*AstFunc)fn_ptr;
    var ssa_fn_ptr: u64 = ssa_new_function(ctx->ssa_ctx, fn->name_ptr, fn->name_len);
    ctx->cur_func = (*SSAFunction)ssa_fn_ptr;
    ctx->cur_block = ctx->cur_func->entry;
    builder_reset_func(ctx);
    builder_add_params(ctx, fn);
    build_block(ctx, fn->body);
    return 0;
}

func ssa_builder_build_program(prog: u64) -> u64 {
    var program: *AstProgram = (*AstProgram)prog;
    var funcs: u64 = program->funcs_vec;
    var count: u64 = vec_len(funcs);

    var ssa_ctx_ptr: u64 = ssa_context_new();
    var bctx_ptr: u64 = builder_ctx_new((*SSAContext)ssa_ctx_ptr);
    var bctx: *BuilderCtx = (*BuilderCtx)bctx_ptr;

    var i: u64 = 0;
    while (i < count) {
        var fn_ptr: u64 = vec_get(funcs, i);
        ssa_builder_build_func(bctx, fn_ptr);
        i = i + 1;
    }

    return ssa_ctx_ptr;
}
