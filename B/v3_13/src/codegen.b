// codegen.b - Code generator wrapper for v3.13
//
// This is a thin wrapper that re-exports functionality from:
// - symtab.b: Symbol table management
// - typeinfo.b: Type size/compatibility calculations
// - emitter.b: ASM output helpers and global state
// - gen_expr.b: Expression code generation
// - gen_stmt.b: Statement code generation

import std.io;
import types;
import std.util;
import std.vec;
import ast;
import emitter.symtab;
import emitter.typeinfo;
import emitter.emitter;
import emitter.gen_expr;
import emitter.gen_stmt;

// ============================================
// Function Codegen
// ============================================

func cg_func(node: u64) -> u64 {
    var name_ptr: u64 = *(node + 8);
    var name_len: u64 = *(node + 16);
    var params: u64 = *(node + 24);
    var ret_type: u64 = *(node + 32);
    var body: u64 = *(node + 40);
    
    // Check if this is an extended AST_FUNC node (72 bytes)
    var ret_ptr_depth: u64 = *(node + 48);
    var ret_struct_name_ptr: u64 = *(node + 56);
    var ret_struct_name_len: u64 = *(node + 64);
    
    // Store return type information
    emitter_set_ret_type(ret_type);
    emitter_set_ret_ptr_depth(ret_ptr_depth);
    emitter_set_ret_struct_name(ret_struct_name_ptr, ret_struct_name_len);
    
    var g_symtab: u64 = emitter_get_symtab();
    symtab_clear(g_symtab);
    
    emit(name_ptr, name_len);
    emit(":\n", 2);
    
    emit("    push rbp\n", 13);
    emit("    mov rbp, rsp\n", 17);
    emit("    sub rsp, 1024\n", 18);
    
    var g_structs_vec: u64 = typeinfo_get_structs();
    
    var nparams: u64 = vec_len(params);
    var i: u64 = 0;
    while (i < nparams) {
        var param: u64 = vec_get(params, i);
        var pname: u64 = *(param);
        var plen: u64 = *(param + 8);
        var ptype: u64 = *(param + 16);
        var pdepth: u64  = *(param + 24);
        var pstruct_name_ptr: u64 = *(param + 32);
        var pstruct_name_len: u64 = *(param + 40);
        
        var names: u64  = *(g_symtab);
        var offsets: u64 = *(g_symtab + 8);
        var types: u64 = *(g_symtab + 16);
        
        var name_info: u64 = heap_alloc(16);
        *(name_info) = pname;
        *(name_info + 8) = plen;
        vec_push(names, name_info);
        
        vec_push(offsets, 16 + i * 8);
        
        var type_info: u64 = heap_alloc(24);
        *(type_info) = ptype;
        *(type_info + 8) = pdepth;
        *(type_info + 16) = 0;

        // If this is a struct, resolve its struct_def now
        if (ptype == TYPE_STRUCT) {
            if (g_structs_vec != 0) {
                if (pstruct_name_ptr != 0) {
                    var num_structs: u64 = vec_len(g_structs_vec);
                    var si: u64 = 0;
                    while (si < num_structs) {
                        var sd: u64 = vec_get(g_structs_vec, si);
                        var sname_ptr: u64 = *(sd + 8);
                        var sname_len: u64 = *(sd + 16);
                        if (sname_len == pstruct_name_len) {
                            if (str_eq(sname_ptr, sname_len, pstruct_name_ptr, pstruct_name_len) != 0) {
                                *(type_info + 16) = sd;
                                break;
                            }
                        }
                        si = si + 1;
                    }
                }
            }
        }
        vec_push(types, type_info);
        
        *(g_symtab + 24) = *(g_symtab + 24) + 1;
        
        i = i + 1;
    }
    
    cg_block(body);
    
    emit("    xor eax, eax\n", 17);
    emit("    mov rsp, rbp\n", 17);
    emit("    pop rbp\n", 12);
    emit("    ret\n", 8);
}

// ============================================
// Program Codegen
// ============================================

func cg_program(prog: u64) -> u64 {
    var funcs: u64 = *(prog + 8);
    var consts: u64 = *(prog + 16);
    var globals: u64  = *(prog + 32);
    var structs: u64 = *(prog + 40);
    
    // Initialize emitter state
    emitter_init();
    
    // Set structs for typeinfo module
    typeinfo_set_structs(structs);
    
    // Set globals
    if (globals == 0) {
        emitter_set_globals(vec_new(32));
    } else {
        emitter_set_globals(globals);
    }
    
    // Copy constants
    var g_consts: u64 = emitter_get_consts();
    var clen: u64 = vec_len(consts);
    var ci: u64 = 0;
    while (ci < clen) {
        var c: u64 = vec_get(consts, ci);
        var cinfo: u64 = heap_alloc(24);
        *(cinfo) = *(c + 8);
        *(cinfo + 8) = *(c + 16);
        *(cinfo + 16) = *(c + 24);
        vec_push(g_consts, cinfo);
        ci = ci + 1;
    }
    
    emit("default rel\n", 12);
    emit("section .text\n", 14);
    emit("global _start\n", 14);
    emit("_start:\n", 8);
    emit("    pop rdi          ; argc\n", 28);
    emit("    mov rsi, rsp     ; argv\n", 28);
    emit("    push rsi\n", 13);
    emit("    push rdi\n", 13);
    emit("    call main\n", 14);
    emit("    mov rdi, rax\n", 17);
    emit("    mov rax, 60\n", 16);
    emit("    syscall\n", 12);
    
    var len: u64 = vec_len(funcs);
    var i: u64 = 0;
    while (i < len) {
        cg_func(vec_get(funcs, i));
        i = i + 1;
    }
    
    string_emit_data();
    globals_emit_bss();
}
