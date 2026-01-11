// v3.6 Compiler - Part 6: Main Entry Point with Module System

// ============================================
// Global Module State
// ============================================
var g_loaded_modules;    // HashMap: path -> 1 (tracks loaded files)
var g_all_funcs;         // Vec of all function ASTs from all modules
var g_all_consts;        // Vec of all const ASTs from all modules
var g_all_globals;       // Vec of all global var info [name_ptr, name_len]
var g_base_dir;          // Base directory for resolving imports
var g_base_dir_len;

var g_file_ptr;
var g_file_len;

// ============================================
// File Reading
// ============================================

func read_entire_file(path) {
    // Open file (O_RDONLY = 0)
    var fd;
    fd = sys_open(path, 0, 0);
    if (fd < 0) {
        return 0;  // Return 0 on failure
    }
    
    // Get file size using fstat
    // struct stat is 144 bytes, st_size at offset 48
    var statbuf;
    statbuf = heap_alloc(144);
    sys_fstat(fd, statbuf);
    var size;
    size = ptr64[statbuf + 48];
    
    // Allocate buffer
    var buf;
    buf = heap_alloc(size + 1);
    
    // Read file
    var total;
    total = 0;
    while (total < size) {
        var n;
        n = sys_read(fd, buf + total, size - total);
        if (n <= 0) { break; }
        total = total + n;
    }
    
    // Null terminate
    ptr8[buf + total] = 0;
    
    // Close
    sys_close(fd);
    
    // Store result in global (ptr, len)
    g_file_ptr = buf;
    g_file_len = total;
    
    return buf;
}

// ============================================
// Module Loading
// ============================================

// Resolve import path to actual file path
// "io" -> "{base_dir}/io.b"
func resolve_module_path(module_path, module_len) {
    // Add .b extension
    var ext;
    ext = heap_alloc(3);
    ptr8[ext] = 46;      // '.'
    ptr8[ext + 1] = 98;  // 'b'
    ptr8[ext + 2] = 0;
    
    var with_ext;
    with_ext = str_concat(module_path, module_len, ext, 2);
    var with_ext_len;
    with_ext_len = module_len + 2;
    
    // Join with base directory
    var slash;
    slash = heap_alloc(1);
    ptr8[slash] = 47;  // '/'
    
    var full_path;
    full_path = str_concat3(g_base_dir, g_base_dir_len, slash, 1, with_ext, with_ext_len);
    
    return full_path;
}

// Load and process a single module file
// Returns 1 on success, 0 on failure
func load_module(file_path, file_path_len) {
    // Check if already loaded (avoid circular imports)
    if (hashmap_has(g_loaded_modules, file_path, file_path_len)) {
        return 1;  // Already loaded, skip
    }
    
    // Mark as loading (before actually loading to detect cycles)
    hashmap_put(g_loaded_modules, file_path, file_path_len, 1);
    
    // Read file
    var content;
    content = read_entire_file(file_path);
    if (content == 0) {
        emit_stderr("[ERROR] Cannot open module: ", 29);
        var i;
        i = 0;
        while (i < file_path_len) {
            emit_char(ptr8[file_path + i]);
            i = i + 1;
        }
        emit_nl();
        return 0;
    }
    
    var src;
    src = g_file_ptr;
    var slen;
    slen = g_file_len;
    
    // Lex
    var tokens;
    tokens = lex_all(src, slen);
    
    // Parse
    var parser;
    parser = parse_new(tokens);
    var prog;
    prog = parse_program(parser);
    
    // Process imports first (recursive)
    var imports;
    imports = ptr64[prog + 24];
    var num_imports;
    num_imports = vec_len(imports);
    var ii;
    ii = 0;
    while (ii < num_imports) {
        var imp;
        imp = vec_get(imports, ii);
        var imp_path;
        imp_path = ptr64[imp + 8];
        var imp_len;
        imp_len = ptr64[imp + 16];
        
        // Resolve and load the imported module
        var resolved;
        resolved = resolve_module_path(imp_path, imp_len);
        var resolved_len;
        resolved_len = str_len(resolved);
        
        if (!load_module(resolved, resolved_len)) {
            return 0;  // Failed to load dependency
        }
        
        ii = ii + 1;
    }
    
    // Add this module's consts to global list
    var consts;
    consts = ptr64[prog + 16];
    var num_consts;
    num_consts = vec_len(consts);
    var ci;
    ci = 0;
    while (ci < num_consts) {
        vec_push(g_all_consts, vec_get(consts, ci));
        ci = ci + 1;
    }
    
    // Add this module's funcs to global list
    var funcs;
    funcs = ptr64[prog + 8];
    var num_funcs;
    num_funcs = vec_len(funcs);
    var fi;
    fi = 0;
    while (fi < num_funcs) {
        vec_push(g_all_funcs, vec_get(funcs, fi));
        fi = fi + 1;
    }
    
    // Add this module's globals to global list
    var globals;
    globals = ptr64[prog + 32];
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
    
    return 1;  // Success
}

// ============================================
// Main Entry Point
// ============================================

func main(argc: i64, argv: i64) -> i64 {
    // Check arguments
    if (argc < 2) {
        emit("Usage: v3_7 <source.b>\n", 23);
        return 1;
    }
    
    // Get filename from argv[1]
    var filename;
    filename = ptr64[argv + 8];
    var filename_len;
    filename_len = str_len(filename);
    
    // Extract base directory from filename
    g_base_dir = path_dirname(filename, filename_len);
    g_base_dir_len = str_len(g_base_dir);
    
    // Initialize global state
    g_loaded_modules = hashmap_new(64);
    g_all_funcs = vec_new(64);
    g_all_consts = vec_new(128);
    g_all_globals = vec_new(64);
    
    // Load main file and all its imports
    if (!load_module(filename, filename_len)) {
        return 1;
    }
    
    // Create merged program AST
    var dummy_imports;
    dummy_imports = vec_new(1);  // Empty imports (already processed)
    var merged_prog;
    merged_prog = ast_program(g_all_funcs, g_all_consts, dummy_imports);
    ptr64[merged_prog + 32] = g_all_globals;  // Set collected globals
    
    // Generate code for all modules
    cg_program(merged_prog);
    
    return 0;
}

