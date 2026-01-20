// main.b - Main entry point for v3.8 modular compiler

import std.io;
import types;
import std.util;
import std.vec;
import std.hashmap;
import lexer;
import ast;
import parser;
import codegen;

// ============================================
// Global Module State
// ============================================
var g_loaded_modules;    // HashMap: path -> 1 (tracks loaded files)
var g_all_funcs;         // Vec of all function ASTs
var g_all_consts;        // Vec of all const ASTs
var g_all_globals;       // Vec of all global var info
var g_base_dir;          // Base directory for imports
var g_base_dir_len;
var g_lib_dir;           // Library root directory for compiler/runtime modules
var g_lib_dir_len;

var g_file_ptr;
var g_file_len;

// ============================================
// File Reading
// ============================================

func read_entire_file(path) {
    var fd;
    fd = sys_open(path, 0, 0);
    if (fd < 0) { return 0; }
    
    var statbuf;
    statbuf = heap_alloc(144);
    sys_fstat(fd, statbuf);
    var size;
    size = *(statbuf + 48);
    
    var buf;
    buf = heap_alloc(size + 1);
    
    var total;
    total = 0;
    while (total < size) {
        var n;
        n = sys_read(fd, buf + total, size - total);
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
// Module Loading
// ============================================

func file_exists(path) {
    var fd;
    fd = sys_open(path, 0, 0);
    if (fd < 0) { return 0; }
    sys_close(fd);
    return 1;
}

func is_std_alias(module_path, module_len) {
    if (str_eq(module_path, module_len, "io", 2)) { return 1; }
    if (str_eq(module_path, module_len, "util", 4)) { return 1; }
    if (str_eq(module_path, module_len, "vec", 3)) { return 1; }
    if (str_eq(module_path, module_len, "hashmap", 7)) { return 1; }
    return 0;
}

func std_alias_to_module_path(module_path, module_len) {
    if (str_eq(module_path, module_len, "io", 2)) { return "std/io"; }
    if (str_eq(module_path, module_len, "util", 4)) { return "std/util"; }
    if (str_eq(module_path, module_len, "vec", 3)) { return "std/vec"; }
    if (str_eq(module_path, module_len, "hashmap", 7)) { return "std/hashmap"; }
    return 0;
}

func is_std_path(module_path, module_len) {
    if (module_len < 4) { return 0; }
    if (*(*u8)module_path != 115) { return 0; }      // s
    if (*(*u8)(module_path + 1) != 116) { return 0; } // t
    if (*(*u8)(module_path + 2) != 100) { return 0; } // d
    if (*(*u8)(module_path + 3) != 47) { return 0; }  // /
    return 1;
}

func resolve_module_path(module_path, module_len) {
    var eff_path;
    var eff_len;
    eff_path = module_path;
    eff_len = module_len;

    var prefer_lib;
    prefer_lib = 0;

    if (is_std_alias(module_path, module_len)) {
        eff_path = std_alias_to_module_path(module_path, module_len);
        eff_len = str_len(eff_path);
        prefer_lib = 1;
    }

    if (is_std_path(eff_path, eff_len)) {
        prefer_lib = 1;
    }

    var ext;
    ext = heap_alloc(3);
    *(*u8)ext = 46;
    *(*u8)(ext + 1) = 98;
    *(*u8)(ext + 2) = 0;
    
    var with_ext;
    with_ext = str_concat(eff_path, eff_len, ext, 2);
    var with_ext_len;
    with_ext_len = eff_len + 2;
    
    var slash;
    slash = heap_alloc(1);
    *(*u8)slash = 47;

    var full1;
    var full2;
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

func load_module_by_name(module_path, module_len) {
    var resolved;
    resolved = resolve_module_path(module_path, module_len);
    var resolved_len;
    resolved_len = str_len(resolved);
    return load_module(resolved, resolved_len);
}

func load_std_prelude() {
    if (!load_module_by_name("std/io", 6)) { return 0; }
    if (!load_module_by_name("std/util", 8)) { return 0; }
    if (!load_module_by_name("std/vec", 7)) { return 0; }
    if (!load_module_by_name("std/hashmap", 11)) { return 0; }
    return 1;
}

func load_module(file_path, file_path_len) {
    if (hashmap_has(g_loaded_modules, file_path, file_path_len)) {
        return 1;
    }
    
    hashmap_put(g_loaded_modules, file_path, file_path_len, 1);
    
    var content;
    content = read_entire_file(file_path);
    if (content == 0) {
        emit_stderr("[ERROR] Cannot open module: ", 29);
        var i;
        i = 0;
        while (i < file_path_len) {
            emit_char(*(*u8)(file_path + i));
            i = i + 1;
        }
        emit_nl();
        return 0;
    }
    
    var src;
    src = g_file_ptr;
    var slen;
    slen = g_file_len;
    
    var tokens;
    tokens = lex_all(src, slen);
    
    var p;
    p = parse_new(tokens);
    var prog;
    prog = parse_program(p);
    
    // Process imports recursively
    var imports;
    imports = *(prog + 24);
    var num_imports;
    num_imports = vec_len(imports);
    var ii;
    ii = 0;
    while (ii < num_imports) {
        var imp;
        imp = vec_get(imports, ii);
        var imp_path;
        imp_path = *(imp + 8);
        var imp_len;
        imp_len = *(imp + 16);
        
        var resolved;
        resolved = resolve_module_path(imp_path, imp_len);
        var resolved_len;
        resolved_len = str_len(resolved);
        
        if (!load_module(resolved, resolved_len)) {
            return 0;
        }
        
        ii = ii + 1;
    }
    
    // Add consts
    var consts;
    consts = *(prog + 16);
    var num_consts;
    num_consts = vec_len(consts);
    var ci;
    ci = 0;
    while (ci < num_consts) {
        vec_push(g_all_consts, vec_get(consts, ci));
        ci = ci + 1;
    }
    
    // Add funcs
    var funcs;
    funcs = *(prog + 8);
    var num_funcs;
    num_funcs = vec_len(funcs);
    var fi;
    fi = 0;
    while (fi < num_funcs) {
        vec_push(g_all_funcs, vec_get(funcs, fi));
        fi = fi + 1;
    }
    
    // Add globals
    var globals;
    globals = *(prog + 32);
    if (globals != 0) {
        var num_globals;
        num_globals = vec_len(globals);
        var gi;
        gi = 0;
        while (gi < num_globals) {
            vec_push(g_all_globals, vec_get(globals, gi));
            gi = gi + 1;
        }
    }
    
    return 1;
}

// ============================================
// Main Entry Point
// ============================================

func main(argc, argv) {
    if (argc < 2) {
        emit("Usage: v3_9 <source.b>\n", 23);
        return 1;
    }
    
    var filename;
    filename = *(argv + 8);
    var filename_len;
    filename_len = str_len(filename);
    
    g_base_dir = path_dirname(filename, filename_len);
    g_base_dir_len = str_len(g_base_dir);

    // Repo layout convention: compiler/runtime modules live under B/v3_9/src
    g_lib_dir = "B/v3_9/src";
    g_lib_dir_len = str_len(g_lib_dir);
    
    g_loaded_modules = hashmap_new(64);
    g_all_funcs = vec_new(64);
    g_all_consts = vec_new(128);
    g_all_globals = vec_new(64);

    // Implicit standard library prelude (std/* available without explicit import)
    if (!load_std_prelude()) {
        return 1;
    }
    
    if (!load_module(filename, filename_len)) {
        return 1;
    }
    
    var dummy_imports;
    dummy_imports = vec_new(1);
    var merged_prog;
    merged_prog = ast_program(g_all_funcs, g_all_consts, dummy_imports);
    *(merged_prog + 32) = g_all_globals;
    
    cg_program(merged_prog);
    
    return 0;
}
