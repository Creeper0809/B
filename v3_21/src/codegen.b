// codegen.b - Code generator wrapper for v3.13
//
// This is a thin wrapper that re-exports functionality from:
// - symtab.b: Symbol table management
// - typeinfo.b: Type size/compatibility calculations
// - emitter.b: ASM output helpers and global state
// - gen_expr.b: Expression code generation
// - gen_stmt.b: Statement code generation

import std.io;
import std.util;
import std.str;
import types;
import std.vec;
import ast;
import compiler;
import ssa.datastruct;
import ssa;
import ssa.mem2reg;
import ssa.opt_o1;
import ssa.destroy;
import ssa.regalloc;
import ssa.lower_phys;
import ssa.codegen;
import ssa.dump;
import opt;
import emitter.symtab;
import emitter.typeinfo;
import emitter.emitter;
import emitter.gen_expr;
import emitter.gen_stmt;

const CODEGEN_DEBUG = 0;

const CG_USED_HAS_CALL_PTR = 1;
const CG_USED_HAS_METHOD_CALL = 2;
const CG_USED_HAS_FUNC_ADDR = 4;

func _cg_used_mark_flag(flags_ptr: u64, mask: u64) -> u64 {
    *(flags_ptr) = *(flags_ptr) | mask;
    return 0;
}

func _cg_used_has_name(used: u64, name_ptr: u64, name_len: u64) -> u64 {
    if (used == 0) { return 0; }
    var n: u64 = vec_len(used);
    for (var i: u64 = 0; i < n; i++) {
        var info: *NameInfo = (*NameInfo)vec_get(used, i);
        var ptr: u64 = info->ptr;
        var len: u64 = info->len;
        if (len == name_len && str_eq(ptr, len, name_ptr, name_len) != 0) { return 1; }
    }
    return 0;
}

func _cg_used_add_name(used: u64, name_ptr: u64, name_len: u64) -> u64 {
    if (_cg_used_has_name(used, name_ptr, name_len) != 0) { return 0; }
    var info: *NameInfo = (*NameInfo)heap_alloc(sizeof(NameInfo));
    info->ptr = name_ptr;
    info->len = name_len;
    vec_push(used, (u64)info);
    return 1;
}

func _cg_used_add_resolved_name(used: u64, name_ptr: u64, name_len: u64) -> u64 {
    var resolved: u64 = resolve_name(name_ptr, name_len);
    if (resolved != 0) {
        var resolved_info: *NameInfo = (*NameInfo)resolved;
        name_ptr = resolved_info->ptr;
        name_len = resolved_info->len;
    }
    return _cg_used_add_name(used, name_ptr, name_len);
}

func _cg_collect_calls_in_expr(node: u64, used: u64, flags_ptr: u64) -> u64 {
    if (node == 0) { return 0; }
    var kind: u64 = ast_kind(node);

    if (kind == AST_CALL) {
        var call: *AstCall = (*AstCall)node;
        _cg_used_add_resolved_name(used, call->name_ptr, call->name_len);
        var args: u64 = call->args_vec;
        if (args != 0) {
            var n: u64 = vec_len(args);
            for (var i: u64 = 0; i < n; i++) {
                _cg_collect_calls_in_expr(vec_get(args, i), used, flags_ptr);
            }
        }
        return 0;
    }

    if (kind == AST_CALL_PTR) {
        var cp: *AstCallPtr = (*AstCallPtr)node;
        _cg_used_mark_flag(flags_ptr, CG_USED_HAS_CALL_PTR);
        _cg_collect_calls_in_expr(cp->callee, used, flags_ptr);
        var args2: u64 = cp->args_vec;
        if (args2 != 0) {
            var n2: u64 = vec_len(args2);
            for (var j: u64 = 0; j < n2; j++) {
                _cg_collect_calls_in_expr(vec_get(args2, j), used, flags_ptr);
            }
        }
        return 0;
    }

    if (kind == AST_METHOD_CALL) {
        var mc: *AstMethodCall = (*AstMethodCall)node;
        _cg_used_mark_flag(flags_ptr, CG_USED_HAS_METHOD_CALL);
        _cg_collect_calls_in_expr(mc->receiver, used, flags_ptr);
        var args3: u64 = mc->args_vec;
        if (args3 != 0) {
            var n3: u64 = vec_len(args3);
            for (var k: u64 = 0; k < n3; k++) {
                _cg_collect_calls_in_expr(vec_get(args3, k), used, flags_ptr);
            }
        }
        return 0;
    }

    if (kind == AST_BINARY) {
        var bin: *AstBinary = (*AstBinary)node;
        _cg_collect_calls_in_expr(bin->left, used, flags_ptr);
        _cg_collect_calls_in_expr(bin->right, used, flags_ptr);
        return 0;
    }

    if (kind == AST_UNARY) {
        var un: *AstUnary = (*AstUnary)node;
        _cg_collect_calls_in_expr(un->operand, used, flags_ptr);
        return 0;
    }

    if (kind == AST_ADDR_OF) {
        var ao: *AstAddrOf = (*AstAddrOf)node;
        var op_kind: u64 = ast_kind(ao->operand);
        if (op_kind == AST_IDENT) {
            var idn: *AstIdent = (*AstIdent)ao->operand;
            if (compiler_func_exists(idn->name_ptr, idn->name_len) != 0) {
                _cg_used_mark_flag(flags_ptr, CG_USED_HAS_FUNC_ADDR);
            }
        }
        _cg_collect_calls_in_expr(ao->operand, used, flags_ptr);
        return 0;
    }

    if (kind == AST_DEREF) {
        var dr: *AstDeref = (*AstDeref)node;
        _cg_collect_calls_in_expr(dr->operand, used, flags_ptr);
        return 0;
    }

    if (kind == AST_DEREF8) {
        var dr8: *AstDeref8 = (*AstDeref8)node;
        _cg_collect_calls_in_expr(dr8->operand, used, flags_ptr);
        return 0;
    }

    if (kind == AST_INDEX) {
        var ix: *AstIndex = (*AstIndex)node;
        _cg_collect_calls_in_expr(ix->base, used, flags_ptr);
        _cg_collect_calls_in_expr(ix->index, used, flags_ptr);
        return 0;
    }

    if (kind == AST_CAST) {
        var ca: *AstCast = (*AstCast)node;
        _cg_collect_calls_in_expr(ca->expr, used, flags_ptr);
        return 0;
    }

    if (kind == AST_MEMBER_ACCESS) {
        var ma: *AstMemberAccess = (*AstMemberAccess)node;
        _cg_collect_calls_in_expr(ma->object, used, flags_ptr);
        return 0;
    }

    if (kind == AST_ASSIGN) {
        var asg2: *AstAssign = (*AstAssign)node;
        _cg_collect_calls_in_expr(asg2->target, used, flags_ptr);
        _cg_collect_calls_in_expr(asg2->value, used, flags_ptr);
        return 0;
    }

    if (kind == AST_STRUCT_LITERAL) {
        var st: *AstStructLiteral = (*AstStructLiteral)node;
        var vals: u64 = st->values_vec;
        if (vals != 0) {
            var n4: u64 = vec_len(vals);
            for (var t: u64 = 0; t < n4; t++) {
                _cg_collect_calls_in_expr(vec_get(vals, t), used, flags_ptr);
            }
        }
        return 0;
    }

    return 0;
}

func _cg_collect_calls_in_stmt(node: u64, used: u64, flags_ptr: u64) -> u64 {
    if (node == 0) { return 0; }
    var kind: u64 = ast_kind(node);

    if (kind == AST_RETURN) {
        var r: *AstReturn = (*AstReturn)node;
        _cg_collect_calls_in_expr(r->expr, used, flags_ptr);
        return 0;
    }

    if (kind == AST_VAR_DECL) {
        var vd: *AstVarDecl = (*AstVarDecl)node;
        _cg_collect_calls_in_expr(vd->init_expr, used, flags_ptr);
        return 0;
    }

    if (kind == AST_CONST_DECL) {
        var cd: *AstConstDecl = (*AstConstDecl)node;
        _cg_collect_calls_in_expr(cd->value, used, flags_ptr);
        return 0;
    }

    if (kind == AST_ASSIGN) {
        var asg: *AstAssign = (*AstAssign)node;
        _cg_collect_calls_in_expr(asg->target, used, flags_ptr);
        _cg_collect_calls_in_expr(asg->value, used, flags_ptr);
        return 0;
    }

    if (kind == AST_EXPR_STMT) {
        var es: *AstExprStmt = (*AstExprStmt)node;
        _cg_collect_calls_in_expr(es->expr, used, flags_ptr);
        return 0;
    }

    if (kind == AST_IF) {
        var ifs: *AstIf = (*AstIf)node;
        _cg_collect_calls_in_expr(ifs->cond, used, flags_ptr);
        _cg_collect_calls_in_stmt(ifs->then_block, used, flags_ptr);
        _cg_collect_calls_in_stmt(ifs->else_block, used, flags_ptr);
        return 0;
    }

    if (kind == AST_WHILE) {
        var wl: *AstWhile = (*AstWhile)node;
        _cg_collect_calls_in_expr(wl->cond, used, flags_ptr);
        _cg_collect_calls_in_stmt(wl->body, used, flags_ptr);
        return 0;
    }

    if (kind == AST_FOR) {
        var fr: *AstFor = (*AstFor)node;
        _cg_collect_calls_in_stmt(fr->init, used, flags_ptr);
        _cg_collect_calls_in_expr(fr->cond, used, flags_ptr);
        _cg_collect_calls_in_stmt(fr->update, used, flags_ptr);
        _cg_collect_calls_in_stmt(fr->body, used, flags_ptr);
        return 0;
    }

    if (kind == AST_SWITCH) {
        var sw: *AstSwitch = (*AstSwitch)node;
        _cg_collect_calls_in_expr(sw->expr, used, flags_ptr);
        var cases: u64 = sw->cases_vec;
        if (cases != 0) {
            var n5: u64 = vec_len(cases);
            for (var c: u64 = 0; c < n5; c++) {
                var case_ptr: u64 = vec_get(cases, c);
                var cs: *AstCase = (*AstCase)case_ptr;
                if (cs->is_default == 0) {
                    _cg_collect_calls_in_expr(cs->value, used, flags_ptr);
                }
                _cg_collect_calls_in_stmt(cs->body, used, flags_ptr);
            }
        }
        return 0;
    }

    if (kind == AST_BLOCK) {
        var blk: *AstBlock = (*AstBlock)node;
        var stmts: u64 = blk->stmts_vec;
        if (stmts != 0) {
            var n6: u64 = vec_len(stmts);
            for (var s: u64 = 0; s < n6; s++) {
                _cg_collect_calls_in_stmt(vec_get(stmts, s), used, flags_ptr);
            }
        }
        return 0;
    }

    return 0;
}

func _cg_collect_calls_in_func(fn: *AstFunc, used: u64, flags_ptr: u64) -> u64 {
    if (fn == 0) { return 0; }
    _cg_collect_calls_in_stmt(fn->body, used, flags_ptr);
    return 0;
}

func _cg_collect_used_func_names(program: *AstProgram, used: u64, flags_ptr: u64) -> u64 {
    if (program == 0) { return 0; }
    var funcs: u64 = program->funcs_vec;
    if (funcs == 0) { return 0; }

    _cg_used_add_name(used, (u64)"main", 4);

    var changed: u64 = 1;
    while (changed != 0) {
        changed = 0;
        var n: u64 = vec_len(funcs);
        for (var i: u64 = 0; i < n; i++) {
            var fn_ptr: u64 = vec_get(funcs, i);
            var fn: *AstFunc = (*AstFunc)fn_ptr;
            if (_cg_used_has_name(used, fn->name_ptr, fn->name_len) != 0) {
                set_current_module_for_func(fn->name_ptr, fn->name_len);
                var before: u64 = vec_len(used);
                _cg_collect_calls_in_func(fn, used, flags_ptr);
                if (vec_len(used) != before) { changed = 1; }
            }
        }
    }
    return 0;
}

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

func _cg_sysv_emit_arg_reg_name(idx: u64) -> u64 {
    if (idx == 0) { emit("rdi", 3); return 0; }
    if (idx == 1) { emit("rsi", 3); return 0; }
    if (idx == 2) { emit("rdx", 3); return 0; }
    if (idx == 3) { emit("rcx", 3); return 0; }
    if (idx == 4) { emit("r8", 2); return 0; }
    if (idx == 5) { emit("r9", 2); return 0; }
    return 0;
}

func _cg_sysv_store_arg_word(arg_idx: u64, dst_offset: u64) -> u64 {
    if (arg_idx < 6) {
        emit("    mov [rbp", 12);
        if (dst_offset < 0) { emit_i64(dst_offset); }
        else { emit("+", 1); emit_u64(dst_offset); }
        emit("], ", 3);
        _cg_sysv_emit_arg_reg_name(arg_idx);
        emit_nl();
        return 0;
    }
    var src_offset: u64 = 16 + (arg_idx - 6) * 8;
    emit("    mov rax, [rbp+", 20);
    emit_u64(src_offset);
    emit("]\n", 2);
    emit("    mov [rbp", 12);
    if (dst_offset < 0) { emit_i64(dst_offset); }
    else { emit("+", 1); emit_u64(dst_offset); }
    emit("], rax\n", 7);
    return 0;
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
    emitln("    sub rsp, 2048");
    
    var g_structs_vec: u64 = typeinfo_get_structs();
    
    var nparams: u64 = vec_len(fn->params_vec);
    var arg_word_index: u64 = 0;
    if (fn->ret_type == TYPE_STRUCT && fn->ret_ptr_depth == 0) {
        var ret_struct_size: u64 = sizeof_type(TYPE_STRUCT, 0, fn->ret_struct_name_ptr, fn->ret_struct_name_len);
        if (ret_struct_size > 16) { arg_word_index = 1; }
    }
    for(var i: u64 = 0 ; i < nparams ; i++){
        var p: *FuncParam = (*FuncParam)vec_get(fn->params_vec, i);
        var param_size: u64 = 8;
        if (p->type_kind == TYPE_SLICE && p->ptr_depth == 0) {
            param_size = 16;
        } else if (p->type_kind == TYPE_STRUCT && p->ptr_depth == 0) {
            param_size = sizeof_type(TYPE_STRUCT, 0, p->struct_name_ptr, p->struct_name_len);
        }
        var offset: u64 = symtab_add(g_symtab, p->name_ptr, p->name_len, p->type_kind, p->ptr_depth, param_size);
        var type_info: u64 = symtab_get_type(g_symtab, p->name_ptr, p->name_len);
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

        if (p->type_kind == TYPE_SLICE && p->ptr_depth == 0) {
            _cg_sysv_store_arg_word(arg_word_index, offset);
            _cg_sysv_store_arg_word(arg_word_index + 1, offset + 8);
            arg_word_index = arg_word_index + 2;
        } else if (p->type_kind == TYPE_STRUCT && p->ptr_depth == 0) {
            var struct_size: u64 = sizeof_type(TYPE_STRUCT, 0, p->struct_name_ptr, p->struct_name_len);
            if (struct_size <= 8) {
                _cg_sysv_store_arg_word(arg_word_index, offset);
                arg_word_index = arg_word_index + 1;
            } else if (struct_size <= 16) {
                _cg_sysv_store_arg_word(arg_word_index, offset);
                _cg_sysv_store_arg_word(arg_word_index + 1, offset + 8);
                arg_word_index = arg_word_index + 2;
            } else {
                _cg_sysv_store_arg_word(arg_word_index, offset);
                arg_word_index = arg_word_index + 1;
            }
        } else {
            _cg_sysv_store_arg_word(arg_word_index, offset);
            arg_word_index = arg_word_index + 1;
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

    var used_names: u64 = 0;
    if (opt_get_level() >= 1) {
        used_names = vec_new(64);
        var used_flags: u64 = 0;
        _cg_collect_used_func_names(program, used_names, &used_flags);
        if ((used_flags & (CG_USED_HAS_CALL_PTR | CG_USED_HAS_METHOD_CALL | CG_USED_HAS_FUNC_ADDR)) != 0) {
            used_names = 0;
        }
    }

    // SSA CFG scaffold (no codegen impact unless SSA/opt enabled)
    typeinfo_set_structs(program->structs_vec);
    typeinfo_set_funcs(sigs);
    var ssa_ctx_ptr: u64 = 0;
    var ssa_ctx: *SSAContext = 0;
    var ir_mode: u64 = opt_get_ir_mode();
    var use_ir: u64 = 0;
    if (ir_mode != IR_NONE) { use_ir = 1; }
    var use_ssa: u64 = 0;
    if (use_ir != 0 || opt_get_level() >= 1) { use_ssa = 1; }

    if (use_ssa != 0) {
        ssa_ctx_ptr = ssa_builder_build_program(prog);
        ssa_ctx = (*SSAContext)ssa_ctx_ptr;
        ssa_mem2reg_run((*SSAContext)ssa_ctx_ptr);
        if (CODEGEN_DEBUG != 0) {
            println("[DEBUG] codegen: mem2reg", 25);
        }
        if (opt_get_level() >= 1) {
            ssa_opt_o1_run((*SSAContext)ssa_ctx_ptr);
            if (CODEGEN_DEBUG != 0) {
                println("[DEBUG] codegen: opt_o1", 25);
            }
        }
        ssa_destroy_run((*SSAContext)ssa_ctx_ptr);
        if (CODEGEN_DEBUG != 0) {
            println("[DEBUG] codegen: destroy", 25);
        }
        ssa_regalloc_run((*SSAContext)ssa_ctx_ptr, 8);
        if (CODEGEN_DEBUG != 0) {
            println("[DEBUG] codegen: regalloc", 26);
        }
        ssa_lower_phys_run((*SSAContext)ssa_ctx_ptr);
        if (CODEGEN_DEBUG != 0) {
            println("[DEBUG] codegen: lower_phys", 27);
        }
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
        var cinfo: *ConstInfo = (*ConstInfo)heap_alloc(sizeof(ConstInfo));
        cinfo->name_ptr = c->name_ptr;
        cinfo->name_len = c->name_len;
        cinfo->value = c->value;
        vec_push(g_consts, (u64)cinfo);
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
    
    var ssa_funcs_u64: *u64 = 0;
    if (use_ssa != 0) {
        ssa_funcs_u64 = (*u64)ssa_ctx->funcs_data;
    }
    for(var i : u64 = 0; i < vec_len(program->funcs_vec);i++){
        var fn_ptr: u64 = vec_get(program->funcs_vec, i);
        var fn: *AstFunc = (*AstFunc)fn_ptr;
        if (used_names != 0 && _cg_used_has_name(used_names, fn->name_ptr, fn->name_len) == 0) {
            continue;
        }
        if (use_ssa != 0) {
            var ssa_fn_ptr: u64 = *(ssa_funcs_u64 + i);
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

func cg_program_with_sigs_ir(prog: u64, sigs: u64) -> u64 {
    push_trace("cg_program_with_sigs_ir", "codegen.b", __LINE__);

    var program: *AstProgram = (*AstProgram)prog;

    typeinfo_set_structs(program->structs_vec);
    typeinfo_set_funcs(sigs);

    var ir_mode: u64 = opt_get_ir_mode();
    var opt_level: u64 = opt_get_level();
    if (ir_mode == IR_3ADDR) {
        var ssa_ctx_ptr3: u64 = ssa_builder_build_program(prog);
        if (opt_level >= 1) {
            ssa_opt_o1_run((*SSAContext)ssa_ctx_ptr3);
        }
        ssa_destroy_run((*SSAContext)ssa_ctx_ptr3);
        ssa_dump_ctx((*SSAContext)ssa_ctx_ptr3, 0);
    } else {
        var ssa_ctx_ptr: u64 = ssa_builder_build_program(prog);
        ssa_mem2reg_run((*SSAContext)ssa_ctx_ptr);
        if (opt_level >= 1) {
            ssa_opt_o1_run((*SSAContext)ssa_ctx_ptr);
        }
        ssa_dump_ctx((*SSAContext)ssa_ctx_ptr, 1);
    }

    pop_trace();
    return 0;
}

func cg_program(prog: u64) -> u64 {
    push_trace("cg_program", "codegen.b", __LINE__);
    
    var program: *AstProgram = (*AstProgram)prog;
    
    // Reuse full function list as signature list
    cg_program_with_sigs(prog, program->funcs_vec);
    
    pop_trace();
}
