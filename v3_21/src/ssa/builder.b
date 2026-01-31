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
import emitter.emitter;
import compiler;
import ssa.codegen;

const SSA_BUILDER_DEBUG = 0;
const TAGGED_PTR_MASK = 281474976710655;

// Simple pointer+length pair for name lookups and metadata.
struct PtrLen {
    ptr: u64;
    len: u64;
}

// Slice register bundle (ptr,len) used in SSA builder.
struct SliceRegs {
    ptr_reg: u64;
    len_reg: u64;
}

func builder_make_bitmask(bit_width: u64) -> u64 {
    if (bit_width >= 64) { return 0; }
    var one: u64 = 1;
    var mask: u64 = one << bit_width;
    return mask - 1;
}

func builder_mask_low_bits(ctx: *BuilderCtx, value_reg: u64, bit_width: u64) -> u64 {
    if (bit_width >= 64) { return value_reg; }
    var mask_val: u64 = builder_make_bitmask(bit_width);
    var mask_reg: u64 = build_const(ctx, mask_val);
    var out_reg: u64 = builder_new_reg(ctx);
    var and_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_AND, out_reg, ssa_operand_reg(value_reg), ssa_operand_reg(mask_reg));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)and_ptr);
    return out_reg;
}

func builder_shift_left(ctx: *BuilderCtx, value_reg: u64, shift_bits: u64) -> u64 {
    if (shift_bits == 0) { return value_reg; }
    var shift_reg: u64 = build_const(ctx, shift_bits);
    var out_reg: u64 = builder_new_reg(ctx);
    var shl_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_SHL, out_reg, ssa_operand_reg(value_reg), ssa_operand_reg(shift_reg));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)shl_ptr);
    return out_reg;
}

func builder_shift_right(ctx: *BuilderCtx, value_reg: u64, shift_bits: u64) -> u64 {
    if (shift_bits == 0) { return value_reg; }
    var shift_reg: u64 = build_const(ctx, shift_bits);
    var out_reg: u64 = builder_new_reg(ctx);
    var shr_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_SHR, out_reg, ssa_operand_reg(value_reg), ssa_operand_reg(shift_reg));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)shr_ptr);
    return out_reg;
}

func builder_mask_tagged_ptr(ctx: *BuilderCtx, value_reg: u64) -> u64 {
    var mask_reg: u64 = build_const(ctx, TAGGED_PTR_MASK);
    var out_reg: u64 = builder_new_reg(ctx);
    var and_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_AND, out_reg, ssa_operand_reg(value_reg), ssa_operand_reg(mask_reg));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)and_ptr);
    return out_reg;
}

func builder_all_ones_reg(ctx: *BuilderCtx) -> u64 {
    var zero_reg: u64 = build_const(ctx, 0);
    var one_reg: u64 = build_const(ctx, 1);
    var out_reg: u64 = builder_new_reg(ctx);
    var sub_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_SUB, out_reg, ssa_operand_reg(zero_reg), ssa_operand_reg(one_reg));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)sub_ptr);
    return out_reg;
}

func builder_get_packed_layout_total_bits(struct_def: u64) -> u64 {
    var sd: *AstStructDef = (*AstStructDef)struct_def;
    var fields: u64 = sd->fields_vec;
    var num_fields: u64 = vec_len(fields);
    var total_bits: u64 = 0;
    for (var i: u64 = 0; i < num_fields; i++) {
        var field: *FieldDesc = (*FieldDesc)vec_get(fields, i);
        if (field->bit_width > 0) {
            total_bits = total_bits + field->bit_width;
        } else {
            var fsize: u64 = sizeof_field_desc(field);
            total_bits = total_bits + fsize * 8;
        }
    }
    return total_bits;
}

func builder_get_packed_field_bit_offset(struct_def: u64, field_name_ptr: u64, field_name_len: u64) -> u64 {
    var sd: *AstStructDef = (*AstStructDef)struct_def;
    var fields: u64 = sd->fields_vec;
    var num_fields: u64 = vec_len(fields);
    var bit_cursor: u64 = 0;
    for (var i: u64 = 0; i < num_fields; i++) {
        var field: *FieldDesc = (*FieldDesc)vec_get(fields, i);
        if (str_eq(field->name_ptr, field->name_len, field_name_ptr, field_name_len)) {
            return bit_cursor;
        }
        if (field->bit_width > 0) {
            bit_cursor = bit_cursor + field->bit_width;
        } else {
            var fsize2: u64 = sizeof_field_desc(field);
            bit_cursor = bit_cursor + fsize2 * 8;
        }
    }
    emit("[ERROR] Packed field not found\n", 33);
    panic("SSA build error");
    return 0;
}

func builder_get_packed_field_bit_width(struct_def: u64, field_name_ptr: u64, field_name_len: u64) -> u64 {
    var sd: *AstStructDef = (*AstStructDef)struct_def;
    var fields: u64 = sd->fields_vec;
    var num_fields: u64 = vec_len(fields);
    for (var i: u64 = 0; i < num_fields; i++) {
        var field: *FieldDesc = (*FieldDesc)vec_get(fields, i);
        if (str_eq(field->name_ptr, field->name_len, field_name_ptr, field_name_len)) {
            if (field->bit_width > 0) { return field->bit_width; }
            return sizeof_field_desc(field) * 8;
        }
    }
    emit("[ERROR] Packed field not found\n", 33);
    panic("SSA build error");
    return 0;
}

func builder_struct_size_from_def(struct_def: u64) -> u64 {
    if (struct_def == 0) { return 0; }
    var sd: *AstStructDef = (*AstStructDef)struct_def;
    if (sd->is_packed == 1) {
        var total_bits: u64 = builder_get_packed_layout_total_bits(struct_def);
        return (total_bits + 7) / 8;
    }
    var fields: u64 = sd->fields_vec;
    if (fields == 0) { return 0; }
    var num_fields: u64 = vec_len(fields);
    var total_size: u64 = 0;
    for (var i: u64 = 0; i < num_fields; i++) {
        var field: *FieldDesc = (*FieldDesc)vec_get(fields, i);
        total_size = total_size + sizeof_field_desc(field);
    }
    return total_size;
}

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
    const_map: u64;       // hashmap: name -> const value
    func_ptr_map: u64;    // hashmap: name -> [func_name_ptr, func_name_len]
    symtab: u64;           // symtab for type/offset lookup
    next_reg: u64;
    next_var_id: u64;
    sret_addr_reg: u64;
    debug_mode: u64;
}

func builder_ctx_new(ssa_ctx: *SSAContext) -> u64 {
    push_trace("builder_ctx_new", "ssa_builder.b", __LINE__);
    pop_trace();
    var p: u64 = heap_alloc(sizeof(BuilderCtx));
    var ctx: *BuilderCtx = (*BuilderCtx)p;
    ctx->ssa_ctx = ssa_ctx;
    ctx->cur_func = 0;
    ctx->cur_block = 0;
    ctx->break_stack = vec_new(8);
    ctx->continue_stack = vec_new(8);
    ctx->var_map = 0;
    ctx->const_map = 0;
    ctx->func_ptr_map = 0;
    ctx->symtab = 0;
    ctx->next_reg = 1;
    ctx->next_var_id = 1;
    ctx->sret_addr_reg = 0;
    ctx->debug_mode = SSA_BUILDER_DEBUG;
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
    ctx->const_map = 0;
    ctx->func_ptr_map = 0;
    ctx->symtab = symtab_new();
    ctx->next_reg = 1;
    ctx->next_var_id = 1;
    var break_len: u64 = vec_len(ctx->break_stack);
    for (var bi: u64 = 0; bi < break_len; bi++) {
        vec_pop(ctx->break_stack);
    }
    var continue_len: u64 = vec_len(ctx->continue_stack);
    for (var ci: u64 = 0; ci < continue_len; ci++) {
        vec_pop(ctx->continue_stack);
    }
    return 0;
}

// ============================================
// Symtab Helpers
// ============================================

func builder_symtab_add_param(ctx: *BuilderCtx, p: *Param, offset: u64) -> u64 {
    var symtab: *Symtab = (*Symtab)ctx->symtab;
    var names: u64 = symtab->names_vec;
    var offsets: u64 = symtab->offsets_vec;
    var types: u64 = symtab->types_vec;

    var name_info: *PtrLen = (*PtrLen)heap_alloc(sizeof(PtrLen));
    name_info->ptr = p->name_ptr;
    name_info->len = p->name_len;
    vec_push(names, (u64)name_info);
    vec_push(offsets, offset);

    var type_info: u64 = heap_alloc(sizeof(TypeInfo));
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
    symtab->count = symtab->count + 1;
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

func builder_set_const(ctx: *BuilderCtx, name_ptr: u64, name_len: u64, value: u64) -> u64 {
    if (ctx->const_map == 0) {
        ctx->const_map = hashmap_new(16);
    }
    hashmap_put(ctx->const_map, name_ptr, name_len, value + 1);
    return 0;
}

func builder_get_const(ctx: *BuilderCtx, name_ptr: u64, name_len: u64) -> u64 {
    if (ctx->const_map == 0) { return 0; }
    return hashmap_get(ctx->const_map, name_ptr, name_len);
}

func builder_set_func_ptr(ctx: *BuilderCtx, name_ptr: u64, name_len: u64, func_ptr: u64, func_len: u64) -> u64 {
    if (ctx->func_ptr_map == 0) {
        ctx->func_ptr_map = hashmap_new(16);
    }
    if (func_ptr == 0 || func_len == 0) {
        hashmap_put(ctx->func_ptr_map, name_ptr, name_len, 0);
        return 0;
    }
    var info: *PtrLen = (*PtrLen)heap_alloc(sizeof(PtrLen));
    info->ptr = func_ptr;
    info->len = func_len;
    hashmap_put(ctx->func_ptr_map, name_ptr, name_len, (u64)info);
    return 0;
}

func builder_get_func_ptr(ctx: *BuilderCtx, name_ptr: u64, name_len: u64) -> u64 {
    if (ctx->func_ptr_map == 0) { return 0; }
    return hashmap_get(ctx->func_ptr_map, name_ptr, name_len);
}

func builder_add_params(ctx: *BuilderCtx, fn: *AstFunc) -> u64 {
    push_trace("builder_add_params", "ssa_builder.b", __LINE__);
    pop_trace();
    if (fn == 0) { return 0; }
    var params: u64 = fn->params_vec;
    if (params == 0) { return 0; }

    ctx->sret_addr_reg = 0;
    var has_sret: u64 = 0;
    if (fn->ret_type == TYPE_STRUCT && fn->ret_ptr_depth == 0) {
        var ret_struct_size: u64 = sizeof_type(TYPE_STRUCT, 0, fn->ret_struct_name_ptr, fn->ret_struct_name_len);
        var ret_def: u64 = get_struct_def(fn->ret_struct_name_ptr, fn->ret_struct_name_len);
        var ret_def_size: u64 = builder_struct_size_from_def(ret_def);
        if (ret_def_size > ret_struct_size) { ret_struct_size = ret_def_size; }
        if (ret_struct_size > 16) { has_sret = 1; }
    }

    var n: u64 = vec_len(params);
    var param_offsets: u64 = vec_new(n);
    var param_arg_idx: u64 = vec_new(n);
    var arg_idx: u64 = 0;
    if (has_sret != 0) { arg_idx = 1; }

    for (var i: u64 = 0; i < n; i++) {
        var p: *Param = (*Param)vec_get(params, i);
        var param_words: u64 = 1;
        if (p->type_kind == TYPE_STRUCT && p->ptr_depth == 0) {
            var struct_size: u64 = sizeof_type(TYPE_STRUCT, 0, p->struct_name_ptr, p->struct_name_len);
            if (struct_size == 0) { return 0; }
            if (struct_size <= 8) { param_words = 1; }
            else if (struct_size <= 16) { param_words = 2; }
            else {
                param_words = 1;
                if (ctx->debug_mode != 0) {
                    emit("[DEBUG] ssa param large struct: ", 35);
                    emit(p->name_ptr, p->name_len);
                    emit(" size=", 6);
                    print_u64(struct_size);
                    emit("\n", 1);
                }
            }

            var offset: u64 = symtab_add(ctx->symtab, p->name_ptr, p->name_len, p->type_kind, p->ptr_depth, struct_size);
            var type_info: u64 = symtab_get_type(ctx->symtab, p->name_ptr, p->name_len);
            var ti: *TypeInfo = (*TypeInfo)type_info;
            ti->is_tagged = p->is_tagged;
            ti->struct_name_ptr = p->struct_name_ptr;
            ti->struct_name_len = p->struct_name_len;
            ti->tag_layout_ptr = p->tag_layout_ptr;
            ti->tag_layout_len = p->tag_layout_len;
            ti->elem_type_kind = p->elem_type_kind;
            ti->elem_ptr_depth = p->elem_ptr_depth;
            ti->array_len = p->array_len;
            var g_structs_vec: u64 = typeinfo_get_structs();
            if (g_structs_vec != 0 && p->struct_name_ptr != 0) {
                var num_structs: u64 = vec_len(g_structs_vec);
                for (var sj: u64 = 0; sj < num_structs; sj++) {
                    var sd_ptr: u64 = vec_get(g_structs_vec, sj);
                    var sd: *AstStructDef = (*AstStructDef)sd_ptr;
                    if (sd->name_len == p->struct_name_len && str_eq(sd->name_ptr, sd->name_len, p->struct_name_ptr, p->struct_name_len) != 0) {
                        ti->struct_def = sd_ptr;
                        break;
                    }
                }
            }
            vec_push(param_offsets, offset);
        } else if (p->type_kind == TYPE_SLICE && p->ptr_depth == 0) {
            var offset2: u64 = symtab_add(ctx->symtab, p->name_ptr, p->name_len, p->type_kind, p->ptr_depth, 16);
            var type_info2: u64 = symtab_get_type(ctx->symtab, p->name_ptr, p->name_len);
            var ti2: *TypeInfo = (*TypeInfo)type_info2;
            ti2->is_tagged = p->is_tagged;
            ti2->struct_name_ptr = p->struct_name_ptr;
            ti2->struct_name_len = p->struct_name_len;
            ti2->tag_layout_ptr = p->tag_layout_ptr;
            ti2->tag_layout_len = p->tag_layout_len;
            ti2->elem_type_kind = p->elem_type_kind;
            ti2->elem_ptr_depth = p->elem_ptr_depth;
            ti2->array_len = p->array_len;
            var g_structs_vec2: u64 = typeinfo_get_structs();
            if (p->elem_type_kind == TYPE_STRUCT && g_structs_vec2 != 0 && p->struct_name_ptr != 0) {
                var num_structs2: u64 = vec_len(g_structs_vec2);
                for (var sj2: u64 = 0; sj2 < num_structs2; sj2++) {
                    var sd_ptr2: u64 = vec_get(g_structs_vec2, sj2);
                    var sd2: *AstStructDef = (*AstStructDef)sd_ptr2;
                    if (sd2->name_len == p->struct_name_len && str_eq(sd2->name_ptr, sd2->name_len, p->struct_name_ptr, p->struct_name_len) != 0) {
                        ti2->struct_def = sd_ptr2;
                        break;
                    }
                }
            }
            param_words = 2;
            vec_push(param_offsets, offset2);
        } else {
            vec_push(param_offsets, 0);
        }

        vec_push(param_arg_idx, arg_idx);
        arg_idx = arg_idx + param_words;
    }

    for (var i: u64 = n; i > 0; i--) {
        var idx: u64 = i - 1;
        var p2: *Param = (*Param)vec_get(params, idx);
        var start_idx: u64 = vec_get(param_arg_idx, idx);
        if (p2->type_kind == TYPE_STRUCT && p2->ptr_depth == 0) {
            var struct_size2: u64 = sizeof_type(TYPE_STRUCT, 0, p2->struct_name_ptr, p2->struct_name_len);
            if (struct_size2 == 0) { return 0; }
            var offset3: u64 = vec_get(param_offsets, idx);
            var base_addr: u64 = builder_new_lea_local(ctx, offset3);
            if (struct_size2 <= 8) {
                var reg0: u64 = builder_new_reg(ctx);
                var param0: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_PARAM, reg0, ssa_operand_const(start_idx), 0);
                ssa_inst_append(ctx->cur_block, (*SSAInstruction)param0);
                builder_store_by_size(ctx, base_addr, reg0, struct_size2);
            } else if (struct_size2 <= 16) {
                var reg_lo: u64 = builder_new_reg(ctx);
                var reg_hi: u64 = builder_new_reg(ctx);
                var param_lo: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_PARAM, reg_lo, ssa_operand_const(start_idx), 0);
                var param_hi: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_PARAM, reg_hi, ssa_operand_const(start_idx + 1), 0);
                ssa_inst_append(ctx->cur_block, (*SSAInstruction)param_lo);
                ssa_inst_append(ctx->cur_block, (*SSAInstruction)param_hi);
                builder_store_by_size(ctx, base_addr, reg_lo, 8);
                var off_reg: u64 = build_const(ctx, 8);
                var addr2: u64 = builder_new_reg(ctx);
                var add_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, addr2, ssa_operand_reg(base_addr), ssa_operand_reg(off_reg));
                ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr);
                var tail_size: u64 = struct_size2 - 8;
                builder_store_by_size(ctx, addr2, reg_hi, tail_size);
            } else {
                var reg_ptr: u64 = builder_new_reg(ctx);
                var param_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_PARAM, reg_ptr, ssa_operand_const(start_idx), 0);
                ssa_inst_append(ctx->cur_block, (*SSAInstruction)param_ptr);
                if (ctx->debug_mode != 0) {
                    emit("[DEBUG] ssa param copy large struct: ", 40);
                    emit(p2->name_ptr, p2->name_len);
                    emit(" size=", 6);
                    print_u64(struct_size2);
                    emit("\n", 1);
                }
                builder_struct_copy(ctx, base_addr, reg_ptr, struct_size2);
            }
            continue;
        }

        if (p2->type_kind == TYPE_SLICE && p2->ptr_depth == 0) {
            var offset4: u64 = vec_get(param_offsets, idx);
            var base_addr2: u64 = builder_new_lea_local(ctx, offset4);
            var ptr_reg: u64 = builder_new_reg(ctx);
            var ptr_param: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_PARAM, ptr_reg, ssa_operand_const(start_idx), 0);
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)ptr_param);
            builder_store_by_size(ctx, base_addr2, ptr_reg, 8);
            var len_reg: u64 = builder_new_reg(ctx);
            var len_param: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_PARAM, len_reg, ssa_operand_const(start_idx + 1), 0);
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)len_param);
            var off_reg2: u64 = build_const(ctx, 8);
            var addr3: u64 = builder_new_reg(ctx);
            var add_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, addr3, ssa_operand_reg(base_addr2), ssa_operand_reg(off_reg2));
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr2);
            builder_store_by_size(ctx, addr3, len_reg, 8);
            continue;
        }

        var var_id: u64 = builder_get_var_id(ctx, p2->name_ptr, p2->name_len);
        var reg_id: u64 = builder_new_reg(ctx);
        var inst_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_PARAM, reg_id, ssa_operand_const(start_idx), 0);
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr);
        var st_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_STORE, 0, ssa_operand_const(var_id), ssa_operand_reg(reg_id));
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)st_ptr);
        builder_symtab_add_param(ctx, p2, 16 + start_idx * 8);
    }
    if (has_sret != 0) {
        var sret_reg: u64 = builder_new_reg(ctx);
        var sret_param: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_PARAM, sret_reg, ssa_operand_const(0), 0);
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)sret_param);
        ctx->sret_addr_reg = sret_reg;
    }
    return 0;
}

// ============================================
// Address/Memory Helpers
// ============================================

func builder_new_lea_local(ctx: *BuilderCtx, offset: u64) -> u64 {
    var reg_id: u64 = builder_new_reg(ctx);
    // Encode signed 64-bit stack offset into 63-bit field with bias so
    // ssa_operand_value can carry it without losing sign.
    var signed_off: i64 = (i64)offset;
    var bias: u64 = 4611686018427387904; // 1<<62
    var enc: u64 = (u64)(signed_off + (i64)bias);
    var inst_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_LEA_LOCAL, reg_id, ssa_operand_const(enc), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr);
    return reg_id;
}

func builder_new_lea_global(ctx: *BuilderCtx, name_ptr: u64, name_len: u64) -> u64 {
    var info: *PtrLen = (*PtrLen)heap_alloc(sizeof(PtrLen));
    info->ptr = name_ptr;
    info->len = name_len;
    var reg_id: u64 = builder_new_reg(ctx);
    var inst_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_LEA_GLOBAL, reg_id, ssa_operand_const((u64)info), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr);
    return reg_id;
}

func builder_new_lea_func(ctx: *BuilderCtx, name_ptr: u64, name_len: u64) -> u64 {
    var info: *PtrLen = (*PtrLen)heap_alloc(sizeof(PtrLen));
    info->ptr = name_ptr;
    info->len = name_len;
    var reg_id: u64 = builder_new_reg(ctx);
    var inst_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_LEA_FUNC, reg_id, ssa_operand_const((u64)info), 0);
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

func builder_struct_copy(ctx: *BuilderCtx, dst_addr: u64, src_addr: u64, size: u64) -> u64 {
    for (var offset: u64 = 0; offset < size; ) {
        var chunk: u64 = size - offset;
        if (chunk > 8) { chunk = 8; }
        var src_reg: u64 = src_addr;
        var dst_reg: u64 = dst_addr;
        if (offset != 0) {
            var off_reg: u64 = build_const(ctx, offset);
            var src_tmp: u64 = builder_new_reg(ctx);
            var dst_tmp: u64 = builder_new_reg(ctx);
            var add_src: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, src_tmp, ssa_operand_reg(src_addr), ssa_operand_reg(off_reg));
            var add_dst: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, dst_tmp, ssa_operand_reg(dst_addr), ssa_operand_reg(off_reg));
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_src);
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_dst);
            src_reg = src_tmp;
            dst_reg = dst_tmp;
        }
        var val_reg: u64 = builder_load_by_size(ctx, src_reg, chunk);
        builder_store_by_size(ctx, dst_reg, val_reg, chunk);
        offset = offset + chunk;
    }
    return 0;
}

func builder_append_slice_arg(ctx: *BuilderCtx, arg_regs: u64, arg: u64) -> u64 {
    var k: u64 = ast_kind(arg);
    if (k == AST_SLICE) {
        var slice_info: u64 = builder_slice_regs(ctx, arg);
        var slice_regs: *SliceRegs = (*SliceRegs)slice_info;
        var ptr_reg: u64 = slice_regs->ptr_reg;
        var len_reg: u64 = slice_regs->len_reg;
        vec_push(arg_regs, ptr_reg);
        vec_push(arg_regs, len_reg);
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
    vec_push(arg_regs, ptr_reg2);
    vec_push(arg_regs, len_reg2);
    return 0;
}

func builder_get_sret_struct_size(ctx: *BuilderCtx, expr: u64) -> u64 {
    if (expr == 0) { return 0; }
    var struct_size: u64 = 0;
    var ti_ptr: u64 = get_expr_type_with_symtab(expr, ctx->symtab);
    if (ti_ptr != 0) {
        var ti: *TypeInfo = (*TypeInfo)ti_ptr;
        if (ti->type_kind == TYPE_STRUCT && ti->ptr_depth == 0) {
            if (ti->struct_name_ptr != 0 && ti->struct_name_len != 0) {
                struct_size = sizeof_type(TYPE_STRUCT, 0, ti->struct_name_ptr, ti->struct_name_len);
            }
            if (struct_size <= 16 && ti->struct_def != 0) {
                var def_size: u64 = builder_struct_size_from_def(ti->struct_def);
                if (def_size > struct_size) { struct_size = def_size; }
            }
        }
    }
    if (struct_size <= 16) {
        var k: u64 = ast_kind(expr);
        if (k == AST_CALL) {
            var call_node: *AstCall = (*AstCall)expr;
            var call_fn_ptr: u64 = compiler_get_func(call_node->name_ptr, call_node->name_len);
            if (call_fn_ptr != 0) {
                var call_fn: *AstFunc = (*AstFunc)call_fn_ptr;
                if (call_fn->ret_type == TYPE_STRUCT && call_fn->ret_ptr_depth == 0) {
                    var call_def: u64 = get_struct_def(call_fn->ret_struct_name_ptr, call_fn->ret_struct_name_len);
                    var call_def_size: u64 = builder_struct_size_from_def(call_def);
                    if (call_def_size == 0) {
                        call_def_size = sizeof_type(TYPE_STRUCT, 0, call_fn->ret_struct_name_ptr, call_fn->ret_struct_name_len);
                    }
                    if (call_def_size > struct_size) { struct_size = call_def_size; }
                }
            }
        }
    }
    if (struct_size <= 16) { return 0; }
    if (SSA_BUILDER_DEBUG != 0) {
        println("[DEBUG] sret temp slot for expr", 31);
    }
    return struct_size;
}

func builder_append_call_arg(ctx: *BuilderCtx, arg_regs: u64, arg: u64) -> u64 {
    var arg_kind: u64 = ast_kind(arg);

    // Fast-path: struct literal arguments (handle byval lowering directly)
    if (arg_kind == AST_STRUCT_LITERAL) {
        var lit: *AstStructLiteral = (*AstStructLiteral)arg;
        var struct_size_lit: u64 = builder_struct_size_from_def(lit->struct_def);
        if (struct_size_lit == 0 && lit->values_vec != 0) {
            struct_size_lit = vec_len(lit->values_vec) * 8;
        }
        if (struct_size_lit == 0) { return 0; }

        if (lit->struct_def != 0 && struct_size_lit <= 16) {
            var struct_info: *AstStructDef = (*AstStructDef)lit->struct_def;
            var packed_flag: u64 = struct_info->is_packed;
            if (packed_flag == 0) {
                var fields: u64 = struct_info->fields_vec;
                var num_fields: u64 = 0;
                if (fields != 0) { num_fields = vec_len(fields); }
                if (num_fields >= 1 && num_fields <= 2 && lit->values_vec != 0) {
                    var f0: *FieldDesc = (*FieldDesc)vec_get(fields, 0);
                    var f0_size: u64 = sizeof_field_desc(f0);
                    var v0: u64 = vec_get(lit->values_vec, 0);
                    var reg0: u64 = build_expr(ctx, v0);
                    if (reg0 == 0) { reg0 = build_const(ctx, 0); }
                    if (num_fields == 1 && f0_size == 8) {
                        vec_push(arg_regs, reg0);
                        return 0;
                    }
                    if (num_fields == 2) {
                        var f1: *FieldDesc = (*FieldDesc)vec_get(fields, 1);
                        var f1_size: u64 = sizeof_field_desc(f1);
                        if (f0_size == 8 && f1_size == 8 && vec_len(lit->values_vec) > 1) {
                            var v1: u64 = vec_get(lit->values_vec, 1);
                            var reg1: u64 = build_expr(ctx, v1);
                            if (reg1 == 0) { reg1 = build_const(ctx, 0); }
                            vec_push(arg_regs, reg0);
                            vec_push(arg_regs, reg1);
                            return 0;
                        }
                    }
                }
            }
        }

        var temp_offset_lit: u64 = symtab_add(ctx->symtab, 0, 0, TYPE_STRUCT, 0, struct_size_lit);
        var temp_addr_lit: u64 = builder_new_lea_local(ctx, temp_offset_lit);
        builder_struct_literal_init(ctx, lit->struct_def, lit->values_vec, temp_addr_lit);

        if (struct_size_lit <= 8) {
            var val_lit: u64 = builder_load_by_size(ctx, temp_addr_lit, struct_size_lit);
            vec_push(arg_regs, val_lit);
            return 0;
        }
        if (struct_size_lit <= 16) {
            var lo_lit: u64 = builder_load_by_size(ctx, temp_addr_lit, 8);
            var off_lit: u64 = build_const(ctx, 8);
            var addr_lit2: u64 = builder_new_reg(ctx);
            var add_lit: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, addr_lit2, ssa_operand_reg(temp_addr_lit), ssa_operand_reg(off_lit));
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_lit);
            var tail_lit: u64 = struct_size_lit - 8;
            var hi_lit: u64 = builder_load_by_size(ctx, addr_lit2, tail_lit);
            vec_push(arg_regs, lo_lit);
            vec_push(arg_regs, hi_lit);
            return 0;
        }

        if (ctx->debug_mode != 0) {
            emit("[DEBUG] ssa call arg large struct literal size=", 52);
            print_u64(struct_size_lit);
            emit("\n", 1);
        }
        vec_push(arg_regs, temp_addr_lit);
        return 0;
    }

    // Handle AST_CALL with struct return FIRST
    if (arg_kind == AST_CALL) {
        var call: *AstCall = (*AstCall)arg;
        var fn_ptr: u64 = compiler_get_func(call->name_ptr, call->name_len);
        if (fn_ptr != 0) {
            var fn: *AstFunc = (*AstFunc)fn_ptr;
            if (fn->ret_type == TYPE_STRUCT && fn->ret_ptr_depth == 0) {
                var struct_size: u64 = sizeof_type(TYPE_STRUCT, 0, fn->ret_struct_name_ptr, fn->ret_struct_name_len);
                if (struct_size <= 8) {
                    var reg0: u64 = builder_new_reg(ctx);
                    builder_emit_call(ctx, call, reg0, 0);
                    vec_push(arg_regs, reg0);
                    return 0;
                }
                if (struct_size <= 16) {
                    var lo_reg: u64 = builder_new_reg(ctx);
                    var hi_reg: u64 = builder_new_reg(ctx);
                    builder_emit_call(ctx, call, lo_reg, hi_reg);
                    vec_push(arg_regs, lo_reg);
                    vec_push(arg_regs, hi_reg);
                    return 0;
                }
                // Large struct return in call args is handled by byval lowering below.
            }
            // Non-struct return from call - fall through to generic handling
        }
    }

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
        if (ti->type_kind == TYPE_STRUCT && ti->ptr_depth == 0) {
            var struct_size: u64 = sizeof_type(TYPE_STRUCT, 0, ti->struct_name_ptr, ti->struct_name_len);
            var arg_kind: u64 = ast_kind(arg);
            if (struct_size == 0) {
                var def_ptr: u64 = ti->struct_def;
                if (def_ptr == 0 && arg_kind == AST_STRUCT_LITERAL) {
                    var lit_def: *AstStructLiteral = (*AstStructLiteral)arg;
                    def_ptr = lit_def->struct_def;
                }
                var def_size: u64 = builder_struct_size_from_def(def_ptr);
                if (def_size > 0) { struct_size = def_size; }
            }
            if (struct_size == 0 && arg_kind == AST_STRUCT_LITERAL) {
                var lit_fallback: *AstStructLiteral = (*AstStructLiteral)arg;
                if (lit_fallback->values_vec != 0) {
                    struct_size = vec_len(lit_fallback->values_vec) * 8;
                }
            }
            if (struct_size == 0) { return 0; }
            if (struct_size <= 8) {
                if (arg_kind == AST_CALL) {
                    var reg0: u64 = builder_new_reg(ctx);
                    builder_emit_call(ctx, (*AstCall)arg, reg0, 0);
                    vec_push(arg_regs, reg0);
                    return 0;
                }
                if (arg_kind == AST_METHOD_CALL) {
                    var reg1: u64 = builder_new_reg(ctx);
                    builder_emit_method_call(ctx, (*AstMethodCall)arg, reg1, 0);
                    vec_push(arg_regs, reg1);
                    return 0;
                }
                if (arg_kind == AST_CALL_PTR) {
                    var reg2: u64 = builder_new_reg(ctx);
                    builder_emit_call_ptr(ctx, (*AstCallPtr)arg, reg2, 0);
                    vec_push(arg_regs, reg2);
                    return 0;
                }
                var addr0: u64 = builder_lvalue_addr(ctx, arg);
                var val0: u64 = builder_load_by_size(ctx, addr0, struct_size);
                vec_push(arg_regs, val0);
                return 0;
            }
            if (struct_size <= 16) {
                var lo_reg: u64 = 0;
                var hi_reg: u64 = 0;
                if (arg_kind == AST_CALL) {
                    lo_reg = builder_new_reg(ctx);
                    hi_reg = builder_new_reg(ctx);
                    builder_emit_call(ctx, (*AstCall)arg, lo_reg, hi_reg);
                } else if (arg_kind == AST_METHOD_CALL) {
                    lo_reg = builder_new_reg(ctx);
                    hi_reg = builder_new_reg(ctx);
                    builder_emit_method_call(ctx, (*AstMethodCall)arg, lo_reg, hi_reg);
                } else if (arg_kind == AST_CALL_PTR) {
                    lo_reg = builder_new_reg(ctx);
                    hi_reg = builder_new_reg(ctx);
                    builder_emit_call_ptr(ctx, (*AstCallPtr)arg, lo_reg, hi_reg);
                } else {
                    var addr1: u64 = builder_lvalue_addr(ctx, arg);
                    lo_reg = builder_load_by_size(ctx, addr1, 8);
                    var off_reg: u64 = build_const(ctx, 8);
                    var addr2: u64 = builder_new_reg(ctx);
                    var add_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, addr2, ssa_operand_reg(addr1), ssa_operand_reg(off_reg));
                    ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr);
                    var tail_size: u64 = struct_size - 8;
                    hi_reg = builder_load_by_size(ctx, addr2, tail_size);
                }
                vec_push(arg_regs, lo_reg);
                vec_push(arg_regs, hi_reg);
                return 0;
            }
            if (ctx->debug_mode != 0) {
                emit("[DEBUG] ssa call arg large struct: ", 38);
                emit(ti->struct_name_ptr, ti->struct_name_len);
                emit(" size=", 6);
                print_u64(struct_size);
                emit("\n", 1);
            }
            var temp_offset: u64 = symtab_add(ctx->symtab, 0, 0, TYPE_STRUCT, 0, struct_size);
            var temp_addr: u64 = builder_new_lea_local(ctx, temp_offset);
            if (arg_kind == AST_STRUCT_LITERAL) {
                var lit: *AstStructLiteral = (*AstStructLiteral)arg;
                builder_struct_literal_init(ctx, lit->struct_def, lit->values_vec, temp_addr);
            } else if (arg_kind == AST_CALL) {
                builder_emit_call_sret(ctx, (*AstCall)arg, temp_addr);
            } else if (arg_kind == AST_METHOD_CALL) {
                builder_emit_method_call_sret(ctx, (*AstMethodCall)arg, temp_addr);
            } else if (arg_kind == AST_CALL_PTR) {
                builder_emit_call_ptr_sret(ctx, (*AstCallPtr)arg, temp_addr);
            } else {
                var src_addr: u64 = builder_lvalue_addr(ctx, arg);
                if (src_addr == 0) { return 0; }
                builder_struct_copy(ctx, temp_addr, src_addr, struct_size);
            }
            vec_push(arg_regs, temp_addr);
            return 0;
        }
    }
    var reg: u64 = build_expr(ctx, arg);
    vec_push(arg_regs, reg);
    return 0;
}

func builder_slice_regs(ctx: *BuilderCtx, expr: u64) -> u64 {
    var info: *SliceRegs = (*SliceRegs)heap_alloc(sizeof(SliceRegs));
    var k: u64 = ast_kind(expr);
    if (k == AST_SLICE) {
        var s: *AstSlice = (*AstSlice)expr;
        var ptr_reg: u64 = 0;
        var ptr_kind: u64 = ast_kind(s->ptr_expr);
        if (ptr_kind == AST_IDENT) {
            var ti_ptr: u64 = get_expr_type_with_symtab(s->ptr_expr, ctx->symtab);
            if (ti_ptr != 0) {
                var ti: *TypeInfo = (*TypeInfo)ti_ptr;
                if (ti->ptr_depth == 0) {
                    if (ti->type_kind == TYPE_ARRAY || ti->array_len != 0) {
                        ptr_reg = builder_lvalue_addr(ctx, s->ptr_expr);
                    }
                }
            }
        }
        if (ptr_reg == 0) {
            ptr_reg = build_expr(ctx, s->ptr_expr);
        }
        var len_reg: u64 = build_expr(ctx, s->len_expr);
        info->ptr_reg = ptr_reg;
        info->len_reg = len_reg;
        return (u64)info;
    }

    var addr_reg: u64 = builder_lvalue_addr(ctx, expr);
    var ptr_reg2: u64 = builder_load_by_size(ctx, addr_reg, 8);
    var off_reg: u64 = build_const(ctx, 8);
    var addr2: u64 = builder_new_reg(ctx);
    var add_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, addr2, ssa_operand_reg(addr_reg), ssa_operand_reg(off_reg));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr);
    var len_reg2: u64 = builder_load_by_size(ctx, addr2, 8);
    info->ptr_reg = ptr_reg2;
    info->len_reg = len_reg2;
    return (u64)info;
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
            var slice_regs: *SliceRegs = (*SliceRegs)slice_info;
            var ptr_reg: u64 = slice_regs->ptr_reg;
            var len_reg: u64 = slice_regs->len_reg;
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
    var regs: *SliceRegs = (*SliceRegs)slice_info;
    var ptr_reg: u64 = regs->ptr_reg;
    var len_reg: u64 = regs->len_reg;
    builder_store_by_size(ctx, base_addr, ptr_reg, 8);
    var off_reg: u64 = build_const(ctx, 8);
    var addr2: u64 = builder_new_reg(ctx);
    var add_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, addr2, ssa_operand_reg(base_addr), ssa_operand_reg(off_reg));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr);
    builder_store_by_size(ctx, addr2, len_reg, 8);
    return 0;
}

func builder_assign_struct_literal_to_addr(ctx: *BuilderCtx, lit: *AstStructLiteral, base_addr: u64) -> u64 {
    if (lit == 0 || base_addr == 0) { return 0; }
    builder_struct_literal_init(ctx, lit->struct_def, lit->values_vec, base_addr);
    return 0;
}

func builder_assign_slice_to_addr(ctx: *BuilderCtx, value: u64, base_addr: u64) -> u64 {
    if (base_addr == 0) { return 0; }
    var value_kind: u64 = ast_kind(value);
    if (value_kind == AST_CALL) {
        builder_emit_call_slice_store(ctx, (*AstCall)value, base_addr);
        return 0;
    }
    if (value_kind == AST_METHOD_CALL) {
        builder_emit_method_call_slice_store(ctx, (*AstMethodCall)value, base_addr);
        return 0;
    }
    if (value_kind == AST_CALL_PTR) {
        builder_emit_call_ptr_slice_store(ctx, (*AstCallPtr)value, base_addr);
        return 0;
    }
    var slice_info: u64 = builder_slice_regs(ctx, value);
    builder_store_slice_regs(ctx, base_addr, slice_info);
    return 0;
}

func builder_build_method_name(struct_ptr: u64, struct_len: u64, method_ptr: u64, method_len: u64) -> u64 {
    var full_len: u64 = struct_len + 1 + method_len;
    var full_ptr: u64 = heap_alloc((full_len + 1) * sizeof(u8));
    for (var i: u64 = 0; i < struct_len; i++) {
        *(*u8)(full_ptr + i) = *(*u8)(struct_ptr + i);
    }
    *(*u8)(full_ptr + struct_len) = 95;
    for (var j: u64 = 0; j < method_len; j++) {
        *(*u8)(full_ptr + struct_len + 1 + j) = *(*u8)(method_ptr + j);
    }
    *(*u8)(full_ptr + full_len) = 0;
    return full_ptr;
}

func builder_emit_call(ctx: *BuilderCtx, call: *AstCall, dst: u64, extra_dst: u64) -> u64 {
    var name_ptr: u64 = call->name_ptr;
    var name_len: u64 = call->name_len;
    if (compiler_func_exists(name_ptr, name_len) == 0) {
        var callee: u64 = ast_ident(name_ptr, name_len);
        var cp: u64 = ast_call_ptr(callee, call->args_vec);
        return builder_emit_call_ptr(ctx, (*AstCallPtr)cp, dst, extra_dst);
    }
    var resolved_ptr: u64 = name_ptr;
    var resolved_len: u64 = name_len;
    var resolved: u64 = resolve_name(name_ptr, name_len);
    if (resolved != 0) {
        var resolved_info: *NameInfo = (*NameInfo)resolved;
        resolved_ptr = resolved_info->ptr;
        resolved_len = resolved_info->len;
    }

    var args: u64 = call->args_vec;
    var nargs: u64 = 0;
    if (args != 0) { nargs = vec_len(args); }
    var arg_regs: u64 = vec_new(nargs * 2);
    for (var i: u64 = 0; i < nargs; i++) {
        var arg: u64 = vec_get(args, i);
        builder_append_call_arg(ctx, arg_regs, arg);
    }
    var total_regs: u64 = vec_len(arg_regs);

    var ret_type: u64 = TYPE_I64;
    var ret_ptr_depth: u64 = 0;
    var ret_struct_size: u64 = 0;
    var ret_ti_ptr: u64 = get_expr_type_with_symtab((u64)call, ctx->symtab);
    if (ret_ti_ptr != 0) {
        var ret_ti: *TypeInfo = (*TypeInfo)ret_ti_ptr;
        ret_type = ret_ti->type_kind;
        ret_ptr_depth = ret_ti->ptr_depth;
        if (ret_type == TYPE_STRUCT && ret_ptr_depth == 0) {
            ret_struct_size = sizeof_type(TYPE_STRUCT, 0, ret_ti->struct_name_ptr, ret_ti->struct_name_len);
        }
    }

    var info_ptr: u64 = heap_alloc(sizeof(SSACallInfo));
    var info: *SSACallInfo = (*SSACallInfo)info_ptr;
    info->name_ptr = resolved_ptr;
    info->name_len = resolved_len;
    info->args_vec = arg_regs;
    info->nargs = total_regs;
    info->ret_type = ret_type;
    info->ret_ptr_depth = ret_ptr_depth;
    info->ret_struct_size = ret_struct_size;

    var extra_opr: u64 = 0;
    if (extra_dst != 0) { extra_opr = ssa_operand_reg(extra_dst); }
    var call_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_CALL, dst, ssa_operand_const(info_ptr), extra_opr);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)call_ptr);
    return dst;
}

func builder_emit_call_sret(ctx: *BuilderCtx, call: *AstCall, addr_reg: u64) -> u64 {
    if (addr_reg == 0) { return 0; }
    var name_ptr: u64 = call->name_ptr;
    var name_len: u64 = call->name_len;
    if (compiler_func_exists(name_ptr, name_len) == 0) {
        var callee: u64 = ast_ident(name_ptr, name_len);
        var cp: u64 = ast_call_ptr(callee, call->args_vec);
        return builder_emit_call_ptr_sret(ctx, (*AstCallPtr)cp, addr_reg);
    }
    var resolved_ptr: u64 = name_ptr;
    var resolved_len: u64 = name_len;
    var resolved: u64 = resolve_name(name_ptr, name_len);
    if (resolved != 0) {
        var resolved_info: *NameInfo = (*NameInfo)resolved;
        resolved_ptr = resolved_info->ptr;
        resolved_len = resolved_info->len;
    }

    var args: u64 = call->args_vec;
    var nargs: u64 = 0;
    if (args != 0) { nargs = vec_len(args); }
    var arg_regs: u64 = vec_new(nargs * 2 + 1);
    vec_push(arg_regs, addr_reg);
    for (var i: u64 = 0; i < nargs; i++) {
        var arg: u64 = vec_get(args, i);
        builder_append_call_arg(ctx, arg_regs, arg);
    }
    var total_regs: u64 = vec_len(arg_regs);

    var ret_type: u64 = TYPE_STRUCT;
    var ret_ptr_depth: u64 = 0;
    var ret_struct_size: u64 = 0;
    var ret_ti_ptr: u64 = get_expr_type_with_symtab((u64)call, ctx->symtab);
    if (ret_ti_ptr != 0) {
        var ret_ti: *TypeInfo = (*TypeInfo)ret_ti_ptr;
        ret_type = ret_ti->type_kind;
        ret_ptr_depth = ret_ti->ptr_depth;
        if (ret_type == TYPE_STRUCT && ret_ptr_depth == 0) {
            ret_struct_size = sizeof_type(TYPE_STRUCT, 0, ret_ti->struct_name_ptr, ret_ti->struct_name_len);
        }
    }

    var info_ptr: u64 = heap_alloc(sizeof(SSACallInfo));
    var info: *SSACallInfo = (*SSACallInfo)info_ptr;
    info->name_ptr = resolved_ptr;
    info->name_len = resolved_len;
    info->args_vec = arg_regs;
    info->nargs = total_regs;
    info->ret_type = ret_type;
    info->ret_ptr_depth = ret_ptr_depth;
    info->ret_struct_size = ret_struct_size;

    var call_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_CALL, 0, ssa_operand_const(info_ptr), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)call_ptr);
    return 0;
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
        var resolved_info: *NameInfo = (*NameInfo)resolved;
        resolved_ptr = resolved_info->ptr;
        resolved_len = resolved_info->len;
    }

    var args: u64 = call->args_vec;
    var nargs: u64 = 0;
    if (args != 0) { nargs = vec_len(args); }
    var arg_regs: u64 = vec_new(nargs * 2);
    for (var i: u64 = 0; i < nargs; i++) {
        var arg: u64 = vec_get(args, i);
        builder_append_call_arg(ctx, arg_regs, arg);
    }
    var total_regs: u64 = vec_len(arg_regs);

    var ret_type: u64 = TYPE_I64;
    var ret_ptr_depth: u64 = 0;
    var ret_struct_size: u64 = 0;
    var ret_ti_ptr: u64 = get_expr_type_with_symtab((u64)call, ctx->symtab);
    if (ret_ti_ptr != 0) {
        var ret_ti: *TypeInfo = (*TypeInfo)ret_ti_ptr;
        ret_type = ret_ti->type_kind;
        ret_ptr_depth = ret_ti->ptr_depth;
        if (ret_type == TYPE_STRUCT && ret_ptr_depth == 0) {
            ret_struct_size = sizeof_type(TYPE_STRUCT, 0, ret_ti->struct_name_ptr, ret_ti->struct_name_len);
        }
    }

    var info_ptr: u64 = heap_alloc(sizeof(SSACallSliceStoreInfo));
    var info: *SSACallSliceStoreInfo = (*SSACallSliceStoreInfo)info_ptr;
    info->is_ptr = 0;
    info->name_ptr = resolved_ptr;
    info->name_len = resolved_len;
    info->callee_reg = 0;
    info->args_vec = arg_regs;
    info->nargs = total_regs;
    info->ret_type = ret_type;
    info->ret_ptr_depth = ret_ptr_depth;

    var call_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_CALL_SLICE_STORE, 0, ssa_operand_const(info_ptr), ssa_operand_reg(addr_reg));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)call_ptr);
    return 0;
}

func builder_emit_method_call(ctx: *BuilderCtx, mc: *AstMethodCall, dst: u64, extra_dst: u64) -> u64 {
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
        var resolved_info: *NameInfo = (*NameInfo)resolved;
        resolved_ptr = resolved_info->ptr;
        resolved_len = resolved_info->len;
    }

    var args: u64 = mc->args_vec;
    var nargs: u64 = 0;
    if (args != 0) { nargs = vec_len(args); }
    var arg_regs: u64 = vec_new(nargs * 2 + 1);
    var recv_addr: u64 = builder_lvalue_addr(ctx, receiver);
    vec_push(arg_regs, recv_addr);
    for (var i: u64 = 0; i < nargs; i++) {
        var arg: u64 = vec_get(args, i);
        builder_append_call_arg(ctx, arg_regs, arg);
    }
    var total_regs: u64 = vec_len(arg_regs);

    var ret_type: u64 = TYPE_I64;
    var ret_ptr_depth: u64 = 0;
    var ret_struct_size: u64 = 0;
    var ret_ti_ptr: u64 = get_expr_type_with_symtab((u64)mc, ctx->symtab);
    if (ret_ti_ptr != 0) {
        var ret_ti: *TypeInfo = (*TypeInfo)ret_ti_ptr;
        ret_type = ret_ti->type_kind;
        ret_ptr_depth = ret_ti->ptr_depth;
        if (ret_type == TYPE_STRUCT && ret_ptr_depth == 0) {
            ret_struct_size = sizeof_type(TYPE_STRUCT, 0, ret_ti->struct_name_ptr, ret_ti->struct_name_len);
        }
    }

    var info_ptr: u64 = heap_alloc(sizeof(SSACallInfo));
    var info: *SSACallInfo = (*SSACallInfo)info_ptr;
    info->name_ptr = resolved_ptr;
    info->name_len = resolved_len;
    info->args_vec = arg_regs;
    info->nargs = total_regs;
    info->ret_type = ret_type;
    info->ret_ptr_depth = ret_ptr_depth;
    info->ret_struct_size = ret_struct_size;

    var extra_opr2: u64 = 0;
    if (extra_dst != 0) { extra_opr2 = ssa_operand_reg(extra_dst); }
    var call_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_CALL, dst, ssa_operand_const(info_ptr), extra_opr2);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)call_ptr2);
    return dst;
}

func builder_emit_method_call_sret(ctx: *BuilderCtx, mc: *AstMethodCall, addr_reg: u64) -> u64 {
    if (addr_reg == 0) { return 0; }
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
        var resolved_info: *NameInfo = (*NameInfo)resolved;
        resolved_ptr = resolved_info->ptr;
        resolved_len = resolved_info->len;
    }

    var args: u64 = mc->args_vec;
    var nargs: u64 = 0;
    if (args != 0) { nargs = vec_len(args); }
    var arg_regs: u64 = vec_new(nargs * 2 + 2);
    vec_push(arg_regs, addr_reg);
    var recv_addr: u64 = builder_lvalue_addr(ctx, receiver);
    vec_push(arg_regs, recv_addr);
    for (var i: u64 = 0; i < nargs; i++) {
        var arg: u64 = vec_get(args, i);
        builder_append_call_arg(ctx, arg_regs, arg);
    }
    var total_regs: u64 = vec_len(arg_regs);

    var ret_type: u64 = TYPE_STRUCT;
    var ret_ptr_depth: u64 = 0;
    var ret_struct_size: u64 = 0;
    var ret_ti_ptr: u64 = get_expr_type_with_symtab((u64)mc, ctx->symtab);
    if (ret_ti_ptr != 0) {
        var ret_ti: *TypeInfo = (*TypeInfo)ret_ti_ptr;
        ret_type = ret_ti->type_kind;
        ret_ptr_depth = ret_ti->ptr_depth;
        if (ret_type == TYPE_STRUCT && ret_ptr_depth == 0) {
            ret_struct_size = sizeof_type(TYPE_STRUCT, 0, ret_ti->struct_name_ptr, ret_ti->struct_name_len);
        }
    }

    var info_ptr: u64 = heap_alloc(sizeof(SSACallInfo));
    var info: *SSACallInfo = (*SSACallInfo)info_ptr;
    info->name_ptr = resolved_ptr;
    info->name_len = resolved_len;
    info->args_vec = arg_regs;
    info->nargs = total_regs;
    info->ret_type = ret_type;
    info->ret_ptr_depth = ret_ptr_depth;
    info->ret_struct_size = ret_struct_size;

    var call_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_CALL, 0, ssa_operand_const(info_ptr), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)call_ptr2);
    return 0;
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
        var resolved_info: *NameInfo = (*NameInfo)resolved;
        resolved_ptr = resolved_info->ptr;
        resolved_len = resolved_info->len;
    }

    var args: u64 = mc->args_vec;
    var nargs: u64 = 0;
    if (args != 0) { nargs = vec_len(args); }
    var arg_regs: u64 = vec_new(nargs * 2 + 1);
    var recv_addr: u64 = builder_lvalue_addr(ctx, receiver);
    vec_push(arg_regs, recv_addr);
    for (var i: u64 = 0; i < nargs; i++) {
        var arg: u64 = vec_get(args, i);
        builder_append_call_arg(ctx, arg_regs, arg);
    }
    var total_regs: u64 = vec_len(arg_regs);

    var ret_type: u64 = TYPE_I64;
    var ret_ptr_depth: u64 = 0;
    var ret_struct_size: u64 = 0;
    var ret_ti_ptr: u64 = get_expr_type_with_symtab((u64)mc, ctx->symtab);
    if (ret_ti_ptr != 0) {
        var ret_ti: *TypeInfo = (*TypeInfo)ret_ti_ptr;
        ret_type = ret_ti->type_kind;
        ret_ptr_depth = ret_ti->ptr_depth;
        if (ret_type == TYPE_STRUCT && ret_ptr_depth == 0) {
            ret_struct_size = sizeof_type(TYPE_STRUCT, 0, ret_ti->struct_name_ptr, ret_ti->struct_name_len);
        }
    }

    var info_ptr: u64 = heap_alloc(sizeof(SSACallSliceStoreInfo));
    var info: *SSACallSliceStoreInfo = (*SSACallSliceStoreInfo)info_ptr;
    info->is_ptr = 0;
    info->name_ptr = resolved_ptr;
    info->name_len = resolved_len;
    info->callee_reg = 0;
    info->args_vec = arg_regs;
    info->nargs = total_regs;
    info->ret_type = ret_type;
    info->ret_ptr_depth = ret_ptr_depth;

    var call_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_CALL_SLICE_STORE, 0, ssa_operand_const(info_ptr), ssa_operand_reg(addr_reg));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)call_ptr2);
    return 0;
}

func builder_emit_call_ptr(ctx: *BuilderCtx, cp: *AstCallPtr, dst: u64, extra_dst: u64) -> u64 {
    var args: u64 = cp->args_vec;
    var nargs: u64 = 0;
    if (args != 0) { nargs = vec_len(args); }
    var arg_regs: u64 = vec_new(nargs * 2);
    for (var i: u64 = 0; i < nargs; i++) {
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
                var resolved_info: *NameInfo = (*NameInfo)resolved;
                resolved_ptr = resolved_info->ptr;
                resolved_len = resolved_info->len;
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
    var ret_struct_size: u64 = 0;
    var ret_ti_ptr: u64 = get_expr_type_with_symtab((u64)cp, ctx->symtab);
    if (ret_ti_ptr != 0) {
        var ret_ti: *TypeInfo = (*TypeInfo)ret_ti_ptr;
        ret_type = ret_ti->type_kind;
        ret_ptr_depth = ret_ti->ptr_depth;
        if (ret_type == TYPE_STRUCT && ret_ptr_depth == 0) {
            ret_struct_size = sizeof_type(TYPE_STRUCT, 0, ret_ti->struct_name_ptr, ret_ti->struct_name_len);
        }
    }

    var info_ptr: u64 = heap_alloc(sizeof(SSACallPtrInfo));
    var info: *SSACallPtrInfo = (*SSACallPtrInfo)info_ptr;
    info->callee_reg = callee_reg;
    info->args_vec = arg_regs;
    info->nargs = total_regs;
    info->ret_type = ret_type;
    info->ret_ptr_depth = ret_ptr_depth;
    info->ret_struct_size = ret_struct_size;

    var extra_opr3: u64 = 0;
    if (extra_dst != 0) { extra_opr3 = ssa_operand_reg(extra_dst); }
    var call_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_CALL_PTR, dst, ssa_operand_const(info_ptr), extra_opr3);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)call_ptr);
    return dst;
}

func builder_emit_call_ptr_sret(ctx: *BuilderCtx, cp: *AstCallPtr, addr_reg: u64) -> u64 {
    if (addr_reg == 0) { return 0; }
    var callee_reg: u64 = build_expr(ctx, cp->callee);
    var args: u64 = cp->args_vec;
    var nargs: u64 = 0;
    if (args != 0) { nargs = vec_len(args); }
    var arg_regs: u64 = vec_new(nargs * 2 + 1);
    vec_push(arg_regs, addr_reg);
    for (var i: u64 = 0; i < nargs; i++) {
        var arg: u64 = vec_get(args, i);
        builder_append_call_arg(ctx, arg_regs, arg);
    }
    var total_regs: u64 = vec_len(arg_regs);

    var ret_type: u64 = TYPE_STRUCT;
    var ret_ptr_depth: u64 = 0;
    var ret_struct_size: u64 = 0;
    var ret_ti_ptr: u64 = get_expr_type_with_symtab((u64)cp, ctx->symtab);
    if (ret_ti_ptr != 0) {
        var ret_ti: *TypeInfo = (*TypeInfo)ret_ti_ptr;
        ret_type = ret_ti->type_kind;
        ret_ptr_depth = ret_ti->ptr_depth;
        if (ret_type == TYPE_STRUCT && ret_ptr_depth == 0) {
            ret_struct_size = sizeof_type(TYPE_STRUCT, 0, ret_ti->struct_name_ptr, ret_ti->struct_name_len);
        }
    }

    var info_ptr: u64 = heap_alloc(sizeof(SSACallPtrInfo));
    var info: *SSACallPtrInfo = (*SSACallPtrInfo)info_ptr;
    info->callee_reg = callee_reg;
    info->args_vec = arg_regs;
    info->nargs = total_regs;
    info->ret_type = ret_type;
    info->ret_ptr_depth = ret_ptr_depth;
    info->ret_struct_size = ret_struct_size;

    var call_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_CALL_PTR, 0, ssa_operand_const(info_ptr), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)call_ptr);
    return 0;
}

func builder_emit_call_ptr_slice_store(ctx: *BuilderCtx, cp: *AstCallPtr, addr_reg: u64) -> u64 {
    var args: u64 = cp->args_vec;
    var nargs: u64 = 0;
    if (args != 0) { nargs = vec_len(args); }
    var arg_regs: u64 = vec_new(nargs * 2);
    for (var i: u64 = 0; i < nargs; i++) {
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
                var resolved_info: *NameInfo = (*NameInfo)resolved;
                resolved_ptr = resolved_info->ptr;
                resolved_len = resolved_info->len;
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
    var ret_struct_size: u64 = 0;
    var ret_ti_ptr: u64 = get_expr_type_with_symtab((u64)cp, ctx->symtab);
    if (ret_ti_ptr != 0) {
        var ret_ti: *TypeInfo = (*TypeInfo)ret_ti_ptr;
        ret_type = ret_ti->type_kind;
        ret_ptr_depth = ret_ti->ptr_depth;
        if (ret_type == TYPE_STRUCT && ret_ptr_depth == 0) {
            ret_struct_size = sizeof_type(TYPE_STRUCT, 0, ret_ti->struct_name_ptr, ret_ti->struct_name_len);
        }
    }

    var info_ptr: u64 = heap_alloc(sizeof(SSACallSliceStoreInfo));
    var info: *SSACallSliceStoreInfo = (*SSACallSliceStoreInfo)info_ptr;
    info->is_ptr = 1;
    info->name_ptr = 0;
    info->name_len = 0;
    info->callee_reg = callee_reg;
    info->args_vec = arg_regs;
    info->nargs = total_regs;
    info->ret_type = ret_type;
    info->ret_ptr_depth = ret_ptr_depth;

    var call_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_CALL_SLICE_STORE, 0, ssa_operand_const(info_ptr), ssa_operand_reg(addr_reg));
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
                var resolved_info2: *NameInfo = (*NameInfo)resolved2;
                resolved_ptr2 = resolved_info2->ptr;
                resolved_len2 = resolved_info2->len;
            }
            return builder_new_lea_func(ctx, resolved_ptr2, resolved_len2);
        }
        var resolved_ptr: u64 = idn->name_ptr;
        var resolved_len: u64 = idn->name_len;
        var resolved: u64 = resolve_name(idn->name_ptr, idn->name_len);
        if (resolved != 0) {
            var resolved_info: *NameInfo = (*NameInfo)resolved;
            resolved_ptr = resolved_info->ptr;
            resolved_len = resolved_info->len;
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
        var addr_reg: u64 = build_expr(ctx, d->operand);
        var op_ti_ptr: u64 = get_expr_type_with_symtab(d->operand, ctx->symtab);
        if (op_ti_ptr != 0) {
            var op_ti: *TypeInfo = (*TypeInfo)op_ti_ptr;
            if (op_ti->is_tagged == 1) {
                addr_reg = builder_mask_tagged_ptr(ctx, addr_reg);
            }
        }
        return addr_reg;
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
        if (bt->ptr_depth > 0 && bt->is_tagged == 1) {
            base_ptr = builder_mask_tagged_ptr(ctx, base_ptr);
        }
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
        var addr_reg2: u64 = build_expr(ctx, un->operand);
        var op_ti_ptr2: u64 = get_expr_type_with_symtab(un->operand, ctx->symtab);
        if (op_ti_ptr2 != 0) {
            var op_ti2: *TypeInfo = (*TypeInfo)op_ti_ptr2;
            if (op_ti2->is_tagged == 1) {
                addr_reg2 = builder_mask_tagged_ptr(ctx, addr_reg2);
            }
        }
        return addr_reg2;
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
    if (op == SSA_OP_JMP || op == SSA_OP_BR || op == SSA_OP_RET || op == SSA_OP_RET_SLICE_HEAP) { return 1; }
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

func builder_scale_ptr_arith(ctx: *BuilderCtx, left_expr: u64, op: u64, rhs_reg: u64) -> u64 {
    if (op != TOKEN_PLUS && op != TOKEN_MINUS) { return rhs_reg; }
    var left_ti_ptr: u64 = get_expr_type_with_symtab(left_expr, ctx->symtab);
    if (left_ti_ptr == 0) { return rhs_reg; }
    var left_ti: *TypeInfo = (*TypeInfo)left_ti_ptr;
    if (left_ti->ptr_depth == 0) { return rhs_reg; }
    var elem_size: u64 = get_pointee_size(left_ti->type_kind, left_ti->ptr_depth);
    if (elem_size <= 1) { return rhs_reg; }
    var size_reg: u64 = build_const(ctx, elem_size);
    var scaled_reg: u64 = builder_new_reg(ctx);
    var mul_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_MUL, scaled_reg, ssa_operand_reg(rhs_reg), ssa_operand_reg(size_reg));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)mul_ptr);
    return scaled_reg;
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
        var info: *PtrLen = (*PtrLen)heap_alloc(sizeof(PtrLen));
        info->ptr = s->str_ptr;
        info->len = s->str_len;
        var reg_id: u64 = builder_new_reg(ctx);
        var inst_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_LEA_STR, reg_id, ssa_operand_const((u64)info), 0);
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr);
        return reg_id;
    }

    if (kind == AST_IDENT) {
        var idn: *AstIdent = (*AstIdent)node;
        var offset: u64 = symtab_find(ctx->symtab, idn->name_ptr, idn->name_len);
        if (offset != 0) {
            var var_type_ptr: u64 = symtab_get_type(ctx->symtab, idn->name_ptr, idn->name_len);
            if (var_type_ptr != 0) {
                var var_ti: *TypeInfo = (*TypeInfo)var_type_ptr;
                if (var_ti->ptr_depth == 0) {
                    if (var_ti->type_kind == TYPE_ARRAY || var_ti->array_len != 0) {
                        return builder_new_lea_local(ctx, offset);
                    }
                }
            }
            var var_id: u64 = builder_get_var_id(ctx, idn->name_ptr, idn->name_len);
            var reg_id: u64 = builder_new_reg(ctx);
            var inst_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_LOAD, reg_id, ssa_operand_const(var_id), 0);
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr);
            return reg_id;
        }
        var const_encoded: u64 = builder_get_const(ctx, idn->name_ptr, idn->name_len);
        if (const_encoded != 0) {
            return build_const(ctx, const_encoded - 1);
        }
        var resolved_ptr: u64 = idn->name_ptr;
        var resolved_len: u64 = idn->name_len;
        var resolved: u64 = resolve_name(idn->name_ptr, idn->name_len);
        if (resolved != 0) {
            var resolved_info: *NameInfo = (*NameInfo)resolved;
            resolved_ptr = resolved_info->ptr;
            resolved_len = resolved_info->len;
        }
        var c_result: u64 = compiler_find_const(resolved_ptr, resolved_len);
        var c: *ConstResult = (*ConstResult)c_result;
        if (c->found != 0) {
            return build_const(ctx, c->value);
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
        rhs_reg = builder_scale_ptr_arith(ctx, bin->left, bin->op, rhs_reg);
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

        if (op == TOKEN_TILDE) {
            var all_ones_reg: u64 = build_const(ctx, -1);
            var dst3: u64 = builder_new_reg(ctx);
            var inst_ptr5: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_XOR, dst3, ssa_operand_reg(val_reg), ssa_operand_reg(all_ones_reg));
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)inst_ptr5);
            return dst3;
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
        var op_ti_ptr: u64 = get_expr_type_with_symtab(d8->operand, ctx->symtab);
        if (op_ti_ptr != 0) {
            var op_ti: *TypeInfo = (*TypeInfo)op_ti_ptr;
            if (op_ti->is_tagged == 1) {
                addr_reg = builder_mask_tagged_ptr(ctx, addr_reg);
            }
        }
        return builder_load_by_size(ctx, addr_reg, 1);
    }

    if (kind == AST_DEREF) {
        var d: *AstDeref = (*AstDeref)node;
        var addr_reg2: u64 = build_expr(ctx, d->operand);
        var op_ti_ptr2: u64 = get_expr_type_with_symtab(d->operand, ctx->symtab);
        if (op_ti_ptr2 != 0) {
            var op_ti2: *TypeInfo = (*TypeInfo)op_ti_ptr2;
            if (op_ti2->is_tagged == 1) {
                addr_reg2 = builder_mask_tagged_ptr(ctx, addr_reg2);
            }
        }
        var size2: u64 = builder_type_size_from_expr(ctx, node);
        return builder_load_by_size(ctx, addr_reg2, size2);
    }

    if (kind == AST_INDEX) {
        var addr_reg3: u64 = builder_lvalue_addr(ctx, node);
        var size3: u64 = builder_type_size_from_expr(ctx, node);
        return builder_load_by_size(ctx, addr_reg3, size3);
    }

    if (kind == AST_MEMBER_ACCESS) {
        var m: *AstMemberAccess = (*AstMemberAccess)node;
        var obj: u64 = m->object;
        var obj_kind: u64 = ast_kind(obj);
        var fp_struct_def: u64 = 0;
        var fp_struct_name_ptr: u64 = 0;
        var fp_struct_name_len: u64 = 0;

        if (obj_kind == AST_CALL_PTR) {
            var cp_fp: *AstCallPtr = (*AstCallPtr)obj;
            var callee_fp: u64 = cp_fp->callee;
            if (ast_kind(callee_fp) == AST_IDENT) {
                var idn_fp: *AstIdent = (*AstIdent)callee_fp;
                var info_fp: u64 = builder_get_func_ptr(ctx, idn_fp->name_ptr, idn_fp->name_len);
                if (info_fp != 0) {
                    var fp_info: *PtrLen = (*PtrLen)info_fp;
                    fp_struct_name_ptr = fp_info->ptr;
                    fp_struct_name_len = fp_info->len;
                    fp_struct_def = get_struct_def(fp_struct_name_ptr, fp_struct_name_len);
                }
            }
        }

        // Handle struct return from call directly
        if (obj_kind == AST_CALL) {
            var call: *AstCall = (*AstCall)obj;
            var fn_ptr: u64 = compiler_get_func(call->name_ptr, call->name_len);
            if (fn_ptr == 0) {
                var info_fp2: u64 = builder_get_func_ptr(ctx, call->name_ptr, call->name_len);
                if (info_fp2 != 0) {
                        var fp_info2: *PtrLen = (*PtrLen)info_fp2;
                        var fp_struct_name_ptr2: u64 = fp_info2->ptr;
                        var fp_struct_name_len2: u64 = fp_info2->len;
                    var fp_struct_def2: u64 = get_struct_def(fp_struct_name_ptr2, fp_struct_name_len2);
                    if (fp_struct_def2 != 0) {
                        var callee_tmp: u64 = ast_ident(call->name_ptr, call->name_len);
                        var cp_tmp: u64 = ast_call_ptr(callee_tmp, call->args_vec);
                        var struct_size_fp2: u64 = builder_struct_size_from_def(fp_struct_def2);
                        if (struct_size_fp2 == 0) {
                            struct_size_fp2 = sizeof_type(TYPE_STRUCT, 0, fp_struct_name_ptr2, fp_struct_name_len2);
                        }
                        if (struct_size_fp2 > 16) {
                            var field_offset_fp3: u64 = get_field_offset(fp_struct_def2, m->member_ptr, m->member_len);
                            var field_size_fp3: u64 = builder_type_size_from_expr(ctx, node);
                            var temp_offset_fp3: u64 = symtab_add(ctx->symtab, 0, 0, TYPE_STRUCT, 0, struct_size_fp2);
                            var temp_addr_fp3: u64 = builder_new_lea_local(ctx, temp_offset_fp3);
                            if (ctx->debug_mode != 0) {
                                emit("[DEBUG] ssa member access call->ptr sret size=", 52);
                                print_u64(struct_size_fp2);
                                emit("\n", 1);
                            }
                            builder_emit_call_ptr_sret(ctx, (*AstCallPtr)cp_tmp, temp_addr_fp3);
                            var field_addr_fp3: u64 = temp_addr_fp3;
                            if (field_offset_fp3 != 0) {
                                var off_reg_fp3: u64 = build_const(ctx, field_offset_fp3);
                                var addr_fp3: u64 = builder_new_reg(ctx);
                                var add_ptr_fp3: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, addr_fp3, ssa_operand_reg(temp_addr_fp3), ssa_operand_reg(off_reg_fp3));
                                ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr_fp3);
                                field_addr_fp3 = addr_fp3;
                            }
                            return builder_load_by_size(ctx, field_addr_fp3, field_size_fp3);
                        }
                        if (struct_size_fp2 <= 16) {
                            var field_offset_fp4: u64 = get_field_offset(fp_struct_def2, m->member_ptr, m->member_len);
                            var field_size_fp4: u64 = builder_type_size_from_expr(ctx, node);
                            if (field_offset_fp4 + field_size_fp4 <= 8) {
                                var lo_reg_fp3: u64 = builder_new_reg(ctx);
                                builder_emit_call_ptr(ctx, (*AstCallPtr)cp_tmp, lo_reg_fp3, 0);
                                if (field_offset_fp4 == 0) { return lo_reg_fp3; }
                                var shift_amt_fp3: u64 = field_offset_fp4 * 8;
                                return builder_shift_right(ctx, lo_reg_fp3, shift_amt_fp3);
                            } else if (field_offset_fp4 >= 8 && field_offset_fp4 + field_size_fp4 <= 16) {
                                var lo_reg_fp4: u64 = builder_new_reg(ctx);
                                var hi_reg_fp2: u64 = builder_new_reg(ctx);
                                builder_emit_call_ptr(ctx, (*AstCallPtr)cp_tmp, lo_reg_fp4, hi_reg_fp2);
                                if (field_offset_fp4 == 8) { return hi_reg_fp2; }
                                var shift_amt_fp4: u64 = (field_offset_fp4 - 8) * 8;
                                return builder_shift_right(ctx, hi_reg_fp2, shift_amt_fp4);
                            }
                        }
                    }
                }
            }
            if (fn_ptr != 0) {
                var fn: *AstFunc = (*AstFunc)fn_ptr;
                if (fn->ret_type == TYPE_STRUCT && fn->ret_ptr_depth == 0) {
                    var struct_size: u64 = sizeof_type(TYPE_STRUCT, 0, fn->ret_struct_name_ptr, fn->ret_struct_name_len);
                    if (struct_size <= 16) {
                        var struct_def: u64 = get_struct_def(fn->ret_struct_name_ptr, fn->ret_struct_name_len);
                        if (struct_def != 0) {
                            var field_offset: u64 = get_field_offset(struct_def, m->member_ptr, m->member_len);
                            var field_size: u64 = builder_type_size_from_expr(ctx, node);

                            if (field_offset + field_size <= 8) {
                                var lo_reg: u64 = builder_new_reg(ctx);
                                builder_emit_call(ctx, call, lo_reg, 0);
                                if (field_offset == 0) { return lo_reg; }
                                var shift_amt: u64 = field_offset * 8;
                                return builder_shift_right(ctx, lo_reg, shift_amt);
                            } else if (field_offset >= 8 && field_offset + field_size <= 16) {
                                var lo_reg2: u64 = builder_new_reg(ctx);
                                var hi_reg: u64 = builder_new_reg(ctx);
                                builder_emit_call(ctx, call, lo_reg2, hi_reg);
                                if (field_offset == 8) { return hi_reg; }
                                var shift_amt2: u64 = (field_offset - 8) * 8;
                                return builder_shift_right(ctx, hi_reg, shift_amt2);
                            }
                        }
                    } else if (struct_size > 16) {
                        var struct_def_big: u64 = get_struct_def(fn->ret_struct_name_ptr, fn->ret_struct_name_len);
                        if (struct_def_big != 0) {
                            var field_offset_big: u64 = get_field_offset(struct_def_big, m->member_ptr, m->member_len);
                            var field_size_big: u64 = builder_type_size_from_expr(ctx, node);
                            var temp_offset_big: u64 = symtab_add(ctx->symtab, 0, 0, TYPE_STRUCT, 0, struct_size);
                            var temp_addr_big: u64 = builder_new_lea_local(ctx, temp_offset_big);
                            if (ctx->debug_mode != 0) {
                                emit("[DEBUG] ssa member access call sret size=", 49);
                                print_u64(struct_size);
                                emit("\n", 1);
                            }
                            builder_emit_call_sret(ctx, call, temp_addr_big);
                            var field_addr_big: u64 = temp_addr_big;
                            if (field_offset_big != 0) {
                                var off_reg_big: u64 = build_const(ctx, field_offset_big);
                                var addr_big2: u64 = builder_new_reg(ctx);
                                var add_ptr_big: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, addr_big2, ssa_operand_reg(temp_addr_big), ssa_operand_reg(off_reg_big));
                                ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr_big);
                                field_addr_big = addr_big2;
                            }
                            return builder_load_by_size(ctx, field_addr_big, field_size_big);
                        }
                    }
                }
            }
        }

        var ti_ptr: u64 = get_expr_type_with_symtab(obj, ctx->symtab);
        if (ti_ptr != 0) {
            var ti: *TypeInfo = (*TypeInfo)ti_ptr;
            if (ti->ptr_depth == 0 && ti->type_kind == TYPE_STRUCT) {
                var struct_def: u64 = ti->struct_def;
                if (struct_def == 0 && ti->struct_name_ptr != 0) {
                    struct_def = get_struct_def(ti->struct_name_ptr, ti->struct_name_len);
                }
                if (struct_def == 0 && (obj_kind == AST_CALL || obj_kind == AST_CALL_PTR)) {
                    if (obj_kind == AST_CALL) {
                        var call_obj: *AstCall = (*AstCall)obj;
                        var fn_ptr_obj: u64 = compiler_get_func(call_obj->name_ptr, call_obj->name_len);
                        if (fn_ptr_obj != 0) {
                            var fn_obj: *AstFunc = (*AstFunc)fn_ptr_obj;
                            if (fn_obj->ret_struct_name_ptr != 0) {
                                struct_def = get_struct_def(fn_obj->ret_struct_name_ptr, fn_obj->ret_struct_name_len);
                                ti->struct_name_ptr = fn_obj->ret_struct_name_ptr;
                                ti->struct_name_len = fn_obj->ret_struct_name_len;
                            }
                        }
                    } else {
                        var cp_obj: *AstCallPtr = (*AstCallPtr)obj;
                        var callee_obj: u64 = cp_obj->callee;
                        var name_ptr_obj: u64 = 0;
                        var name_len_obj: u64 = 0;
                        var ck_obj: u64 = ast_kind(callee_obj);
                        if (ck_obj == AST_IDENT) {
                            var idn_obj: *AstIdent = (*AstIdent)callee_obj;
                            name_ptr_obj = idn_obj->name_ptr;
                            name_len_obj = idn_obj->name_len;
                        } else if (ck_obj == AST_ADDR_OF) {
                            var a_obj: *AstAddrOf = (*AstAddrOf)callee_obj;
                            if (ast_kind(a_obj->operand) == AST_IDENT) {
                                var idn_obj2: *AstIdent = (*AstIdent)a_obj->operand;
                                name_ptr_obj = idn_obj2->name_ptr;
                                name_len_obj = idn_obj2->name_len;
                            }
                        }
                        if (name_ptr_obj != 0) {
                            var resolved_ptr_obj: u64 = name_ptr_obj;
                            var resolved_len_obj: u64 = name_len_obj;
                            var resolved_obj: u64 = resolve_name(name_ptr_obj, name_len_obj);
                            if (resolved_obj != 0) {
                                var resolved_info_obj: *NameInfo = (*NameInfo)resolved_obj;
                                resolved_ptr_obj = resolved_info_obj->ptr;
                                resolved_len_obj = resolved_info_obj->len;
                            }
                            var fn_ptr_obj2: u64 = compiler_get_func(resolved_ptr_obj, resolved_len_obj);
                            if (fn_ptr_obj2 != 0) {
                                var fn_obj2: *AstFunc = (*AstFunc)fn_ptr_obj2;
                                if (fn_obj2->ret_struct_name_ptr != 0) {
                                    struct_def = get_struct_def(fn_obj2->ret_struct_name_ptr, fn_obj2->ret_struct_name_len);
                                    ti->struct_name_ptr = fn_obj2->ret_struct_name_ptr;
                                    ti->struct_name_len = fn_obj2->ret_struct_name_len;
                                }
                            }
                        }
                    }
                }
                if (struct_def != 0 && (obj_kind == AST_CALL || obj_kind == AST_METHOD_CALL || obj_kind == AST_CALL_PTR)) {

                    var struct_size: u64 = sizeof_type(TYPE_STRUCT, 0, ti->struct_name_ptr, ti->struct_name_len);
                    if (struct_def != 0) {
                        var def_size2: u64 = builder_struct_size_from_def(struct_def);
                        if (def_size2 > struct_size) { struct_size = def_size2; }
                    }
                    if (struct_size > 16) {
                        var field_offset_big: u64 = get_field_offset(struct_def, m->member_ptr, m->member_len);
                        var field_size_big: u64 = builder_type_size_from_expr(ctx, node);
                        var temp_offset_big: u64 = symtab_add(ctx->symtab, 0, 0, TYPE_STRUCT, 0, struct_size);
                        var temp_addr_big: u64 = builder_new_lea_local(ctx, temp_offset_big);
                        if (ctx->debug_mode != 0) {
                            emit("[DEBUG] ssa member access sret struct size=", 49);
                            print_u64(struct_size);
                            emit("\n", 1);
                        }

                        if (obj_kind == AST_CALL) {
                            builder_emit_call_sret(ctx, (*AstCall)obj, temp_addr_big);
                        } else if (obj_kind == AST_METHOD_CALL) {
                            builder_emit_method_call_sret(ctx, (*AstMethodCall)obj, temp_addr_big);
                        } else {
                            builder_emit_call_ptr_sret(ctx, (*AstCallPtr)obj, temp_addr_big);
                        }

                        var field_addr: u64 = temp_addr_big;
                        if (field_offset_big != 0) {
                            var off_reg_big: u64 = build_const(ctx, field_offset_big);
                            var addr_big2: u64 = builder_new_reg(ctx);
                            var add_ptr_big: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, addr_big2, ssa_operand_reg(temp_addr_big), ssa_operand_reg(off_reg_big));
                            ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr_big);
                            field_addr = addr_big2;
                        }
                        return builder_load_by_size(ctx, field_addr, field_size_big);
                    }
                    if (struct_size <= 16) {
                        var field_offset: u64 = get_field_offset(struct_def, m->member_ptr, m->member_len);
                        var field_size: u64 = builder_type_size_from_expr(ctx, node);

                        // Only handle simple cases: field fully within lo or hi register
                        // Field spans both registers → fallback to memory
                        if (field_offset + field_size <= 8) {
                            // Field in lo register (rax)
                            var lo_reg: u64 = builder_new_reg(ctx);
                            if (obj_kind == AST_CALL) {
                                builder_emit_call(ctx, (*AstCall)obj, lo_reg, 0);
                            } else if (obj_kind == AST_METHOD_CALL) {
                                builder_emit_method_call(ctx, (*AstMethodCall)obj, lo_reg, 0);
                            } else {
                                builder_emit_call_ptr(ctx, (*AstCallPtr)obj, lo_reg, 0);
                            }
                            if (field_offset == 0) { return lo_reg; }
                            // Need to shift/extract if field not at offset 0
                            var shift_amt: u64 = field_offset * 8;
                            var shifted: u64 = builder_shift_right(ctx, lo_reg, shift_amt);
                            return shifted;
                        } else if (field_offset >= 8 && field_offset + field_size <= 16) {
                            // Field in hi register (rdx)
                            var lo_reg: u64 = builder_new_reg(ctx);
                            var hi_reg: u64 = builder_new_reg(ctx);
                            if (obj_kind == AST_CALL) {
                                builder_emit_call(ctx, (*AstCall)obj, lo_reg, hi_reg);
                            } else if (obj_kind == AST_METHOD_CALL) {
                                builder_emit_method_call(ctx, (*AstMethodCall)obj, lo_reg, hi_reg);
                            } else {
                                builder_emit_call_ptr(ctx, (*AstCallPtr)obj, lo_reg, hi_reg);
                            }
                            if (field_offset == 8) { return hi_reg; }
                            // Need to shift/extract if field not at offset 8
                            var shift_amt2: u64 = (field_offset - 8) * 8;
                            var shifted2: u64 = builder_shift_right(ctx, hi_reg, shift_amt2);
                            return shifted2;
                        }
                        // Field spans both registers - fallback to memory-based access
                    }
                }
            }
            if (ti->ptr_depth > 0 && ti->is_tagged == 1 && ti->tag_layout_ptr != 0) {
                var layout_def: u64 = get_struct_def(ti->tag_layout_ptr, ti->tag_layout_len);
                if (layout_def != 0) {
                    var layout_info: *AstStructDef = (*AstStructDef)layout_def;
                    var packed_flag: u64 = layout_info->is_packed;
                    if (packed_flag == 1) {
                        var total_bits: u64 = builder_get_packed_layout_total_bits(layout_def);
                        var field_offset: u64 = builder_get_packed_field_bit_offset(layout_def, m->member_ptr, m->member_len);
                        var field_width: u64 = builder_get_packed_field_bit_width(layout_def, m->member_ptr, m->member_len);
                        var start_bit: u64 = 64 - total_bits;
                        var shift_bits: u64 = start_bit + field_offset;
                        var reg_val: u64 = build_expr(ctx, obj);
                        reg_val = builder_shift_right(ctx, reg_val, shift_bits);
                        reg_val = builder_mask_low_bits(ctx, reg_val, field_width);
                        return reg_val;
                    }
                }
            }
            if (ti->ptr_depth == 0 && ti->type_kind == TYPE_STRUCT) {
                var struct_def2: u64 = ti->struct_def;
                if (struct_def2 == 0 && ti->struct_name_ptr != 0) {
                    struct_def2 = get_struct_def(ti->struct_name_ptr, ti->struct_name_len);
                }
                if (struct_def2 != 0) {
                    var struct_info2: *AstStructDef = (*AstStructDef)struct_def2;
                    var packed_flag2: u64 = struct_info2->is_packed;
                    if (packed_flag2 == 1) {
                        var total_bits2: u64 = builder_get_packed_layout_total_bits(struct_def2);
                        var field_offset2: u64 = builder_get_packed_field_bit_offset(struct_def2, m->member_ptr, m->member_len);
                        var field_width2: u64 = builder_get_packed_field_bit_width(struct_def2, m->member_ptr, m->member_len);
                        var shift_bits2: u64 = field_offset2;
                        var size_bytes2: u64 = (total_bits2 + 7) / 8;
                        var base_addr: u64 = builder_lvalue_addr(ctx, obj);
                        var raw_val: u64 = builder_load_by_size(ctx, base_addr, size_bytes2);
                        raw_val = builder_shift_right(ctx, raw_val, shift_bits2);
                        raw_val = builder_mask_low_bits(ctx, raw_val, field_width2);
                        return raw_val;
                    }
                }
            }
        }

        if (fp_struct_def != 0 && obj_kind == AST_CALL_PTR) {
            var struct_size_fp: u64 = builder_struct_size_from_def(fp_struct_def);
            if (struct_size_fp == 0) {
                struct_size_fp = sizeof_type(TYPE_STRUCT, 0, fp_struct_name_ptr, fp_struct_name_len);
            }
            if (struct_size_fp > 16) {
                var field_offset_fp: u64 = get_field_offset(fp_struct_def, m->member_ptr, m->member_len);
                var field_size_fp: u64 = builder_type_size_from_expr(ctx, node);
                var temp_offset_fp: u64 = symtab_add(ctx->symtab, 0, 0, TYPE_STRUCT, 0, struct_size_fp);
                var temp_addr_fp: u64 = builder_new_lea_local(ctx, temp_offset_fp);
                if (ctx->debug_mode != 0) {
                    emit("[DEBUG] ssa member access call_ptr sret size=", 52);
                    print_u64(struct_size_fp);
                    emit("\n", 1);
                }
                builder_emit_call_ptr_sret(ctx, (*AstCallPtr)obj, temp_addr_fp);
                var field_addr_fp: u64 = temp_addr_fp;
                if (field_offset_fp != 0) {
                    var off_reg_fp: u64 = build_const(ctx, field_offset_fp);
                    var addr_fp2: u64 = builder_new_reg(ctx);
                    var add_ptr_fp: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, addr_fp2, ssa_operand_reg(temp_addr_fp), ssa_operand_reg(off_reg_fp));
                    ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr_fp);
                    field_addr_fp = addr_fp2;
                }
                return builder_load_by_size(ctx, field_addr_fp, field_size_fp);
            }
            if (struct_size_fp <= 16) {
                var field_offset_fp2: u64 = get_field_offset(fp_struct_def, m->member_ptr, m->member_len);
                var field_size_fp2: u64 = builder_type_size_from_expr(ctx, node);
                if (field_offset_fp2 + field_size_fp2 <= 8) {
                    var lo_reg_fp: u64 = builder_new_reg(ctx);
                    builder_emit_call_ptr(ctx, (*AstCallPtr)obj, lo_reg_fp, 0);
                    if (field_offset_fp2 == 0) { return lo_reg_fp; }
                    var shift_amt_fp: u64 = field_offset_fp2 * 8;
                    return builder_shift_right(ctx, lo_reg_fp, shift_amt_fp);
                } else if (field_offset_fp2 >= 8 && field_offset_fp2 + field_size_fp2 <= 16) {
                    var lo_reg_fp2: u64 = builder_new_reg(ctx);
                    var hi_reg_fp: u64 = builder_new_reg(ctx);
                    builder_emit_call_ptr(ctx, (*AstCallPtr)obj, lo_reg_fp2, hi_reg_fp);
                    if (field_offset_fp2 == 8) { return hi_reg_fp; }
                    var shift_amt_fp2: u64 = (field_offset_fp2 - 8) * 8;
                    return builder_shift_right(ctx, hi_reg_fp, shift_amt_fp2);
                }
            }
        }

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

    if (kind == AST_SIZEOF_EXPR) {
        var sz_expr: *AstSizeofExpr = (*AstSizeofExpr)node;
        var ti_ptr: u64 = get_expr_type_with_symtab(sz_expr->expr, ctx->symtab);
        var size_val2: u64 = 8;
        if (ti_ptr != 0) {
            size_val2 = sizeof_type_ex(ti_ptr);
        }
        return build_const(ctx, size_val2);
    }

    if (kind == AST_CALL) {
        var call_ptr: u64 = node;
        var dst: u64 = builder_new_reg(ctx);
        var ret_ti_ptr: u64 = get_expr_type_with_symtab(node, ctx->symtab);
        if (ret_ti_ptr != 0) {
            var ret_ti: *TypeInfo = (*TypeInfo)ret_ti_ptr;
            if (ret_ti->type_kind == TYPE_VOID && ret_ti->ptr_depth == 0) {
                dst = 0;
            }
            if (ret_ti->type_kind == TYPE_STRUCT && ret_ti->ptr_depth == 0) {
                var struct_size: u64 = sizeof_type(TYPE_STRUCT, 0, ret_ti->struct_name_ptr, ret_ti->struct_name_len);
                if (struct_size > 16) {
                    var temp_offset: u64 = symtab_add(ctx->symtab, 0, 0, TYPE_STRUCT, 0, struct_size);
                    var temp_addr: u64 = builder_new_lea_local(ctx, temp_offset);
                    builder_emit_call_sret(ctx, (*AstCall)call_ptr, temp_addr);
                    return temp_addr;
                }
            }
        }
        return builder_emit_call(ctx, (*AstCall)call_ptr, dst, 0);
    }

    if (kind == AST_CALL_PTR) {
        var cp_ptr: u64 = node;
        var dst2: u64 = builder_new_reg(ctx);
        var ret_ti_ptr2: u64 = get_expr_type_with_symtab(node, ctx->symtab);
        if (ret_ti_ptr2 != 0) {
            var ret_ti2: *TypeInfo = (*TypeInfo)ret_ti_ptr2;
            if (ret_ti2->type_kind == TYPE_VOID && ret_ti2->ptr_depth == 0) {
                dst2 = 0;
            }
            if (ret_ti2->type_kind == TYPE_STRUCT && ret_ti2->ptr_depth == 0) {
                var struct_size2: u64 = sizeof_type(TYPE_STRUCT, 0, ret_ti2->struct_name_ptr, ret_ti2->struct_name_len);
                if (struct_size2 > 16) {
                    var temp_offset2: u64 = symtab_add(ctx->symtab, 0, 0, TYPE_STRUCT, 0, struct_size2);
                    var temp_addr2: u64 = builder_new_lea_local(ctx, temp_offset2);
                    builder_emit_call_ptr_sret(ctx, (*AstCallPtr)cp_ptr, temp_addr2);
                    return temp_addr2;
                }
            }
        }
        return builder_emit_call_ptr(ctx, (*AstCallPtr)cp_ptr, dst2, 0);
    }

    if (kind == AST_METHOD_CALL) {
        var mc_ptr: u64 = node;
        var dst3: u64 = builder_new_reg(ctx);
        var ret_ti_ptr3: u64 = get_expr_type_with_symtab(node, ctx->symtab);
        if (ret_ti_ptr3 != 0) {
            var ret_ti3: *TypeInfo = (*TypeInfo)ret_ti_ptr3;
            if (ret_ti3->type_kind == TYPE_VOID && ret_ti3->ptr_depth == 0) {
                dst3 = 0;
            }
            if (ret_ti3->type_kind == TYPE_STRUCT && ret_ti3->ptr_depth == 0) {
                var struct_size3: u64 = sizeof_type(TYPE_STRUCT, 0, ret_ti3->struct_name_ptr, ret_ti3->struct_name_len);
                if (struct_size3 > 16) {
                    var temp_offset3: u64 = symtab_add(ctx->symtab, 0, 0, TYPE_STRUCT, 0, struct_size3);
                    var temp_addr3: u64 = builder_new_lea_local(ctx, temp_offset3);
                    builder_emit_method_call_sret(ctx, (*AstMethodCall)mc_ptr, temp_addr3);
                    return temp_addr3;
                }
            }
        }
        return builder_emit_method_call(ctx, (*AstMethodCall)mc_ptr, dst3, 0);
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

    for (var i: u64 = 0; i < count; i++) {
        var c_ptr: u64 = vec_get(cases, i);
        var c: *AstCase = (*AstCase)c_ptr;
        var case_bb: *SSABlock = (*SSABlock)ssa_new_block(ctx->ssa_ctx, ctx->cur_func);
        vec_push(case_blocks, (u64)case_bb);
        vec_push(case_nodes, c_ptr);
        if (c->is_default != 0) {
            default_bb = case_bb;
        }
    }

    for (var i: u64 = 0; i < count; i++) {
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
    }

    var jmp_ptr1: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_JMP, 0, ssa_operand_const(default_bb->id), 0);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)jmp_ptr1);
    ssa_add_edge(ctx->cur_block, default_bb);

    builder_push_loop(ctx, exit_bb, 0);
    for (var i: u64 = 0; i < count; i++) {
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

// ============================================
// Return Helpers
// ============================================

func builder_emit_return_slice_from_call(ctx: *BuilderCtx, expr: u64) -> u64 {
    var ptr_reg: u64 = builder_new_reg(ctx);
    var len_reg: u64 = builder_new_reg(ctx);
    var kind: u64 = ast_kind(expr);
    if (kind == AST_CALL) {
        builder_emit_call(ctx, (*AstCall)expr, ptr_reg, len_reg);
    } else if (kind == AST_METHOD_CALL) {
        builder_emit_method_call(ctx, (*AstMethodCall)expr, ptr_reg, len_reg);
    } else {
        builder_emit_call_ptr(ctx, (*AstCallPtr)expr, ptr_reg, len_reg);
    }
    var ret_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_RET, 0, ssa_operand_reg(ptr_reg), ssa_operand_reg(len_reg));
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)ret_ptr);
    return 0;
}

func builder_emit_return_struct_from_call(ctx: *BuilderCtx, expr: u64, struct_size: u64) -> u64 {
    var lo_reg: u64 = builder_new_reg(ctx);
    var hi_reg: u64 = 0;
    if (struct_size > 8) { hi_reg = builder_new_reg(ctx); }
    var kind: u64 = ast_kind(expr);
    if (kind == AST_CALL) {
        builder_emit_call(ctx, (*AstCall)expr, lo_reg, hi_reg);
    } else if (kind == AST_METHOD_CALL) {
        builder_emit_method_call(ctx, (*AstMethodCall)expr, lo_reg, hi_reg);
    } else {
        builder_emit_call_ptr(ctx, (*AstCallPtr)expr, lo_reg, hi_reg);
    }
    var ret_src2: u64 = 0;
    if (hi_reg != 0) { ret_src2 = ssa_operand_reg(hi_reg); }
    var ret_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_RET, 0, ssa_operand_reg(lo_reg), ret_src2);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)ret_ptr);
    return 0;
}

func builder_emit_return_struct_from_addr(ctx: *BuilderCtx, expr: u64, struct_size: u64) -> u64 {
    var addr_reg: u64 = builder_lvalue_addr(ctx, expr);
    if (addr_reg == 0) { return 0; }
    var head_size: u64 = struct_size;
    if (head_size > 8) { head_size = 8; }
    var lo_reg: u64 = builder_load_by_size(ctx, addr_reg, head_size);
    if (lo_reg == 0) {
        lo_reg = build_const(ctx, 0);
    }
    var hi_reg: u64 = 0;
    if (struct_size > 8) {
        var off_reg: u64 = build_const(ctx, 8);
        var addr2: u64 = builder_new_reg(ctx);
        var add_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, addr2, ssa_operand_reg(addr_reg), ssa_operand_reg(off_reg));
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr);
        var tail_size: u64 = struct_size - 8;
        if (tail_size > 8) { tail_size = 8; }
        hi_reg = builder_load_by_size(ctx, addr2, tail_size);
        if (hi_reg == 0) {
            hi_reg = build_const(ctx, 0);
        }
    }
    var ret_src2: u64 = 0;
    if (struct_size > 8) {
        if (hi_reg != 0) {
            ret_src2 = ssa_operand_reg(hi_reg);
        } else {
            var zero_reg: u64 = build_const(ctx, 0);
            ret_src2 = ssa_operand_reg(zero_reg);
        }
    }
    var ret_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_RET, 0, ssa_operand_reg(lo_reg), ret_src2);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)ret_ptr2);
    return 0;
}

func builder_build_struct_literal_scalar(ctx: *BuilderCtx, lit: *AstStructLiteral) -> u64 {
    var values: u64 = lit->values_vec;
    if (values == 0) { return build_const(ctx, 0); }
    var count: u64 = vec_len(values);
    if (count == 0) { return build_const(ctx, 0); }
    var first: u64 = vec_get(values, 0);
    if (ast_kind(first) == AST_STRUCT_LITERAL) {
        return builder_build_struct_literal_scalar(ctx, (*AstStructLiteral)first);
    }
    var reg: u64 = build_expr(ctx, first);
    if (reg == 0) { reg = build_const(ctx, 0); }
    return reg;
}

func builder_emit_return_struct_from_literal(ctx: *BuilderCtx, lit: *AstStructLiteral, struct_size: u64) -> u64 {
    var values: u64 = lit->values_vec;
    if (values == 0) {
        var zero_reg: u64 = build_const(ctx, 0);
        var ret_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_RET, 0, ssa_operand_reg(zero_reg), 0);
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)ret_ptr);
        return 0;
    }
    
    var num_values: u64 = vec_len(values);
    if (num_values == 0) {
        var zero_reg2: u64 = build_const(ctx, 0);
        var ret_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_RET, 0, ssa_operand_reg(zero_reg2), 0);
        ssa_inst_append(ctx->cur_block, (*SSAInstruction)ret_ptr2);
        return 0;
    }
    
    var struct_def: u64 = lit->struct_def;
    var first_val: u64 = 0;
    var second_val: u64 = 0;
    var first_size: u64 = 0;
    var second_size: u64 = 0;
    
    if (struct_def != 0) {
        var sd: *AstStructDef = (*AstStructDef)struct_def;
        var fields: u64 = sd->fields_vec;
        if (fields != 0 && num_values > 0) {
            var field0: *FieldDesc = (*FieldDesc)vec_get(fields, 0);
            first_size = sizeof_field_desc(field0);
            var v0: u64 = vec_get(values, 0);
            if (ast_kind(v0) == AST_STRUCT_LITERAL) {
                first_val = builder_build_struct_literal_scalar(ctx, (*AstStructLiteral)v0);
            } else {
                first_val = build_expr(ctx, v0);
            }
            if (first_val == 0) {
                first_val = build_const(ctx, 0);
            }
            
            if (struct_size > 8) {
                if (num_values > 1) {
                    if (vec_len(fields) > 1) {
                        var field1: *FieldDesc = (*FieldDesc)vec_get(fields, 1);
                        second_size = sizeof_field_desc(field1);
                    }
                    var v1: u64 = vec_get(values, 1);
                    if (ast_kind(v1) == AST_STRUCT_LITERAL) {
                        second_val = builder_build_struct_literal_scalar(ctx, (*AstStructLiteral)v1);
                    } else {
                        second_val = build_expr(ctx, v1);
                    }
                    if (second_val == 0) {
                        second_val = build_const(ctx, 0);
                    }
                } else {
                    second_val = build_const(ctx, 0);
                }
            }
        }
    } else {
        if (num_values > 0) {
            var v0b: u64 = vec_get(values, 0);
            if (ast_kind(v0b) == AST_STRUCT_LITERAL) {
                first_val = builder_build_struct_literal_scalar(ctx, (*AstStructLiteral)v0b);
            } else {
                first_val = build_expr(ctx, v0b);
            }
            if (first_val == 0) {
                first_val = build_const(ctx, 0);
            }
            first_size = 8;
            if (struct_size > 8) {
                if (num_values > 1) {
                    var v1b: u64 = vec_get(values, 1);
                    if (ast_kind(v1b) == AST_STRUCT_LITERAL) {
                        second_val = builder_build_struct_literal_scalar(ctx, (*AstStructLiteral)v1b);
                    } else {
                        second_val = build_expr(ctx, v1b);
                    }
                    if (second_val == 0) {
                        second_val = build_const(ctx, 0);
                    }
                    second_size = 8;
                } else {
                    second_val = build_const(ctx, 0);
                }
            }
        }
    }
    
    if (first_val == 0) {
        first_val = build_const(ctx, 0);
    }
    
    if (struct_size > 8 && second_val == 0) {
        second_val = build_const(ctx, 0);
    }
    
    var ret_src2: u64 = 0;
    if (struct_size > 8) {
        if (second_val != 0) {
            ret_src2 = ssa_operand_reg(second_val);
        } else {
            var zero_reg: u64 = build_const(ctx, 0);
            ret_src2 = ssa_operand_reg(zero_reg);
        }
    }
    var ret_ptr3: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_RET, 0, ssa_operand_reg(first_val), ret_src2);
    ssa_inst_append(ctx->cur_block, (*SSAInstruction)ret_ptr3);
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
            var sret_size: u64 = builder_get_sret_struct_size(ctx, es->expr);
            if (sret_size != 0) {
                var sret_offset: u64 = symtab_add(ctx->symtab, 0, 0, TYPE_STRUCT, 0, sret_size);
                var sret_addr_reg: u64 = builder_new_lea_local(ctx, sret_offset);
                builder_emit_call_sret(ctx, (*AstCall)es->expr, sret_addr_reg);
                return 0;
            }
            builder_emit_call(ctx, (*AstCall)es->expr, 0, 0);
            return 0;
        }
        if (expr_kind == AST_METHOD_CALL) {
            var sret_size2: u64 = builder_get_sret_struct_size(ctx, es->expr);
            if (sret_size2 != 0) {
                var sret_offset2: u64 = symtab_add(ctx->symtab, 0, 0, TYPE_STRUCT, 0, sret_size2);
                var sret_addr_reg2: u64 = builder_new_lea_local(ctx, sret_offset2);
                builder_emit_method_call_sret(ctx, (*AstMethodCall)es->expr, sret_addr_reg2);
                return 0;
            }
            builder_emit_method_call(ctx, (*AstMethodCall)es->expr, 0, 0);
            return 0;
        }
        if (expr_kind == AST_CALL_PTR) {
            var sret_size3: u64 = builder_get_sret_struct_size(ctx, es->expr);
            if (sret_size3 != 0) {
                var sret_offset3: u64 = symtab_add(ctx->symtab, 0, 0, TYPE_STRUCT, 0, sret_size3);
                var sret_addr_reg3: u64 = builder_new_lea_local(ctx, sret_offset3);
                builder_emit_call_ptr_sret(ctx, (*AstCallPtr)es->expr, sret_addr_reg3);
                return 0;
            }
            builder_emit_call_ptr(ctx, (*AstCallPtr)es->expr, 0, 0);
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
            if (init_kind == AST_ADDR_OF) {
                var addr_init: *AstAddrOf = (*AstAddrOf)vd->init_expr;
                if (ast_kind(addr_init->operand) == AST_IDENT) {
                    var idn_init: *AstIdent = (*AstIdent)addr_init->operand;
                    var resolved_ptr: u64 = idn_init->name_ptr;
                    var resolved_len: u64 = idn_init->name_len;
                    var resolved: u64 = resolve_name(idn_init->name_ptr, idn_init->name_len);
                    if (resolved != 0) {
                        var resolved_info: *NameInfo = (*NameInfo)resolved;
                        resolved_ptr = resolved_info->ptr;
                        resolved_len = resolved_info->len;
                    }
                    var fn_ptr_map: u64 = compiler_get_func(resolved_ptr, resolved_len);
                    if (fn_ptr_map != 0) {
                        var fn_map: *AstFunc = (*AstFunc)fn_ptr_map;
                        if (fn_map->ret_type == TYPE_STRUCT && fn_map->ret_ptr_depth == 0) {
                            builder_set_func_ptr(ctx, vd->name_ptr, vd->name_len, fn_map->ret_struct_name_ptr, fn_map->ret_struct_name_len);
                        } else {
                            builder_set_func_ptr(ctx, vd->name_ptr, vd->name_len, 0, 0);
                        }
                    } else {
                        builder_set_func_ptr(ctx, vd->name_ptr, vd->name_len, 0, 0);
                    }
                } else {
                    builder_set_func_ptr(ctx, vd->name_ptr, vd->name_len, 0, 0);
                }
            } else {
                builder_set_func_ptr(ctx, vd->name_ptr, vd->name_len, 0, 0);
            }
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
            // Handle struct-returning function calls
            if (vd->type_kind == TYPE_STRUCT && vd->ptr_depth == 0) {
                var struct_size: u64 = sizeof_type(TYPE_STRUCT, 0, vd->struct_name_ptr, vd->struct_name_len);
                if (struct_size > 0 && struct_size <= 16) {
                    if (init_kind == AST_CALL || init_kind == AST_METHOD_CALL || init_kind == AST_CALL_PTR) {
                        var offset: u64 = symtab_find(ctx->symtab, vd->name_ptr, vd->name_len);
                        if (offset == 0) {
                            // Fall back to normal handling if offset not found
                            var val_reg: u64 = build_expr(ctx, vd->init_expr);
                            var st_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_STORE, 0, ssa_operand_const(var_id), ssa_operand_reg(val_reg));
                            ssa_inst_append(ctx->cur_block, (*SSAInstruction)st_ptr);
                            return 0;
                        }
                        var base_addr: u64 = builder_new_lea_local(ctx, offset);
                        var lo_reg: u64 = builder_new_reg(ctx);
                        var hi_reg: u64 = 0;
                        if (struct_size > 8) {
                            hi_reg = builder_new_reg(ctx);
                        }
                        if (init_kind == AST_CALL) {
                            builder_emit_call(ctx, (*AstCall)vd->init_expr, lo_reg, hi_reg);
                        } else if (init_kind == AST_METHOD_CALL) {
                            builder_emit_method_call(ctx, (*AstMethodCall)vd->init_expr, lo_reg, hi_reg);
                        } else {
                            builder_emit_call_ptr(ctx, (*AstCallPtr)vd->init_expr, lo_reg, hi_reg);
                        }
                        builder_store_by_size(ctx, base_addr, lo_reg, 8);
                        if (hi_reg != 0) {
                            var off8: u64 = build_const(ctx, 8);
                            var addr2: u64 = builder_new_reg(ctx);
                            var add_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, addr2, ssa_operand_reg(base_addr), ssa_operand_reg(off8));
                            ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptr);
                            var tail_size: u64 = struct_size - 8;
                            if (tail_size > 8) { tail_size = 8; }
                            builder_store_by_size(ctx, addr2, hi_reg, tail_size);
                        }
                        return 0;
                    }
                }
                if (struct_size > 16) {
                    if (init_kind == AST_CALL || init_kind == AST_METHOD_CALL || init_kind == AST_CALL_PTR) {
                        var offset2: u64 = symtab_find(ctx->symtab, vd->name_ptr, vd->name_len);
                        if (offset2 == 0) { return 0; }
                        var base_addr2: u64 = builder_new_lea_local(ctx, offset2);
                        if (init_kind == AST_CALL) {
                            builder_emit_call_sret(ctx, (*AstCall)vd->init_expr, base_addr2);
                        } else if (init_kind == AST_METHOD_CALL) {
                            builder_emit_method_call_sret(ctx, (*AstMethodCall)vd->init_expr, base_addr2);
                        } else {
                            builder_emit_call_ptr_sret(ctx, (*AstCallPtr)vd->init_expr, base_addr2);
                        }
                        return 0;
                    }
                }
            }
            var val_reg: u64 = build_expr(ctx, vd->init_expr);
            var st_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_STORE, 0, ssa_operand_const(var_id), ssa_operand_reg(val_reg));
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)st_ptr);
        }
        return 0;
    }

    if (kind == AST_CONST_DECL) {
        var cd: *AstConstDecl = (*AstConstDecl)node;
        builder_set_const(ctx, cd->name_ptr, cd->name_len, cd->value);
        return 0;
    }

    if (kind == AST_ASSIGN) {
        var asn: *AstAssign = (*AstAssign)node;
        var target_kind: u64 = ast_kind(asn->target);
        if (target_kind == AST_IDENT && asn->value != 0) {
            var idn_tgt: *AstIdent = (*AstIdent)asn->target;
            var value_kind0: u64 = ast_kind(asn->value);
            if (value_kind0 == AST_ADDR_OF) {
                var addr_val: *AstAddrOf = (*AstAddrOf)asn->value;
                if (ast_kind(addr_val->operand) == AST_IDENT) {
                    var idn_val: *AstIdent = (*AstIdent)addr_val->operand;
                    var resolved_ptr: u64 = idn_val->name_ptr;
                    var resolved_len: u64 = idn_val->name_len;
                    var resolved: u64 = resolve_name(idn_val->name_ptr, idn_val->name_len);
                    if (resolved != 0) {
                        var resolved_info: *NameInfo = (*NameInfo)resolved;
                        resolved_ptr = resolved_info->ptr;
                        resolved_len = resolved_info->len;
                    }
                    var fn_ptr_map2: u64 = compiler_get_func(resolved_ptr, resolved_len);
                    if (fn_ptr_map2 != 0) {
                        var fn_map2: *AstFunc = (*AstFunc)fn_ptr_map2;
                        if (fn_map2->ret_type == TYPE_STRUCT && fn_map2->ret_ptr_depth == 0) {
                            builder_set_func_ptr(ctx, idn_tgt->name_ptr, idn_tgt->name_len, fn_map2->ret_struct_name_ptr, fn_map2->ret_struct_name_len);
                        } else {
                            builder_set_func_ptr(ctx, idn_tgt->name_ptr, idn_tgt->name_len, 0, 0);
                        }
                    } else {
                        builder_set_func_ptr(ctx, idn_tgt->name_ptr, idn_tgt->name_len, 0, 0);
                    }
                } else {
                    builder_set_func_ptr(ctx, idn_tgt->name_ptr, idn_tgt->name_len, 0, 0);
                }
            } else {
                builder_set_func_ptr(ctx, idn_tgt->name_ptr, idn_tgt->name_len, 0, 0);
            }
        }
        var tgt_ti_ptr: u64 = 0;
        var tgt_is_struct: u64 = 0;
        var tgt_struct_size: u64 = 0;
        var tgt_struct_name_ptr: u64 = 0;
        var tgt_struct_name_len: u64 = 0;
        if (target_kind == AST_IDENT || target_kind == AST_DEREF || target_kind == AST_DEREF8 || target_kind == AST_MEMBER_ACCESS) {
            tgt_ti_ptr = get_expr_type_with_symtab(asn->target, ctx->symtab);
            if (tgt_ti_ptr != 0) {
                var ti_s: *TypeInfo = (*TypeInfo)tgt_ti_ptr;
                if (ti_s->type_kind == TYPE_STRUCT && ti_s->ptr_depth == 0) {
                    tgt_is_struct = 1;
                    tgt_struct_name_ptr = ti_s->struct_name_ptr;
                    tgt_struct_name_len = ti_s->struct_name_len;
                    tgt_struct_size = sizeof_type(TYPE_STRUCT, 0, tgt_struct_name_ptr, tgt_struct_name_len);
                }
            }
        }
        if (target_kind == AST_MEMBER_ACCESS) {
            var m: *AstMemberAccess = (*AstMemberAccess)asn->target;
            var obj: u64 = m->object;
            var obj_ti_ptr: u64 = get_expr_type_with_symtab(obj, ctx->symtab);
            if (obj_ti_ptr != 0) {
                var ot: *TypeInfo = (*TypeInfo)obj_ti_ptr;
                if (ot->ptr_depth > 0 && ot->is_tagged == 1 && ot->tag_layout_ptr != 0) {
                    var layout_def: u64 = get_struct_def(ot->tag_layout_ptr, ot->tag_layout_len);
                    if (layout_def != 0) {
                        var layout_info: *AstStructDef = (*AstStructDef)layout_def;
                        var packed_flag: u64 = layout_info->is_packed;
                        if (packed_flag == 1) {
                            var total_bits: u64 = builder_get_packed_layout_total_bits(layout_def);
                            var field_offset: u64 = builder_get_packed_field_bit_offset(layout_def, m->member_ptr, m->member_len);
                            var field_width: u64 = builder_get_packed_field_bit_width(layout_def, m->member_ptr, m->member_len);
                            var start_bit: u64 = 64 - total_bits;
                            var shift_bits: u64 = start_bit + field_offset;
                            var value_reg: u64 = build_expr(ctx, asn->value);
                            value_reg = builder_mask_low_bits(ctx, value_reg, field_width);
                            value_reg = builder_shift_left(ctx, value_reg, shift_bits);
                            var obj_val: u64 = build_expr(ctx, obj);
                            var merged: u64 = value_reg;
                            if (field_width < 64) {
                                var field_mask_val: u64 = builder_make_bitmask(field_width);
                                var field_mask_reg: u64 = build_const(ctx, field_mask_val);
                                field_mask_reg = builder_shift_left(ctx, field_mask_reg, shift_bits);
                                var all_ones_reg: u64 = builder_all_ones_reg(ctx);
                                var inv_mask_reg: u64 = builder_new_reg(ctx);
                                var xor_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_XOR, inv_mask_reg, ssa_operand_reg(field_mask_reg), ssa_operand_reg(all_ones_reg));
                                ssa_inst_append(ctx->cur_block, (*SSAInstruction)xor_ptr);
                                var cleared_reg: u64 = builder_new_reg(ctx);
                                var and_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_AND, cleared_reg, ssa_operand_reg(obj_val), ssa_operand_reg(inv_mask_reg));
                                ssa_inst_append(ctx->cur_block, (*SSAInstruction)and_ptr);
                                merged = builder_new_reg(ctx);
                                var or_ptr: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_OR, merged, ssa_operand_reg(cleared_reg), ssa_operand_reg(value_reg));
                                ssa_inst_append(ctx->cur_block, (*SSAInstruction)or_ptr);
                            }
                            if (ast_kind(obj) == AST_IDENT) {
                                var idn_tag: *AstIdent = (*AstIdent)obj;
                                var tag_offset: u64 = symtab_find(ctx->symtab, idn_tag->name_ptr, idn_tag->name_len);
                                if (tag_offset != 0) {
                                    var var_id_tag: u64 = builder_get_var_id(ctx, idn_tag->name_ptr, idn_tag->name_len);
                                    var st_ptr_tag: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_STORE, 0, ssa_operand_const(var_id_tag), ssa_operand_reg(merged));
                                    ssa_inst_append(ctx->cur_block, (*SSAInstruction)st_ptr_tag);
                                    return 0;
                                }
                            }
                            var obj_addr: u64 = builder_lvalue_addr(ctx, obj);
                            builder_store_by_size(ctx, obj_addr, merged, 8);
                            return 0;
                        }
                    }
                }
                if (ot->ptr_depth == 0 && ot->type_kind == TYPE_STRUCT) {
                    var struct_def2: u64 = ot->struct_def;
                    if (struct_def2 == 0 && ot->struct_name_ptr != 0) {
                        struct_def2 = get_struct_def(ot->struct_name_ptr, ot->struct_name_len);
                    }
                    if (struct_def2 != 0) {
                        var struct_info2: *AstStructDef = (*AstStructDef)struct_def2;
                        var packed_flag2: u64 = struct_info2->is_packed;
                        if (packed_flag2 == 1) {
                            var total_bits2: u64 = builder_get_packed_layout_total_bits(struct_def2);
                            var field_offset2: u64 = builder_get_packed_field_bit_offset(struct_def2, m->member_ptr, m->member_len);
                            var field_width2: u64 = builder_get_packed_field_bit_width(struct_def2, m->member_ptr, m->member_len);
                            var shift_bits2: u64 = field_offset2;
                            var size_bytes2: u64 = (total_bits2 + 7) / 8;
                            var base_addr2: u64 = builder_lvalue_addr(ctx, obj);
                            var cur_val: u64 = builder_load_by_size(ctx, base_addr2, size_bytes2);
                            var value_reg2: u64 = build_expr(ctx, asn->value);
                            value_reg2 = builder_mask_low_bits(ctx, value_reg2, field_width2);
                            value_reg2 = builder_shift_left(ctx, value_reg2, shift_bits2);
                            var merged2: u64 = value_reg2;
                            if (field_width2 < 64) {
                                var field_mask_val2: u64 = builder_make_bitmask(field_width2);
                                var field_mask_reg2: u64 = build_const(ctx, field_mask_val2);
                                field_mask_reg2 = builder_shift_left(ctx, field_mask_reg2, shift_bits2);
                                var all_ones_reg2: u64 = builder_all_ones_reg(ctx);
                                var inv_mask_reg2: u64 = builder_new_reg(ctx);
                                var xor_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_XOR, inv_mask_reg2, ssa_operand_reg(field_mask_reg2), ssa_operand_reg(all_ones_reg2));
                                ssa_inst_append(ctx->cur_block, (*SSAInstruction)xor_ptr2);
                                var cleared_reg2: u64 = builder_new_reg(ctx);
                                var and_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_AND, cleared_reg2, ssa_operand_reg(cur_val), ssa_operand_reg(inv_mask_reg2));
                                ssa_inst_append(ctx->cur_block, (*SSAInstruction)and_ptr2);
                                merged2 = builder_new_reg(ctx);
                                var or_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_OR, merged2, ssa_operand_reg(cleared_reg2), ssa_operand_reg(value_reg2));
                                ssa_inst_append(ctx->cur_block, (*SSAInstruction)or_ptr2);
                            }
                            builder_store_by_size(ctx, base_addr2, merged2, size_bytes2);
                            return 0;
                        }
                    }
                }
            }
        }
        var target_addr: u64 = 0;
        var target_offset: u64 = 0;

        if (target_kind == AST_IDENT) {
            var idn: *AstIdent = (*AstIdent)asn->target;
            target_offset = symtab_find(ctx->symtab, idn->name_ptr, idn->name_len);
            if (target_offset != 0) {
                target_addr = builder_new_lea_local(ctx, target_offset);
            } else {
                target_addr = builder_lvalue_addr(ctx, asn->target);
            }
        } else if (target_kind == AST_DEREF || target_kind == AST_DEREF8 || target_kind == AST_INDEX || target_kind == AST_MEMBER_ACCESS) {
            target_addr = builder_lvalue_addr(ctx, asn->target);
        } else {
            return 0;
        }

        if (ast_kind(asn->value) == AST_STRUCT_LITERAL) {
            builder_assign_struct_literal_to_addr(ctx, (*AstStructLiteral)asn->value, target_addr);
            return 0;
        }

        if (tgt_is_struct != 0 && tgt_struct_size > 0) {
            var val_kind_s: u64 = ast_kind(asn->value);
            if (val_kind_s == AST_CALL || val_kind_s == AST_METHOD_CALL || val_kind_s == AST_CALL_PTR) {
                if (tgt_struct_size > 16) {
                    if (val_kind_s == AST_CALL) {
                        builder_emit_call_sret(ctx, (*AstCall)asn->value, target_addr);
                    } else if (val_kind_s == AST_METHOD_CALL) {
                        builder_emit_method_call_sret(ctx, (*AstMethodCall)asn->value, target_addr);
                    } else {
                        builder_emit_call_ptr_sret(ctx, (*AstCallPtr)asn->value, target_addr);
                    }
                    return 0;
                }
                var lo_reg_s: u64 = builder_new_reg(ctx);
                var hi_reg_s: u64 = 0;
                if (tgt_struct_size > 8) { hi_reg_s = builder_new_reg(ctx); }
                if (val_kind_s == AST_CALL) {
                    builder_emit_call(ctx, (*AstCall)asn->value, lo_reg_s, hi_reg_s);
                } else if (val_kind_s == AST_METHOD_CALL) {
                    builder_emit_method_call(ctx, (*AstMethodCall)asn->value, lo_reg_s, hi_reg_s);
                } else {
                    builder_emit_call_ptr(ctx, (*AstCallPtr)asn->value, lo_reg_s, hi_reg_s);
                }
                builder_store_by_size(ctx, target_addr, lo_reg_s, 8);
                if (hi_reg_s != 0) {
                    var off8s: u64 = build_const(ctx, 8);
                    var addr2s: u64 = builder_new_reg(ctx);
                    var add_ptrs: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_ADD, addr2s, ssa_operand_reg(target_addr), ssa_operand_reg(off8s));
                    ssa_inst_append(ctx->cur_block, (*SSAInstruction)add_ptrs);
                    var tail_size_s: u64 = tgt_struct_size - 8;
                    if (tail_size_s > 8) { tail_size_s = 8; }
                    builder_store_by_size(ctx, addr2s, hi_reg_s, tail_size_s);
                }
                return 0;
            }

            var src_addr_s: u64 = builder_lvalue_addr(ctx, asn->value);
            if (src_addr_s == 0) { return 0; }
            builder_struct_copy(ctx, target_addr, src_addr_s, tgt_struct_size);
            return 0;
        }

        if (tgt_ti_ptr != 0) {
            var ti: *TypeInfo = (*TypeInfo)tgt_ti_ptr;
            if (ti->type_kind == TYPE_SLICE && ti->ptr_depth == 0) {
                builder_assign_slice_to_addr(ctx, asn->value, target_addr);
                return 0;
            }
        }

        var val_reg3: u64 = build_expr(ctx, asn->value);
        if (target_kind == AST_IDENT && target_offset != 0) {
            var idn2: *AstIdent = (*AstIdent)asn->target;
            var var_id3: u64 = builder_get_var_id(ctx, idn2->name_ptr, idn2->name_len);
            var st_ptr3: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_STORE, 0, ssa_operand_const(var_id3), ssa_operand_reg(val_reg3));
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)st_ptr3);
            return 0;
        }

        var size4: u64 = 8;
        if (target_kind == AST_DEREF8) {
            size4 = 1;
        } else {
            size4 = builder_type_size_from_expr(ctx, asn->target);
        }
        builder_store_by_size(ctx, target_addr, val_reg3, size4);
        return 0;
    }

    if (kind == AST_RETURN) {
        var ret: *AstReturn = (*AstReturn)node;
        if (ret->expr == 0) {
            var ret_ptr0: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_RET, 0, 0, 0);
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)ret_ptr0);
            return 0;
        }

        if (ast_kind(ret->expr) == AST_STRUCT_LITERAL) {
            var lit0: *AstStructLiteral = (*AstStructLiteral)ret->expr;
            var struct_size0: u64 = builder_struct_size_from_def(lit0->struct_def);
            if (struct_size0 == 0) {
                var fallback_name_ptr: u64 = emitter_get_ret_struct_name_ptr();
                var fallback_name_len: u64 = emitter_get_ret_struct_name_len();
                if (fallback_name_ptr != 0 && fallback_name_len != 0) {
                    struct_size0 = sizeof_type(TYPE_STRUCT, 0, fallback_name_ptr, fallback_name_len);
                }
            }
            if (struct_size0 == 0 && lit0->values_vec != 0) {
                struct_size0 = vec_len(lit0->values_vec) * 8;
            }
            if (struct_size0 == 0) { return 0; }
            if (struct_size0 > 16) {
                if (ctx->sret_addr_reg == 0) { return 0; }
                builder_struct_literal_init(ctx, lit0->struct_def, lit0->values_vec, ctx->sret_addr_reg);
                var ret_ptr_lit: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_RET, 0, 0, 0);
                ssa_inst_append(ctx->cur_block, (*SSAInstruction)ret_ptr_lit);
                return 0;
            }
            return builder_emit_return_struct_from_literal(ctx, lit0, struct_size0);
        }

        var ret_type: u64 = emitter_get_ret_type();
        var ret_ptr_depth: u64 = emitter_get_ret_ptr_depth();
        var ret_struct_name_ptr: u64 = emitter_get_ret_struct_name_ptr();
        var ret_struct_name_len: u64 = emitter_get_ret_struct_name_len();
        var ret_expr_ti_ptr: u64 = get_expr_type_with_symtab(ret->expr, ctx->symtab);
        var ret_expr_is_struct: u64 = 0;
        var ret_expr_struct_name_ptr: u64 = 0;
        var ret_expr_struct_name_len: u64 = 0;
        var ret_expr_struct_def: u64 = 0;
        if (ret_expr_ti_ptr != 0) {
            var ret_expr_ti: *TypeInfo = (*TypeInfo)ret_expr_ti_ptr;
            if (ret_expr_ti->type_kind == TYPE_STRUCT && ret_expr_ti->ptr_depth == 0) {
                ret_expr_is_struct = 1;
                ret_expr_struct_name_ptr = ret_expr_ti->struct_name_ptr;
                ret_expr_struct_name_len = ret_expr_ti->struct_name_len;
                ret_expr_struct_def = ret_expr_ti->struct_def;
            }
        }
        var use_struct_return: u64 = 0;
        var struct_name_ptr: u64 = ret_struct_name_ptr;
        var struct_name_len: u64 = ret_struct_name_len;
        if (ret_type == TYPE_STRUCT && ret_ptr_depth == 0) {
            use_struct_return = 1;
            if ((struct_name_ptr == 0 || struct_name_len == 0) && ret_expr_is_struct != 0) {
                struct_name_ptr = ret_expr_struct_name_ptr;
                struct_name_len = ret_expr_struct_name_len;
                if ((struct_name_ptr == 0 || struct_name_len == 0) && ret_expr_struct_def != 0) {
                    var ret_expr_struct_info: *AstStructDef = (*AstStructDef)ret_expr_struct_def;
                    struct_name_ptr = ret_expr_struct_info->name_ptr;
                    struct_name_len = ret_expr_struct_info->name_len;
                }
            }
        } else if (ret_expr_is_struct != 0) {
            use_struct_return = 1;
            struct_name_ptr = ret_expr_struct_name_ptr;
            struct_name_len = ret_expr_struct_name_len;
            if ((struct_name_ptr == 0 || struct_name_len == 0) && ret_expr_struct_def != 0) {
                var ret_expr_struct_info2: *AstStructDef = (*AstStructDef)ret_expr_struct_def;
                struct_name_ptr = ret_expr_struct_info2->name_ptr;
                struct_name_len = ret_expr_struct_info2->name_len;
            }
        }
        if (ctx->sret_addr_reg != 0) {
            use_struct_return = 1;
        }
        
        if (use_struct_return != 0) {
            var expr_kind: u64 = ast_kind(ret->expr);
            var struct_size: u64 = 0;
            var struct_def_for_size: u64 = ret_expr_struct_def;
            if ((struct_name_ptr == 0 || struct_name_len == 0) && expr_kind == AST_CALL) {
                var call_node0: *AstCall = (*AstCall)ret->expr;
                var call_fn_ptr0: u64 = compiler_get_func(call_node0->name_ptr, call_node0->name_len);
                if (call_fn_ptr0 != 0) {
                    var call_fn0: *AstFunc = (*AstFunc)call_fn_ptr0;
                    if (call_fn0->ret_type == TYPE_STRUCT && call_fn0->ret_ptr_depth == 0) {
                        struct_name_ptr = call_fn0->ret_struct_name_ptr;
                        struct_name_len = call_fn0->ret_struct_name_len;
                        struct_def_for_size = get_struct_def(struct_name_ptr, struct_name_len);
                    }
                }
            }
            if (struct_def_for_size == 0 && expr_kind == AST_STRUCT_LITERAL) {
                var lit_size: *AstStructLiteral = (*AstStructLiteral)ret->expr;
                struct_def_for_size = lit_size->struct_def;
            }
            if (struct_name_ptr != 0 && struct_name_len != 0) {
                struct_size = sizeof_type(TYPE_STRUCT, 0, struct_name_ptr, struct_name_len);
            }
            if (struct_def_for_size != 0) {
                var def_size: u64 = builder_struct_size_from_def(struct_def_for_size);
                if (def_size > struct_size) { struct_size = def_size; }
            }
            if (struct_name_ptr != 0 && struct_name_len != 0) {
                var name_def: u64 = get_struct_def(struct_name_ptr, struct_name_len);
                if (name_def != 0) {
                    var name_def_size: u64 = builder_struct_size_from_def(name_def);
                    if (name_def_size > struct_size) { struct_size = name_def_size; }
                }
            }
            if (struct_size == 0 && expr_kind == AST_STRUCT_LITERAL) {
                var lit_fallback: *AstStructLiteral = (*AstStructLiteral)ret->expr;
                if (lit_fallback->values_vec != 0) {
                    struct_size = vec_len(lit_fallback->values_vec) * 8;
                }
            }
            if (expr_kind == AST_CALL) {
                var call_node: *AstCall = (*AstCall)ret->expr;
                var call_fn_ptr: u64 = compiler_get_func(call_node->name_ptr, call_node->name_len);
                if (call_fn_ptr != 0) {
                    var call_fn: *AstFunc = (*AstFunc)call_fn_ptr;
                    if (call_fn->ret_type == TYPE_STRUCT && call_fn->ret_ptr_depth == 0) {
                        var call_def: u64 = get_struct_def(call_fn->ret_struct_name_ptr, call_fn->ret_struct_name_len);
                        var call_def_size: u64 = builder_struct_size_from_def(call_def);
                        if (call_def_size > 16 && ctx->sret_addr_reg != 0) {
                            builder_emit_call_sret(ctx, call_node, ctx->sret_addr_reg);
                            var ret_ptr_sret_call: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_RET, 0, 0, 0);
                            ssa_inst_append(ctx->cur_block, (*SSAInstruction)ret_ptr_sret_call);
                            return 0;
                        }
                        if (call_def_size == 0) {
                            call_def_size = sizeof_type(TYPE_STRUCT, 0, call_fn->ret_struct_name_ptr, call_fn->ret_struct_name_len);
                        }
                        if (call_def_size > struct_size) { struct_size = call_def_size; }
                    }
                }
            }
            if (struct_size == 0) { return 0; }
            if (struct_size > 16) {
                if (ctx->sret_addr_reg == 0) { return 0; }
                if (expr_kind == AST_STRUCT_LITERAL) {
                    var lit2: *AstStructLiteral = (*AstStructLiteral)ret->expr;
                    builder_struct_literal_init(ctx, lit2->struct_def, lit2->values_vec, ctx->sret_addr_reg);
                } else if (expr_kind == AST_CALL || expr_kind == AST_METHOD_CALL || expr_kind == AST_CALL_PTR) {
                    if (expr_kind == AST_CALL) {
                        builder_emit_call_sret(ctx, (*AstCall)ret->expr, ctx->sret_addr_reg);
                    } else if (expr_kind == AST_METHOD_CALL) {
                        builder_emit_method_call_sret(ctx, (*AstMethodCall)ret->expr, ctx->sret_addr_reg);
                    } else {
                        builder_emit_call_ptr_sret(ctx, (*AstCallPtr)ret->expr, ctx->sret_addr_reg);
                    }
                } else {
                    var src_addr: u64 = builder_lvalue_addr(ctx, ret->expr);
                    if (src_addr == 0) { return 0; }
                    builder_struct_copy(ctx, ctx->sret_addr_reg, src_addr, struct_size);
                }
                var ret_ptr0: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_RET, 0, 0, 0);
                ssa_inst_append(ctx->cur_block, (*SSAInstruction)ret_ptr0);
                return 0;
            }
            if (expr_kind == AST_STRUCT_LITERAL) {
                return builder_emit_return_struct_from_literal(ctx, (*AstStructLiteral)ret->expr, struct_size);
            }
            if (expr_kind == AST_CALL || expr_kind == AST_METHOD_CALL || expr_kind == AST_CALL_PTR) {
                return builder_emit_return_struct_from_call(ctx, ret->expr, struct_size);
            }
            return builder_emit_return_struct_from_addr(ctx, ret->expr, struct_size);
        }
        
        if (ret_type == TYPE_SLICE && ret_ptr_depth == 0) {
            var expr_kind2: u64 = ast_kind(ret->expr);
            if (expr_kind2 == AST_SLICE) {
                var slice_node: *AstSlice = (*AstSlice)ret->expr;
                var ti_ptr2: u64 = get_expr_type_with_symtab(slice_node->ptr_expr, ctx->symtab);
                if (ti_ptr2 != 0) {
                    var ti2: *TypeInfo = (*TypeInfo)ti_ptr2;
                    var is_local_array: u64 = 0;
                    if (ti2->ptr_depth == 0) {
                        if (ti2->type_kind == TYPE_ARRAY || ti2->array_len != 0) {
                            is_local_array = 1;
                        }
                    }
                    if (is_local_array != 0) {
                        var elem_size: u64 = sizeof_type(ti2->elem_type_kind, ti2->elem_ptr_depth, ti2->struct_name_ptr, ti2->struct_name_len);
                        if (elem_size == 0) { elem_size = 8; }
                        var ptr_reg0: u64 = builder_lvalue_addr(ctx, slice_node->ptr_expr);
                        if (ptr_reg0 == 0) {
                            ptr_reg0 = build_expr(ctx, slice_node->ptr_expr);
                        }
                        var len_reg0: u64 = build_expr(ctx, slice_node->len_expr);
                        var ret_ptr_heap: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_RET_SLICE_HEAP, elem_size, ssa_operand_reg(ptr_reg0), ssa_operand_reg(len_reg0));
                        ssa_inst_append(ctx->cur_block, (*SSAInstruction)ret_ptr_heap);
                        var ptr_is_reg: u64 = 1;
                        var len_is_reg: u64 = 1;
                        var len_val: u64 = len_reg0;
                        if (ast_kind(slice_node->len_expr) == AST_LITERAL) {
                            var lit_len: *AstLiteral = (*AstLiteral)slice_node->len_expr;
                            len_val = lit_len->value;
                            len_is_reg = 0;
                        }
                        ssa_ret_slice_heap_set(ret_ptr_heap, elem_size);
                        ssa_ret_slice_heap_set_ex(ret_ptr_heap, elem_size, ptr_reg0, len_val, ptr_is_reg, len_is_reg);
                        return 0;
                    }
                }
            }
            if (expr_kind2 == AST_CALL || expr_kind2 == AST_METHOD_CALL || expr_kind2 == AST_CALL_PTR) {
                return builder_emit_return_slice_from_call(ctx, ret->expr);
            }
            var slice_info: u64 = builder_slice_regs(ctx, ret->expr);
            var slice_regs: *SliceRegs = (*SliceRegs)slice_info;
            var ptr_reg: u64 = slice_regs->ptr_reg;
            var len_reg: u64 = slice_regs->len_reg;
            var ret_ptr2: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_RET, 0, ssa_operand_reg(ptr_reg), ssa_operand_reg(len_reg));
            ssa_inst_append(ctx->cur_block, (*SSAInstruction)ret_ptr2);
            return 0;
        }

        var ret_ti_ptr: u64 = get_expr_type_with_symtab(ret->expr, ctx->symtab);
        if (ret_ti_ptr != 0) {
            var ret_ti: *TypeInfo = (*TypeInfo)ret_ti_ptr;
            if (ret_ti->type_kind == TYPE_SLICE && ret_ti->ptr_depth == 0) {
                var expr_kind3: u64 = ast_kind(ret->expr);
                if (expr_kind3 == AST_SLICE) {
                    var slice_node2: *AstSlice = (*AstSlice)ret->expr;
                    var ti_ptr3: u64 = get_expr_type_with_symtab(slice_node2->ptr_expr, ctx->symtab);
                    if (ti_ptr3 != 0) {
                        var ti3: *TypeInfo = (*TypeInfo)ti_ptr3;
                        var is_local_array2: u64 = 0;
                        if (ti3->ptr_depth == 0) {
                            if (ti3->type_kind == TYPE_ARRAY || ti3->array_len != 0) {
                                is_local_array2 = 1;
                            }
                        }
                        if (is_local_array2 != 0) {
                            var elem_size2: u64 = sizeof_type(ti3->elem_type_kind, ti3->elem_ptr_depth, ti3->struct_name_ptr, ti3->struct_name_len);
                            if (elem_size2 == 0) { elem_size2 = 8; }
                            var ptr_reg3: u64 = builder_lvalue_addr(ctx, slice_node2->ptr_expr);
                            if (ptr_reg3 == 0) {
                                ptr_reg3 = build_expr(ctx, slice_node2->ptr_expr);
                            }
                            var len_reg3: u64 = build_expr(ctx, slice_node2->len_expr);
                            var ret_ptr_heap3: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_RET_SLICE_HEAP, elem_size2, ssa_operand_reg(ptr_reg3), ssa_operand_reg(len_reg3));
                            ssa_inst_append(ctx->cur_block, (*SSAInstruction)ret_ptr_heap3);
                            var ptr_is_reg3: u64 = 1;
                            var len_is_reg3: u64 = 1;
                            var len_val3: u64 = len_reg3;
                            if (ast_kind(slice_node2->len_expr) == AST_LITERAL) {
                                var lit_len3: *AstLiteral = (*AstLiteral)slice_node2->len_expr;
                                len_val3 = lit_len3->value;
                                len_is_reg3 = 0;
                            }
                            ssa_ret_slice_heap_set(ret_ptr_heap3, elem_size2);
                            ssa_ret_slice_heap_set_ex(ret_ptr_heap3, elem_size2, ptr_reg3, len_val3, ptr_is_reg3, len_is_reg3);
                            return 0;
                        }
                    }
                }
                if (expr_kind3 == AST_CALL || expr_kind3 == AST_METHOD_CALL || expr_kind3 == AST_CALL_PTR) {
                    return builder_emit_return_slice_from_call(ctx, ret->expr);
                }
                var slice_info2: u64 = builder_slice_regs(ctx, ret->expr);
                var slice_regs2: *SliceRegs = (*SliceRegs)slice_info2;
                var ptr_reg2: u64 = slice_regs2->ptr_reg;
                var len_reg2: u64 = slice_regs2->len_reg;
                var ret_ptr3: u64 = ssa_new_inst(ctx->ssa_ctx, SSA_OP_RET, 0, ssa_operand_reg(ptr_reg2), ssa_operand_reg(len_reg2));
                ssa_inst_append(ctx->cur_block, (*SSAInstruction)ret_ptr3);
                return 0;
            }
        }

        var val_reg4: u64 = build_expr(ctx, ret->expr);
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


