// compiler.b - Compiler globals and driver helpers

import std.io;
import std.str;
import std.path;
import std.vec;
import std.hashmap;
import std.util;
import types;
import lexer;
import ast;
import parser.util;
import parser.decl;

// ============================================
// Global Module State
// ============================================
var g_loaded_modules;    // HashMap: path -> 1 (tracks loaded files)
var g_all_funcs;         // Vec of all function ASTs
var g_all_func_sigs;     // Vec of all function signatures (pass 1)
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
var g_module_aliases;     // HashMap: module_id -> alias_map
var g_prelude_aliases;    // HashMap: alias -> [mangled_ptr, mangled_len]
var g_module_exports;     // HashMap: module_id -> exports vec
var g_func_module_map;    // HashMap: mangled func -> module_id
var g_current_module_ptr;
var g_current_module_len;

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

func compiler_get_source_ptr() -> u64 {
    return g_file_ptr;
}

func compiler_get_source_len() -> u64 {
    return g_file_len;
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
// Module Id + Mangling Helpers
// ============================================

// Return 1 if s starts with prefix
func str_has_prefix(s: u64, s_len: u64, prefix: u64, prefix_len: u64) -> u64 {
    if (s_len < prefix_len) { return 0; }
    var i: u64 = 0;
    while (i < prefix_len) {
        if (*(*u8)(s + i) != *(*u8)(prefix + i)) { return 0; }
        i = i + 1;
    }
    return 1;
}

// Returns [ptr,len] struct (16 bytes)
func module_id_from_path(path: u64, path_len: u64) -> u64 {
    var start: u64 = 0;
    if (g_lib_dir != 0 && str_has_prefix(path, path_len, g_lib_dir, g_lib_dir_len)) {
        if (path_len > g_lib_dir_len && *(*u8)(path + g_lib_dir_len) == 47) {
            start = g_lib_dir_len + 1;
        }
    }
    if (start == 0 && g_base_dir != 0 && str_has_prefix(path, path_len, g_base_dir, g_base_dir_len)) {
        if (path_len > g_base_dir_len && *(*u8)(path + g_base_dir_len) == 47) {
            start = g_base_dir_len + 1;
        }
    }

    var end: u64 = path_len;
    if (end >= 2) {
        if (*(*u8)(path + end - 2) == 46 && *(*u8)(path + end - 1) == 98) {
            end = end - 2;
        }
    }

    var id_len: u64 = 0;
    if (end > start) { id_len = end - start; }
    var id_ptr: u64 = heap_alloc(id_len + 1);
    var i: u64 = 0;
    while (i < id_len) {
        *(*u8)(id_ptr + i) = *(*u8)(path + start + i);
        i = i + 1;
    }
    *(*u8)(id_ptr + id_len) = 0;

    var out: u64 = heap_alloc(16);
    *(out) = id_ptr;
    *(out + 8) = id_len;
    return out;
}

// Import path already normalized to "a/b" without extension
func module_id_from_import(path: u64, path_len: u64) -> u64 {
    var id_ptr: u64 = heap_alloc(path_len + 1);
    var i: u64 = 0;
    while (i < path_len) {
        *(*u8)(id_ptr + i) = *(*u8)(path + i);
        i = i + 1;
    }
    *(*u8)(id_ptr + path_len) = 0;
    var out: u64 = heap_alloc(16);
    *(out) = id_ptr;
    *(out + 8) = path_len;
    return out;
}

func module_prefix_from_id(id_ptr: u64, id_len: u64) -> u64 {
    var extra: u64 = 0;
    if (id_len > 0) {
        var c0: u64 = *(*u8)(id_ptr);
        if (c0 >= 48 && c0 <= 57) { extra = 1; }
    }

    var pref_ptr: u64 = heap_alloc(id_len + extra + 1);
    if (extra == 1) {
        *(*u8)(pref_ptr) = 95;
    }
    var i: u64 = 0;
    while (i < id_len) {
        var c: u64 = *(*u8)(id_ptr + i);
        if (c == 47 || c == 46) { c = 95; }
        *(*u8)(pref_ptr + extra + i) = c;
        i = i + 1;
    }
    *(*u8)(pref_ptr + id_len + extra) = 0;
    var out: u64 = heap_alloc(16);
    *(out) = pref_ptr;
    *(out + 8) = id_len + extra;
    return out;
}

// Returns [ptr,len]
func mangle_name(prefix_ptr: u64, prefix_len: u64, name_ptr: u64, name_len: u64) -> u64 {
    if (prefix_len == 0) {
        var out0: u64 = heap_alloc(16);
        *(out0) = name_ptr;
        *(out0 + 8) = name_len;
        return out0;
    }
    var sep_len: u64 = 2;
    var total: u64 = prefix_len + sep_len + name_len;
    var buf: u64 = heap_alloc(total + 1);
    var i: u64 = 0;
    while (i < prefix_len) {
        *(*u8)(buf + i) = *(*u8)(prefix_ptr + i);
        i = i + 1;
    }
    *(*u8)(buf + i) = 95;
    *(*u8)(buf + i + 1) = 95;
    var j: u64 = 0;
    while (j < name_len) {
        *(*u8)(buf + i + sep_len + j) = *(*u8)(name_ptr + j);
        j = j + 1;
    }
    *(*u8)(buf + total) = 0;
    var out: u64 = heap_alloc(16);
    *(out) = buf;
    *(out + 8) = total;
    return out;
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

// ============================================
// Import Alias + Export Table
// ============================================

// Export entry: [name_ptr, name_len, mangled_ptr, mangled_len] = 32 bytes
func module_exports_get(module_ptr: u64, module_len: u64) -> u64 {
    if (g_module_exports == 0) { return 0; }
    return hashmap_get(g_module_exports, module_ptr, module_len);
}

func module_exports_ensure(module_ptr: u64, module_len: u64) -> u64 {
    if (g_module_exports == 0) {
        g_module_exports = hashmap_new(64);
    }
    var existing: u64 = hashmap_get(g_module_exports, module_ptr, module_len);
    if (existing != 0) { return existing; }
    var vec: u64 = vec_new(32);
    hashmap_put(g_module_exports, module_ptr, module_len, vec);
    return vec;
}

func add_module_export(module_ptr: u64, module_len: u64, name_ptr: u64, name_len: u64, mangled_ptr: u64, mangled_len: u64) -> u64 {
    var exports: u64 = module_exports_ensure(module_ptr, module_len);
    var entry: u64 = heap_alloc(32);
    *(entry) = name_ptr;
    *(entry + 8) = name_len;
    *(entry + 16) = mangled_ptr;
    *(entry + 24) = mangled_len;
    vec_push(exports, entry);
    return 0;
}

func module_aliases_get(module_ptr: u64, module_len: u64) -> u64 {
    if (g_module_aliases == 0) { return 0; }
    return hashmap_get(g_module_aliases, module_ptr, module_len);
}

func module_aliases_ensure(module_ptr: u64, module_len: u64) -> u64 {
    if (g_module_aliases == 0) {
        g_module_aliases = hashmap_new(128);
    }
    var existing: u64 = hashmap_get(g_module_aliases, module_ptr, module_len);
    if (existing != 0) { return existing; }
    var map: u64 = hashmap_new(128);
    hashmap_put(g_module_aliases, module_ptr, module_len, map);
    return map;
}

func add_import_alias(module_ptr: u64, module_len: u64, alias_ptr: u64, alias_len: u64, mangled_ptr: u64, mangled_len: u64) -> u64 {
    var alias_map: u64 = module_aliases_ensure(module_ptr, module_len);
    var existing: u64 = hashmap_get(alias_map, alias_ptr, alias_len);
    if (existing != 0) {
        var ex_ptr: u64 = *(existing);
        var ex_len: u64 = *(existing + 8);
        if (ex_ptr == mangled_ptr && ex_len == mangled_len) {
            return 0;
        }
        emit_stderr("[ERROR] import alias conflict: ", 33);
        emit_stderr(alias_ptr, alias_len);
        emit_stderr_nl();
        panic("Parse error");
    }
    var info: u64 = heap_alloc(16);
    *(info) = mangled_ptr;
    *(info + 8) = mangled_len;
    hashmap_put(alias_map, alias_ptr, alias_len, info);
    return 0;
}

func add_prelude_alias(alias_ptr: u64, alias_len: u64, mangled_ptr: u64, mangled_len: u64) -> u64 {
    if (g_prelude_aliases == 0) {
        g_prelude_aliases = hashmap_new(128);
    }
    var existing: u64 = hashmap_get(g_prelude_aliases, alias_ptr, alias_len);
    if (existing != 0) {
        var ex_ptr: u64 = *(existing);
        var ex_len: u64 = *(existing + 8);
        if (ex_ptr == mangled_ptr && ex_len == mangled_len) {
            return 0;
        }
        emit_stderr("[ERROR] prelude alias conflict: ", 34);
        emit_stderr(alias_ptr, alias_len);
        emit_stderr_nl();
        panic("Parse error");
    }
    var info: u64 = heap_alloc(16);
    *(info) = mangled_ptr;
    *(info + 8) = mangled_len;
    hashmap_put(g_prelude_aliases, alias_ptr, alias_len, info);
    return 0;
}

func resolve_import_alias(module_ptr: u64, module_len: u64, name_ptr: u64, name_len: u64) -> u64 {
    var alias_map: u64 = module_aliases_get(module_ptr, module_len);
    if (alias_map == 0) { return 0; }
    return hashmap_get(alias_map, name_ptr, name_len);
}

func resolve_prelude_alias(name_ptr: u64, name_len: u64) -> u64 {
    if (g_prelude_aliases == 0) { return 0; }
    return hashmap_get(g_prelude_aliases, name_ptr, name_len);
}

func compiler_func_exists(name_ptr: u64, name_len: u64) -> u64 {
    if (g_all_funcs == 0) { return 0; }
    var resolved_ptr: u64 = name_ptr;
    var resolved_len: u64 = name_len;
    var resolved: u64 = resolve_name(name_ptr, name_len);
    if (resolved != 0) {
        resolved_ptr = *(resolved);
        resolved_len = *(resolved + 8);
    }
    var n: u64 = vec_len(g_all_funcs);
    for (var i: u64 = 0; i < n; i++) {
        var fn_ptr: u64 = vec_get(g_all_funcs, i);
        var fn: *AstFunc = (*AstFunc)fn_ptr;
        if (str_eq(fn->name_ptr, fn->name_len, resolved_ptr, resolved_len)) { return 1; }
    }
    return 0;
}

func compiler_global_exists(name_ptr: u64, name_len: u64) -> u64 {
    if (g_all_globals == 0) { return 0; }
    var n: u64 = vec_len(g_all_globals);
    for (var i: u64 = 0; i < n; i++) {
        var ginfo: *GlobalInfo = (*GlobalInfo)vec_get(g_all_globals, i);
        if (str_eq(ginfo->name_ptr, ginfo->name_len, name_ptr, name_len)) { return 1; }
    }
    return 0;
}

func prelude_try_symbol(module_path: u64, module_len: u64, name_ptr: u64, name_len: u64) -> u64 {
    var mod_id: u64 = module_id_from_import(module_path, module_len);
    if (mod_id == 0) { return 0; }
    var mod_ptr: u64 = *(mod_id);
    var mod_len: u64 = *(mod_id + 8);
    var exports: u64 = module_exports_get(mod_ptr, mod_len);
    if (exports == 0) { return 0; }

    var n: u64 = vec_len(exports);
    for (var i: u64 = 0; i < n; i++) {
        var e: u64 = vec_get(exports, i);
        var sym_ptr: u64 = *(e);
        var sym_len: u64 = *(e + 8);
        if (str_eq(sym_ptr, sym_len, name_ptr, name_len) != 0) {
            var mangled_ptr: u64 = *(e + 16);
            var mangled_len: u64 = *(e + 24);
            add_prelude_alias(name_ptr, name_len, mangled_ptr, mangled_len);
            var info: u64 = heap_alloc(16);
            *(info) = mangled_ptr;
            *(info + 8) = mangled_len;
            return info;
        }
    }
    return 0;
}

func load_std_prelude_modules() -> u64 {
    if (!load_module_by_name("std/io", 6)) { return 0; }
    if (!load_module_by_name("std/str", 7)) { return 0; }
    if (!load_module_by_name("std/char", 8)) { return 0; }
    if (!load_module_by_name("std/util", 8)) { return 0; }
    if (!load_module_by_name("std/vec", 7)) { return 0; }
    if (!load_module_by_name("std/hashmap", 11)) { return 0; }
    return 1;
}

func resolve_prelude_alias_lazy(name_ptr: u64, name_len: u64) -> u64 {
    var info: u64 = prelude_try_symbol("std/io", 6, name_ptr, name_len);
    if (info != 0) { return info; }
    info = prelude_try_symbol("std/str", 7, name_ptr, name_len);
    if (info != 0) { return info; }
    info = prelude_try_symbol("std/char", 8, name_ptr, name_len);
    if (info != 0) { return info; }
    info = prelude_try_symbol("std/util", 8, name_ptr, name_len);
    if (info != 0) { return info; }
    info = prelude_try_symbol("std/vec", 7, name_ptr, name_len);
    if (info != 0) { return info; }
    info = prelude_try_symbol("std/hashmap", 11, name_ptr, name_len);
    if (info != 0) { return info; }
    return 0;
}

func resolve_name(name_ptr: u64, name_len: u64) -> u64 {
    if (g_current_module_ptr != 0 && g_current_module_len != 0) {
        var alias: u64 = resolve_import_alias(g_current_module_ptr, g_current_module_len, name_ptr, name_len);
        if (alias != 0) { return alias; }
    }

    if (g_current_module_ptr != 0 && g_current_module_len != 0) {
        var exports: u64 = module_exports_get(g_current_module_ptr, g_current_module_len);
        if (exports != 0) {
            var n: u64 = vec_len(exports);
            for (var i: u64 = 0; i < n; i++) {
                var e: u64 = vec_get(exports, i);
                var n_ptr: u64 = *(e);
                var n_len: u64 = *(e + 8);
                if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
                    var info: u64 = heap_alloc(16);
                    *(info) = *(e + 16);
                    *(info + 8) = *(e + 24);
                    return info;
                }
            }
        }
    }

    return 0;
}

// ============================================
// Const Lookup (SSA/Codegen Shared)
// ============================================

func compiler_find_const(name_ptr: u64, name_len: u64) -> u64 {
    var result: u64 = heap_alloc(16);
    var res: *ConstResult = (*ConstResult)result;
    res->found = 0;
    res->value = 0;

    if (g_all_consts == 0) { return result; }
    var n: u64 = vec_len(g_all_consts);
    var i: u64 = 0;
    while (i < n) {
        var c_ptr: u64 = vec_get(g_all_consts, i);
        var c: *AstConstDecl = (*AstConstDecl)c_ptr;
        if (str_eq(c->name_ptr, c->name_len, name_ptr, name_len)) {
            res->found = 1;
            res->value = c->value;
            return result;
        }
        i = i + 1;
    }
    return result;
}

func import_all_from_module(importer_ptr: u64, importer_len: u64, module_ptr: u64, module_len: u64) -> u64 {
    var exports: u64 = module_exports_get(module_ptr, module_len);
    if (exports == 0) { return 0; }
    var n: u64 = vec_len(exports);
    for (var i: u64 = 0; i < n; i++) {
        var e: u64 = vec_get(exports, i);
        var name_ptr: u64 = *(e);
        var name_len: u64 = *(e + 8);
        var mangled_ptr: u64 = *(e + 16);
        var mangled_len: u64 = *(e + 24);
        add_import_alias(importer_ptr, importer_len, name_ptr, name_len, mangled_ptr, mangled_len);
    }
    return 1;
}

func import_symbol_from_module(importer_ptr: u64, importer_len: u64, module_ptr: u64, module_len: u64, symbol_ptr: u64, symbol_len: u64, alias_ptr: u64, alias_len: u64) -> u64 {
    var exports: u64 = module_exports_get(module_ptr, module_len);
    if (exports == 0) { return 0; }
    var n: u64 = vec_len(exports);
    for (var i: u64 = 0; i < n; i++) {
        var e: u64 = vec_get(exports, i);
        var name_ptr: u64 = *(e);
        var name_len: u64 = *(e + 8);
        if (str_eq(name_ptr, name_len, symbol_ptr, symbol_len)) {
            var mangled_ptr: u64 = *(e + 16);
            var mangled_len: u64 = *(e + 24);
            add_import_alias(importer_ptr, importer_len, alias_ptr, alias_len, mangled_ptr, mangled_len);
            return 1;
        }
    }
    emit_stderr("[ERROR] import symbol not found: ", 35);
    emit_stderr(symbol_ptr, symbol_len);
    emit_stderr_nl();
    panic("Parse error");
    return 0;
}

func prelude_import_all_from_module(module_ptr: u64, module_len: u64) -> u64 {
    var exports: u64 = module_exports_get(module_ptr, module_len);
    if (exports == 0) { return 0; }
    var n: u64 = vec_len(exports);
    for (var i: u64 = 0; i < n; i++) {
        var e: u64 = vec_get(exports, i);
        var name_ptr: u64 = *(e);
        var name_len: u64 = *(e + 8);
        var mangled_ptr: u64 = *(e + 16);
        var mangled_len: u64 = *(e + 24);
        add_prelude_alias(name_ptr, name_len, mangled_ptr, mangled_len);
    }
    return 1;
}

func set_current_module_for_func(func_ptr: u64, func_len: u64) -> u64 {
    g_current_module_ptr = 0;
    g_current_module_len = 0;
    if (g_func_module_map == 0) { return 0; }
    var info: u64 = hashmap_get(g_func_module_map, func_ptr, func_len);
    if (info != 0) {
        g_current_module_ptr = *(info);
        g_current_module_len = *(info + 8);
    }
    return 0;
}

// ============================================
// Export Registration + Mangling
// ============================================

func register_module_exports(prog: u64, module_ptr: u64, module_len: u64, prefix_ptr: u64, prefix_len: u64) -> u64 {
    var funcs: u64 = *(prog + 8);
    if (funcs != 0) {
        var num_funcs: u64 = vec_len(funcs);
        for (var i: u64 = 0; i < num_funcs; i++) {
            var fn_ptr: u64 = vec_get(funcs, i);
            var fn: *AstFunc = (*AstFunc)fn_ptr;
            var orig_ptr: u64 = fn->name_ptr;
            var orig_len: u64 = fn->name_len;
            var mangled_ptr: u64 = orig_ptr;
            var mangled_len: u64 = orig_len;

            if (prefix_len != 0 && !(orig_len == 4 && str_eq(orig_ptr, orig_len, "main", 4))) {
                var m: u64 = mangle_name(prefix_ptr, prefix_len, orig_ptr, orig_len);
                mangled_ptr = *(m);
                mangled_len = *(m + 8);
                fn->name_ptr = mangled_ptr;
                fn->name_len = mangled_len;
            }

            add_module_export(module_ptr, module_len, orig_ptr, orig_len, mangled_ptr, mangled_len);

            if (g_func_module_map == 0) {
                g_func_module_map = hashmap_new(128);
            }
            var info: u64 = heap_alloc(16);
            *(info) = module_ptr;
            *(info + 8) = module_len;
            hashmap_put(g_func_module_map, mangled_ptr, mangled_len, info);
        }
    }

    var consts: u64 = *(prog + 16);
    if (consts != 0) {
        var num_consts: u64 = vec_len(consts);
        for (var ci: u64 = 0; ci < num_consts; ci++) {
            var c_ptr: u64 = vec_get(consts, ci);
            var c: *AstConstDecl = (*AstConstDecl)c_ptr;
            var orig_ptr: u64 = c->name_ptr;
            var orig_len: u64 = c->name_len;
            var mangled_ptr: u64 = orig_ptr;
            var mangled_len: u64 = orig_len;

            if (prefix_len != 0) {
                var m2: u64 = mangle_name(prefix_ptr, prefix_len, orig_ptr, orig_len);
                mangled_ptr = *(m2);
                mangled_len = *(m2 + 8);
                c->name_ptr = mangled_ptr;
                c->name_len = mangled_len;
            }
            add_module_export(module_ptr, module_len, orig_ptr, orig_len, mangled_ptr, mangled_len);
        }
    }

    var globals: u64 = *(prog + 32);
    if (globals != 0) {
        var num_globals: u64 = vec_len(globals);
        for (var gi: u64 = 0; gi < num_globals; gi++) {
            var ginfo: *GlobalInfo = (*GlobalInfo)vec_get(globals, gi);
            var orig_ptr: u64 = ginfo->name_ptr;
            var orig_len: u64 = ginfo->name_len;
            var mangled_ptr: u64 = orig_ptr;
            var mangled_len: u64 = orig_len;

            if (prefix_len != 0) {
                var m3: u64 = mangle_name(prefix_ptr, prefix_len, orig_ptr, orig_len);
                mangled_ptr = *(m3);
                mangled_len = *(m3 + 8);
                ginfo->name_ptr = mangled_ptr;
                ginfo->name_len = mangled_len;
            }
            add_module_export(module_ptr, module_len, orig_ptr, orig_len, mangled_ptr, mangled_len);
        }
    }
    return 0;
}

func load_module_by_name(module_path: u64, module_len: u64) -> u64 {
    var resolved: u64 = resolve_module_path(module_path, module_len);
    var resolved_len: u64 = str_len(resolved);
    return load_module(resolved, resolved_len);
}

func load_std_prelude() -> u64 {
    if (!load_module_by_name("std/io", 6)) { return 0; }
    var id_io: u64 = module_id_from_import("std/io", 6);
    prelude_import_all_from_module(*(id_io), *(id_io + 8));

    if (!load_module_by_name("std/str", 7)) { return 0; }
    var id_str: u64 = module_id_from_import("std/str", 7);
    prelude_import_all_from_module(*(id_str), *(id_str + 8));

    if (!load_module_by_name("std/char", 8)) { return 0; }
    var id_char: u64 = module_id_from_import("std/char", 8);
    prelude_import_all_from_module(*(id_char), *(id_char + 8));

    if (!load_module_by_name("std/util", 8)) { return 0; }
    var id_util: u64 = module_id_from_import("std/util", 8);
    prelude_import_all_from_module(*(id_util), *(id_util + 8));

    if (!load_module_by_name("std/vec", 7)) { return 0; }
    var id_vec: u64 = module_id_from_import("std/vec", 7);
    prelude_import_all_from_module(*(id_vec), *(id_vec + 8));

    if (!load_module_by_name("std/hashmap", 11)) { return 0; }
    var id_hm: u64 = module_id_from_import("std/hashmap", 11);
    prelude_import_all_from_module(*(id_hm), *(id_hm + 8));
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
    
    // Module identity for mangling
    var module_id: u64 = module_id_from_path(file_path, file_path_len);
    var module_ptr: u64 = *(module_id);
    var module_len: u64 = *(module_id + 8);
    var module_prefix: u64 = module_prefix_from_id(module_ptr, module_len);
    var prefix_ptr: u64 = *(module_prefix);
    var prefix_len: u64 = *(module_prefix + 8);
    
    // Pass 1: collect function signatures only
    var p1: u64 = parse_new(tokens);
    var prog_sig: u64 = parse_program_pass1(p1);

    var sig_funcs: u64 = *(prog_sig + 8);
    var num_sig_funcs: u64 = vec_len(sig_funcs);
    for (var sfi: u64 = 0; sfi < num_sig_funcs; sfi++) {
        vec_push(g_all_func_sigs, vec_get(sig_funcs, sfi));
    }

    // Pass 2: full parse with bodies
    var p: u64 = parse_new(tokens);
    var prog: u64 = parse_program(p);

    // Register exports + mangle symbols
    register_module_exports(prog, module_ptr, module_len, prefix_ptr, prefix_len);

    // Process imports recursively
    var imports: u64  = *(prog + 24);
    var num_imports: u64 = vec_len(imports);
    for (var ii: u64 = 0; ii<num_imports;ii++){
        var imp: u64 = vec_get(imports, ii);
        var imp_path: u64 = *(imp + 8);
        var imp_len: u64 = *(imp + 16);
        var imp_sym_ptr: u64 = *(imp + 24);
        var imp_sym_len: u64 = *(imp + 32);
        var imp_alias_ptr: u64 = *(imp + 40);
        var imp_alias_len: u64 = *(imp + 48);

        var resolved: u64 = resolve_module_path(imp_path, imp_len);
        var resolved_len: u64 = str_len(resolved);

        if (!load_module(resolved, resolved_len)) {
            return 0;
        }

        var imp_mod_id: u64 = module_id_from_import(imp_path, imp_len);
        var imp_mod_ptr: u64 = *(imp_mod_id);
        var imp_mod_len: u64 = *(imp_mod_id + 8);

        if (imp_sym_ptr == 0) {
            import_all_from_module(module_ptr, module_len, imp_mod_ptr, imp_mod_len);
        } else {
            import_symbol_from_module(module_ptr, module_len, imp_mod_ptr, imp_mod_len, imp_sym_ptr, imp_sym_len, imp_alias_ptr, imp_alias_len);
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
// Driver helpers
// ============================================

func init_compiler_globals() -> u64 {
    g_loaded_modules = hashmap_new(64);
    g_all_funcs = vec_new(64);
    g_all_func_sigs = vec_new(64);
    g_all_consts = vec_new(128);
    g_all_globals = vec_new(64);
    g_all_structs = hashmap_new(64);
    g_all_structs_vec = vec_new(16);
    g_module_aliases = hashmap_new(128);
    g_prelude_aliases = hashmap_new(128);
    g_module_exports = hashmap_new(64);
    g_func_module_map = hashmap_new(128);
    g_current_module_ptr = 0;
    g_current_module_len = 0;
    return 0;
}

func setup_paths(filename: u64, filename_len: u64) -> u64 {
    g_base_dir = path_dirname(filename, filename_len);
    g_base_dir_len = str_len(g_base_dir);

    // Find version directory by going up from base_dir
    // src: B/v3_XX/src -> up 1 = B/v3_XX
    // test: B/v3_XX/test/b -> up 2 = B/v3_XX
    var up_one: u64 = path_dirname(g_base_dir, g_base_dir_len);
    var up_one_len: u64 = str_len(up_one);
    var version_dir: u64 = path_dirname(up_one, up_one_len);
    var version_dir_len: u64 = str_len(version_dir);
    var slash_config: u64 = "/config.ini";
    var config_path1: u64 = str_concat(up_one, up_one_len, slash_config, 11);
    var version: u64 = read_version_from_config(config_path1);

    if (version == 0) {
        var config_path2: u64 = str_concat(version_dir, version_dir_len, slash_config, 11);
        version = read_version_from_config(config_path2);
    }

    if (version == 0) {
        version = "v3_15";  // Fallback to hardcoded default
    }

    // Build lib_dir path: "{version_dir}/src"
    var src_suffix: u64 = "/src";
    g_lib_dir = str_concat(version_dir, version_dir_len, src_suffix, 4);
    g_lib_dir_len = str_len(g_lib_dir);
    return 0;
}

func build_merged_program() -> u64 {
    var dummy_imports: u64 = vec_new(1);
    var merged_prog: u64 = ast_program(g_all_funcs, g_all_consts, dummy_imports);
    *(merged_prog + 32) = g_all_globals;
    *(merged_prog + 40) = g_all_structs_vec;
    return merged_prog;
}

func get_func_sigs() -> u64 {
    return g_all_func_sigs;
}
