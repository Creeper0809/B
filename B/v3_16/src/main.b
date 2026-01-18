// main.b - Main entry point for v3.8 modular compiler

import std.io;
import std.util;
import compiler;
import codegen;

func main(argc: u64, argv: u64) -> u64 {
    if (argc < 2) {
        emit("Usage: v3_9 <source.b>\n", 23);
        return 1;
    }
    
    var filename: u64 = *(argv + 8);
    var filename_len: u64 = str_len(filename);

    setup_paths(filename, filename_len);

    push_trace("main", "main.b", __LINE__);

    init_compiler_globals();

    // Implicit standard library prelude (std/* available without explicit import)
    if (!load_std_prelude()) {
        pop_trace();
        return 1;
    }
    
    if (!load_module(filename, filename_len)) {
        pop_trace();
        return 1;
    }
    
    var merged_prog: u64 = build_merged_program();
    cg_program_with_sigs(merged_prog, get_func_sigs());
    
    pop_trace();
    return 0;
}
