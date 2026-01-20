// ssa_builder.b - SSA CFG builder (v3_17)
//
// AST를 순회하며 기본 블록/엣지 연결과 명령어 생성까지 처리합니다.
// (SSA Rename은 다음 단계)

import std.io;
import std.util;
import std.vec;
import std.hashmap;
import std.str;
import types;
import ast;
import ssa.datastruct;
import ssa.core;
import emitter.typeinfo;
import emitter.symtab;
import compiler;
import ssa.codegen;

const SSA_BUILDER_DEBUG = 0;

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
    symtab: u64;           // symtab for type/offset lookup
    next_reg: u64;
    next_var_id: u64;
}

func builder_ctx_new(ssa_ctx: *SSAContext) -> u64 {
    push_trace("builder_ctx_new", "ssa_builder.b", __LINE__);
    pop_trace();
    // BuilderCtx = 9 * 8 bytes = 72 bytes
    var p: u64 = heap_alloc(72);
    var ctx: *BuilderCtx = (*BuilderCtx)p;
    ctx->ssa_ctx = ssa_ctx;
    ctx->cur_func = 0;
    ctx->cur_block = 0;
    ctx->break_stack = vec_new(8);
    ctx->continue_stack = vec_new(8);
    ctx->var_map = 0;
    ctx->symtab = 0;
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
    push_trace("builder_reset_func", "ssa_builder.b", __LINE__);
    pop_trace();
    ctx->var_map = hashmap_new(16);
    ctx->symtab = symtab_new();
    ctx->next_reg = 1;
    ctx->next_var_id = 1;
    *(*u64)(ctx->break_stack + 8) = 0;
    *(*u64)(ctx->continue_stack + 8) = 0;
    return 0;
}

// ============================================
// Symtab Helpers
// ============================================

func builder_symtab_add_param(ctx: *BuilderCtx, p: *Param, offset: u64) -> u64 {
    var symtab_ptr: u64 = ctx->symtab;
    var names: u64 = *(symtab_ptr);
    var offsets: u64 = *(symtab_ptr + 8);
    var types: u64 = *(symtab_ptr + 16);
    var count: u64 = *(symtab_ptr + 24);

    var name_info: u64 = heap_alloc(16);
    *(name_info) = p->name_ptr;
    *(name_info + 8) = p->name_len;
    vec_push(names, name_info);
    vec_push(offsets, offset);

    var type_info: u64 = heap_alloc(SIZEOF_TYPEINFO);
    var ti: *TypeInfo = (*TypeInfo)type_info;
    ti->type_kind = p->type_kind;
    ti->ptr_depth = p->ptr_depth;
    ti->is_tagged = p->is_tagged;
    ti->struct_name_ptr = p->struct_name_ptr;
    ti->struct_name_len = p->struct_name_len;
    ti->tag_layout_ptr = p->tag_layout_ptr;
    ti->tag_layout_len = p->tag_layout_len;
    ti->struct_def = 0;
    ti->elem_type_kind = p->elem_type_kind;
    ti->elem_ptr_depth = p->elem_ptr_depth;
    ti->array_len = p->array_len;

    var g_structs_vec: u64 = typeinfo_get_structs();
    if (p->type_kind == TYPE_STRUCT && g_structs_vec != 0 && p->struct_name_ptr != 0) {
        var num_structs: u64 = vec_len(g_structs_vec);
        for (var si: u64 = 0; si < num_structs; si++) {
            var sd_ptr: u64 = vec_get(g_structs_vec, si);
            var sd: *AstStructDef = (*AstStructDef)sd_ptr;
            if (sd->name_len == p->struct_name_len && str_eq(sd->name_ptr, sd->name_len, p->struct_name_ptr, p->struct_name_len) != 0) {
                ti->struct_def = sd_ptr;
                break;
            }
        }
    }
    if (p->elem_type_kind == TYPE_STRUCT && g_structs_vec != 0 && p->struct_name_ptr != 0) {
        var num_structs2: u64 = vec_len(g_structs_vec);
        for (var sj: u64 = 0; sj < num_structs2; sj++) {
            var sd_ptr2: u64 = vec_get(g_structs_vec, sj);
            var sd2: *AstStructDef = (*AstStructDef)sd_ptr2;
            if (sd2->name_len == p->struct_name_len && str_eq(sd2->name_ptr, sd2->name_len, p->struct_name_ptr, p->struct_name_len) != 0) {
                ti->struct_def = sd_ptr2;
                break;
            }
        }
    }

    vec_push(types, type_info);
    *(symtab_ptr + 24) = count + 1;
    return 0;
}

func builder_symtab_add_local(ctx: *BuilderCtx, decl: *AstVarDecl) -> u64 {
    var name_ptr: u64 = decl->name_ptr;
    var name_len: u64 = decl->name_len;
    var type_kind: u64 = decl->type_kind;
    var ptr_depth: u64 = decl->ptr_depth;
    var struct_name_ptr: u64 = decl->struct_name_ptr;
    var struct_name_len: u64 = decl->struct_name_len;
    var elem_type_kind: u64 = decl->elem_type_kind;
    var elem_ptr_depth: u64 = decl->elem_ptr_depth;
    var array_len: u64 = decl->array_len;

    var size: u64 = 0;
    if (type_kind == TYPE_ARRAY) {
        var elem_size: u64 = sizeof_type(elem_type_kind, elem_ptr_depth, struct_name_ptr, struct_name_len);
        size = elem_size * array_len;
    } else if (type_kind == TYPE_SLICE) {
        size = 16;
    } else {
        size = sizeof_type(type_kind, ptr_depth, struct_name_ptr, struct_name_len);
    }

    symtab_add(ctx->symtab, name_ptr, name_len, type_kind, ptr_depth, size);

    var type_info: u64 = symtab_get_type(ctx->symtab, name_ptr, name_len);
    var ti: *TypeInfo = (*TypeInfo)type_info;
    ti->is_tagged = decl->is_tagged;
    ti->struct_name_ptr = struct_name_ptr;
    ti->struct_name_len = struct_name_len;
    ti->tag_layout_ptr = decl->tag_layout_ptr;
    ti->tag_layout_len = decl->tag_layout_len;
    ti->elem_type_kind = elem_type_kind;
    ti->elem_ptr_depth = elem_ptr_depth;
    ti->array_len = array_len;

    var g_structs_vec: u64 = typeinfo_get_structs();
    if (type_kind == TYPE_STRUCT && g_structs_vec != 0 && struct_name_ptr != 0) {
        var num_structs: u64 = vec_len(g_structs_vec);
        for (var si: u64 = 0; si < num_structs; si++) {
            var sd_ptr: u64 = vec_get(g_structs_vec, si);
            var sd: *AstStructDef = (*AstStructDef)sd_ptr;
            if (sd->name_len == struct_name_len && str_eq(sd->name_ptr, sd->name_len, struct_name_ptr, struct_name_len) != 0) {
                ti->struct_def = sd_ptr;
                break;
            }
        }
    }
    if (type_kind == TYPE_ARRAY || type_kind == TYPE_SLICE) {
        if (elem_type_kind == TYPE_STRUCT && g_structs_vec != 0 && struct_name_ptr != 0) {
            var num_structs2: u64 = vec_len(g_structs_vec);
            for (var sj: u64 = 0; sj < num_structs2; sj++) {
                var sd_ptr2: u64 = vec_get(g_structs_vec, sj);
                var sd2: *AstStructDef = (*AstStructDef)sd_ptr2;
                if (sd2->name_len == struct_name_len && str_eq(sd2->name_ptr, sd2->name_len, struct_name_ptr, struct_name_len) != 0) {
                    ti->struct_def = sd_ptr2;
                    break;
                }
            }
        }
    }

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
    push_trace("builder_add_params", "ssa_builder.b", __LINE__);
    pop_trace();
    if (fn == 0) { return 0; }
    var params: u64 = fn->params_vec;
    if (params == 0) { return 0; }

    var n: u64 = vec_len(params);
    var i: u64 = 0;
    var param_idx: u64 = 0;
    var arg_offset: u64 = 0;
    while (i < n) {
        var p: *Param = (*Param)vec_get(params, i);
        if (p->type_kind == TYPE_SLICE && p->ptr_depth == 0) {
            builder_symtab_add_param(ctx, p, 16 + arg_offset);
            arg_offset = arg_offset + 16;
            param_idx = param_idx + 2;
            i = i + 1;
            continue;
        }

        var var_id: u64 = builder_get_var_id(ctx, p->name_ptr, p->name_len);
        var reg_id: u64 = builder_new_reg(ctx);
        var inst_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_PARAM, reg_id, ssa_operand_const(param_idx), 0);
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr);
        var st_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_STORE, 0, ssa_operand_const(var_id), ssa_operand_reg(reg_id));
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)st_ptr);

        builder_symtab_add_param(ctx, p, 16 + arg_offset);
        arg_offset = arg_offset + 8;
        param_idx = param_idx + 1;
        i = i + 1;
    }
    return 0;
}

// ============================================
// Address/Memory Helpers
// ============================================

func builder_new_lea_local(ctx: *BuilderCtx, offset: u64) -> u64 {
    var reg_id: u64 = builder_new_reg(ctx);
    var inst_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_LEA_LOCAL, reg_id, ssa_operand_const(offset), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr);
    return reg_id;
}

func builder_new_lea_global(ctx: *BuilderCtx, name_ptr: u64, name_len: u64) -> u64 {
    var info: u64 = heap_alloc(16);
    *(info) = name_ptr;
    *(info + 8) = name_len;
    var reg_id: u64 = builder_new_reg(ctx);
    var inst_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_LEA_GLOBAL, reg_id, ssa_operand_const(info), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr);
    return reg_id;
}

func builder_new_lea_func(ctx: *BuilderCtx, name_ptr: u64, name_len: u64) -> u64 {
    var info: u64 = heap_alloc(16);
    *(info) = name_ptr;
    *(info + 8) = name_len;
    var reg_id: u64 = builder_new_reg(ctx);
    var inst_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_LEA_FUNC, reg_id, ssa_operand_const(info), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr);
    return reg_id;
}

func builder_load_by_size(ctx: *BuilderCtx, addr_reg: u64, size: u64) -> u64 {
    var reg_id: u64 = builder_new_reg(ctx);
    var op: u64 = SSA_OP_LOAD64;
    if (size == 1) { op = SSA_OP_LOAD8; }
    else if (size == 2) { op = SSA_OP_LOAD16; }
    else if (size == 4) { op = SSA_OP_LOAD32; }
    var inst_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, op, reg_id, ssa_operand_reg(addr_reg), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr);
    return reg_id;
}

func builder_store_by_size(ctx: *BuilderCtx, addr_reg: u64, val_reg: u64, size: u64) -> u64 {
    var op: u64 = SSA_OP_STORE64;
    if (size == 1) { op = SSA_OP_STORE8; }
    else if (size == 2) { op = SSA_OP_STORE16; }
    else if (size == 4) { op = SSA_OP_STORE32; }
    var inst_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, op, 0, ssa_operand_reg(addr_reg), ssa_operand_reg(val_reg));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr);
    return 0;
}

func builder_append_slice_arg(ctx: *BuilderCtx, arg_regs: u64, arg: u64) -> u64 {
    var k: u64 = ast_kind(arg);
    if (k == AST_SLICE) {
        var s: *AstSlice = (*AstSlice)arg;
        var ptr_reg: u64 = build_expr(ctx, s->ptr_expr);
        var len_reg: u64 = build_expr(ctx, s->len_expr);
        vec_push(arg_regs, len_reg);
        vec_push(arg_regs, ptr_reg);
        return 0;
    }

    var addr_reg: u64 = builder_lvalue_addr(ctx, arg);
    if (addr_reg == 0) { return 0; }
    var ptr_reg2: u64 = builder_load_by_size(ctx, addr_reg, 8);
    var off_reg: u64 = build_const(ctx, 8);
    var addr2: u64 = builder_new_reg(ctx);
    var add_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, addr2, ssa_operand_reg(addr_reg), ssa_operand_reg(off_reg));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr);
    var len_reg2: u64 = builder_load_by_size(ctx, addr2, 8);
    vec_push(arg_regs, len_reg2);
    vec_push(arg_regs, ptr_reg2);
    return 0;
}

func builder_append_call_arg(ctx: *BuilderCtx, arg_regs: u64, arg: u64) -> u64 {
    var ti_ptr: u64 = get_expr_type_with_symtab(arg, ctx->symtab);
    if (ti_ptr != 0) {
        var ti: *TypeInfo = (*TypeInfo)ti_ptr;
        if (ti->type_kind == TYPE_SLICE && ti->ptr_depth == 0) {
            return builder_append_slice_arg(ctx, arg_regs, arg);
        }
        if (ti->type_kind == TYPE_ARRAY && ti->ptr_depth == 0) {
            var addr_reg: u64 = builder_lvalue_addr(ctx, arg);
            vec_push(arg_regs, addr_reg);
            return 0;
        }
    }
    var reg: u64 = build_expr(ctx, arg);
    vec_push(arg_regs, reg);
    return 0;
}

func builder_slice_regs(ctx: *BuilderCtx, expr: u64) -> u64 {
    var info: u64 = heap_alloc(16);
    var k: u64 = ast_kind(expr);
    if (k == AST_SLICE) {
        var s: *AstSlice = (*AstSlice)expr;
        var ptr_reg: u64 = build_expr(ctx, s->ptr_expr);
        var len_reg: u64 = build_expr(ctx, s->len_expr);
        *(info) = ptr_reg;
        *(info + 8) = len_reg;
        return info;
    }

    var addr_reg: u64 = builder_lvalue_addr(ctx, expr);
    var ptr_reg2: u64 = builder_load_by_size(ctx, addr_reg, 8);
    var off_reg: u64 = build_const(ctx, 8);
    var addr2: u64 = builder_new_reg(ctx);
    var add_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, addr2, ssa_operand_reg(addr_reg), ssa_operand_reg(off_reg));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr);
    var len_reg2: u64 = builder_load_by_size(ctx, addr2, 8);
    *(info) = ptr_reg2;
    *(info + 8) = len_reg2;
    return info;
}

func builder_struct_literal_init(ctx: *BuilderCtx, struct_def: u64, values: u64, base_addr: u64) -> u64 {
    if (values == 0) { return 0; }
    if (struct_def == 0) {
        var num_values_raw: u64 = vec_len(values);
        var field_offset_raw: u64 = 0;
        for (var ri: u64 = 0; ri < num_values_raw; ri++) {
            var addr_reg_raw: u64 = base_addr;
            if (field_offset_raw != 0) {
                var off_reg_raw: u64 = build_const(ctx, field_offset_raw);
                var addr_tmp: u64 = builder_new_reg(ctx);
                var add_ptr_raw: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, addr_tmp, ssa_operand_reg(base_addr), ssa_operand_reg(off_reg_raw));
                ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr_raw);
                addr_reg_raw = addr_tmp;
            }
            var value_raw: u64 = vec_get(values, ri);
            var val_reg_raw: u64 = build_expr(ctx, value_raw);
            builder_store_by_size(ctx, addr_reg_raw, val_reg_raw, 8);
            field_offset_raw = field_offset_raw + 8;
        }
        return 0;
    }
    var sd: *AstStructDef = (*AstStructDef)struct_def;
    var fields: u64 = sd->fields_vec;
    if (fields == 0) { return 0; }

    var num_values: u64 = vec_len(values);
    var num_fields: u64 = vec_len(fields);
    var field_offset: u64 = 0;

    for (var i: u64 = 0; i < num_values; i++) {
        if (i >= num_fields) { break; }
        var field: *FieldDesc = (*FieldDesc)vec_get(fields, i);
        var field_size: u64 = sizeof_field_desc(field);

        var addr_reg: u64 = base_addr;
        if (field_offset != 0) {
            var off_reg: u64 = build_const(ctx, field_offset);
            var addr2: u64 = builder_new_reg(ctx);
            var add_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, addr2, ssa_operand_reg(base_addr), ssa_operand_reg(off_reg));
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr);
            addr_reg = addr2;
        }

        var value: u64 = vec_get(values, i);
        if (ast_kind(value) == AST_STRUCT_LITERAL) {
            var lit: *AstStructLiteral = (*AstStructLiteral)value;
            var lit_def: u64 = lit->struct_def;
            if (lit_def == 0 && field->type_kind == TYPE_STRUCT) {
                lit_def = get_struct_def(field->struct_name_ptr, field->struct_name_len);
            }
            builder_struct_literal_init(ctx, lit_def, lit->values_vec, addr_reg);
        } else if (field->type_kind == TYPE_SLICE && field->ptr_depth == 0) {
            var slice_info: u64 = builder_slice_regs(ctx, value);
            var ptr_reg: u64 = *(slice_info);
            var len_reg: u64 = *(slice_info + 8);
            builder_store_by_size(ctx, addr_reg, ptr_reg, 8);
            var off8: u64 = build_const(ctx, 8);
            var addr3: u64 = builder_new_reg(ctx);
            var add_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, addr3, ssa_operand_reg(addr_reg), ssa_operand_reg(off8));
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr2);
            builder_store_by_size(ctx, addr3, len_reg, 8);
        } else {
            var val_reg: u64 = build_expr(ctx, value);
            var store_size: u64 = field_size;
            if (store_size > 8) { store_size = 8; }
            builder_store_by_size(ctx, addr_reg, val_reg, store_size);
        }

        field_offset = field_offset + field_size;
    }

    return 0;
}

func builder_store_slice_regs(ctx: *BuilderCtx, base_addr: u64, slice_info: u64) -> u64 {
    if (base_addr == 0 || slice_info == 0) { return 0; }
    var ptr_reg: u64 = *(slice_info);
    var len_reg: u64 = *(slice_info + 8);
    builder_store_by_size(ctx, base_addr, ptr_reg, 8);
    var off_reg: u64 = build_const(ctx, 8);
    var addr2: u64 = builder_new_reg(ctx);
    var add_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, addr2, ssa_operand_reg(base_addr), ssa_operand_reg(off_reg));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr);
    builder_store_by_size(ctx, addr2, len_reg, 8);
    return 0;
}

func builder_build_method_name(struct_ptr: u64, struct_len: u64, method_ptr: u64, method_len: u64) -> u64 {
    var full_len: u64 = struct_len + 1 + method_len;
    var full_ptr: u64 = heap_alloc(full_len);
    var i: u64 = 0;
    while (i < struct_len) {
        *(*u8)(full_ptr + i) = *(*u8)(struct_ptr + i);
        i = i + 1;
    }
    *(*u8)(full_ptr + struct_len) = 95;
    var j: u64 = 0;
    while (j < method_len) {
        *(*u8)(full_ptr + struct_len + 1 + j) = *(*u8)(method_ptr + j);
        j = j + 1;
    }
    return full_ptr;
}

func builder_emit_call(ctx: *BuilderCtx, call: *AstCall, dst: u64) -> u64 {
    var name_ptr: u64 = call->name_ptr;
    var name_len: u64 = call->name_len;
    if (compiler_func_exists(name_ptr, name_len) == 0) {
        var callee: u64 = ast_ident(name_ptr, name_len);
        var cp: u64 = ast_call_ptr(callee, call->args_vec);
        return builder_emit_call_ptr(ctx, (*AstCallPtr)cp, dst);
    }
    var resolved_ptr: u64 = name_ptr;
    var resolved_len: u64 = name_len;
    var resolved: u64 = resolve_name(name_ptr, name_len);
    if (resolved != 0) {
        resolved_ptr = *(resolved);
        resolved_len = *(resolved + 8);
    }

    var args: u64 = call->args_vec;
    var nargs: u64 = 0;
    if (args != 0) { nargs = vec_len(args); }
    var arg_regs: u64 = vec_new(nargs * 2);
    var i: u64 = nargs;
    while (i > 0) {
        i = i - 1;
        var arg: u64 = vec_get(args, i);
        builder_append_call_arg(ctx, arg_regs, arg);
    }
    var total_regs: u64 = vec_len(arg_regs);

    var ret_type: u64 = TYPE_I64;
    var ret_ptr_depth: u64 = 0;
    var ret_ti_ptr: u64 = get_expr_type_with_symtab((u64)call, ctx->symtab);
    if (ret_ti_ptr != 0) {
        var ret_ti: *TypeInfo = (*TypeInfo)ret_ti_ptr;
        ret_type = ret_ti->type_kind;
        ret_ptr_depth = ret_ti->ptr_depth;
    }

    var info: u64 = heap_alloc(48);
    *(info) = resolved_ptr;
    *(info + 8) = resolved_len;
    *(info + 16) = arg_regs;
    *(info + 24) = total_regs;
    *(info + 32) = ret_type;
    *(info + 40) = ret_ptr_depth;

    var call_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_CALL, dst, ssa_operand_const(info), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)call_ptr);
    return dst;
}

func builder_emit_call_slice_store(ctx: *BuilderCtx, call: *AstCall, addr_reg: u64) -> u64 {
    var name_ptr: u64 = call->name_ptr;
    var name_len: u64 = call->name_len;
    if (compiler_func_exists(name_ptr, name_len) == 0) {
        var callee: u64 = ast_ident(name_ptr, name_len);
        var cp: u64 = ast_call_ptr(callee, call->args_vec);
        return builder_emit_call_ptr_slice_store(ctx, (*AstCallPtr)cp, addr_reg);
    }
    var resolved_ptr: u64 = name_ptr;
    var resolved_len: u64 = name_len;
    var resolved: u64 = resolve_name(name_ptr, name_len);
    if (resolved != 0) {
        resolved_ptr = *(resolved);
        resolved_len = *(resolved + 8);
    }

    var args: u64 = call->args_vec;
    var nargs: u64 = 0;
    if (args != 0) { nargs = vec_len(args); }
    var arg_regs: u64 = vec_new(nargs * 2);
    var i: u64 = nargs;
    while (i > 0) {
        i = i - 1;
        var arg: u64 = vec_get(args, i);
        builder_append_call_arg(ctx, arg_regs, arg);
    }
    var total_regs: u64 = vec_len(arg_regs);

    var ret_type: u64 = TYPE_I64;
    var ret_ptr_depth: u64 = 0;
    var ret_ti_ptr: u64 = get_expr_type_with_symtab((u64)call, ctx->symtab);
    if (ret_ti_ptr != 0) {
        var ret_ti: *TypeInfo = (*TypeInfo)ret_ti_ptr;
        ret_type = ret_ti->type_kind;
        ret_ptr_depth = ret_ti->ptr_depth;
    }

    var info: u64 = heap_alloc(48);
    *(info) = resolved_ptr;
    *(info + 8) = resolved_len;
    *(info + 16) = arg_regs;
    *(info + 24) = total_regs;
    *(info + 32) = ret_type;
    *(info + 40) = ret_ptr_depth;

    var call_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_CALL_SLICE_STORE, 0, ssa_operand_const(info), ssa_operand_reg(addr_reg));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)call_ptr);
    return 0;
}

func builder_emit_method_call(ctx: *BuilderCtx, mc: *AstMethodCall, dst: u64) -> u64 {
    var receiver: u64 = mc->receiver;
    var recv_type_ptr: u64 = get_expr_type_with_symtab(receiver, ctx->symtab);
    if (recv_type_ptr == 0) { return 0; }
    var recv_ti: *TypeInfo = (*TypeInfo)recv_type_ptr;
    if (recv_ti->type_kind != TYPE_STRUCT) { return 0; }
    var struct_ptr: u64 = recv_ti->struct_name_ptr;
    var struct_len: u64 = recv_ti->struct_name_len;

    var full_ptr: u64 = builder_build_method_name(struct_ptr, struct_len, mc->method_ptr, mc->method_len);
    var full_len: u64 = struct_len + 1 + mc->method_len;
    var resolved_ptr: u64 = full_ptr;
    var resolved_len: u64 = full_len;
    var resolved: u64 = resolve_name(full_ptr, full_len);
    if (resolved != 0) {
        resolved_ptr = *(resolved);
        resolved_len = *(resolved + 8);
    }

    var args: u64 = mc->args_vec;
    var nargs: u64 = 0;
    if (args != 0) { nargs = vec_len(args); }
    var arg_regs: u64 = vec_new(nargs * 2 + 1);
    var i: u64 = nargs;
    while (i > 0) {
        i = i - 1;
        var arg: u64 = vec_get(args, i);
        builder_append_call_arg(ctx, arg_regs, arg);
    }
    var recv_addr: u64 = builder_lvalue_addr(ctx, receiver);
    vec_push(arg_regs, recv_addr);
    var total_regs: u64 = vec_len(arg_regs);

    var ret_type: u64 = TYPE_I64;
    var ret_ptr_depth: u64 = 0;
    var ret_ti_ptr: u64 = get_expr_type_with_symtab((u64)mc, ctx->symtab);
    if (ret_ti_ptr != 0) {
        var ret_ti: *TypeInfo = (*TypeInfo)ret_ti_ptr;
        ret_type = ret_ti->type_kind;
        ret_ptr_depth = ret_ti->ptr_depth;
    }

    var info: u64 = heap_alloc(48);
    *(info) = resolved_ptr;
    *(info + 8) = resolved_len;
    *(info + 16) = arg_regs;
    *(info + 24) = total_regs;
    *(info + 32) = ret_type;
    *(info + 40) = ret_ptr_depth;

    var call_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_CALL, dst, ssa_operand_const(info), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)call_ptr2);
    return dst;
}

func builder_emit_method_call_slice_store(ctx: *BuilderCtx, mc: *AstMethodCall, addr_reg: u64) -> u64 {
    var receiver: u64 = mc->receiver;
    var recv_type_ptr: u64 = get_expr_type_with_symtab(receiver, ctx->symtab);
    if (recv_type_ptr == 0) { return 0; }
    var recv_ti: *TypeInfo = (*TypeInfo)recv_type_ptr;
    if (recv_ti->type_kind != TYPE_STRUCT) { return 0; }
    var struct_ptr: u64 = recv_ti->struct_name_ptr;
    var struct_len: u64 = recv_ti->struct_name_len;

    var full_ptr: u64 = builder_build_method_name(struct_ptr, struct_len, mc->method_ptr, mc->method_len);
    var full_len: u64 = struct_len + 1 + mc->method_len;
    var resolved_ptr: u64 = full_ptr;
    var resolved_len: u64 = full_len;
    var resolved: u64 = resolve_name(full_ptr, full_len);
    if (resolved != 0) {
        resolved_ptr = *(resolved);
        resolved_len = *(resolved + 8);
    }

    var args: u64 = mc->args_vec;
    var nargs: u64 = 0;
    if (args != 0) { nargs = vec_len(args); }
    var arg_regs: u64 = vec_new(nargs * 2 + 1);
    var i: u64 = nargs;
    while (i > 0) {
        i = i - 1;
        var arg: u64 = vec_get(args, i);
        builder_append_call_arg(ctx, arg_regs, arg);
    }
    var recv_addr: u64 = builder_lvalue_addr(ctx, receiver);
    vec_push(arg_regs, recv_addr);
    var total_regs: u64 = vec_len(arg_regs);

    var ret_type: u64 = TYPE_I64;
    var ret_ptr_depth: u64 = 0;
    var ret_ti_ptr: u64 = get_expr_type_with_symtab((u64)mc, ctx->symtab);
    if (ret_ti_ptr != 0) {
        var ret_ti: *TypeInfo = (*TypeInfo)ret_ti_ptr;
        ret_type = ret_ti->type_kind;
        ret_ptr_depth = ret_ti->ptr_depth;
    }

    var info: u64 = heap_alloc(48);
    *(info) = resolved_ptr;
    *(info + 8) = resolved_len;
    *(info + 16) = arg_regs;
    *(info + 24) = total_regs;
    *(info + 32) = ret_type;
    *(info + 40) = ret_ptr_depth;

    var call_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_CALL_SLICE_STORE, 0, ssa_operand_const(info), ssa_operand_reg(addr_reg));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)call_ptr2);
    return 0;
}

func builder_emit_call_ptr(ctx: *BuilderCtx, cp: *AstCallPtr, dst: u64) -> u64 {
    var args: u64 = cp->args_vec;
    var nargs: u64 = 0;
    if (args != 0) { nargs = vec_len(args); }
    var arg_regs: u64 = vec_new(nargs * 2);
    var i: u64 = nargs;
    while (i > 0) {
        i = i - 1;
        var arg: u64 = vec_get(args, i);
        builder_append_call_arg(ctx, arg_regs, arg);
    }
    var total_regs: u64 = vec_len(arg_regs);

    var callee: u64 = cp->callee;
    var callee_reg: u64 = 0;
    if (ast_kind(callee) == AST_IDENT) {
        var idn: *AstIdent = (*AstIdent)callee;
        if (compiler_func_exists(idn->name_ptr, idn->name_len) != 0) {
            var resolved_ptr: u64 = idn->name_ptr;
            var resolved_len: u64 = idn->name_len;
            var resolved: u64 = resolve_name(idn->name_ptr, idn->name_len);
            if (resolved != 0) {
                resolved_ptr = *(resolved);
                resolved_len = *(resolved + 8);
            }
            callee_reg = builder_new_lea_func(ctx, resolved_ptr, resolved_len);
        } else {
            callee_reg = build_expr(ctx, callee);
        }
    } else {
        callee_reg = build_expr(ctx, callee);
    }

    var ret_type: u64 = TYPE_I64;
    var ret_ptr_depth: u64 = 0;
    var ret_ti_ptr: u64 = get_expr_type_with_symtab((u64)cp, ctx->symtab);
    if (ret_ti_ptr != 0) {
        var ret_ti: *TypeInfo = (*TypeInfo)ret_ti_ptr;
        ret_type = ret_ti->type_kind;
        ret_ptr_depth = ret_ti->ptr_depth;
    }

    var info: u64 = heap_alloc(40);
    *(info) = callee_reg;
    *(info + 8) = arg_regs;
    *(info + 16) = total_regs;
    *(info + 24) = ret_type;
    *(info + 32) = ret_ptr_depth;

    var call_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_CALL_PTR, dst, ssa_operand_const(info), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)call_ptr);
    return dst;
}

func builder_emit_call_ptr_slice_store(ctx: *BuilderCtx, cp: *AstCallPtr, addr_reg: u64) -> u64 {
    var args: u64 = cp->args_vec;
    var nargs: u64 = 0;
    if (args != 0) { nargs = vec_len(args); }
    var arg_regs: u64 = vec_new(nargs * 2);
    var i: u64 = nargs;
    while (i > 0) {
        i = i - 1;
        var arg: u64 = vec_get(args, i);
        builder_append_call_arg(ctx, arg_regs, arg);
    }
    var total_regs: u64 = vec_len(arg_regs);

    var callee: u64 = cp->callee;
    var callee_reg: u64 = 0;
    if (ast_kind(callee) == AST_IDENT) {
        var idn: *AstIdent = (*AstIdent)callee;
        if (compiler_func_exists(idn->name_ptr, idn->name_len) != 0) {
            var resolved_ptr: u64 = idn->name_ptr;
            var resolved_len: u64 = idn->name_len;
            var resolved: u64 = resolve_name(idn->name_ptr, idn->name_len);
            if (resolved != 0) {
                resolved_ptr = *(resolved);
                resolved_len = *(resolved + 8);
            }
            callee_reg = builder_new_lea_func(ctx, resolved_ptr, resolved_len);
        } else {
            callee_reg = build_expr(ctx, callee);
        }
    } else {
        callee_reg = build_expr(ctx, callee);
    }

    var ret_type: u64 = TYPE_I64;
    var ret_ptr_depth: u64 = 0;
    var ret_ti_ptr: u64 = get_expr_type_with_symtab((u64)cp, ctx->symtab);
    if (ret_ti_ptr != 0) {
        var ret_ti: *TypeInfo = (*TypeInfo)ret_ti_ptr;
        ret_type = ret_ti->type_kind;
        ret_ptr_depth = ret_ti->ptr_depth;
    }

    var info: u64 = heap_alloc(40);
    *(info) = callee_reg;
    *(info + 8) = arg_regs;
    *(info + 16) = total_regs;
    *(info + 24) = ret_type;
    *(info + 32) = ret_ptr_depth;

    var call_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_CALL_SLICE_STORE, 0, ssa_operand_const(info), ssa_operand_reg(addr_reg));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)call_ptr);
    return 0;
}

func builder_type_size_from_expr(ctx: *BuilderCtx, node: u64) -> u64 {
    var ti_ptr: u64 = get_expr_type_with_symtab(node, ctx->symtab);
    if (ti_ptr == 0) { return 8; }
    var ti: *TypeInfo = (*TypeInfo)ti_ptr;
    return sizeof_type(ti->type_kind, ti->ptr_depth, ti->struct_name_ptr, ti->struct_name_len);
}

func builder_lvalue_addr(ctx: *BuilderCtx, node: u64) -> u64 {
    var k: u64 = ast_kind(node);

    if (k == AST_IDENT) {
        var idn: *AstIdent = (*AstIdent)node;
        var offset: u64 = symtab_find(ctx->symtab, idn->name_ptr, idn->name_len);
        if (offset != 0) {
            return builder_new_lea_local(ctx, offset);
        }
        if (compiler_func_exists(idn->name_ptr, idn->name_len) != 0) {
            var resolved_ptr2: u64 = idn->name_ptr;
            var resolved_len2: u64 = idn->name_len;
            var resolved2: u64 = resolve_name(idn->name_ptr, idn->name_len);
            if (resolved2 != 0) {
                resolved_ptr2 = *(resolved2);
                resolved_len2 = *(resolved2 + 8);
            }
            return builder_new_lea_func(ctx, resolved_ptr2, resolved_len2);
        }
        var resolved_ptr: u64 = idn->name_ptr;
        var resolved_len: u64 = idn->name_len;
        var resolved: u64 = resolve_name(idn->name_ptr, idn->name_len);
        if (resolved != 0) {
            resolved_ptr = *(resolved);
            resolved_len = *(resolved + 8);
        }
        return builder_new_lea_global(ctx, resolved_ptr, resolved_len);
    }

    if (k == AST_MEMBER_ACCESS) {
        var m: *AstMemberAccess = (*AstMemberAccess)node;
        var obj: u64 = m->object;
        var ti_ptr: u64 = get_expr_type_with_symtab(obj, ctx->symtab);
        if (ti_ptr == 0) { return 0; }
        var ti: *TypeInfo = (*TypeInfo)ti_ptr;
        var base_addr: u64 = 0;
        if (ti->ptr_depth > 0) {
            base_addr = build_expr(ctx, obj);
        } else {
            base_addr = builder_lvalue_addr(ctx, obj);
        }
        var struct_def: u64 = ti->struct_def;
        if (struct_def == 0) { return base_addr; }
        var field_offset: u64 = get_field_offset(struct_def, m->member_ptr, m->member_len);
        if (field_offset == 0) { return base_addr; }
        var off_reg: u64 = build_const(ctx, field_offset);
        var out_reg: u64 = builder_new_reg(ctx);
        var add_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, out_reg, ssa_operand_reg(base_addr), ssa_operand_reg(off_reg));
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr);
        return out_reg;
    }

    if (k == AST_DEREF || k == AST_DEREF8) {
        var d: *AstDeref = (*AstDeref)node;
        return build_expr(ctx, d->operand);
    }

    if (k == AST_INDEX) {
        var idx: *AstIndex = (*AstIndex)node;
        var base: u64 = idx->base;
        var base_type_ptr: u64 = get_expr_type_with_symtab(base, ctx->symtab);
        if (base_type_ptr == 0) { return 0; }
        var bt: *TypeInfo = (*TypeInfo)base_type_ptr;
        var elem_size: u64 = get_pointee_size(bt->type_kind, bt->ptr_depth);
        if (bt->ptr_depth == 1 && bt->type_kind == TYPE_STRUCT) {
            elem_size = sizeof_type(bt->type_kind, 0, bt->struct_name_ptr, bt->struct_name_len);
        }
        if (bt->type_kind == TYPE_ARRAY && bt->ptr_depth == 0) {
            elem_size = sizeof_type(bt->elem_type_kind, bt->elem_ptr_depth, bt->struct_name_ptr, bt->struct_name_len);
            var base_addr: u64 = builder_lvalue_addr(ctx, base);
            var idx_reg: u64 = build_expr(ctx, idx->index);
            if (elem_size > 1) {
                var size_reg: u64 = build_const(ctx, elem_size);
                var mul_reg: u64 = builder_new_reg(ctx);
                var mul_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_MUL, mul_reg, ssa_operand_reg(idx_reg), ssa_operand_reg(size_reg));
                ssa_inst_append(ctx->cur_block, (*SSAInstruction)mul_ptr);
                idx_reg = mul_reg;
            }
            var out_reg2: u64 = builder_new_reg(ctx);
            var add_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, out_reg2, ssa_operand_reg(base_addr), ssa_operand_reg(idx_reg));
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr2);
            return out_reg2;
        }

        var base_ptr: u64 = build_expr(ctx, base);
        if (bt->type_kind == TYPE_SLICE && bt->ptr_depth == 0) {
            var addr_reg: u64 = builder_lvalue_addr(ctx, base);
            base_ptr = builder_load_by_size(ctx, addr_reg, 8);
            elem_size = sizeof_type(bt->elem_type_kind, bt->elem_ptr_depth, bt->struct_name_ptr, bt->struct_name_len);
        }

        var idx_reg2: u64 = build_expr(ctx, idx->index);
        if (elem_size > 1) {
            var size_reg2: u64 = build_const(ctx, elem_size);
            var mul_reg2: u64 = builder_new_reg(ctx);
            var mul_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_MUL, mul_reg2, ssa_operand_reg(idx_reg2), ssa_operand_reg(size_reg2));
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)mul_ptr2);
            idx_reg2 = mul_reg2;
        }
        var out_reg3: u64 = builder_new_reg(ctx);
        var add_ptr3: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, out_reg3, ssa_operand_reg(base_ptr), ssa_operand_reg(idx_reg2));
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr3);
        return out_reg3;
    }

    if (k == AST_DEREF || k == AST_DEREF8) {
        var un: *AstDeref = (*AstDeref)node;
        return build_expr(ctx, un->operand);
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
    push_trace("build_expr", "ssa_builder.b", __LINE__);
    pop_trace();
    if (node == 0) { return 0; }
    var kind: u64 = ast_kind(node);

    if (kind == AST_LITERAL) {
        var lit: *AstLiteral = (*AstLiteral)node;
        return build_const(ctx, lit->value);
    }

    if (kind == AST_STRING) {
        var s: *AstString = (*AstString)node;
        var info: u64 = heap_alloc(16);
        *(info) = s->str_ptr;
        *(info + 8) = s->str_len;
        var reg_id: u64 = builder_new_reg(ctx);
        var inst_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_LEA_STR, reg_id, ssa_operand_const(info), 0);
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr);
        return reg_id;
    }

    if (kind == AST_IDENT) {
        var idn: *AstIdent = (*AstIdent)node;
        var offset: u64 = symtab_find(ctx->symtab, idn->name_ptr, idn->name_len);
        if (offset != 0) {
            var var_id: u64 = builder_get_var_id(ctx, idn->name_ptr, idn->name_len);
            var reg_id: u64 = builder_new_reg(ctx);
            var inst_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_LOAD, reg_id, ssa_operand_const(var_id), 0);
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr);
            return reg_id;
        }
        var addr_reg: u64 = builder_lvalue_addr(ctx, node);
        var size: u64 = builder_type_size_from_expr(ctx, node);
        return builder_load_by_size(ctx, addr_reg, size);
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

    if (kind == AST_ADDR_OF) {
        var a: *AstAddrOf = (*AstAddrOf)node;
        return builder_lvalue_addr(ctx, a->operand);
    }

    if (kind == AST_DEREF8) {
        var d8: *AstDeref8 = (*AstDeref8)node;
        var addr_reg: u64 = build_expr(ctx, d8->operand);
        return builder_load_by_size(ctx, addr_reg, 1);
    }

    if (kind == AST_DEREF) {
        var d: *AstDeref = (*AstDeref)node;
        var addr_reg2: u64 = build_expr(ctx, d->operand);
        var size2: u64 = builder_type_size_from_expr(ctx, node);
        return builder_load_by_size(ctx, addr_reg2, size2);
    }

    if (kind == AST_INDEX) {
        var addr_reg3: u64 = builder_lvalue_addr(ctx, node);
        var size3: u64 = builder_type_size_from_expr(ctx, node);
        return builder_load_by_size(ctx, addr_reg3, size3);
    }

    if (kind == AST_MEMBER_ACCESS) {
        var addr_reg4: u64 = builder_lvalue_addr(ctx, node);
        var size4: u64 = builder_type_size_from_expr(ctx, node);
        return builder_load_by_size(ctx, addr_reg4, size4);
    }

    if (kind == AST_CAST) {
        var cast: *AstCast = (*AstCast)node;
        return build_expr(ctx, cast->expr);
    }

    if (kind == AST_SIZEOF) {
        var sz: *AstSizeof = (*AstSizeof)node;
        var size_val: u64 = sizeof_type(sz->type_kind, sz->ptr_depth, sz->struct_name_ptr, sz->struct_name_len);
        return build_const(ctx, size_val);
    }

    if (kind == AST_CALL) {
        var call: *AstCall = (*AstCall)node;
        var dst: u64 = builder_new_reg(ctx);
        var ret_ti_ptr: u64 = get_expr_type_with_symtab(node, ctx->symtab);
        if (ret_ti_ptr != 0) {
            var ret_ti: *TypeInfo = (*TypeInfo)ret_ti_ptr;
            if (ret_ti->type_kind == TYPE_VOID && ret_ti->ptr_depth == 0) {
                dst = 0;
            }
        }
        return builder_emit_call(ctx, call, dst);
    }

    if (kind == AST_CALL_PTR) {
        var cp: *AstCallPtr = (*AstCallPtr)node;
        var dst2: u64 = builder_new_reg(ctx);
        var ret_ti_ptr2: u64 = get_expr_type_with_symtab(node, ctx->symtab);
        if (ret_ti_ptr2 != 0) {
            var ret_ti2: *TypeInfo = (*TypeInfo)ret_ti_ptr2;
            if (ret_ti2->type_kind == TYPE_VOID && ret_ti2->ptr_depth == 0) {
                dst2 = 0;
            }
        }
        return builder_emit_call_ptr(ctx, cp, dst2);
    }

    if (kind == AST_METHOD_CALL) {
        var mc: *AstMethodCall = (*AstMethodCall)node;
        var dst: u64 = builder_new_reg(ctx);
        var ret_ti_ptr2: u64 = get_expr_type_with_symtab(node, ctx->symtab);
        if (ret_ti_ptr2 != 0) {
            var ret_ti2: *TypeInfo = (*TypeInfo)ret_ti_ptr2;
            if (ret_ti2->type_kind == TYPE_VOID && ret_ti2->ptr_depth == 0) {
                dst = 0;
            }
        }
        return builder_emit_method_call(ctx, mc, dst);
    }

    return build_const(ctx, 0);
}

// ============================================
// CFG Builders
// ============================================

func build_block(ctx: *BuilderCtx, block_node: u64) -> u64 {
    push_trace("build_block", "ssa_builder.b", __LINE__);
    pop_trace();
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
    push_trace("build_for", "ssa_builder.b", __LINE__);
    pop_trace();
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
    push_trace("build_switch", "ssa_builder.b", __LINE__);
    pop_trace();
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
    push_trace("build_if", "ssa_builder.b", __LINE__);
    pop_trace();
    var ifn: *AstIf = (*AstIf)node;
    var has_else: u64 = 0;
    if (ifn->else_block != 0) { has_else = 1; }

    if (SSA_BUILDER_DEBUG != 0) {
        println("[DEBUG] build_if: cond", 25);
    }

    var cond_reg: u64 = build_expr(ctx, ifn->cond);

    if (SSA_BUILDER_DEBUG != 0) {
        println("[DEBUG] build_if: blocks", 27);
    }

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
    if (SSA_BUILDER_DEBUG != 0) {
        println("[DEBUG] build_if: then", 25);
    }
    build_block(ctx, ifn->then_block);
    var jmp_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_JMP, 0, ssa_operand_const(merge_bb->id), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)jmp_ptr);
    ssa_add_edge(ctx->cur_block, merge_bb);

    if (has_else == 1) {
        builder_set_block(ctx, else_bb);
        if (SSA_BUILDER_DEBUG != 0) {
            println("[DEBUG] build_if: else", 25);
        }
        build_block(ctx, ifn->else_block);
        var jmp_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_JMP, 0, ssa_operand_const(merge_bb->id), 0);
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)jmp_ptr2);
        ssa_add_edge(ctx->cur_block, merge_bb);
    }

    builder_set_block(ctx, merge_bb);
    return 0;
}

func build_while(ctx: *BuilderCtx, node: u64) -> u64 {
    push_trace("build_while", "ssa_builder.b", __LINE__);
    pop_trace();
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
    push_trace("build_stmt", "ssa_builder.b", __LINE__);
    pop_trace();
    var kind: u64 = ast_kind(node);
    if (SSA_BUILDER_DEBUG != 0) {
        emit("[DEBUG] build_stmt kind=", 27);
        print_u64(kind);
        emit("\n", 1);
    }

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

    if (kind == AST_ASM) {
        var a: *AstAsm = (*AstAsm)node;
        var inst_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ASM, 0, ssa_operand_const(a->text_vec), 0);
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr);
        return 0;
    }

    if (kind == AST_BREAK) {
        var break_bb: u64 = builder_top_break(ctx);
        if (break_bb != 0) {
            var br_bb: *SSABlock = (*SSABlock)break_bb;
            var jmp_ptrb: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_JMP, 0, ssa_operand_const(br_bb->id), 0);
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)jmp_ptrb);
            ssa_add_edge(ctx->cur_block, br_bb);
        }
        var dead_bb: *SSABlock = (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func);
        builder_set_block(ctx, dead_bb);
        return 0;
    }

    if (kind == AST_CONTINUE) {
        var cont_bb: u64 = builder_top_continue(ctx);
        if (cont_bb != 0) {
            var ct_bb: *SSABlock = (*SSABlock)cont_bb;
            var jmp_ptrc: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_JMP, 0, ssa_operand_const(ct_bb->id), 0);
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)jmp_ptrc);
            ssa_add_edge(ctx->cur_block, ct_bb);
        }
        var dead_bb2: *SSABlock = (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func);
        builder_set_block(ctx, dead_bb2);
        return 0;
    }

    if (kind == AST_EXPR_STMT) {
        var es: *AstExprStmt = (*AstExprStmt)node;
        var expr_kind: u64 = ast_kind(es->expr);
        if (expr_kind == AST_CALL) {
            builder_emit_call(ctx, (*AstCall)es->expr, 0);
            return 0;
        }
        if (expr_kind == AST_METHOD_CALL) {
            builder_emit_method_call(ctx, (*AstMethodCall)es->expr, 0);
            return 0;
        }
        if (expr_kind == AST_CALL_PTR) {
            builder_emit_call_ptr(ctx, (*AstCallPtr)es->expr, 0);
            return 0;
        }
        build_expr(ctx, es->expr);
        return 0;
    }

    if (kind == AST_VAR_DECL) {
        var vd: *AstVarDecl = (*AstVarDecl)node;
        var var_id: u64 = builder_get_var_id(ctx, vd->name_ptr, vd->name_len);
        builder_symtab_add_local(ctx, vd);
        if (vd->init_expr != 0) {
            var init_kind: u64 = ast_kind(vd->init_expr);
            if (vd->type_kind == TYPE_SLICE && vd->ptr_depth == 0) {
                var offset_slice: u64 = symtab_find(ctx->symtab, vd->name_ptr, vd->name_len);
                var base_addr: u64 = builder_new_lea_local(ctx, offset_slice);
                var init_kind2: u64 = ast_kind(vd->init_expr);
                if (init_kind2 == AST_CALL) {
                    builder_emit_call_slice_store(ctx, (*AstCall)vd->init_expr, base_addr);
                    return 0;
                }
                if (init_kind2 == AST_METHOD_CALL) {
                    builder_emit_method_call_slice_store(ctx, (*AstMethodCall)vd->init_expr, base_addr);
                    return 0;
                }
                if (init_kind2 == AST_CALL_PTR) {
                    builder_emit_call_ptr_slice_store(ctx, (*AstCallPtr)vd->init_expr, base_addr);
                    return 0;
                }
                var slice_info: u64 = builder_slice_regs(ctx, vd->init_expr);
                builder_store_slice_regs(ctx, base_addr, slice_info);
                return 0;
            }
            if (init_kind == AST_STRUCT_LITERAL) {
                var offset: u64 = symtab_find(ctx->symtab, vd->name_ptr, vd->name_len);
                var base_addr: u64 = builder_new_lea_local(ctx, offset);
                var lit: *AstStructLiteral = (*AstStructLiteral)vd->init_expr;
                builder_struct_literal_init(ctx, lit->struct_def, lit->values_vec, base_addr);
                return 0;
            }
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
            var offset2: u64 = symtab_find(ctx->symtab, idn->name_ptr, idn->name_len);
            var value_kind: u64 = ast_kind(asn->value);
            if (value_kind == AST_STRUCT_LITERAL) {
                var base_addr2: u64 = 0;
                if (offset2 != 0) {
                    base_addr2 = builder_new_lea_local(ctx, offset2);
                } else {
                    base_addr2 = builder_lvalue_addr(ctx, asn->target);
                }
                var lit2: *AstStructLiteral = (*AstStructLiteral)asn->value;
                builder_struct_literal_init(ctx, lit2->struct_def, lit2->values_vec, base_addr2);
                return 0;
            }
            var tgt_type: u64 = symtab_get_type(ctx->symtab, idn->name_ptr, idn->name_len);
            if (tgt_type != 0) {
                var ti: *TypeInfo = (*TypeInfo)tgt_type;
                if (ti->type_kind == TYPE_SLICE && ti->ptr_depth == 0) {
                    var base_addr3: u64 = 0;
                    if (offset2 != 0) {
                        base_addr3 = builder_new_lea_local(ctx, offset2);
                    } else {
                        base_addr3 = builder_lvalue_addr(ctx, asn->target);
                    }
                    var value_kind2: u64 = ast_kind(asn->value);
                    if (value_kind2 == AST_CALL) {
                        builder_emit_call_slice_store(ctx, (*AstCall)asn->value, base_addr3);
                        return 0;
                    }
                    if (value_kind2 == AST_METHOD_CALL) {
                        builder_emit_method_call_slice_store(ctx, (*AstMethodCall)asn->value, base_addr3);
                        return 0;
                    }
                    if (value_kind2 == AST_CALL_PTR) {
                        builder_emit_call_ptr_slice_store(ctx, (*AstCallPtr)asn->value, base_addr3);
                        return 0;
                    }
                    var slice_info2: u64 = builder_slice_regs(ctx, asn->value);
                    builder_store_slice_regs(ctx, base_addr3, slice_info2);
                    return 0;
                }
            }
            var val_reg3: u64 = build_expr(ctx, asn->value);
            if (offset2 != 0) {
                var var_id3: u64 = builder_get_var_id(ctx, idn->name_ptr, idn->name_len);
                var st_ptr3: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_STORE, 0, ssa_operand_const(var_id3), ssa_operand_reg(val_reg3));
                ssa_inst_append(ctx->cur_block, (*SSAInstruction)st_ptr3);
                return 0;
            }
            var addr_reg2: u64 = builder_lvalue_addr(ctx, asn->target);
            var size4: u64 = builder_type_size_from_expr(ctx, asn->target);
            builder_store_by_size(ctx, addr_reg2, val_reg3, size4);
            return 0;
        }
        if (target_kind == AST_DEREF || target_kind == AST_DEREF8 || target_kind == AST_INDEX || target_kind == AST_MEMBER_ACCESS) {
            var addr_reg: u64 = builder_lvalue_addr(ctx, asn->target);
            var val_reg4: u64 = build_expr(ctx, asn->value);
            var size4: u64 = 8;
            if (target_kind == AST_DEREF8) {
                size4 = 1;
            } else {
                size4 = builder_type_size_from_expr(ctx, asn->target);
            }
            builder_store_by_size(ctx, addr_reg, val_reg4, size4);
        }
        return 0;
    }

    if (kind == AST_RETURN) {
        var ret: *AstReturn = (*AstReturn)node;
        var val_reg4: u64 = 0;
        if (ret->expr != 0) {
            var ret_ti_ptr: u64 = get_expr_type_with_symtab(ret->expr, ctx->symtab);
            if (ret_ti_ptr != 0) {
                var ret_ti: *TypeInfo = (*TypeInfo)ret_ti_ptr;
                if (ret_ti->type_kind == TYPE_SLICE && ret_ti->ptr_depth == 0) {
                    var slice_info: u64 = builder_slice_regs(ctx, ret->expr);
                    var ptr_reg: u64 = *(slice_info);
                    var len_reg: u64 = *(slice_info + 8);
                    var ret_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_RET, 0, ssa_operand_reg(ptr_reg), ssa_operand_reg(len_reg));
                    ssa_inst_append(ctx->cur_block, (*SSAInstruction)ret_ptr2);
                    return 0;
                }
            }
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

