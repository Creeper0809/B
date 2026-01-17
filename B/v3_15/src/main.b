// main.b - Main entry point for v3.8 modular compiler

import std.io;
import types;
import std.util;
import std.vec;
import std.hashmap;
import lexer;
import ast;
import parser.util;
import parser.type;
import parser.expr;
import parser.stmt;
import parser.decl;
import codegen;

// ============================================
// Global Module State
// ============================================
var g_loaded_modules;    // HashMap: path -> 1 (tracks loaded files)
var g_all_funcs;         // Vec of all function ASTs
var g_all_consts;        // Vec of all const ASTs
var g_all_globals;       // Vec of all global var info
var g_all_structs;       // HashMap: struct_name -> struct_def
var g_all_structs_vec;   // Vec of all struct_defs (for codegen)
var g_base_dir;          // Base directory for imports
var g_base_dir_len;
var g_lib_dir;           // Library root directory for compiler/runtime modules
var g_lib_dir_len;

var g_file_ptr;
var g_file_len;

// ============================================
// File Reading
// ============================================

func read_entire_file(path: u64) -> u64 {
    var fd: u64 = sys_open(path, 0, 0);
    if (fd < 0) { return 0; }
    
    var statbuf: u64 = heap_alloc(144);
    sys_fstat(fd, statbuf);
    var size: u64 = *(statbuf + 48);
    
    var buf: u64 = heap_alloc(size + 1);
    
    var total: u64 = 0;
    while (total < size) {
        var n: u64 = sys_read(fd, buf + total, size - total);
        if (n <= 0) { break; }
        total = total + n;
    }
    
    *(*u8)(buf + total) = 0;
    
    sys_close(fd);
    
    g_file_ptr = buf;
    g_file_len = total;
    
    return buf;
}

// ============================================
// Config File Parsing
// ============================================

// Simple line-by-line config parser
func find_line_starting_with(content: u64, content_len: u64, prefix: u64, prefix_len: u64) -> u64 {
    var i: u64 = 0;
    
    while (i < content_len) {
        // Find start of current line
        var line_start: u64 = i;
        
        // Find end of line
        var line_end: u64 = i;
        while (line_end < content_len) {
            if (*(*u8)(content + line_end) == 10) { break; }
            line_end = line_end + 1;
        }
        
        var line_len: u64 = line_end - line_start;
        
        // Check if line starts with prefix
        if (line_len >= prefix_len) {
            if (str_eq(content + line_start, prefix_len, prefix, prefix_len)) {
                // Found matching line, return pointer to start of value (after prefix)
                var value_start: u64 = line_start + prefix_len;
                var value_len: u64 = line_len - prefix_len;
                
                // Allocate and copy value
                var value: u64 = heap_alloc(value_len + 1);
                var j: u64 = 0;
                while (j < value_len) {
                    *(*u8)(value + j) = *(*u8)(content + value_start + j);
                    j = j + 1;
                }
                *(*u8)(value + value_len) = 0;
                return value;
            }
        }
        
        // Move to next line
        i = line_end + 1;
    }
    
    return 0;
}

// Read config.ini and extract VERSION value
func read_version_from_config(config_path: u64) -> u64 {
    var content: u64 = read_entire_file(config_path);
    if (content == 0) {
        return 0;
    }
    
    return find_line_starting_with(content, g_file_len, "VERSION=", 8);
}

// ============================================
// Module Loading
// ============================================

func file_exists(path: u64) -> u64 {
    var fd: u64 = sys_open(path, 0, 0);
    if (fd < 0) { return 0; }
    sys_close(fd);
    return 1;
}

func is_std_alias(module_path: u64, module_len: u64) -> u64 {
    if (str_eq(module_path, module_len, "io", 2)) { return 1; }
    if (str_eq(module_path, module_len, "util", 4)) { return 1; }
    if (str_eq(module_path, module_len, "vec", 3)) { return 1; }
    if (str_eq(module_path, module_len, "hashmap", 7)) { return 1; }
    return 0;
}

func std_alias_to_module_path(module_path: u64, module_len: u64) -> u64 {
    if (str_eq(module_path, module_len, "io", 2)) { return "std/io"; }
    if (str_eq(module_path, module_len, "util", 4)) { return "std/util"; }
    if (str_eq(module_path, module_len, "vec", 3)) { return "std/vec"; }
    if (str_eq(module_path, module_len, "hashmap", 7)) { return "std/hashmap"; }
    return 0;
}

func is_std_path(module_path: u64, module_len: u64) -> u64 {
    if (module_len < 4) { return 0; }
    if (*(*u8)module_path != 115) { return 0; }      // s
    if (*(*u8)(module_path + 1) != 116) { return 0; } // t
    if (*(*u8)(module_path + 2) != 100) { return 0; } // d
    if (*(*u8)(module_path + 3) != 47) { return 0; }  // /
    return 1;
}

func resolve_module_path(module_path: u64, module_len: u64) -> u64 {
    var eff_path: u64 = module_path;
    var eff_len: u64 = module_len;

    var prefer_lib: u64 = 0;

    if (is_std_alias(module_path, module_len)) {
        eff_path = std_alias_to_module_path(module_path, module_len);
        eff_len = str_len(eff_path);
        prefer_lib = 1;
    }

    if (is_std_path(eff_path, eff_len)) {
        prefer_lib = 1;
    }

    var ext: u64 = heap_alloc(3);
    *(*u8)ext = 46;
    *(*u8)(ext + 1) = 98;
    *(*u8)(ext + 2) = 0;
    
    var with_ext: u64 = str_concat(eff_path, eff_len, ext, 2);
    var with_ext_len: u64 = eff_len + 2;
    
    var slash: u64 = heap_alloc(1);
    *(*u8)slash = 47;

    var full1: u64;
    var full2: u64;
    if (prefer_lib) {
        full1 = str_concat3(g_lib_dir, g_lib_dir_len, slash, 1, with_ext, with_ext_len);
        if (file_exists(full1)) { return full1; }
        full2 = str_concat3(g_base_dir, g_base_dir_len, slash, 1, with_ext, with_ext_len);
        return full2;
    }

    full1 = str_concat3(g_base_dir, g_base_dir_len, slash, 1, with_ext, with_ext_len);
    if (file_exists(full1)) { return full1; }
    full2 = str_concat3(g_lib_dir, g_lib_dir_len, slash, 1, with_ext, with_ext_len);
    return full2;
}

func load_module_by_name(module_path: u64, module_len: u64) -> u64 {
    var resolved: u64 = resolve_module_path(module_path, module_len);
    var resolved_len: u64 = str_len(resolved);
    return load_module(resolved, resolved_len);
}

func load_std_prelude() -> u64 {
    if (!load_module_by_name("std/io", 6)) { return 0; }
    if (!load_module_by_name("std/util", 8)) { return 0; }
    if (!load_module_by_name("std/vec", 7)) { return 0; }
    if (!load_module_by_name("std/hashmap", 11)) { return 0; }
    return 1;
}

func load_module(file_path: u64, file_path_len: u64) -> u64 {
    if (hashmap_has(g_loaded_modules, file_path, file_path_len)) {
        return 1;
    }
    
    hashmap_put(g_loaded_modules, file_path, file_path_len, 1);
    
    var content: u64 = read_entire_file(file_path);
    if (content == 0) {
        emit_stderr("[ERROR] Cannot open module: ", 29);
        for (var i: u64 = 0; i< file_path_len;i++){
            emit_char(*(*u8)(file_path + i));
        }
        emit_nl();
        return 0;
    }
    
    var src: u64 = g_file_ptr;
    var slen: u64  = g_file_len;
    
    var tokens: u64 = lex_all(src, slen);
    
    var p: u64 = parse_new(tokens);
    var prog: u64 = parse_program(p);
    
    // Process imports recursively
    var imports: u64  = *(prog + 24);
    var num_imports: u64 = vec_len(imports);
    for (var ii: u64 = 0; ii<num_imports;ii++){
        var imp: u64 = vec_get(imports, ii);
        var imp_path: u64 = *(imp + 8);
        var imp_len: u64 = *(imp + 16);
        
        var resolved: u64 = resolve_module_path(imp_path, imp_len);
        var resolved_len: u64 = str_len(resolved);
        
        if (!load_module(resolved, resolved_len)) {
            return 0;
        }
    }
    
    // Add consts
    var consts: u64 = *(prog + 16);
    var num_consts: u64  = vec_len(consts);
    for (var ci: u64 = 0; ci < num_consts; ci++){
        vec_push(g_all_consts, vec_get(consts, ci));
    }
    
    // Add funcs
    var funcs: u64 = *(prog + 8);
    var num_funcs: u64 = vec_len(funcs);
    for (var fi: u64 = 0;fi < num_funcs; fi++){
         vec_push(g_all_funcs, vec_get(funcs, fi));
    }
    
    // Add globals
    var globals: u64  = *(prog + 32);
    if (globals != 0) {
        var num_globals: u64  = vec_len(globals);
        for (var gi: u64 = 0; gi < num_globals; gi++){
            vec_push(g_all_globals, vec_get(globals, gi));
        }
    }
    
    // Register structs
    var structs: u64 = *(prog + 40);
    if (structs != 0) {
        var num_structs: u64 = vec_len(structs);
        for (var si: u64 = 0; si < num_structs; si++){
            var struct_def: u64 = vec_get(structs, si);
            var struct_name_ptr: u64 = *(struct_def + 8);
            var struct_name_len: u64 = *(struct_def + 16);
            hashmap_put(g_all_structs, struct_name_ptr, struct_name_len, struct_def);
        }
    }
    
    return 1;
}

// ============================================
// Helper functions for parser
// ============================================

// Check if a name is a registered struct type
func is_struct_type(name_ptr: u64, name_len: u64) -> u64 {
    if (g_all_structs == 0) { return 0; }
    var struct_def: u64 = hashmap_get(g_all_structs, name_ptr, name_len);
    if (struct_def == 0) { return 0; }
    return 1;
}

// Get struct definition by name
func get_struct_def(name_ptr: u64, name_len: u64) -> u64 {
    if (g_all_structs == 0) { return 0; }
    return hashmap_get(g_all_structs, name_ptr, name_len);
}

// Register a struct type during parsing
func register_struct_type(struct_def: u64) -> u64 {
    if (g_all_structs == 0) {
        g_all_structs = hashmap_new(64);
    }
    if (g_all_structs_vec == 0) {
        g_all_structs_vec = vec_new(16);
    }
    var struct_name_ptr: u64 = *(struct_def + 8);
    var struct_name_len: u64 = *(struct_def + 16);
    hashmap_put(g_all_structs, struct_name_ptr, struct_name_len, struct_def);
    vec_push(g_all_structs_vec, struct_def);
}

// ============================================
// Main Entry Point
// ============================================

func main(argc: u64, argv: u64) -> u64 {
    if (argc < 2) {
        emit("Usage: v3_9 <source.b>\n", 23);
        return 1;
    }
    
    var filename: u64 = *(argv + 8);
    var filename_len: u64 = str_len(filename);
    
    g_base_dir = path_dirname(filename, filename_len);
    g_base_dir_len = str_len(g_base_dir);

    // Find version directory by going up from base_dir
    // B/v3_XX/test/b/file.b -> base_dir = B/v3_XX/test/b -> up 2 levels -> B/v3_XX
    var up_one: u64 = path_dirname(g_base_dir, g_base_dir_len);
    var version_dir: u64 = path_dirname(up_one, str_len(up_one));
    var version_dir_len: u64 = str_len(version_dir);
    
    // Read version from config.ini in version directory
    var slash_config: u64 = "/config.ini";
    var config_path: u64 = str_concat(version_dir, version_dir_len, slash_config, 11);
    var version: u64 = read_version_from_config(config_path);
    if (version == 0) {
        version = "v3_15";  // Fallback to hardcoded default
    }
    
    // Build lib_dir path: "B/{version}/src"
    var b_prefix: u64 = "B/";
    var src_suffix: u64 = "/src";
    g_lib_dir = str_concat3(b_prefix, 2, version, str_len(version), src_suffix, 4);
    g_lib_dir_len = str_len(g_lib_dir);

    g_loaded_modules = hashmap_new(64);
    g_all_funcs = vec_new(64);
    g_all_consts = vec_new(128);
    g_all_globals = vec_new(64);
    g_all_structs = hashmap_new(64);
    g_all_structs_vec = vec_new(16);

    // Implicit standard library prelude (std/* available without explicit import)
    if (!load_std_prelude()) {
        return 1;
    }
    
    if (!load_module(filename, filename_len)) {
        return 1;
    }
    
    var dummy_imports: u64 = vec_new(1);
    var merged_prog: u64 = ast_program(g_all_funcs, g_all_consts, dummy_imports);
    *(merged_prog + 32) = g_all_globals;
    *(merged_prog + 40) = g_all_structs_vec;
    
    cg_program(merged_prog);
    
    return 0;
}
