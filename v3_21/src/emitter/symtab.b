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
import std.str;
import types;

// Local layout mirrors for sizeof (avoid sizeof on imported types during bootstrap).
struct SymtabLocal { names_vec: u64; offsets_vec: u64; types_vec: u64; count: u64; stack_offset: u64; }
struct NameInfoLocal { ptr: u64; len: u64; }

// ============================================
// Symbol Table
// ============================================

func symtab_new() -> u64 {
    var s: u64 = heap_alloc(sizeof(SymtabLocal));
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
    var names: *Vec = (*Vec)names_vec;
    names->length = 0;
    var offsets_vec: u64 = symtab->offsets_vec;
    var offsets: *Vec = (*Vec)offsets_vec;
    offsets->length = 0;
    var types_vec: u64 = symtab->types_vec;
    var types: *Vec = (*Vec)types_vec;
    types->length = 0;
}

func symtab_add(s: u64, name_ptr: u64, name_len: u64, type_kind: u64, ptr_depth: u64, size: u64) -> u64 {
    var symtab: *Symtab = (*Symtab)s;
    
    // Allocate on stack (grow downward)
    var offset: u64 = symtab->stack_offset - size;
    symtab->stack_offset = offset;
    
    // Add name info
    var name_info: *NameInfo = (*NameInfo)heap_alloc(sizeof(NameInfoLocal));
    name_info->ptr = name_ptr;
    name_info->len = name_len;
    vec_push(symtab->names_vec, (u64)name_info);
    
    // Add offset
    vec_push(symtab->offsets_vec, offset);
    
    // Add type info
    var type_info: u64 = heap_alloc(sizeof(TypeInfo));
    var ti: *TypeInfo = (*TypeInfo)type_info;
    ti->type_kind = type_kind;
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
    vec_push(symtab->types_vec, type_info);
    
    symtab->count = symtab->count + 1;
    
    return offset;
}

func symtab_find(s: u64, name_ptr: u64, name_len: u64) -> u64 {
    var symtab: *Symtab = (*Symtab)s;
    var names: u64 = symtab->names_vec;
    var offsets: u64 = symtab->offsets_vec;
    var count: u64 = symtab->count;
    
    if (count == 0) { return 0; }

    for (var idx: i64 = (i64)count - 1; idx >= 0; idx = idx - 1) {
        var i: u64 = (u64)idx;
        var name_info: *NameInfo = (*NameInfo)vec_get(names, i);
        var n_ptr: u64 = name_info->ptr;
        var n_len: u64 = name_info->len;
        
        if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
            return vec_get(offsets, i);
        }

    }
    
    return 0;
}

func symtab_get_type(s: u64, name_ptr: u64, name_len: u64) -> u64 {
    var symtab: *Symtab = (*Symtab)s;
    var names: u64 = symtab->names_vec;
    var types: u64 = symtab->types_vec;
    var count: u64 = symtab->count;
    
    if (count == 0) { return 0; }

    for (var idx: i64 = (i64)count - 1; idx >= 0; idx = idx - 1) {
        var i: u64 = (u64)idx;
        var name_info: *NameInfo = (*NameInfo)vec_get(names, i);
        var n_ptr: u64 = name_info->ptr;
        var n_len: u64 = name_info->len;
        
        if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
            return vec_get(types, i);
        }

    }
    
    return 0;
}

func symtab_update_type(s: u64, name_ptr: u64, name_len: u64, type_kind: u64, ptr_depth: u64) -> u64 {
    var symtab: *Symtab = (*Symtab)s;
    var names: u64 = symtab->names_vec;
    var types: u64 = symtab->types_vec;
    var count: u64 = symtab->count;
    
    if (count == 0) { return; }

    for (var idx: i64 = (i64)count - 1; idx >= 0; idx = idx - 1) {
        var i: u64 = (u64)idx;
        var name_info: *NameInfo = (*NameInfo)vec_get(names, i);
        var n_ptr: u64 = name_info->ptr;
        var n_len: u64 = name_info->len;
        
        if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
            var type_info: u64 = vec_get(types, i);
            var ti: *TypeInfo = (*TypeInfo)type_info;
            ti->type_kind = type_kind;
            ti->ptr_depth = ptr_depth;
            return;
        }

    }
}
