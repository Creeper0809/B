// main.b - Main entry point for v3.8 modular compiler

import std.io;
import std.str;
import compiler;
import codegen;
import opt;

func main(argc: u64, argv: u64) -> u64 {
    if (argc < 2) {
        emit("Usage: v3_17 [-O1] <source.b>\n", 33);
        return 1;
    }

    var filename: u64 = 0;
    var i: u64 = 1;
    while (i < argc) {
        var arg: u64 = *(argv + i * 8);
        var arg_len: u64 = str_len(arg);

        if (str_eq(arg, arg_len, "-O1", 3)) {
            opt_set_level(1);
            i = i + 1;
            continue;
        }
        if (str_eq(arg, arg_len, "-O0", 3)) {
            opt_set_level(0);
            i = i + 1;
            continue;
        }

        filename = arg;
        i = i + 1;
    }

    if (filename == 0) {
        emit("Usage: v3_17 [-O1] <source.b>\n", 33);
        return 1;
    }

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
