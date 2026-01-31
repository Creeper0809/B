// emitter.b - ASM output helpers, labels, string/data tables, global state
//
// This module contains:
// - Global codegen state (symtab, label counter, strings, loops, etc.)
// - Label generation and emission
// - String literal table management
// - Global variable BSS emission
// - Constant lookup

import std.io;
import std.vec;
import std.util;
import std.str;
import types;

// Local layout structs for sizeof during bootstrap
struct SymtabLocal {
    names_vec: u64;
    offsets_vec: u64;
    types_vec: u64;
    count: u64;
    stack_offset: u64;
}

struct ConstInfoLocal {
    name_ptr: u64;
    name_len: u64;
    value: u64;
}

struct ConstResultLocal {
    found: u64;
    value: u64;
}

struct StringEntryLocal {
    str_ptr: u64;
    str_len: u64;
    label_id: u64;
}

// ============================================
// Global Codegen State
// ============================================

var g_symtab;                       // Symbol table for current function
var g_label_counter;                // Label counter for unique labels
var g_consts;                       // Global constants table
var g_strings;                      // String literals table
var g_loop_labels;                  // Stack of loop end labels for break
var g_loop_continue_labels;         // Stack of loop continue labels
var g_globals;                      // Global variables list

// Current function return type information (for struct return)
var g_current_func_ret_type;
var g_current_func_ret_ptr_depth;
var g_current_func_ret_struct_name_ptr;
var g_current_func_ret_struct_name_len;

// ============================================
// State Accessors
// ============================================

func emitter_get_symtab() -> u64 { return g_symtab; }
func emitter_set_symtab(s: u64) -> u64 { g_symtab = s; }

func emitter_get_globals() -> u64 { return g_globals; }
func emitter_set_globals(g: u64) -> u64 { g_globals = g; }

func emitter_get_consts() -> u64 { return g_consts; }
func emitter_set_consts(c: u64) -> u64 { g_consts = c; }

func emitter_get_loop_labels() -> u64 { return g_loop_labels; }
func emitter_get_continue_labels() -> u64 { return g_loop_continue_labels; }

func emitter_set_ret_type(t: u64) -> u64 { g_current_func_ret_type = t; }
func emitter_set_ret_ptr_depth(d: u64) -> u64 { g_current_func_ret_ptr_depth = d; }
func emitter_set_ret_struct_name(ptr: u64, len: u64) -> u64 {
    g_current_func_ret_struct_name_ptr = ptr;
    g_current_func_ret_struct_name_len = len;
}

func emitter_get_ret_type() -> u64 { return g_current_func_ret_type; }
func emitter_get_ret_ptr_depth() -> u64 { return g_current_func_ret_ptr_depth; }
func emitter_get_ret_struct_name_ptr() -> u64 { return g_current_func_ret_struct_name_ptr; }
func emitter_get_ret_struct_name_len() -> u64 { return g_current_func_ret_struct_name_len; }

// ============================================
// Initialization
// ============================================

func emitter_init() -> u64 {
    // Create symtab inline instead of calling symtab_new
    // symtab = [names_vec, offsets_vec, types_vec, count, stack_offset]
    g_symtab = heap_alloc(sizeof(SymtabLocal));
    var symtab: *Symtab = (*Symtab)g_symtab;
    symtab->names_vec = vec_new(64);
    symtab->offsets_vec = vec_new(64);
    symtab->types_vec = vec_new(64);
    symtab->count = 0;
    symtab->stack_offset = 0 - 8;        // stack_offset (starts at -8)
    
    g_label_counter = 0;
    g_strings = vec_new(32);
    g_loop_labels = vec_new(16);
    g_loop_continue_labels = vec_new(16);
    g_consts = vec_new(64);
}

func emitter_set_globals_from_prog(globals: u64) -> u64 {
    if (globals == 0) {
        g_globals = vec_new(32);
    } else {
        g_globals = globals;
    }
}

func emitter_load_consts(consts: u64) -> u64 {
    g_consts = vec_new(64);
    var clen: u64 = vec_len(consts);
    for (var ci: u64 = 0; ci < clen; ci++) {
        var c: u64 = vec_get(consts, ci);
        var const_decl: *AstConstDecl = (*AstConstDecl)c;
        var cinfo: u64 = heap_alloc(sizeof(ConstInfoLocal));
        var cinfo_struct: *ConstInfo = (*ConstInfo)cinfo;
        cinfo_struct->name_ptr = const_decl->name_ptr;
        cinfo_struct->name_len = const_decl->name_len;
        cinfo_struct->value = const_decl->value;
        vec_push(g_consts, cinfo);
    }
}

// ============================================
// Global Variable Check
// ============================================

func is_global_var(name_ptr: u64, name_len: u64) -> u64 {
    var len: u64 = vec_len(g_globals);
    for (var i: u64 = 0; i < len; i++) {
        var ginfo: *GlobalInfo = (*GlobalInfo)vec_get(g_globals, i);
        if (str_eq(ginfo->name_ptr, ginfo->name_len, name_ptr, name_len)) {
            return 1;
        }
    }
    return 0;
}

// ============================================
// Constants Lookup
// ============================================

func const_find(name_ptr: u64, name_len: u64) -> u64 {
    var len: u64 = vec_len(g_consts);
    for (var i: u64 = 0; i < len; i++) {
        var c: u64 = vec_get(g_consts, i);
        var cinfo: *ConstInfo = (*ConstInfo)c;
        if (str_eq(cinfo->name_ptr, cinfo->name_len, name_ptr, name_len)) {
            var result: u64 = heap_alloc(sizeof(ConstResultLocal));
            var result_struct: *ConstResult = (*ConstResult)result;
            result_struct->found = 1;
            result_struct->value = cinfo->value;
            return result;
        }
    }
    var result: u64 = heap_alloc(sizeof(ConstResultLocal));
    var result_struct: *ConstResult = (*ConstResult)result;
    result_struct->found = 0;
    return result;
}

// ============================================
// Labels
// ============================================

func new_label() -> u64 {
    var l: u64 = g_label_counter;
    g_label_counter = g_label_counter + 1;
    return l;
}

func emit_label(n: u64) -> u64 {
    emit(".L", 2);
    emit_u64(n);
}

func emit_label_def(n: u64) -> u64 {
    emit_label(n);
    emit(":", 1);
    emit_nl();
}

// ============================================
// String Literals Table
// ============================================

func string_table_init() -> u64 {
    g_strings = vec_new(32);
}

func string_get_label(str_ptr: u64, str_len: u64) -> u64 {
    var count: u64 = vec_len(g_strings);

    for (var i: u64 = 0; i < count; i++) {
        var entry: u64 = vec_get(g_strings, i);
        var str_entry: *StringEntry = (*StringEntry)entry;
        
        if (str_eq(str_entry->str_ptr, str_entry->str_len, str_ptr, str_len)) {
            return str_entry->label_id;
        }
    }
    
    var label_id: u64 = g_label_counter;
    g_label_counter = g_label_counter + 1;
    
    var entry: u64 = heap_alloc(sizeof(StringEntryLocal));
    var str_entry: *StringEntry = (*StringEntry)entry;
    str_entry->str_ptr = str_ptr;
    str_entry->str_len = str_len;
    str_entry->label_id = label_id;
    vec_push(g_strings, entry);
    
    return label_id;
}

func string_emit_data() -> u64 {
    var count: u64 = vec_len(g_strings);
    
    if (count == 0) { return; }
    
    emitln("\nsection .data");
    
    for (var i: u64 = 0; i < count; i++) {
        var entry: u64 = vec_get(g_strings, i);
        var str_entry: *StringEntry = (*StringEntry)entry;
        var str_ptr: u64 = str_entry->str_ptr;
        var str_len: u64 = str_entry->str_len;
        var label_id: u64 = str_entry->label_id;
        
        emit("_str", 4);
        emit_u64(label_id);
        emit(": db ", 5);
        
        for (var j: u64 = 1; j < str_len - 1; ) {
            var c: u64 = *(*u8)(str_ptr + j);
            
            if (c == 92) {  // backslash
                j = j + 1;
                if (j < str_len - 1) {
                    var ec: u64 = *(*u8)(str_ptr + j);
                    if (ec == 110) { emit("10", 2); }       // \n
                    else if (ec == 116) { emit("9", 1); }   // \t
                    else if (ec == 48) { emit("0", 1); }    // \0
                    else if (ec == 92) { emit("92", 2); }   // \\
                    else if (ec == 34) { emit("34", 2); }   // \"
                    else { emit_u64(ec); }
                }
            } else {
                emit_u64(c);
            }

            j = j + 1;
            if (j < str_len - 1) { emit(",", 1); }
        }
        
        emitln(",0");
    }
}

// ============================================
// Global Variables BSS Emission
// ============================================

func globals_emit_bss() -> u64 {
    var count: u64 = vec_len(g_globals);
    
    if (count == 0) { return; }
    
    emitln("\nsection .bss");
    
    for (var i: u64 = 0; i < count; i++) {
        var ginfo: *GlobalInfo = (*GlobalInfo)vec_get(g_globals, i);
        
        emit("_gvar_", 6);
        emit(ginfo->name_ptr, ginfo->name_len);
        emitln(": resq 1");
        
    }
}
