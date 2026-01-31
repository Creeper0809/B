// typeinfo.b - Type size/compatibility calculations and struct layout
//
// This module handles type-related calculations:
// - Type size computation (primitives, pointers, structs)
// - Type compatibility checking
// - Struct field offset calculation
// - Expression type inference

import std.io;
import std.vec;
import std.util;
import std.str;
import types;
import ast;
import compiler;

func typeinfo_make(base_type: u64, ptr_depth: u64) -> u64 {
    var result: u64 = heap_alloc(sizeof(TypeInfo));
    var ti: *TypeInfo = (*TypeInfo)result;
    ti->type_kind = base_type;
    ti->ptr_depth = ptr_depth;
    ti->is_tagged = 0;
    ti->struct_name_ptr = 0;
    ti->struct_name_len = 0;
    ti->tag_layout_ptr = 0;
    ti->tag_layout_len = 0;
    ti->struct_def = 0;
    ti->elem_type_kind = 0;
    ti->elem_ptr_depth = 0;
    ti->array_len = 0;
    return result;
}

func typeinfo_make_struct(ptr_depth: u64, struct_name_ptr: u64, struct_name_len: u64, struct_def: u64) -> u64 {
    var result: u64 = heap_alloc(sizeof(TypeInfo));
    var ti: *TypeInfo = (*TypeInfo)result;
    ti->type_kind = TYPE_STRUCT;
    ti->ptr_depth = ptr_depth;
    ti->is_tagged = 0;
    ti->struct_name_ptr = struct_name_ptr;
    ti->struct_name_len = struct_name_len;
    ti->tag_layout_ptr = 0;
    ti->tag_layout_len = 0;
    ti->struct_def = struct_def;
    ti->elem_type_kind = 0;
    ti->elem_ptr_depth = 0;
    ti->array_len = 0;
    return result;
}

func typeinfo_make_array(ptr_depth: u64, elem_type_kind: u64, elem_ptr_depth: u64, elem_struct_name_ptr: u64, elem_struct_name_len: u64, elem_struct_def: u64, array_len: u64) -> u64 {
    var result: u64 = heap_alloc(sizeof(TypeInfo));
    var ti: *TypeInfo = (*TypeInfo)result;
    ti->type_kind = TYPE_ARRAY;
    ti->ptr_depth = ptr_depth;
    ti->is_tagged = 0;
    ti->struct_name_ptr = elem_struct_name_ptr;
    ti->struct_name_len = elem_struct_name_len;
    ti->tag_layout_ptr = 0;
    ti->tag_layout_len = 0;
    ti->struct_def = elem_struct_def;
    ti->elem_type_kind = elem_type_kind;
    ti->elem_ptr_depth = elem_ptr_depth;
    ti->array_len = array_len;
    return result;
}

func typeinfo_make_slice(ptr_depth: u64, elem_type_kind: u64, elem_ptr_depth: u64, elem_struct_name_ptr: u64, elem_struct_name_len: u64, elem_struct_def: u64) -> u64 {
    var result: u64 = heap_alloc(sizeof(TypeInfo));
    var ti: *TypeInfo = (*TypeInfo)result;
    ti->type_kind = TYPE_SLICE;
    ti->ptr_depth = ptr_depth;
    ti->is_tagged = 0;
    ti->struct_name_ptr = elem_struct_name_ptr;
    ti->struct_name_len = elem_struct_name_len;
    ti->tag_layout_ptr = 0;
    ti->tag_layout_len = 0;
    ti->struct_def = elem_struct_def;
    ti->elem_type_kind = elem_type_kind;
    ti->elem_ptr_depth = elem_ptr_depth;
    ti->array_len = 0;
    return result;
}

// Global struct definitions (set by codegen before use)
var g_structs_vec;
// Global function definitions (set by codegen before use)
var g_funcs_vec;

func typeinfo_set_structs(structs: u64) -> u64 {
    g_structs_vec = structs;
}

func typeinfo_get_structs() -> u64 {
    return g_structs_vec;
}

func typeinfo_set_funcs(funcs: u64) -> u64 {
    g_funcs_vec = funcs;
}

// ============================================
// Type Size Helpers
// ============================================

func get_type_size(base_type: u64, ptr_depth: u64) -> u64 {
    if (ptr_depth > 0) { return 8; }
    if (base_type == TYPE_U8) { return 1; }
    if (base_type == TYPE_U16) { return 2; }
    if (base_type == TYPE_U32) { return 4; }
    if (base_type == TYPE_U64) { return 8; }
    if (base_type == TYPE_I64) { return 8; }
    if (base_type == TYPE_SLICE) { return 16; }
    return 8;
}

func get_pointee_size(base_type: u64, ptr_depth: u64) -> u64 {
    if (ptr_depth > 1) { return 8; }
    if (ptr_depth == 1) {
        if (base_type == TYPE_U8) { return 1; }
        if (base_type == TYPE_U16) { return 2; }
        if (base_type == TYPE_U32) { return 4; }
        if (base_type == TYPE_U64) { return 8; }
        if (base_type == TYPE_I64) { return 8; }
        if (base_type == TYPE_SLICE) { return 16; }
    }
    return 8;
}

func sizeof_field_desc(field: *FieldDesc) -> u64 {
    if (field->bit_width > 0) {
        return (field->bit_width + 7) / 8;
    }
    if (field->type_kind == TYPE_ARRAY) {
        var elem_size: u64 = sizeof_type(field->elem_type_kind, field->elem_ptr_depth, field->struct_name_ptr, field->struct_name_len);
        return elem_size * field->array_len;
    }
    if (field->type_kind == TYPE_SLICE) { return 16; }
    return sizeof_type(field->type_kind, field->ptr_depth, field->struct_name_ptr, field->struct_name_len);
}

func get_field_desc(struct_def: u64, field_name_ptr: u64, field_name_len: u64) -> u64 {
    var struct_info: *AstStructDef = (*AstStructDef)struct_def;
    var fields: u64 = struct_info->fields_vec;
    var num_fields: u64 = vec_len(fields);
    for (var i: u64 = 0; i < num_fields; i++) {
        var field: *FieldDesc = (*FieldDesc)vec_get(fields, i);
        if (str_eq(field->name_ptr, field->name_len, field_name_ptr, field_name_len)) {
            return (u64)field;
        }
    }
    return 0;
}

func check_type_compat(from_base: u64, from_depth: u64, from_tagged: u64, from_layout_ptr: u64, from_layout_len: u64, to_base: u64, to_depth: u64, to_tagged: u64, to_layout_ptr: u64, to_layout_len: u64) -> u64 {
    if (from_base == TYPE_ARRAY || to_base == TYPE_ARRAY || from_base == TYPE_SLICE || to_base == TYPE_SLICE) {
        if (from_base == to_base && from_depth == to_depth) { return 0; }
        return 1;
    }
    if (from_base == to_base) {
        if (from_depth == to_depth) {
            if (from_depth > 0 && from_tagged != to_tagged) { return 1; }
            if (from_depth > 0 && from_tagged == 1) {
                if (!str_eq(from_layout_ptr, from_layout_len, to_layout_ptr, to_layout_len)) { return 1; }
            }
            return 0;
        }
    }
    if (from_depth > 0) {
        if (to_depth > 0) { return 1; }
    }
    if (from_depth == 0) {
        if (to_depth == 0) {
            var from_size: u64 = get_type_size(from_base, 0);
            var to_size: u64 = get_type_size(to_base, 0);
            if (from_size == to_size) { return 0; }
            return 1;
        }
    }
    if (from_depth == 0) {
        if (to_depth > 0) { return 1; }
    }
    if (from_depth > 0) {
        if (to_depth == 0) { return 1; }
    }
    return 1;
}

// Calculate size of a type including structs
// Returns size in bytes for allocating on stack
func sizeof_type(type_kind: u64, ptr_depth: u64, struct_name_ptr: u64, struct_name_len: u64) -> u64 {
    // Pointers are always 8 bytes
    if (ptr_depth > 0) { return 8; }
    
    // Primitive types
    if (type_kind == TYPE_U8) { return 1; }
    if (type_kind == TYPE_U16) { return 2; }
    if (type_kind == TYPE_U32) { return 4; }
    if (type_kind == TYPE_U64) { return 8; }
    if (type_kind == TYPE_I64) { return 8; }
    if (type_kind == TYPE_SLICE) { return 16; }
    
    // Struct type: sum of field sizes
    if (type_kind == TYPE_STRUCT) {
        if (g_structs_vec == 0) { return 8; }
        
        // Find struct by name
        var num_structs: u64 = vec_len(g_structs_vec);
        var struct_def: u64 = 0;
        
        for (var si: u64 = 0; si < num_structs; si++) {
            var candidate: *AstStructDef = (*AstStructDef)vec_get(g_structs_vec, si);
            var candidate_name_ptr: u64 = candidate->name_ptr;
            var candidate_name_len: u64 = candidate->name_len;
            
            if (str_eq(candidate_name_ptr, candidate_name_len, struct_name_ptr, struct_name_len)) {
                struct_def = (u64)candidate;
                break;
            }
        }
        
        if (struct_def == 0) { return 8; }

        var struct_info: *AstStructDef = (*AstStructDef)struct_def;
        var packed_flag: u64 = struct_info->is_packed;
        if (packed_flag == 1) {
            var fields_p: u64 = struct_info->fields_vec;
            var num_fields_p: u64 = vec_len(fields_p);
            var total_bits: u64 = 0;
            for (var pi: u64 = 0; pi < num_fields_p; pi++) {
                var field_p: *FieldDesc = (*FieldDesc)vec_get(fields_p, pi);
                if (field_p->bit_width > 0) {
                    total_bits = total_bits + field_p->bit_width;
                } else {
                    var fsize: u64 = sizeof_field_desc(field_p);
                    total_bits = total_bits + fsize * 8;
                }
            }
            return (total_bits + 7) / 8;
        }
        
        var fields: u64 = struct_info->fields_vec;
        var num_fields: u64 = vec_len(fields);
        var total_size: u64 = 0;
        
        for (var i: u64 = 0; i < num_fields; i++) {
            var field: *FieldDesc = (*FieldDesc)vec_get(fields, i);
            var field_size: u64 = sizeof_field_desc(field);
            total_size = total_size + field_size;
        }
        
        return total_size;
    }
    
    // Default: 8 bytes
    return 8;
}

// Sizeof helper for extended types (array/slice)
func sizeof_type_ex(ti: u64) -> u64 {
    var info: *TypeInfo = (*TypeInfo)ti;
    if (info->ptr_depth > 0) { return 8; }
    if (info->type_kind == TYPE_STRUCT && info->ptr_depth == 0) {
        if (info->struct_name_ptr == 0 && info->struct_def != 0) {
            var struct_def: u64 = info->struct_def;
            var struct_info: *AstStructDef = (*AstStructDef)struct_def;
            var packed_flag: u64 = struct_info->is_packed;
            if (packed_flag == 1) {
                var fields_p: u64 = struct_info->fields_vec;
                var num_fields_p: u64 = vec_len(fields_p);
                var total_bits: u64 = 0;
                for (var pi: u64 = 0; pi < num_fields_p; pi++) {
                    var field_p: *FieldDesc = (*FieldDesc)vec_get(fields_p, pi);
                    if (field_p->bit_width > 0) {
                        total_bits = total_bits + field_p->bit_width;
                    } else {
                        var fsize: u64 = sizeof_field_desc(field_p);
                        total_bits = total_bits + fsize * 8;
                    }
                }
                return (total_bits + 7) / 8;
            }

            var fields: u64 = struct_info->fields_vec;
            var num_fields: u64 = vec_len(fields);
            var total_size: u64 = 0;
            for (var i: u64 = 0; i < num_fields; i++) {
                var field: *FieldDesc = (*FieldDesc)vec_get(fields, i);
                total_size = total_size + sizeof_field_desc(field);
            }
            return total_size;
        }
    }
    if (info->type_kind == TYPE_ARRAY) {
        var elem_size: u64 = sizeof_type(info->elem_type_kind, info->elem_ptr_depth, info->struct_name_ptr, info->struct_name_len);
        return elem_size * info->array_len;
    }
    if (info->type_kind == TYPE_SLICE) { return 16; }
    return sizeof_type(info->type_kind, info->ptr_depth, info->struct_name_ptr, info->struct_name_len);
}

// ============================================
// Struct Helper Functions
// ============================================

// Get field offset in bytes from struct definition
// Returns 0 if field not found (caller must handle)
func get_field_offset(struct_def: u64, field_name_ptr: u64, field_name_len: u64) -> u64 {
    var struct_info: *AstStructDef = (*AstStructDef)struct_def;
    var packed_flag2: u64 = struct_info->is_packed;
    if (packed_flag2 == 1) {
        emit_stderr("[ERROR] Packed struct field address is not supported\n", 56);
        panic("Codegen error");
    }
    var fields: u64 = struct_info->fields_vec;
    var num_fields: u64 = vec_len(fields);
    var offset: u64 = 0;
    
    for (var i: u64 = 0; i < num_fields; i++) {
        var field: *FieldDesc = (*FieldDesc)vec_get(fields, i);
        
        if (str_eq(field->name_ptr, field->name_len, field_name_ptr, field_name_len)) {
            return offset;
        }
        
        // Calculate field size based on type
        var field_size: u64 = sizeof_field_desc(field);
        offset = offset + field_size;
    }
    
    return 0;
}

// ============================================
// Expression Type Inference
// ============================================

// Forward declarations for symtab functions (imported by codegen)
// We need g_symtab from emitter module

func get_expr_type_with_symtab(node: u64, symtab: u64) -> u64 {
    var kind: u64 = ast_kind(node);

    if (kind == AST_SIZEOF || kind == AST_SIZEOF_EXPR) {
        return typeinfo_make(TYPE_U64, 0);
    }

    if (kind == AST_CALL) {
        if (g_funcs_vec != 0) {
            var call: *AstCall = (*AstCall)node;
            var name_ptr: u64 = call->name_ptr;
            var name_len: u64 = call->name_len;
            var resolved_ptr: u64 = name_ptr;
            var resolved_len: u64 = name_len;
            var resolved: u64 = resolve_name(name_ptr, name_len);
            if (resolved != 0) {
                var resolved_info: *NameInfo = (*NameInfo)resolved;
                resolved_ptr = resolved_info->ptr;
                resolved_len = resolved_info->len;
            }
            var num_funcs: u64 = vec_len(g_funcs_vec);
            for (var i: u64 = 0; i < num_funcs; i++) {
                var fn_ptr: u64 = vec_get(g_funcs_vec, i);
                var fn: *AstFunc = (*AstFunc)fn_ptr;
                if (str_eq(fn->name_ptr, fn->name_len, resolved_ptr, resolved_len)) {

                    if (fn->ret_type == TYPE_STRUCT) {
                        var struct_def: u64 = get_struct_def(fn->ret_struct_name_ptr, fn->ret_struct_name_len);
                        var result_struct: u64 = typeinfo_make_struct(fn->ret_ptr_depth, fn->ret_struct_name_ptr, fn->ret_struct_name_len, struct_def);
                        var rs: *TypeInfo = (*TypeInfo)result_struct;
                        rs->is_tagged = fn->ret_is_tagged;
                        return result_struct;
                    }
                    if (fn->ret_type == TYPE_SLICE) {
                        // Slice return type: element type info is not stored on AstFunc.
                        // Preserve slice shape (base kind + pointer depth) for codegen.
                        var result_slice: u64 = typeinfo_make(fn->ret_type, fn->ret_ptr_depth);
                        var rsl: *TypeInfo = (*TypeInfo)result_slice;
                        rsl->is_tagged = fn->ret_is_tagged;
                        return result_slice;
                    }
                    var result_basic: u64 = typeinfo_make(fn->ret_type, fn->ret_ptr_depth);
                    var rb: *TypeInfo = (*TypeInfo)result_basic;
                    rb->is_tagged = fn->ret_is_tagged;
                    rb->struct_name_ptr = fn->ret_struct_name_ptr;
                    rb->struct_name_len = fn->ret_struct_name_len;
                    rb->tag_layout_ptr = fn->ret_tag_layout_ptr;
                    rb->tag_layout_len = fn->ret_tag_layout_len;
                    return result_basic;
                }
            }
        }
        return typeinfo_make(TYPE_I64, 0);
    }

    if (kind == AST_CALL_PTR) {
        if (g_funcs_vec != 0) {
            var cp: *AstCallPtr = (*AstCallPtr)node;
            var callee: u64 = cp->callee;
            var name_ptr2: u64 = 0;
            var name_len2: u64 = 0;
            var ck: u64 = ast_kind(callee);
            if (ck == AST_IDENT) {
                var idn: *AstIdent = (*AstIdent)callee;
                name_ptr2 = idn->name_ptr;
                name_len2 = idn->name_len;
            } else if (ck == AST_ADDR_OF) {
                var a: *AstAddrOf = (*AstAddrOf)callee;
                if (ast_kind(a->operand) == AST_IDENT) {
                    var idn2: *AstIdent = (*AstIdent)a->operand;
                    name_ptr2 = idn2->name_ptr;
                    name_len2 = idn2->name_len;
                }
            }

            if (name_ptr2 != 0) {
                var resolved_ptr2: u64 = name_ptr2;
                var resolved_len2: u64 = name_len2;
                var resolved2: u64 = resolve_name(name_ptr2, name_len2);
                if (resolved2 != 0) {
                    var resolved_info2: *NameInfo = (*NameInfo)resolved2;
                    resolved_ptr2 = resolved_info2->ptr;
                    resolved_len2 = resolved_info2->len;
                }
                var num_funcs2: u64 = vec_len(g_funcs_vec);
                for (var j: u64 = 0; j < num_funcs2; j++) {
                    var fn_ptr2: u64 = vec_get(g_funcs_vec, j);
                    var fn2: *AstFunc = (*AstFunc)fn_ptr2;
                    if (str_eq(fn2->name_ptr, fn2->name_len, resolved_ptr2, resolved_len2)) {
                        if (fn2->ret_type == TYPE_STRUCT) {
                            var struct_def2: u64 = get_struct_def(fn2->ret_struct_name_ptr, fn2->ret_struct_name_len);
                            var result_struct2: u64 = typeinfo_make_struct(fn2->ret_ptr_depth, fn2->ret_struct_name_ptr, fn2->ret_struct_name_len, struct_def2);
                            var rs2: *TypeInfo = (*TypeInfo)result_struct2;
                            rs2->is_tagged = fn2->ret_is_tagged;
                            return result_struct2;
                        }
                        if (fn2->ret_type == TYPE_SLICE) {
                            var result_slice2: u64 = typeinfo_make(fn2->ret_type, fn2->ret_ptr_depth);
                            var rsl2: *TypeInfo = (*TypeInfo)result_slice2;
                            rsl2->is_tagged = fn2->ret_is_tagged;
                            return result_slice2;
                        }
                        var result_basic2: u64 = typeinfo_make(fn2->ret_type, fn2->ret_ptr_depth);
                        var rb2: *TypeInfo = (*TypeInfo)result_basic2;
                        rb2->is_tagged = fn2->ret_is_tagged;
                        rb2->struct_name_ptr = fn2->ret_struct_name_ptr;
                        rb2->struct_name_len = fn2->ret_struct_name_len;
                        rb2->tag_layout_ptr = fn2->ret_tag_layout_ptr;
                        rb2->tag_layout_len = fn2->ret_tag_layout_len;
                        return result_basic2;
                    }
                }
            }
        }
        return typeinfo_make(TYPE_I64, 0);
    }

    if (kind == AST_METHOD_CALL) {
        if (g_funcs_vec != 0) {
            var mc: *AstMethodCall = (*AstMethodCall)node;
            var receiver: u64 = mc->receiver;
            var recv_type_ptr: u64 = get_expr_type_with_symtab(receiver, symtab);
            if (recv_type_ptr == 0) { return typeinfo_make(TYPE_I64, 0); }
            var recv_ti: *TypeInfo = (*TypeInfo)recv_type_ptr;
            if (recv_ti->type_kind != TYPE_STRUCT) { return typeinfo_make(TYPE_I64, 0); }

            var struct_ptr: u64 = recv_ti->struct_name_ptr;
            var struct_len: u64 = recv_ti->struct_name_len;
            var full_len: u64 = struct_len + 1 + mc->method_len;
            var full_ptr: u64 = heap_alloc((full_len + 1) * sizeof(u8));
            for (var i2: u64 = 0; i2 < struct_len; i2++) {
                *(*u8)(full_ptr + i2) = *(*u8)(struct_ptr + i2);
            }
            *(*u8)(full_ptr + struct_len) = 95;
            for (var j2: u64 = 0; j2 < mc->method_len; j2++) {
                *(*u8)(full_ptr + struct_len + 1 + j2) = *(*u8)(mc->method_ptr + j2);
            }
            *(*u8)(full_ptr + full_len) = 0;

            var resolved_ptr2: u64 = full_ptr;
            var resolved_len2: u64 = full_len;
            var resolved2: u64 = resolve_name(full_ptr, full_len);
            if (resolved2 != 0) {
                var resolved_info2: *NameInfo = (*NameInfo)resolved2;
                resolved_ptr2 = resolved_info2->ptr;
                resolved_len2 = resolved_info2->len;
            }

            var num_funcs2: u64 = vec_len(g_funcs_vec);
            for (var k2: u64 = 0; k2 < num_funcs2; k2++) {
                var fn_ptr2: u64 = vec_get(g_funcs_vec, k2);
                var fn2: *AstFunc = (*AstFunc)fn_ptr2;
                if (str_eq(fn2->name_ptr, fn2->name_len, resolved_ptr2, resolved_len2)) {
                    if (fn2->ret_type == TYPE_STRUCT) {
                        var struct_def2: u64 = get_struct_def(fn2->ret_struct_name_ptr, fn2->ret_struct_name_len);
                        var result_struct2: u64 = typeinfo_make_struct(fn2->ret_ptr_depth, fn2->ret_struct_name_ptr, fn2->ret_struct_name_len, struct_def2);
                        var rs2: *TypeInfo = (*TypeInfo)result_struct2;
                        rs2->is_tagged = fn2->ret_is_tagged;
                        return result_struct2;
                    }
                    if (fn2->ret_type == TYPE_SLICE) {
                        var result_slice2: u64 = typeinfo_make(fn2->ret_type, fn2->ret_ptr_depth);
                        var rsl2: *TypeInfo = (*TypeInfo)result_slice2;
                        rsl2->is_tagged = fn2->ret_is_tagged;
                        return result_slice2;
                    }
                    var result_basic2: u64 = typeinfo_make(fn2->ret_type, fn2->ret_ptr_depth);
                    var rb2: *TypeInfo = (*TypeInfo)result_basic2;
                    rb2->is_tagged = fn2->ret_is_tagged;
                    rb2->struct_name_ptr = fn2->ret_struct_name_ptr;
                    rb2->struct_name_len = fn2->ret_struct_name_len;
                    rb2->tag_layout_ptr = fn2->ret_tag_layout_ptr;
                    rb2->tag_layout_len = fn2->ret_tag_layout_len;
                    return result_basic2;
                }
            }
        }
        return typeinfo_make(TYPE_I64, 0);
    }
    
    if (kind == AST_IDENT) {
        var ident: *AstIdent = (*AstIdent)node;
        var name_ptr: u64 = ident->name_ptr;
        var name_len: u64 = ident->name_len;
        // Need to call symtab_get_type - done by caller with symtab param
        var sym: *Symtab = (*Symtab)symtab;
        var names: u64 = sym->names_vec;
        var types: u64 = sym->types_vec;
        var count: u64 = sym->count;

        if (count == 0) {
            return typeinfo_make(TYPE_I64, 0);
        }

        for (var idx: i64 = (i64)count - 1; idx >= 0; idx = idx - 1) {
            var i: u64 = (u64)idx;
            var name_info: *NameInfo = (*NameInfo)vec_get(names, i);
            var n_ptr: u64 = name_info->ptr;
            var n_len: u64 = name_info->len;
            
            if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
                return vec_get(types, i);
            }

        }

        // Not found - return default type
        return typeinfo_make(TYPE_I64, 0);
    }
    
    if (kind == AST_STRING) {
        return typeinfo_make(TYPE_U8, 1);
    }
    
    if (kind == AST_CAST) {
        var cast_node: *AstCast = (*AstCast)node;
        if (cast_node->target_type == TYPE_STRUCT) {
            var struct_def: u64 = get_struct_def(cast_node->struct_name_ptr, cast_node->struct_name_len);
            var result_struct: u64 = typeinfo_make_struct(cast_node->target_ptr_depth, cast_node->struct_name_ptr, cast_node->struct_name_len, struct_def);
            var rs: *TypeInfo = (*TypeInfo)result_struct;
            rs->is_tagged = cast_node->target_is_tagged;
            return result_struct;
        }

        var result_basic: u64 = typeinfo_make(cast_node->target_type, cast_node->target_ptr_depth);
        var rb: *TypeInfo = (*TypeInfo)result_basic;
        rb->is_tagged = cast_node->target_is_tagged;
        rb->struct_name_ptr = cast_node->struct_name_ptr;
        rb->struct_name_len = cast_node->struct_name_len;
        rb->tag_layout_ptr = cast_node->tag_layout_ptr;
        rb->tag_layout_len = cast_node->tag_layout_len;
        return result_basic;
    }
    
    if (kind == AST_ADDR_OF) {
        var addr_of: *AstAddrOf = (*AstAddrOf)node;
        var operand: u64 = addr_of->operand;
        var op_type: u64 = get_expr_type_with_symtab(operand, symtab);
        if (op_type != 0) {
            var result: u64 = heap_alloc(sizeof(TypeInfo));
            var op_ti: *TypeInfo = (*TypeInfo)op_type;
            var res_ti: *TypeInfo = (*TypeInfo)result;
            res_ti->type_kind = op_ti->type_kind;
            res_ti->ptr_depth = op_ti->ptr_depth + 1;
            res_ti->is_tagged = 0;
            res_ti->struct_def = op_ti->struct_def;
            res_ti->struct_name_ptr = op_ti->struct_name_ptr;
            res_ti->struct_name_len = op_ti->struct_name_len;
            res_ti->tag_layout_ptr = 0;
            res_ti->tag_layout_len = 0;
            res_ti->elem_type_kind = op_ti->elem_type_kind;
            res_ti->elem_ptr_depth = op_ti->elem_ptr_depth;
            res_ti->array_len = op_ti->array_len;
            return result;
        }
    }
    
    if (kind == AST_DEREF) {
        var deref: *AstDeref = (*AstDeref)node;
        var operand: u64 = deref->operand;
        var op_type: u64 = get_expr_type_with_symtab(operand, symtab);
        if (op_type != 0) {
            var op_ti: *TypeInfo = (*TypeInfo)op_type;
            var depth: u64 = op_ti->ptr_depth;
            if (depth > 0) {
                var result: u64 = heap_alloc(sizeof(TypeInfo));
                var res_ti: *TypeInfo = (*TypeInfo)result;
                res_ti->type_kind = op_ti->type_kind;
                res_ti->ptr_depth = depth - 1;
                res_ti->is_tagged = 0;
                res_ti->struct_def = op_ti->struct_def;
                res_ti->struct_name_ptr = op_ti->struct_name_ptr;
                res_ti->struct_name_len = op_ti->struct_name_len;
                res_ti->tag_layout_ptr = 0;
                res_ti->tag_layout_len = 0;
                res_ti->elem_type_kind = op_ti->elem_type_kind;
                res_ti->elem_ptr_depth = op_ti->elem_ptr_depth;
                res_ti->array_len = op_ti->array_len;
                return result;
            }
        }
    }
    
    if (kind == AST_DEREF8) {
        return typeinfo_make(TYPE_U8, 0);
    }

    if (kind == AST_INDEX) {
        var index: *AstIndex = (*AstIndex)node;
        var base: u64 = index->base;
        var base_type: u64 = get_expr_type_with_symtab(base, symtab);
        if (base_type != 0) {
            var bt: *TypeInfo = (*TypeInfo)base_type;
            if (bt->ptr_depth > 0) {
                if (bt->type_kind == TYPE_STRUCT) {
                    return typeinfo_make_struct(bt->ptr_depth - 1, bt->struct_name_ptr, bt->struct_name_len, bt->struct_def);
                }
                return typeinfo_make(bt->type_kind, bt->ptr_depth - 1);
            }
            if (bt->type_kind == TYPE_ARRAY || bt->type_kind == TYPE_SLICE) {
                if (bt->elem_type_kind == TYPE_STRUCT) {
                    return typeinfo_make_struct(bt->elem_ptr_depth, bt->struct_name_ptr, bt->struct_name_len, bt->struct_def);
                }
                return typeinfo_make(bt->elem_type_kind, bt->elem_ptr_depth);
            }
        }
        return typeinfo_make(TYPE_I64, 0);
    }

    if (kind == AST_SLICE) {
        var slice: *AstSlice = (*AstSlice)node;
        var ptr_expr: u64 = slice->ptr_expr;
        var ptr_type: u64 = get_expr_type_with_symtab(ptr_expr, symtab);
        if (ptr_type != 0) {
            var pt: *TypeInfo = (*TypeInfo)ptr_type;
            if (pt->ptr_depth > 0) {
                if (pt->type_kind == TYPE_STRUCT) {
                    return typeinfo_make_slice(0, TYPE_STRUCT, pt->ptr_depth - 1, pt->struct_name_ptr, pt->struct_name_len, pt->struct_def);
                }
                return typeinfo_make_slice(0, pt->type_kind, pt->ptr_depth - 1, 0, 0, 0);
            }
        }
        return typeinfo_make_slice(0, TYPE_U8, 0, 0, 0, 0);
    }
    
    if (kind == AST_MEMBER_ACCESS) {
        var member_access: *AstMemberAccess = (*AstMemberAccess)node;
        var object: u64 = member_access->object;
        var member_ptr: u64 = member_access->member_ptr;
        var member_len: u64 = member_access->member_len;
        
        // Get the type of the object
        var obj_type: u64 = get_expr_type_with_symtab(object, symtab);
        if (obj_type == 0) { return 0; }
        
        var obj_ti: *TypeInfo = (*TypeInfo)obj_type;
        var base_type: u64 = obj_ti->type_kind;
        var ptr_depth: u64 = obj_ti->ptr_depth;

        // Tagged layout bitfield access
        if (ptr_depth > 0 && obj_ti->is_tagged == 1 && obj_ti->tag_layout_ptr != 0) {
            return typeinfo_make(TYPE_U64, 0);
        }
        
        // Handle ptr->field (dereference pointer first)
        if (ptr_depth > 0) {
            ptr_depth = ptr_depth - 1;
        }
        
        if (base_type != TYPE_STRUCT) { return 0; }
        
        var struct_def: u64 = obj_ti->struct_def;
        if (struct_def == 0) { return 0; }
        
        // Find the field in the struct
        var struct_info: *AstStructDef = (*AstStructDef)struct_def;
        var fields: u64 = struct_info->fields_vec;
        var num_fields: u64 = vec_len(fields);
        
        for (var i: u64 = 0; i < num_fields; i++) {
            var field: *FieldDesc = (*FieldDesc)vec_get(fields, i);
            if (str_eq(field->name_ptr, field->name_len, member_ptr, member_len)) {
                var field_type: u64 = field->type_kind;
                var field_ptr_depth: u64 = field->ptr_depth;
                if (field_type == TYPE_STRUCT) {
                    var field_struct_def: u64 = 0;
                    if (g_structs_vec != 0) {
                        var num_structs: u64 = vec_len(g_structs_vec);
                        for (var j: u64 = 0; j < num_structs; j++) {
                            var sd: *AstStructDef = (*AstStructDef)vec_get(g_structs_vec, j);
                            var sname_ptr: u64 = sd->name_ptr;
                            var sname_len: u64 = sd->name_len;
                            if (str_eq(sname_ptr, sname_len, field->struct_name_ptr, field->struct_name_len)) {
                                field_struct_def = (u64)sd;
                                break;
                            }
                        }
                    }
                    var result_struct: u64 = typeinfo_make_struct(field_ptr_depth, field->struct_name_ptr, field->struct_name_len, field_struct_def);
                    var rs: *TypeInfo = (*TypeInfo)result_struct;
                    rs->is_tagged = field->is_tagged;
                    rs->tag_layout_ptr = field->tag_layout_ptr;
                    rs->tag_layout_len = field->tag_layout_len;
                    return result_struct;
                }
                if (field_type == TYPE_ARRAY) {
                    var elem_struct_def: u64 = 0;
                    if (field->elem_type_kind == TYPE_STRUCT && field->struct_name_ptr != 0) {
                        elem_struct_def = get_struct_def(field->struct_name_ptr, field->struct_name_len);
                    }
                    return typeinfo_make_array(field_ptr_depth, field->elem_type_kind, field->elem_ptr_depth, field->struct_name_ptr, field->struct_name_len, elem_struct_def, field->array_len);
                }
                if (field_type == TYPE_SLICE) {
                    var elem_struct_def2: u64 = 0;
                    if (field->elem_type_kind == TYPE_STRUCT && field->struct_name_ptr != 0) {
                        elem_struct_def2 = get_struct_def(field->struct_name_ptr, field->struct_name_len);
                    }
                    return typeinfo_make_slice(field_ptr_depth, field->elem_type_kind, field->elem_ptr_depth, field->struct_name_ptr, field->struct_name_len, elem_struct_def2);
                }
                var result_field: u64 = typeinfo_make(field_type, field_ptr_depth);
                var rf: *TypeInfo = (*TypeInfo)result_field;
                rf->is_tagged = field->is_tagged;
                rf->tag_layout_ptr = field->tag_layout_ptr;
                rf->tag_layout_len = field->tag_layout_len;
                return result_field;
            }
        }
        
        return 0;
    }
    
    if (kind == AST_STRUCT_LITERAL) {
        var lit: *AstStructLiteral = (*AstStructLiteral)node;
        var struct_def: u64 = lit->struct_def;
        return typeinfo_make_struct(0, 0, 0, struct_def);
    }
    
    if (kind == AST_BINARY) {
        var binary: *AstBinary = (*AstBinary)node;
        var op: u64 = binary->op;

        // Logical/comparison operators return i64
        if (op == TOKEN_ANDAND || op == TOKEN_OROR ||
            op == TOKEN_LT || op == TOKEN_GT ||
            op == TOKEN_LTEQ || op == TOKEN_GTEQ ||
            op == TOKEN_EQEQ || op == TOKEN_BANGEQ) {
            return typeinfo_make(TYPE_I64, 0);
        }

        var left: u64 = binary->left;
        var right: u64 = binary->right;
        
        if (op == TOKEN_PLUS || op == TOKEN_MINUS) {
            var left_type: u64 = get_expr_type_with_symtab(left, symtab);
            if (left_type != 0) {
                var left_ti: *TypeInfo = (*TypeInfo)left_type;
                var l_depth: u64 = left_ti->ptr_depth;
                if (l_depth > 0) {
                    var result: u64 = heap_alloc(sizeof(TypeInfo));
                    var res_ti: *TypeInfo = (*TypeInfo)result;
                    res_ti->type_kind = left_ti->type_kind;
                    res_ti->ptr_depth = l_depth;
                    res_ti->is_tagged = left_ti->is_tagged;
                    res_ti->struct_def = left_ti->struct_def;
                    res_ti->struct_name_ptr = 0;
                    res_ti->struct_name_len = 0;
                    res_ti->elem_type_kind = left_ti->elem_type_kind;
                    res_ti->elem_ptr_depth = left_ti->elem_ptr_depth;
                    res_ti->array_len = left_ti->array_len;
                    return result;
                }
            }

            var right_type: u64 = get_expr_type_with_symtab(right, symtab);
            if (right_type != 0) {
                var right_ti: *TypeInfo = (*TypeInfo)right_type;
                var r_depth: u64 = right_ti->ptr_depth;
                if (r_depth > 0) {
                    var result: u64 = heap_alloc(sizeof(TypeInfo));
                    var res_ti: *TypeInfo = (*TypeInfo)result;
                    res_ti->type_kind = right_ti->type_kind;
                    res_ti->ptr_depth = r_depth;
                    res_ti->is_tagged = right_ti->is_tagged;
                    res_ti->struct_def = right_ti->struct_def;
                    res_ti->struct_name_ptr = 0;
                    res_ti->struct_name_len = 0;
                    res_ti->elem_type_kind = right_ti->elem_type_kind;
                    res_ti->elem_ptr_depth = right_ti->elem_ptr_depth;
                    res_ti->array_len = right_ti->array_len;
                    return result;
                }
            }
        }
    }
    
    if (kind == AST_LITERAL) {
        return typeinfo_make(TYPE_I64, 0);
    }
    
    // Default
    return typeinfo_make(TYPE_I64, 0);
}
