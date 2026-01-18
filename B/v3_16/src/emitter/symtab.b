// symtab.b - Symbol table for code generation
//
// Symbol table structure: [names_vec, offsets_vec, types_vec, count, stack_offset]
// - names_vec: vector of [name_ptr, name_len] pairs
// - offsets_vec: vector of stack offsets (i64)
// - types_vec: vector of TypeInfo (TypeInfo is 40 bytes)
// - count: number of symbols
// - stack_offset: current stack offset for allocation

import std.io;
import std.vec;
import std.util;
import types;

// ============================================
// Symbol Table
// ============================================

func symtab_new() -> u64 {
    var s: u64 = heap_alloc(40);
    var symtab: *Symtab = (*Symtab)s;
    symtab->names_vec = vec_new(64);
    symtab->offsets_vec = vec_new(64);
    symtab->types_vec = vec_new(64);
    symtab->count = 0;
    symtab->stack_offset = 0;
    return s;
}

func symtab_clear(s: u64) -> u64 {
    var symtab: *Symtab = (*Symtab)s;
    symtab->count = 0;
    symtab->stack_offset = 0;

    var names_vec: u64 = symtab->names_vec;
    *(names_vec + 8) = 0;
    var offsets_vec: u64 = symtab->offsets_vec;
    *(offsets_vec + 8) = 0;
    var types_vec: u64 = symtab->types_vec;
    *(types_vec + 8) = 0;
}

func symtab_add(s: u64, name_ptr: u64, name_len: u64, type_kind: u64, ptr_depth: u64, size: u64) -> u64 {
    var symtab: *Symtab = (*Symtab)s;
    
    // Allocate on stack (grow downward)
    var offset: u64 = symtab->stack_offset - size;
    symtab->stack_offset = offset;
    
    // Add name info
    var name_info: u64 = heap_alloc(16);
    *(name_info) = name_ptr;
    *(name_info + 8) = name_len;
    vec_push(symtab->names_vec, name_info);
    
    // Add offset
    vec_push(symtab->offsets_vec, offset);
    
    // Add type info
    var type_info: u64 = heap_alloc(SIZEOF_TYPEINFO);
    var ti: *TypeInfo = (*TypeInfo)type_info;
    ti->type_kind = type_kind;
    ti->ptr_depth = ptr_depth;
    ti->is_tagged = 0;
    ti->struct_name_ptr = 0;
    ti->struct_name_len = 0;
    ti->struct_def = 0;
    ti->elem_type_kind = 0;
    ti->elem_ptr_depth = 0;
    ti->array_len = 0;
    vec_push(symtab->types_vec, type_info);
    
    symtab->count = symtab->count + 1;
    
    return offset;
}

func symtab_find(s: u64, name_ptr: u64, name_len: u64) -> u64 {
    var names: u64 = *(s);
    var offsets: u64 = *(s + 8);
    var count: u64 = *(s + 24);
    
    if (count == 0) { return 0; }

    var idx: i64 = (i64)count - 1;
    while (idx >= 0) {
        var i: u64 = (u64)idx;
        var name_info: u64 = vec_get(names, i);
        var n_ptr: u64 = *(name_info);
        var n_len: u64 = *(name_info + 8);
        
        if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
            return vec_get(offsets, i);
        }

        idx = idx - 1;
    }
    
    return 0;
}

func symtab_get_type(s: u64, name_ptr: u64, name_len: u64) -> u64 {
    var names: u64 = *(s);
    var types: u64 = *(s + 16);
    var count: u64 = *(s + 24);
    
    if (count == 0) { return 0; }

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
    
    return 0;
}

func symtab_update_type(s: u64, name_ptr: u64, name_len: u64, type_kind: u64, ptr_depth: u64) -> u64 {
    var names: u64 = *(s);
    var types: u64 = *(s + 16);
    var count: u64 = *(s + 24);
    
    if (count == 0) { return; }

    var idx: i64 = (i64)count - 1;
    while (idx >= 0) {
        var i: u64 = (u64)idx;
        var name_info: u64 = vec_get(names, i);
        var n_ptr: u64 = *(name_info);
        var n_len: u64 = *(name_info + 8);
        
        if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
            var type_info: u64 = vec_get(types, i);
            var ti: *TypeInfo = (*TypeInfo)type_info;
            ti->type_kind = type_kind;
            ti->ptr_depth = ptr_depth;
            return;
        }

        idx = idx - 1;
    }
}
