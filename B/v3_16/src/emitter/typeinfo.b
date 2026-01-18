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
import types;
import ast;

func typeinfo_make(base_type: u64, ptr_depth: u64) -> u64 {
    var result: u64 = heap_alloc(SIZEOF_TYPEINFO);
    var ti: *TypeInfo = (*TypeInfo)result;
    ti->type_kind = base_type;
    ti->ptr_depth = ptr_depth;
    ti->is_tagged = 0;
    ti->struct_name_ptr = 0;
    ti->struct_name_len = 0;
    ti->struct_def = 0;
    ti->elem_type_kind = 0;
    ti->elem_ptr_depth = 0;
    ti->array_len = 0;
    return result;
}

func typeinfo_make_struct(ptr_depth: u64, struct_name_ptr: u64, struct_name_len: u64, struct_def: u64) -> u64 {
    var result: u64 = heap_alloc(SIZEOF_TYPEINFO);
    var ti: *TypeInfo = (*TypeInfo)result;
    ti->type_kind = TYPE_STRUCT;
    ti->ptr_depth = ptr_depth;
    ti->is_tagged = 0;
    ti->struct_name_ptr = struct_name_ptr;
    ti->struct_name_len = struct_name_len;
    ti->struct_def = struct_def;
    ti->elem_type_kind = 0;
    ti->elem_ptr_depth = 0;
    ti->array_len = 0;
    return result;
}

func typeinfo_make_array(ptr_depth: u64, elem_type_kind: u64, elem_ptr_depth: u64, elem_struct_name_ptr: u64, elem_struct_name_len: u64, elem_struct_def: u64, array_len: u64) -> u64 {
    var result: u64 = heap_alloc(SIZEOF_TYPEINFO);
    var ti: *TypeInfo = (*TypeInfo)result;
    ti->type_kind = TYPE_ARRAY;
    ti->ptr_depth = ptr_depth;
    ti->is_tagged = 0;
    ti->struct_name_ptr = elem_struct_name_ptr;
    ti->struct_name_len = elem_struct_name_len;
    ti->struct_def = elem_struct_def;
    ti->elem_type_kind = elem_type_kind;
    ti->elem_ptr_depth = elem_ptr_depth;
    ti->array_len = array_len;
    return result;
}

func typeinfo_make_slice(ptr_depth: u64, elem_type_kind: u64, elem_ptr_depth: u64, elem_struct_name_ptr: u64, elem_struct_name_len: u64, elem_struct_def: u64) -> u64 {
    var result: u64 = heap_alloc(SIZEOF_TYPEINFO);
    var ti: *TypeInfo = (*TypeInfo)result;
    ti->type_kind = TYPE_SLICE;
    ti->ptr_depth = ptr_depth;
    ti->is_tagged = 0;
    ti->struct_name_ptr = elem_struct_name_ptr;
    ti->struct_name_len = elem_struct_name_len;
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
    if (field->type_kind == TYPE_ARRAY) {
        var elem_size: u64 = sizeof_type(field->elem_type_kind, field->elem_ptr_depth, field->struct_name_ptr, field->struct_name_len);
        return elem_size * field->array_len;
    }
    if (field->type_kind == TYPE_SLICE) { return 16; }
    return sizeof_type(field->type_kind, field->ptr_depth, field->struct_name_ptr, field->struct_name_len);
}

func get_field_desc(struct_def: u64, field_name_ptr: u64, field_name_len: u64) -> u64 {
    var fields: u64 = *(struct_def + 24);
    var num_fields: u64 = vec_len(fields);
    for (var i: u64 = 0; i < num_fields; i++) {
        var field: *FieldDesc = (*FieldDesc)vec_get(fields, i);
        if (str_eq(field->name_ptr, field->name_len, field_name_ptr, field_name_len)) {
            return (u64)field;
        }
    }
    return 0;
}

func check_type_compat(from_base: u64, from_depth: u64, from_tagged: u64, to_base: u64, to_depth: u64, to_tagged: u64) -> u64 {
    if (from_base == TYPE_ARRAY || to_base == TYPE_ARRAY || from_base == TYPE_SLICE || to_base == TYPE_SLICE) {
        if (from_base == to_base && from_depth == to_depth) { return 0; }
        return 1;
    }
    if (from_base == to_base) {
        if (from_depth == to_depth) {
            if (from_depth > 0 && from_tagged != to_tagged) { return 1; }
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
            var candidate: u64 = vec_get(g_structs_vec, si);
            var candidate_name_ptr: u64 = *(candidate + 8);
            var candidate_name_len: u64 = *(candidate + 16);
            
            if (str_eq(candidate_name_ptr, candidate_name_len, struct_name_ptr, struct_name_len)) {
                struct_def = candidate;
                break;
            }
        }
        
        if (struct_def == 0) { return 8; }
        
        var fields: u64 = *(struct_def + 24);
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
    var fields: u64 = *(struct_def + 24);
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

    if (kind == AST_CALL) {
        if (g_funcs_vec != 0) {
            var call: *AstCall = (*AstCall)node;
            var name_ptr: u64 = call->name_ptr;
            var name_len: u64 = call->name_len;
            var num_funcs: u64 = vec_len(g_funcs_vec);
            for (var i: u64 = 0; i < num_funcs; i++) {
                var fn_ptr: u64 = vec_get(g_funcs_vec, i);
                var fn: *AstFunc = (*AstFunc)fn_ptr;
                if (str_eq(fn->name_ptr, fn->name_len, name_ptr, name_len)) {
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
                    return result_basic;
                }
            }
        }
        return typeinfo_make(TYPE_I64, 0);
    }
    
    if (kind == AST_IDENT) {
        var name_ptr: u64 = *(node + 8);
        var name_len: u64 = *(node + 16);
        // Need to call symtab_get_type - done by caller with symtab param
        var names: u64 = *(symtab);
        var types: u64 = *(symtab + 16);
        var count: u64 = *(symtab + 24);

        if (count == 0) {
            return typeinfo_make(TYPE_I64, 0);
        }

        var idx: i64 = (i64)count - 1;
        while (idx >= 0) {
            var i: u64 = (u64)idx;
            var name_info: u64 = vec_get(names, i);
            var n_ptr: u64 = *(name_info);
            var n_len: u64 = *(name_info + 8);
            
            if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
                return vec_get(types, i);
            }

            idx = idx - 1;
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
        return result_basic;
    }
    
    if (kind == AST_ADDR_OF) {
        var operand: u64 = *(node + 8);
        var op_type: u64 = get_expr_type_with_symtab(operand, symtab);
        if (op_type != 0) {
            var result: u64 = heap_alloc(SIZEOF_TYPEINFO);
            var op_ti: *TypeInfo = (*TypeInfo)op_type;
            var res_ti: *TypeInfo = (*TypeInfo)result;
            res_ti->type_kind = op_ti->type_kind;
            res_ti->ptr_depth = op_ti->ptr_depth + 1;
            res_ti->is_tagged = 0;
            res_ti->struct_def = op_ti->struct_def;
            res_ti->struct_name_ptr = op_ti->struct_name_ptr;
            res_ti->struct_name_len = op_ti->struct_name_len;
            res_ti->elem_type_kind = op_ti->elem_type_kind;
            res_ti->elem_ptr_depth = op_ti->elem_ptr_depth;
            res_ti->array_len = op_ti->array_len;
            return result;
        }
    }
    
    if (kind == AST_DEREF) {
        var operand: u64 = *(node + 8);
        var op_type: u64 = get_expr_type_with_symtab(operand, symtab);
        if (op_type != 0) {
            var op_ti: *TypeInfo = (*TypeInfo)op_type;
            var depth: u64 = op_ti->ptr_depth;
            if (depth > 0) {
                var result: u64 = heap_alloc(SIZEOF_TYPEINFO);
                var res_ti: *TypeInfo = (*TypeInfo)result;
                res_ti->type_kind = op_ti->type_kind;
                res_ti->ptr_depth = depth - 1;
                res_ti->is_tagged = 0;
                res_ti->struct_def = op_ti->struct_def;
                res_ti->struct_name_ptr = op_ti->struct_name_ptr;
                res_ti->struct_name_len = op_ti->struct_name_len;
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
        var base: u64 = *(node + 8);
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
        var ptr_expr: u64 = *(node + 8);
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
        var object: u64 = *(node + 8);
        var member_ptr: u64 = *(node + 16);
        var member_len: u64 = *(node + 24);
        
        // Get the type of the object
        var obj_type: u64 = get_expr_type_with_symtab(object, symtab);
        if (obj_type == 0) { return 0; }
        
        var obj_ti: *TypeInfo = (*TypeInfo)obj_type;
        var base_type: u64 = obj_ti->type_kind;
        var ptr_depth: u64 = obj_ti->ptr_depth;
        
        // Handle ptr->field (dereference pointer first)
        if (ptr_depth > 0) {
            ptr_depth = ptr_depth - 1;
        }
        
        if (base_type != TYPE_STRUCT) { return 0; }
        
        var struct_def: u64 = obj_ti->struct_def;
        if (struct_def == 0) { return 0; }
        
        // Find the field in the struct
        var fields: u64 = *(struct_def + 24);
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
                            var sd: u64 = vec_get(g_structs_vec, j);
                            var sname_ptr: u64 = *(sd + 8);
                            var sname_len: u64 = *(sd + 16);
                            if (str_eq(sname_ptr, sname_len, field->struct_name_ptr, field->struct_name_len)) {
                                field_struct_def = sd;
                                break;
                            }
                        }
                    }
                    var result_struct: u64 = typeinfo_make_struct(field_ptr_depth, field->struct_name_ptr, field->struct_name_len, field_struct_def);
                    var rs: *TypeInfo = (*TypeInfo)result_struct;
                    rs->is_tagged = field->is_tagged;
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
                return result_field;
            }
        }
        
        return 0;
    }
    
    if (kind == AST_STRUCT_LITERAL) {
        var struct_def: u64 = *(node + 8);
        return typeinfo_make_struct(0, 0, 0, struct_def);
    }
    
    if (kind == AST_BINARY) {
        var op: u64 = *(node + 8);

        // Logical/comparison operators return i64
        if (op == TOKEN_ANDAND || op == TOKEN_OROR ||
            op == TOKEN_LT || op == TOKEN_GT ||
            op == TOKEN_LTEQ || op == TOKEN_GTEQ ||
            op == TOKEN_EQEQ || op == TOKEN_BANGEQ) {
            return typeinfo_make(TYPE_I64, 0);
        }

        var left: u64 = *(node + 16);
        var right: u64 = *(node + 24);
        
        if (op == TOKEN_PLUS || op == TOKEN_MINUS) {
            var left_type: u64 = get_expr_type_with_symtab(left, symtab);
            if (left_type != 0) {
                var left_ti: *TypeInfo = (*TypeInfo)left_type;
                var l_depth: u64 = left_ti->ptr_depth;
                if (l_depth > 0) {
                    var result: u64 = heap_alloc(SIZEOF_TYPEINFO);
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
                    var result: u64 = heap_alloc(SIZEOF_TYPEINFO);
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
