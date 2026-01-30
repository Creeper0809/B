// main.b - Main entry point for v3.8 modular compiler

import std.io;
import std.str;
import std.os;
import std.path;
import std.util;
import compiler;
import codegen;
import opt;

// Explicit argv layouts for execve-style argument arrays.
// Each field is a single u64 pointer slot, matching the exact contiguous memory
// layout expected by execve without any manual byte offset calculations.
struct Argv6 { a0: u64; a1: u64; a2: u64; a3: u64; a4: u64; a5: u64; }
struct Argv5 { a0: u64; a1: u64; a2: u64; a3: u64; a4: u64; }
struct Argv2 { a0: u64; a1: u64; }


func main(argc: u64, argv: u64) -> u64 {
    if (argc < 2) {
        emit("Usage: v3_19 [-O0|-O1] [-dump-ir|-dump-ssa|-asm] <source.b>\n", 60);
        return 1;
    }

    var argv_ptr: *u64 = (*u64)argv;
    // Compute sizes at runtime to keep sizeof in use without const-restrictions.
    // This keeps allocations correct while avoiding manual byte multipliers.
    var argv6_size: u64 = sizeof(Argv6);
    var argv5_size: u64 = sizeof(Argv5);
    var argv2_size: u64 = sizeof(Argv2);
    var compiler_path: u64 = *argv_ptr;
    var compiler_len: u64 = 0;
    if (compiler_path != 0) { compiler_len = str_len(compiler_path); }
    var filename: u64 = 0;
    for (var i: u64 = 1; i < argc; i++) {
        var arg: u64 = *(argv_ptr + i);
        var arg_len: u64 = str_len(arg);

        if (str_eq(arg, arg_len, "-O1", 3)) {
            opt_set_level(1);
            continue;
        }
        if (str_eq(arg, arg_len, "-O0", 3)) {
            opt_set_level(0);
            continue;
        }
        if (str_eq(arg, arg_len, "-dump-ir", 8)) {
            opt_set_ir_mode(IR_3ADDR);
            opt_set_output_mode(OUT_IR);
            continue;
        }
        if (str_eq(arg, arg_len, "-dump-ssa", 9)) {
            opt_set_ir_mode(IR_SSA);
            opt_set_output_mode(OUT_IR);
            continue;
        }
        if (str_eq(arg, arg_len, "-asm", 4)) {
            opt_set_output_mode(OUT_ASM);
            continue;
        }

        filename = arg;
    }

    if (filename == 0) {
        emit("Usage: v3_19 [-O0|-O1] [-dump-ir|-dump-ssa|-asm] <source.b>\n", 60);
        return 1;
    }

    var filename_len: u64 = str_len(filename);

    setup_paths_with_compiler(compiler_path, compiler_len, filename, filename_len);

    push_trace("main", "main.b", __LINE__);

    init_compiler_globals();

    if (!load_module(filename, filename_len)) {
        pop_trace();
        return 1;
    }
    
    var merged_prog: u64 = build_merged_program();
    var out_mode: u64 = opt_get_output_mode();
    var base_name: u64 = path_basename_noext(filename, filename_len);
    var base_len: u64 = str_len(base_name);
    var s_ext: u64 = ".s";
    var o_ext: u64 = ".o";
    var out_ext: u64 = ".out";

    if (out_mode == OUT_IR) {
        cg_program_with_sigs_ir(merged_prog, get_func_sigs());
    } else if (out_mode == OUT_ASM) {
        cg_program_with_sigs(merged_prog, get_func_sigs());
    } else {
        var asm_path: u64 = str_concat(base_name, base_len, s_ext, 2);
        var obj_path: u64 = str_concat(base_name, base_len, o_ext, 2);
        var exe_path: u64 = str_concat(base_name, base_len, out_ext, 4);

        var flags: u64 = OS_O_WRONLY + OS_O_CREAT + OS_O_TRUNC;
        var fd: u64 = sys_open(asm_path, flags, 420);
        if (fd < 0) { pop_trace(); return 1; }

        var saved_fd: u64 = 100;
        var dup_res: i64 = (i64)os_sys_dup2(1, saved_fd);
        if (dup_res < 0) { sys_close(fd); pop_trace(); return 1; }

        os_sys_dup2(fd, 1);
        cg_program_with_sigs(merged_prog, get_func_sigs());
        sys_close(fd);

        os_sys_dup2(saved_fd, 1);
        sys_close(saved_fd);

        var nasm_argv: *Argv6 = (*Argv6)heap_alloc(argv6_size);
        nasm_argv->a0 = (u64)"nasm";
        nasm_argv->a1 = (u64)"-felf64";
        nasm_argv->a2 = asm_path;
        nasm_argv->a3 = (u64)"-o";
        nasm_argv->a4 = obj_path;
        nasm_argv->a5 = 0;
        os_execute((u64)"/usr/bin/nasm", (u64)nasm_argv);

        var ld_argv: *Argv5 = (*Argv5)heap_alloc(argv5_size);
        ld_argv->a0 = (u64)"ld";
        ld_argv->a1 = obj_path;
        ld_argv->a2 = (u64)"-o";
        ld_argv->a3 = exe_path;
        ld_argv->a4 = 0;
        os_execute((u64)"/usr/bin/ld", (u64)ld_argv);

        emit("[OK] output: ", 14);
        emit(exe_path, str_len(exe_path));
        emit("\n", 1);

        var exe_argv: *Argv2 = (*Argv2)heap_alloc(argv2_size);
        exe_argv->a0 = exe_path;
        exe_argv->a1 = 0;
        var status: i64 = os_execute(exe_path, (u64)exe_argv);
        emit("[RUN] exit=", 11);
        print_i64(status);
        emit("\n", 1);
    }
    
    pop_trace();
    return 0;
}
