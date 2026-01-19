// main.b - Main entry point for v3.8 modular compiler

import std.io;
import std.str;
import std.os;
import compiler;
import codegen;
import opt;

func main(argc: u64, argv: u64) -> u64 {
    if (argc < 2) {
        emit("Usage: v3_19 [-O0|-O1] [-3addr|-ssa] [-ir|-asm] <source.b>\n", 66);
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
        if (str_eq(arg, arg_len, "-3addr", 6)) {
            opt_set_ir_mode(IR_3ADDR);
            i = i + 1;
            continue;
        }
        if (str_eq(arg, arg_len, "-ssa", 4)) {
            opt_set_ir_mode(IR_SSA);
            i = i + 1;
            continue;
        }
        if (str_eq(arg, arg_len, "-ir", 3)) {
            opt_set_output_mode(OUT_IR);
            i = i + 1;
            continue;
        }
        if (str_eq(arg, arg_len, "-asm", 4)) {
            opt_set_output_mode(OUT_ASM);
            i = i + 1;
            continue;
        }

        filename = arg;
        i = i + 1;
    }

    if (filename == 0) {
        emit("Usage: v3_19 [-O0|-O1] [-3addr|-ssa] [-ir|-asm] <source.b>\n", 66);
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
    var out_mode: u64 = opt_get_output_mode();
    if (out_mode == OUT_IR) {
        cg_program_with_sigs_ir(merged_prog, get_func_sigs());
    } else if (out_mode == OUT_ASM) {
        cg_program_with_sigs(merged_prog, get_func_sigs());
    } else {
        var asm_path: u64 = "out.s";
        var obj_path: u64 = "out.o";
        var exe_path: u64 = "a.out";

        var flags: u64 = OS_O_WRONLY + OS_O_CREAT + OS_O_TRUNC;
        var fd: u64 = sys_open(asm_path, flags, 420);
        if (fd < 0) { pop_trace(); return 1; }

        os_sys_dup2(fd, 1);
        cg_program_with_sigs(merged_prog, get_func_sigs());
        sys_close(fd);

        var nasm_argv: u64 = heap_alloc(8 * 6);
        *(*u64)(nasm_argv + 0) = (u64)"nasm";
        *(*u64)(nasm_argv + 8) = (u64)"-felf64";
        *(*u64)(nasm_argv + 16) = asm_path;
        *(*u64)(nasm_argv + 24) = (u64)"-o";
        *(*u64)(nasm_argv + 32) = obj_path;
        *(*u64)(nasm_argv + 40) = 0;
        os_execute((u64)"/usr/bin/nasm", nasm_argv);

        var ld_argv: u64 = heap_alloc(8 * 5);
        *(*u64)(ld_argv + 0) = (u64)"ld";
        *(*u64)(ld_argv + 8) = obj_path;
        *(*u64)(ld_argv + 16) = (u64)"-o";
        *(*u64)(ld_argv + 24) = exe_path;
        *(*u64)(ld_argv + 32) = 0;
        os_execute((u64)"/usr/bin/ld", ld_argv);
    }
    
    pop_trace();
    return 0;
}
