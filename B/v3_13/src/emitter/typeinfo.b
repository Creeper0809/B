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

// Global struct definitions (set by codegen before use)
var g_structs_vec;

func typeinfo_set_structs(structs: u64) -> u64 {
    g_structs_vec = structs;
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
    }
    return 8;
}

func check_type_compat(from_base: u64, from_depth: u64, to_base: u64, to_depth: u64) -> u64 {
    if (from_base == to_base) {
        if (from_depth == to_depth) { return 0; }
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
            
            // Recursively calculate field size
            var field_size: u64 = sizeof_type(field->type_kind, field->ptr_depth, field->struct_name_ptr, field->struct_name_len);
            total_size = total_size + field_size;
        }
        
        return total_size;
    }
    
    // Default: 8 bytes
    return 8;
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
        var field_size: u64 = sizeof_type(field->type_kind, field->ptr_depth, field->struct_name_ptr, field->struct_name_len);
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
    
    if (kind == AST_IDENT) {
        var name_ptr: u64 = *(node + 8);
        var name_len: u64 = *(node + 16);
        // Need to call symtab_get_type - done by caller with symtab param
        var names: u64 = *(symtab);
        var types: u64 = *(symtab + 16);
        var count: u64 = *(symtab + 24);
        
        var i: u64 = count - 1;
        while (i >= 0) {
            var name_info: u64 = vec_get(names, i);
            var n_ptr: u64 = *(name_info);
            var n_len: u64 = *(name_info + 8);
            
            if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
                return vec_get(types, i);
            }
            i = i - 1;
        }
        
        // Not found - return default type
        var result: u64 = heap_alloc(16);
        *(result) = TYPE_I64;
        *(result + 8) = 0;
        return result;
    }
    
    if (kind == AST_STRING) {
        var result: u64 = heap_alloc(16);
        *(result) = TYPE_U8;
        *(result + 8) = 1;
        return result;
    }
    
    if (kind == AST_CAST) {
        var result: u64 = heap_alloc(16);
        *(result) = *(node + 16);
        *(result + 8) = *(node + 24);
        return result;
    }
    
    if (kind == AST_ADDR_OF) {
        var operand: u64 = *(node + 8);
        var op_type: u64 = get_expr_type_with_symtab(operand, symtab);
        if (op_type != 0) {
            var result: u64 = heap_alloc(24);
            *(result) = *(op_type);
            *(result + 8) = *(op_type + 8) + 1;
            *(result + 16) = *(op_type + 16);  // Copy struct_def
            return result;
        }
    }
    
    if (kind == AST_DEREF) {
        var operand: u64 = *(node + 8);
        var op_type: u64 = get_expr_type_with_symtab(operand, symtab);
        if (op_type != 0) {
            var depth: u64 = *(op_type + 8);
            if (depth > 0) {
                var result: u64 = heap_alloc(24);
                *(result) = *(op_type);
                *(result + 8) = depth - 1;
                *(result + 16) = *(op_type + 16);  // Copy struct_def
                return result;
            }
        }
    }
    
    if (kind == AST_DEREF8) {
        var result: u64 = heap_alloc(16);
        *(result) = TYPE_U8;
        *(result + 8) = 0;
        return result;
    }
    
    if (kind == AST_MEMBER_ACCESS) {
        var object: u64 = *(node + 8);
        var member_ptr: u64 = *(node + 16);
        var member_len: u64 = *(node + 24);
        
        // Get the type of the object
        var obj_type: u64 = get_expr_type_with_symtab(object, symtab);
        if (obj_type == 0) { return 0; }
        
        var base_type: u64 = *(obj_type);
        var ptr_depth: u64 = *(obj_type + 8);
        
        // Handle ptr->field (dereference pointer first)
        if (ptr_depth > 0) {
            ptr_depth = ptr_depth - 1;
        }
        
        if (base_type != TYPE_STRUCT) { return 0; }
        
        var struct_def: u64 = *(obj_type + 16);
        if (struct_def == 0) { return 0; }
        
        // Find the field in the struct
        var fields: u64 = *(struct_def + 24);
        var num_fields: u64 = vec_len(fields);
        
        for (var i: u64 = 0; i < num_fields; i++) {
            var field: u64 = vec_get(fields, i);
            var fname_ptr: u64 = *(field);
            var fname_len: u64 = *(field + 8);
            
            if (str_eq(fname_ptr, fname_len, member_ptr, member_len)) {
                var field_type: u64 = *(field + 16);
                var field_struct_name_ptr: u64 = *(field + 24);
                var field_struct_name_len: u64 = *(field + 32);
                var field_ptr_depth: u64 = *(field + 40);
                
                // Return the field's type
                var result: u64 = heap_alloc(24);
                *(result) = field_type;
                *(result + 8) = field_ptr_depth;
                
                // If field is a struct, find its struct_def
                if (field_type == TYPE_STRUCT) {
                    var field_struct_def: u64 = 0;
                    if (g_structs_vec != 0) {
                        var num_structs: u64 = vec_len(g_structs_vec);
                        for (var j: u64 = 0; j < num_structs; j++) {
                            var sd: u64 = vec_get(g_structs_vec, j);
                            var sname_ptr: u64 = *(sd + 8);
                            var sname_len: u64 = *(sd + 16);
                            if (str_eq(sname_ptr, sname_len, field_struct_name_ptr, field_struct_name_len)) {
                                field_struct_def = sd;
                                break;
                            }
                        }
                    }
                    *(result + 16) = field_struct_def;
                }
                
                return result;
            }
        }
        
        return 0;
    }
    
    if (kind == AST_STRUCT_LITERAL) {
        var struct_def: u64 = *(node + 8);
        var result: u64 = heap_alloc(24);
        *(result) = TYPE_STRUCT;
        *(result + 8) = 0;  // ptr_depth = 0
        *(result + 16) = struct_def;
        return result;
    }
    
    if (kind == AST_BINARY) {
        var op: u64 = *(node + 8);

        // Logical/comparison operators return i64
        if (op == TOKEN_ANDAND || op == TOKEN_OROR ||
            op == TOKEN_LT || op == TOKEN_GT ||
            op == TOKEN_LTEQ || op == TOKEN_GTEQ ||
            op == TOKEN_EQEQ || op == TOKEN_BANGEQ) {
            var result: u64 = heap_alloc(16);
            *(result) = TYPE_I64;
            *(result + 8) = 0;
            return result;
        }

        var left: u64 = *(node + 16);
        var right: u64 = *(node + 24);
        
        if (op == TOKEN_PLUS || op == TOKEN_MINUS) {
            var left_type: u64 = get_expr_type_with_symtab(left, symtab);
            if (left_type != 0) {
                var l_depth: u64 = *(left_type + 8);
                if (l_depth > 0) {
                    var result: u64 = heap_alloc(16);
                    *(result) = *(left_type);
                    *(result + 8) = l_depth;
                    return result;
                }
            }

            var right_type: u64 = get_expr_type_with_symtab(right, symtab);
            if (right_type != 0) {
                var r_depth: u64 = *(right_type + 8);
                if (r_depth > 0) {
                    var result: u64 = heap_alloc(16);
                    *(result) = *(right_type);
                    *(result + 8) = r_depth;
                    return result;
                }
            }
        }
    }
    
    if (kind == AST_LITERAL) {
        var result: u64 = heap_alloc(16);
        *(result) = TYPE_I64;
        *(result + 8) = 0;
        return result;
    }
    
    // Default
    var result: u64 = heap_alloc(16);
    *(result) = TYPE_I64;
    *(result + 8) = 0;
    return result;
}
