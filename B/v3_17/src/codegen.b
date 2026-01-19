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
import std.vec;
import ast;
import compiler;
import ssa;
import ssa_builder;
import ssa_mem2reg;
import ssa_opt_o1;
import ssa_destroy;
import ssa_regalloc;
import ssa_lower_phys;
import ssa_codegen;
import opt;
import emitter.symtab;
import emitter.typeinfo;
import emitter.emitter;
import emitter.gen_expr;
import emitter.gen_stmt;

// ============================================
// Function Codegen
// ============================================

// Function parameter layout (48 bytes)
struct FuncParam {
    name_ptr: u64;
    name_len: u64;
    type_kind: u64;
    ptr_depth: u64;
    is_tagged: u64;
    struct_name_ptr: u64;
    struct_name_len: u64;
    tag_layout_ptr: u64;
    tag_layout_len: u64;
    elem_type_kind: u64;
    elem_ptr_depth: u64;
    array_len: u64;
}

func cg_func(node: u64) -> u64 {
    var fn: *AstFunc = (*AstFunc)node;

    set_current_module_for_func(fn->name_ptr, fn->name_len);
    
    // Store return type information
    emitter_set_ret_type(fn->ret_type);
    emitter_set_ret_ptr_depth(fn->ret_ptr_depth);
    emitter_set_ret_struct_name(fn->ret_struct_name_ptr, fn->ret_struct_name_len);
    
    var g_symtab: u64 = emitter_get_symtab();
    symtab_clear(g_symtab);

    emit(fn->name_ptr, fn->name_len);
    emit(":\n", 2);
    
    emitln("    push rbp");
    emitln("    mov rbp, rsp");
    emitln("    sub rsp, 1024");
    
    var g_structs_vec: u64 = typeinfo_get_structs();
    
    var nparams: u64 = vec_len(fn->params_vec);
    var arg_offset: u64 = 0;
    for(var i: u64 = 0 ; i < nparams ; i++){
         var p: *FuncParam = (*FuncParam)vec_get(fn->params_vec, i);
        
        var names: u64  = *(g_symtab);
        var offsets: u64 = *(g_symtab + 8);
        var types: u64 = *(g_symtab + 16);
        
        var name_info: u64 = heap_alloc(16);
        *(name_info) = p->name_ptr;
        *(name_info + 8) = p->name_len;
        vec_push(names, name_info);
        
        vec_push(offsets, 16 + arg_offset);
        
        var type_info: u64 = heap_alloc(SIZEOF_TYPEINFO);
        var ti: *TypeInfo = (*TypeInfo)type_info;
        ti->type_kind = p->type_kind;
        ti->ptr_depth = p->ptr_depth;
        ti->is_tagged = p->is_tagged;
        ti->struct_name_ptr = p->struct_name_ptr;
        ti->struct_name_len = p->struct_name_len;
        ti->tag_layout_ptr = p->tag_layout_ptr;
        ti->tag_layout_len = p->tag_layout_len;
        ti->struct_def = 0;
        ti->elem_type_kind = p->elem_type_kind;
        ti->elem_ptr_depth = p->elem_ptr_depth;
        ti->array_len = p->array_len;

        // If this is a struct, resolve its struct_def now
        // This applies even for pointer types (*Point) - we store the base struct def
        if (p->type_kind == TYPE_STRUCT && g_structs_vec != 0 && p->struct_name_ptr != 0) {
            var num_structs: u64 = vec_len(g_structs_vec);
            for(var si: u64 = 0 ; si < num_structs ; si++){
                var sd_ptr: u64 = vec_get(g_structs_vec, si);
                var sd: *AstStructDef = (*AstStructDef)sd_ptr;
                if (sd->name_len == p->struct_name_len && str_eq(sd->name_ptr, sd->name_len, p->struct_name_ptr, p->struct_name_len) != 0) {
                    ti->struct_def = sd_ptr;
                    break;
                }
            }
        }
        if (p->elem_type_kind == TYPE_STRUCT && g_structs_vec != 0 && p->struct_name_ptr != 0) {
            var num_structs2: u64 = vec_len(g_structs_vec);
            for(var sj: u64 = 0 ; sj < num_structs2 ; sj++){
                var sd_ptr2: u64 = vec_get(g_structs_vec, sj);
                var sd2: *AstStructDef = (*AstStructDef)sd_ptr2;
                if (sd2->name_len == p->struct_name_len && str_eq(sd2->name_ptr, sd2->name_len, p->struct_name_ptr, p->struct_name_len) != 0) {
                    ti->struct_def = sd_ptr2;
                    break;
                }
            }
        }
        vec_push(types, type_info);
        
        *(g_symtab + 24) = *(g_symtab + 24) + 1;

        if (p->type_kind == TYPE_SLICE && p->ptr_depth == 0) {
            arg_offset = arg_offset + 16;
        } else {
            arg_offset = arg_offset + 8;
        }
    }
    
    cg_block(fn->body);
    
    emitln("   xor eax, eax");
    emitln("    mov rsp, rbp");
    emitln("    pop rbp");
    emitln("   ret");
}

// ============================================
// Program Codegen
// ============================================

func cg_program_with_sigs(prog: u64, sigs: u64) -> u64 {
    push_trace("cg_program_with_sigs", "codegen.b", __LINE__);

    var program: *AstProgram = (*AstProgram)prog;

    // SSA CFG scaffold (no codegen impact yet)
    var ssa_ctx_ptr: u64 = ssa_builder_build_program(prog);
    var ssa_ctx: *SSAContext = (*SSAContext)ssa_ctx_ptr;
    if (opt_get_level() >= 1) {
        ssa_mem2reg_run((*SSAContext)ssa_ctx_ptr);
        ssa_opt_o1_run((*SSAContext)ssa_ctx_ptr);
        ssa_destroy_run((*SSAContext)ssa_ctx_ptr);
        ssa_regalloc_run((*SSAContext)ssa_ctx_ptr, 6);
        ssa_regalloc_apply_run((*SSAContext)ssa_ctx_ptr);
        ssa_lower_phys_run((*SSAContext)ssa_ctx_ptr);
    }

    // Initialize emitter state
    emitter_init();

    // Set structs and functions for typeinfo module
    typeinfo_set_structs(program->structs_vec);
    typeinfo_set_funcs(sigs);
    
    // Set globals
    if (program->globals_vec == 0) {
        emitter_set_globals(vec_new(32));
    } else {
        emitter_set_globals(program->globals_vec);
    }
    
    // Copy constants
    var g_consts: u64 = emitter_get_consts();
    for(var ci: u64 = 0;ci < vec_len(program->consts_vec) ;ci++){
        var c_ptr: u64 = vec_get(program->consts_vec, ci);
        var c: *AstConstDecl = (*AstConstDecl)c_ptr;
        var cinfo: u64 = heap_alloc(24);
        *(cinfo) = c->name_ptr;
        *(cinfo + 8) = c->name_len;
        *(cinfo + 16) = c->value;
        vec_push(g_consts, cinfo);
    }
    
    emitln("default rel");
    emitln("section .text");
    emitln("global _start");
    emitln("_start:");
    emitln("    pop rdi          ; argc");
    emitln("    mov rsi, rsp     ; argv");
    emitln("    push rsi");
    emitln("    push rdi");
    emitln("    call main");
    emitln("    mov rdi, rax");
    emitln("    mov rax, 60");
    emitln("    syscall");
    
    for(var i : u64 = 0; i < vec_len(program->funcs_vec);i++){
        var fn_ptr: u64 = vec_get(program->funcs_vec, i);
        if (opt_get_level() >= 1) {
            var ssa_fn_ptr: u64 = *(*u64)(ssa_ctx->funcs_data + i * 8);
            if (ssa_codegen_is_supported_func(fn_ptr, program->globals_vec) != 0) {
                ssa_codegen_emit_func(fn_ptr, ssa_fn_ptr);
            } else {
                cg_func(fn_ptr);
            }
        } else {
            cg_func(fn_ptr);
        }
    }
    
    string_emit_data();
    globals_emit_bss();
    
    pop_trace();
}

func cg_program(prog: u64) -> u64 {
    push_trace("cg_program", "codegen.b", __LINE__);
    
    var program: *AstProgram = (*AstProgram)prog;
    
    // Reuse full function list as signature list
    cg_program_with_sigs(prog, program->funcs_vec);
    
    pop_trace();
}
