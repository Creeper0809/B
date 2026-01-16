// symtab.b - Symbol table for code generation
//
// Symbol table structure: [names_vec, offsets_vec, types_vec, count, stack_offset]
// - names_vec: vector of [name_ptr, name_len] pairs
// - offsets_vec: vector of stack offsets (i64)
// - types_vec: vector of [type_kind, ptr_depth, struct_def] triples
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
    var st: *Symtab = (*Symtab)s;
    st->names_vec = vec_new(64);
    st->offsets_vec = vec_new(64);
    st->types_vec = vec_new(64);
    st->count = 0;
    st->stack_offset = 0;
    return s;
}

func symtab_clear(s: u64) -> u64 {
    var st: *Symtab = (*Symtab)s;
    st->count = 0;
    st->stack_offset = 0;
    
    var names: u64 = st->names_vec;
    *(names + 8) = 0;         // names.len = 0
    var offsets: u64 = st->offsets_vec;
    *(offsets + 8) = 0;       // offsets.len = 0
    var types: u64 = st->types_vec;
    *(types + 8) = 0;         // types.len = 0
}

func symtab_add(s: u64, name_ptr: u64, name_len: u64, type_kind: u64, ptr_depth: u64, size: u64) -> u64 {
    var st: *Symtab = (*Symtab)s;
    var names: u64 = st->names_vec;
    var offsets: u64 = st->offsets_vec;
    var types: u64 = st->types_vec;
    var count: u64 = st->count;
    
    // Allocate on stack (grow downward)
    var offset: u64 = st->stack_offset - size;
    st->stack_offset = offset;
    
    // Add name info
    var name_info: u64 = heap_alloc(16);
    *(name_info) = name_ptr;
    *(name_info + 8) = name_len;
    vec_push(names, name_info);
    
    // Add offset
    vec_push(offsets, offset);
    
    // Add type info
    var type_info: u64 = heap_alloc(24);
    *(type_info) = type_kind;
    *(type_info + 8) = ptr_depth;
    *(type_info + 16) = 0;  // struct_def pointer (filled later for TYPE_STRUCT)
    vec_push(types, type_info);
    
    st->count = count + 1;
    
    return offset;
}

func symtab_find(s: u64, name_ptr: u64, name_len: u64) -> u64 {
    var st: *Symtab = (*Symtab)s;
    var names: u64 = st->names_vec;
    var offsets: u64 = st->offsets_vec;
    var count: u64 = st->count;
    
    var i: u64 = count - 1;
    while (i >= 0) {
        var name_info: u64 = vec_get(names, i);
        var n_ptr: u64 = *(name_info);
        var n_len: u64 = *(name_info + 8);
        
        if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
            return vec_get(offsets, i);
        }
        i = i - 1;
    }
    
    return 0;
}

func symtab_get_type(s: u64, name_ptr: u64, name_len: u64) -> u64 {
    var st: *Symtab = (*Symtab)s;
    var names: u64 = st->names_vec;
    var types: u64 = st->types_vec;
    var count: u64 = st->count;
    
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
    
    return 0;
}

func symtab_update_type(s: u64, name_ptr: u64, name_len: u64, type_kind: u64, ptr_depth: u64) -> u64 {
    var st: *Symtab = (*Symtab)s;
    var names: u64 = st->names_vec;
    var types: u64 = st->types_vec;
    var count: u64 = st->count;
    
    var i: u64 = count - 1;
    while (i >= 0) {
        var name_info: u64 = vec_get(names, i);
        var n_ptr: u64 = *(name_info);
        var n_len: u64 = *(name_info + 8);
        
        if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
            var type_info: u64 = vec_get(types, i);
            *(type_info) = type_kind;
            *(type_info + 8) = ptr_depth;
            return;
        }
        i = i - 1;
    }
}
