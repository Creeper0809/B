// gen_stmt.b - Statement code generation
//
// Generates x86-64 assembly for statements:
// - cg_stmt: generate code for a single statement
// - cg_block: generate code for a block of statements

import std.io;
import std.vec;
import std.util;
import std.str;
import types;
import ast;
import compiler;
import emitter.emitter;
import emitter.symtab;
import emitter.typeinfo;
import emitter.gen_expr;

// ============================================
// Block Codegen
// ============================================

func cg_block(node: u64) -> u64 {
    var block: *AstBlock = (*AstBlock)node;
    var stmts: u64 = block->stmts_vec;
    var len: u64 = vec_len(stmts);
    for(var i: u64 = 0; i < len;i++){
        cg_stmt(vec_get(stmts, i));
   }
}

// ============================================
// Statement Codegen
// ============================================

func cg_stmt(node: u64) -> u64 {
    var kind: u64 = ast_kind(node);
    var symtab: u64 = emitter_get_symtab();
    var g_structs_vec: u64 = typeinfo_get_structs();

    switch (kind) {
        case AST_RETURN:
            cg_return_stmt(node, symtab);
            return;
        case AST_VAR_DECL:
            cg_var_decl_stmt(node, symtab, g_structs_vec);
            return;
        case AST_ASSIGN:
            cg_assign_stmt(node, symtab);
            return;
        case AST_EXPR_STMT:
            var expr_stmt: *AstExprStmt = (*AstExprStmt)node;
            var expr: u64 = expr_stmt->expr;
            cg_expr(expr);
            return;
        case AST_IF:
            cg_if_stmt(node);
            return;
        case AST_WHILE:
            cg_while_stmt(node);
            return;
        case AST_FOR:
            cg_for_stmt(node);
            return;
        case AST_SWITCH:
            cg_switch_stmt(node);
            return;
        case AST_BREAK:
            var g_loop_labels: u64 = emitter_get_loop_labels();
            var len: u64 = vec_len(g_loop_labels);
            if (len == 0) {
                emit("    ; ERROR: break outside loop\n", 29);
                panic();
            }
            var label: u64 = vec_get(g_loop_labels, len - 1);
            emit("    jmp ", 8);
            emit_label(label);
            emit_nl();
            return;
        case AST_CONTINUE:
            var g_loop_continue_labels: u64 = emitter_get_continue_labels();
            var len2: u64 = vec_len(g_loop_continue_labels);
            if (len2 == 0) {
                emit("    ; ERROR: continue outside loop\n", 32);
                panic();
            }
            var label2: u64 = vec_get(g_loop_continue_labels, len2 - 1);
            emit("    jmp ", 8);
            emit_label(label2);
            emit_nl();
            return;
        case AST_ASM:
            cg_asm_stmt(node);
            return;
        case AST_BLOCK:
            cg_block(node);
            return;
    }
}

func emit_call_resolved(name_ptr: u64, name_len: u64) -> u64 {
    var resolved_ptr: u64 = name_ptr;
    var resolved_len: u64 = name_len;
    var resolved: u64 = resolve_name(name_ptr, name_len);
    if (resolved != 0) {
        var info: *NameInfo = (*NameInfo)resolved;
        resolved_ptr = info->ptr;
        resolved_len = info->len;
    }
    emit("    call ", 9);
    emit(resolved_ptr, resolved_len);
    emit_nl();
    return 0;
}

func cg_call_sret(call: *AstCall, dest_offset: u64, symtab: u64) -> u64 {
    var args: u64 = call->args_vec;
    var nargs: u64 = 0;
    if (args != 0) { nargs = vec_len(args); }
    var total_arg_words: u64 = 0;
    if (nargs > 0) {
        for (var i: i64 = (i64)nargs - 1; i >= 0; i = i - 1) {
            var arg: u64 = vec_get(args, (u64)i);
            total_arg_words = total_arg_words + _cg_sysv_push_call_arg(arg, symtab);
        }
    }

    emit("    lea rdi, [rbp", 18);
    if (dest_offset < 0) { emit_i64(dest_offset); }
    else { emit("+", 1); emit_u64(dest_offset); }
    emit("]\n", 2);

    var stack_words: u64 = _cg_sysv_pop_arg_regs_sret(total_arg_words);
    emit_call_resolved(call->name_ptr, call->name_len);
    if (stack_words > 0) {
        emit("    add rsp, ", 13);
        emit_u64(stack_words * 8);
        emit_nl();
    }
    return 0;
}

func cg_ensure_heap_brk_global() -> u64 {
    var globals: u64 = emitter_get_globals();
    if (globals == 0) { return 0; }
    if (is_global_var("__cg_heap_brk", 13) != 0) { return 0; }
    var ginfo: *GlobalInfo = (*GlobalInfo)heap_alloc(sizeof(GlobalInfo));
    ginfo->name_ptr = "__cg_heap_brk";
    ginfo->name_len = 13;
    vec_push(globals, (u64)ginfo);
    return 0;
}

// ============================================
// Return Statement
// ============================================

func cg_return_stmt(node: u64, symtab: u64) -> u64 {
    var ret: *AstReturn = (*AstReturn)node;
    var expr: u64 = ret->expr;
    
    if (expr != 0) {
        var ret_type: u64 = emitter_get_ret_type();
        var ret_ptr_depth: u64 = emitter_get_ret_ptr_depth();
        var ret_struct_name_ptr: u64 = emitter_get_ret_struct_name_ptr();
        var ret_struct_name_len: u64 = emitter_get_ret_struct_name_len();
        
        // Check if return type is struct (value, not pointer)
        if (ret_type == TYPE_STRUCT && ret_ptr_depth == 0) {
            var expr_kind: u64 = ast_kind(expr);
            
            // Find struct size
            var struct_size: u64 = sizeof_type(ret_type, 0, ret_struct_name_ptr, ret_struct_name_len);
            
            // Large structs: return via hidden sret pointer in rdi
            if (struct_size > 16) {
                if (expr_kind == AST_STRUCT_LITERAL) {
                    var lit2: *AstStructLiteral = (*AstStructLiteral)expr;
                    var values2: u64 = lit2->values_vec;
                    var vcount2: u64 = 0;
                    if (values2 != 0) { vcount2 = vec_len(values2); }
                    var off: u64 = 0;
                    for (var i2: u64 = 0; i2 < vcount2; i2++) {
                        emit("    push rdi\n", 13);
                        cg_expr(vec_get(values2, i2));
                        emit("    pop rdi\n", 12);
                        emit("    mov [rdi", 12);
                        if (off != 0) { emit("+", 1); emit_u64(off); }
                        emit("], rax\n", 7);
                        off = off + 8;
                    }
                    if (off < struct_size) {
                        emit("    xor eax, eax\n", 17);
                        for (var fill_off: u64 = off; fill_off < struct_size; fill_off = fill_off + 8) {
                            emit("    mov [rdi", 12);
                            if (fill_off != 0) { emit("+", 1); emit_u64(fill_off); }
                            emit("], rax\n", 7);
                        }
                    }
                } else {
                    emit("    push rdi\n", 13);
                    cg_lvalue(expr);
                    emit("    mov rbx, rax\n", 19);
                    emit("    pop rdi\n", 12);
                    for (var off2: u64 = 0; off2 < struct_size; off2 = off2 + 8) {
                        emit("    mov rax, [rbx", 18);
                        if (off2 != 0) { emit("+", 1); emit_u64(off2); }
                        emit("]\n", 2);
                        emit("    mov [rdi", 12);
                        if (off2 != 0) { emit("+", 1); emit_u64(off2); }
                        emit("], rax\n", 7);
                    }
                }
                emit("    mov rsp, rbp\n", 17);
                emit("    pop rbp\n", 12);
                emit("    ret\n", 8);
                return 0;
            }
            
            // If expression is a function call, it already returns struct in rax/rdx
            if (expr_kind == AST_CALL) {
                cg_expr(expr);
                // rax and rdx already contain the struct value
            } else if (expr_kind == AST_STRUCT_LITERAL) {
                // For struct literals, evaluate fields and place in rax/rdx
                var lit: *AstStructLiteral = (*AstStructLiteral)expr;
                var values: u64 = lit->values_vec;
                if (values == 0) {
                    emit("    xor eax, eax\n", 17);
                    emit("    xor edx, edx\n", 17);
                } else {
                    var vcount: u64 = vec_len(values);
                    // First field -> rax
                    if (vcount > 0) {
                        cg_expr(vec_get(values, 0));
                        // rax now has first field
                    } else {
                        emit("    xor eax, eax\n", 17);
                    }
                    // Second field -> rdx (if struct > 8 bytes)
                    if (struct_size > 8) {
                        if (vcount > 1) {
                            emit("    push rax\n", 13);
                            cg_expr(vec_get(values, 1));
                            emit("    mov rdx, rax\n", 17);
                            emit("    pop rax\n", 12);
                        } else {
                            emit("    xor edx, edx\n", 17);
                        }
                    }
                }
            } else {
                // For other expressions (AST_IDENT, etc), get address and load
                cg_lvalue(expr);

                // rax now contains address of struct
                // Load struct content into rax (and rdx if needed)
                emit("    mov r10, rax\n", 17);   // Save struct address in r10
                emit("    mov rax, [r10]\n", 19); // Load first 8 bytes into rax
                if (struct_size > 8) {
                    emit("    mov rdx, [r10+8]\n", 21); // Load next 8 bytes into rdx
                }
            }
        } else if (ret_type == TYPE_SLICE && ret_ptr_depth == 0) {
            var expr_kind2: u64 = ast_kind(expr);
            if (expr_kind2 == AST_SLICE) {
                var slice_node: *AstSlice = (*AstSlice)expr;
                var handled: u64 = 0;
                var ptr_kind: u64 = ast_kind(slice_node->ptr_expr);
                if (ptr_kind == AST_IDENT) {
                    var idn: *AstIdent = (*AstIdent)slice_node->ptr_expr;
                    var ti_ptr2: u64 = symtab_get_type(symtab, idn->name_ptr, idn->name_len);
                    if (ti_ptr2 != 0) {
                        var ti2: *TypeInfo = (*TypeInfo)ti_ptr2;
                        if (ti2->type_kind == TYPE_ARRAY && ti2->ptr_depth == 0) {
                            cg_ensure_heap_brk_global();
                            var elem_size: u64 = sizeof_type(ti2->elem_type_kind, ti2->elem_ptr_depth, ti2->struct_name_ptr, ti2->struct_name_len);
                            cg_expr(slice_node->len_expr);
                            emit("    mov r12, rax\n", 19);
                            emit("    mov r8, rax\n", 18);
                            emit("    mov rax, ", 13);
                            emit_u64(elem_size);
                            emit_nl();
                            emit("    imul r8, rax\n", 20);
                            var init_label: u64 = new_label();
                            var ok_label: u64 = new_label();
                            var fail_label: u64 = new_label();
                            emit("    mov rax, [_gvar___cg_heap_brk]\n", 35);
                            emit("    cmp rax, 0\n", 16);
                            emit("    jne ", 8);
                            emit_label(init_label);
                            emit_nl();
                            emit("    mov rax, 12\n", 18);
                            emit("    xor rdi, rdi\n", 19);
                            emit("    syscall\n", 13);
                            emit("    mov [_gvar___cg_heap_brk], rax\n", 39);
                            emit_label_def(init_label);
                            emit("    mov rbx, [_gvar___cg_heap_brk]\n", 35);
                            emit("    mov rdi, rbx\n", 19);
                            emit("    add rdi, r8\n", 18);
                            emit("    mov rax, 12\n", 18);
                            emit("    syscall\n", 13);
                            emit("    cmp rax, rdi\n", 18);
                            emit("    jb ", 7);
                            emit_label(fail_label);
                            emit_nl();
                            emit("    mov [_gvar___cg_heap_brk], rax\n", 39);
                            emit("    jmp ", 8);
                            emit_label(ok_label);
                            emit_nl();
                            emit_label_def(fail_label);
                            emit("    xor rbx, rbx\n", 19);
                            emit_label_def(ok_label);
                            emit("    mov rdx, r12\n", 19);
                            cg_expr(slice_node->ptr_expr);
                            emit("    mov rsi, rax\n", 19);
                            emit("    mov rdi, rbx\n", 19);
                            emit("    xor r9, r9\n", 17);
                            var loop_label: u64 = new_label();
                            var end_label: u64 = new_label();
                            emit_label_def(loop_label);
                            emit("    cmp r9, r8\n", 19);
                            emit("    jge ", 8);
                            emit_label(end_label);
                            emit_nl();
                            emit("    mov r10b, [rsi+r9]\n", 30);
                            emit("    mov [rdi+r9], r10b\n", 30);
                            emit("    add r9, 1\n", 16);
                            emit("    jmp ", 8);
                            emit_label(loop_label);
                            emit_nl();
                            emit_label_def(end_label);
                            emit("    mov rax, rbx\n", 19);
                            handled = 1;
                        }
                    }
                }
                if (handled == 0) {
                    cg_expr(slice_node->ptr_expr);
                    emit("    mov rbx, rax\n", 19);
                    cg_expr(slice_node->len_expr);
                    emit("    mov rdx, rax\n", 19);
                    emit("    mov rax, rbx\n", 19);
                }
            } else if (expr_kind2 == AST_CALL) {
                cg_expr(expr);
                // rax/rdx already set by callee
            } else {
                cg_lvalue(expr);
                emit("    mov rbx, [rax]\n", 19);
                emit("    mov rdx, [rax+8]\n", 21);
                emit("    mov rax, rbx\n", 19);
            }
        } else {
            // Normal return (non-struct or pointer to struct)
            cg_expr(expr);
        }
    } else {
        emit("    xor eax, eax\n", 17);
    }
    emit("    mov rsp, rbp\n", 17);
    emit("    pop rbp\n", 12);
    emit("    ret\n", 8);
}

// ============================================
// Variable Declaration Statement
// ============================================

func cg_var_decl_stmt(node: u64, symtab: u64, g_structs_vec: u64) -> u64 {
    var decl: *AstVarDecl = (*AstVarDecl)node;
    var name_ptr: u64 = decl->name_ptr;
    var name_len: u64 = decl->name_len;
    var type_kind: u64 = decl->type_kind;
    var ptr_depth: u64 = decl->ptr_depth;
    var is_tagged: u64 = decl->is_tagged;
    var init: u64 = decl->init_expr;
    var struct_name_ptr: u64 = decl->struct_name_ptr;
    var struct_name_len: u64 = decl->struct_name_len;
    var tag_layout_ptr: u64 = decl->tag_layout_ptr;
    var tag_layout_len: u64 = decl->tag_layout_len;
    var elem_type_kind: u64 = decl->elem_type_kind;
    var elem_ptr_depth: u64 = decl->elem_ptr_depth;
    var array_len: u64 = decl->array_len;
    
    // Calculate size based on type
    var size: u64 = 0;
    if (type_kind == TYPE_ARRAY) {
        var elem_size: u64 = sizeof_type(elem_type_kind, elem_ptr_depth, struct_name_ptr, struct_name_len);
        size = elem_size * array_len;
    } else if (type_kind == TYPE_SLICE) {
        size = 16;
    } else {
        size = sizeof_type(type_kind, ptr_depth, struct_name_ptr, struct_name_len);
    }
    
    var offset: u64 = symtab_add(symtab, name_ptr, name_len, type_kind, ptr_depth, size);
    var type_info0: u64 = symtab_get_type(symtab, name_ptr, name_len);
    var ti0: *TypeInfo = (*TypeInfo)type_info0;
    ti0->is_tagged = is_tagged;
    if (is_tagged == 1 && struct_name_ptr != 0 && type_kind != TYPE_STRUCT && type_kind != TYPE_ARRAY && type_kind != TYPE_SLICE) {
        ti0->struct_name_ptr = struct_name_ptr;
        ti0->struct_name_len = struct_name_len;
    }
    if (is_tagged == 1 && tag_layout_ptr != 0) {
        ti0->tag_layout_ptr = tag_layout_ptr;
        ti0->tag_layout_len = tag_layout_len;
    }
    
    // If base type is struct, find struct_def and store pointer in type_info
    if (type_kind == TYPE_STRUCT) {
        var struct_def: u64 = 0;
        if (g_structs_vec != 0) {
            var num_structs: u64 = vec_len(g_structs_vec);
            for (var i: u64 = 0; i < num_structs; i++) {
                var sd: u64 = vec_get(g_structs_vec, i);
                var struct_def: *AstStructDef = (*AstStructDef)sd;
                var sname_ptr: u64 = struct_def->name_ptr;
                var sname_len: u64 = struct_def->name_len;
                if (str_eq(sname_ptr, sname_len, struct_name_ptr, struct_name_len)) {
                    struct_def = sd;
                    break;
                }
            }
        }
        var type_info: u64 = symtab_get_type(symtab, name_ptr, name_len);
        var ti: *TypeInfo = (*TypeInfo)type_info;
        ti->struct_def = struct_def;
        ti->struct_name_ptr = struct_name_ptr;
        ti->struct_name_len = struct_name_len;
        ti->elem_type_kind = 0;
        ti->elem_ptr_depth = 0;
        ti->array_len = 0;
    }

    // If array/slice, store element type info in symtab
    if (type_kind == TYPE_ARRAY || type_kind == TYPE_SLICE) {
        var type_info2: u64 = symtab_get_type(symtab, name_ptr, name_len);
        var ti2: *TypeInfo = (*TypeInfo)type_info2;
        ti2->elem_type_kind = elem_type_kind;
        ti2->elem_ptr_depth = elem_ptr_depth;
        ti2->array_len = array_len;
        ti2->struct_name_ptr = struct_name_ptr;
        ti2->struct_name_len = struct_name_len;
        if (elem_type_kind == TYPE_STRUCT && g_structs_vec != 0 && struct_name_ptr != 0) {
            var num_structs2: u64 = vec_len(g_structs_vec);
            var struct_def2: u64 = 0;
            for (var si2: u64 = 0; si2 < num_structs2; si2++) {
                var sd2: u64 = vec_get(g_structs_vec, si2);
                var sdef2: *AstStructDef = (*AstStructDef)sd2;
                if (str_eq(sdef2->name_ptr, sdef2->name_len, struct_name_ptr, struct_name_len)) {
                    struct_def2 = sd2;
                    break;
                }
            }
            ti2->struct_def = struct_def2;
        }
    }
    
    if (init != 0) {
        if (type_kind == TYPE_ARRAY) {
            emit_stderr("[ERROR] Array initialization is not supported\n", 46);
            panic("Codegen error");
        }
        var init_kind: u64 = ast_kind(init);

        if (type_kind == TYPE_STRUCT && ptr_depth == 0) {
            var struct_size0: u64 = sizeof_type(type_kind, ptr_depth, struct_name_ptr, struct_name_len);
            if (struct_size0 > 16 && init_kind == AST_CALL) {
                cg_call_sret((*AstCall)init, offset, symtab);
                return;
            }
        }
        
        // Handle struct literal initialization specially
        if (init_kind == AST_STRUCT_LITERAL) {
            cg_struct_literal_init(init, offset);
            return;
        }
        
        if (type_kind != 0) {
            var init_type: u64 = get_expr_type_with_symtab(init, symtab);
            if (init_type != 0) {
                var it_info: *TypeInfo = (*TypeInfo)init_type;
                var it_base: u64 = it_info->type_kind;
                var it_depth: u64 = it_info->ptr_depth;
                var it_tagged: u64 = it_info->is_tagged;
                check_type_compat(it_base, it_depth, it_tagged, it_info->tag_layout_ptr, it_info->tag_layout_len, type_kind, ptr_depth, decl->is_tagged, decl->tag_layout_ptr, decl->tag_layout_len);
            }
        }
        
        // Slice initialization: slice(ptr, len) or copy from another slice
        if (type_kind == TYPE_SLICE) {
            if (init_kind == AST_SLICE) {
                var slice_node: *AstSlice = (*AstSlice)init;
                cg_expr(slice_node->ptr_expr);
                emit("    mov [rbp", 12);
                if (offset < 0) { emit_i64(offset); }
                else { emit("+", 1); emit_u64(offset); }
                emit("], rax\n", 7);
                cg_expr(slice_node->len_expr);
                emit("    mov [rbp", 12);
                var off2: u64 = offset + 8;
                if (off2 < 0) { emit_i64(off2); }
                else { emit("+", 1); emit_u64(off2); }
                emit("], rax\n", 7);
                return;
            }
            if (init_kind == AST_CALL) {
                cg_expr(init);
                emit("    mov [rbp", 12);
                if (offset < 0) { emit_i64(offset); }
                else { emit("+", 1); emit_u64(offset); }
                emit("], rax\n", 7);
                emit("    mov [rbp", 12);
                var offc: u64 = offset + 8;
                if (offc < 0) { emit_i64(offc); }
                else { emit("+", 1); emit_u64(offc); }
                emit("], rdx\n", 7);
                return;
            }
            // Copy from another slice value
            cg_lvalue(init);
            emit("    mov rbx, [rax]\n", 19);
            emit("    mov rcx, [rax+8]\n", 21);
            emit("    mov [rbp", 12);
            if (offset < 0) { emit_i64(offset); }
            else { emit("+", 1); emit_u64(offset); }
            emit("], rbx\n", 7);
            emit("    mov [rbp", 12);
            var off3: u64 = offset + 8;
            if (off3 < 0) { emit_i64(off3); }
            else { emit("+", 1); emit_u64(off3); }
            emit("], rcx\n", 7);
            return;
        }

        cg_expr(init);
        if (is_tagged == 1 && ptr_depth > 0) {
            var init_type2: u64 = get_expr_type_with_symtab(init, symtab);
            if (init_type2 != 0) {
                var it2: *TypeInfo = (*TypeInfo)init_type2;
                if (!(it2->ptr_depth > 0 && it2->is_tagged == 1)) {
                    emit_tagged_mask();
                }
            } else {
                emit_tagged_mask();
            }
        }
        
        // Store small integer types with correct width (u8/u16/u32)
        if (ptr_depth == 0) {
            if (type_kind == TYPE_U8) {
                emit("    mov [rbp", 12);
                if (offset < 0) { emit_i64(offset); }
                else { emit("+", 1); emit_u64(offset); }
                emit("], al\n", 6);
                return;
            }
            if (type_kind == TYPE_U16) {
                emit("    mov [rbp", 12);
                if (offset < 0) { emit_i64(offset); }
                else { emit("+", 1); emit_u64(offset); }
                emit("], ax\n", 6);
                return;
            }
            if (type_kind == TYPE_U32) {
                emit("    mov [rbp", 12);
                if (offset < 0) { emit_i64(offset); }
                else { emit("+", 1); emit_u64(offset); }
                emit("], eax\n", 7);
                return;
            }
        }
        
        // Check if initializing struct by value (e.g., var p: Point = Point_new(...))
        if (type_kind == TYPE_STRUCT && ptr_depth == 0) {
            // Struct returned in rax/rdx registers
            emit("    mov [rbp", 12);
            if (offset < 0) { emit_i64(offset); }
            else { emit("+", 1); emit_u64(offset); }
            emit("], rax\n", 7);
            
            // Check if struct is larger than 8 bytes
            var struct_size: u64 = sizeof_type(type_kind, ptr_depth, struct_name_ptr, struct_name_len);
            if (struct_size > 8) {
                emit("    mov [rbp", 12);
                var offset2: u64 = offset + 8;
                if (offset2 < 0) { emit_i64(offset2); }
                else { emit("+", 1); emit_u64(offset2); }
                emit("], rdx\n", 7);
            }
        } else {
            // Normal case: single value in rax
            emit("    mov [rbp", 12);
            if (offset < 0) { emit_i64(offset); }
            else { emit("+", 1); emit_u64(offset); }
            emit("], rax\n", 7);
        }
    }
}

func cg_struct_literal_init(init: u64, offset: u64) -> u64 {
    var lit: *AstStructLiteral = (*AstStructLiteral)init;
    var struct_def: u64 = lit->struct_def;
    var values: u64 = lit->values_vec;
    var num_values: u64 = vec_len(values);
    var sd: *AstStructDef = (*AstStructDef)struct_def;
    var fields: u64 = sd->fields_vec;
    var num_fields: u64 = vec_len(fields);
    
    // Initialize each field
    var field_offset: u64 = 0;
    for (var i: u64 = 0; i < num_values; i++) {
        if (i < num_fields) {
            var field: *FieldDesc = (*FieldDesc)vec_get(fields, i);
            var field_size: u64 = sizeof_field_desc(field);
            
            // Evaluate field value
            cg_expr(vec_get(values, i));
            
            // Store at variable offset + field offset
            emit("    mov [rbp", 12);
            var total_offset: u64 = offset + field_offset;
            if (total_offset < 0) { emit_i64(total_offset); }
            else { emit("+", 1); emit_u64(total_offset); }
            emit("], rax\n", 7);
            
            field_offset = field_offset + field_size;
        }
    }
}

// ============================================
// Assignment Statement
// ============================================

func cg_assign_stmt(node: u64, symtab: u64) -> u64 {
    var assign: *AstAssign = (*AstAssign)node;
    var target: u64 = assign->target;
    var value: u64 = assign->value;
    
    var target_kind: u64 = ast_kind(target);
    var value_kind: u64 = ast_kind(value);
    if (target_kind == AST_MEMBER_ACCESS) {
        var m: *AstMemberAccess = (*AstMemberAccess)target;
        var obj: u64 = m->object;
        var member_ptr: u64 = m->member_ptr;
        var member_len: u64 = m->member_len;
        var obj_type: u64 = get_expr_type_with_symtab(obj, symtab);
        if (obj_type != 0) {
            var ot: *TypeInfo = (*TypeInfo)obj_type;
            if (ot->ptr_depth > 0 && ot->is_tagged == 1 && ot->tag_layout_ptr != 0) {
                var layout_def: u64 = get_struct_def(ot->tag_layout_ptr, ot->tag_layout_len);
                if (layout_def == 0) {
                    emit("[ERROR] Tagged layout struct not found\n", 41);
                    panic("Codegen error");
                }
                var layout_info: *AstStructDef = (*AstStructDef)layout_def;
                var packed_flag: u64 = layout_info->is_packed;
                if (packed_flag == 0) {
                    emit("[ERROR] Tagged layout must be packed struct\n", 49);
                    panic("Codegen error");
                }
                if (ast_kind(obj) != AST_IDENT) {
                    emit("[ERROR] Tagged layout assignment requires identifier base\n", 62);
                    panic("Codegen error");
                }

                var total_bits: u64 = get_packed_layout_total_bits(layout_def);
                var field_offset: u64 = get_packed_field_bit_offset(layout_def, member_ptr, member_len);
                var field_width: u64 = get_packed_field_bit_width(layout_def, member_ptr, member_len);
                var start_bit: u64 = 64 - total_bits;
                var shift_bits: u64 = start_bit + field_offset;

                cg_expr(value);
                emit("    mov r9, rax\n", 16);
                cg_expr(obj);
                emit("    mov rbx, rax\n", 17);

                if (field_width < 64) {
                    emit_mask_to_rdx(field_width);
                    emit("    and r9, rdx\n", 16);
                }
                if (shift_bits > 0) {
                    emit("    mov rcx, ", 13);
                    emit_u64(shift_bits);
                    emit_nl();
                    emit("    shl r9, cl\n", 15);
                }

                if (field_width < 64) {
                    emit_mask_to_rdx(field_width);
                    if (shift_bits > 0) {
                        emit("    mov r10, rdx\n", 17);
                        emit("    mov rcx, ", 13);
                        emit_u64(shift_bits);
                        emit_nl();
                        emit("    shl r10, cl\n", 16);
                    } else {
                        emit("    mov r10, rdx\n", 17);
                    }
                    emit("    not r10\n", 12);
                    emit("    and rbx, r10\n", 17);
                } else {
                    emit("    xor rbx, rbx\n", 17);
                }

                emit("    or rbx, r9\n", 15);
                cg_lvalue(obj);
                emit("    mov [rax], rbx\n", 19);
                return;
            }
            if (ot->ptr_depth == 0 && ot->type_kind == TYPE_STRUCT && ot->struct_def != 0) {
                var struct_info: *AstStructDef = (*AstStructDef)ot->struct_def;
                var packed_flag2: u64 = struct_info->is_packed;
                if (packed_flag2 == 1) {
                    var total_bits2: u64 = get_packed_layout_total_bits(ot->struct_def);
                    var field_offset2: u64 = get_packed_field_bit_offset(ot->struct_def, member_ptr, member_len);
                    var field_width2: u64 = get_packed_field_bit_width(ot->struct_def, member_ptr, member_len);
                    var shift_bits2: u64 = field_offset2;
                    var size_bytes2: u64 = (total_bits2 + 7) / 8;

                    cg_expr(value);
                    emit("    mov r9, rax\n", 16);
                    cg_lvalue(obj);
                    if (size_bytes2 == 1) {
                        emit("    movzx rbx, byte [rax]\n", 30);
                    } else if (size_bytes2 == 2) {
                        emit("    movzx rbx, word [rax]\n", 30);
                    } else if (size_bytes2 == 4) {
                        emit("    mov ebx, [rax]\n", 19);
                    } else {
                        emit("    mov rbx, [rax]\n", 19);
                    }

                    if (field_width2 < 64) {
                        emit_mask_to_rdx(field_width2);
                        emit("    and r9, rdx\n", 16);
                    }
                    if (shift_bits2 > 0) {
                        emit("    mov rcx, ", 13);
                        emit_u64(shift_bits2);
                        emit_nl();
                        emit("    shl r9, cl\n", 15);
                    }

                    if (field_width2 < 64) {
                        emit_mask_to_rdx(field_width2);
                        if (shift_bits2 > 0) {
                            emit("    mov r10, rdx\n", 17);
                            emit("    mov rcx, ", 13);
                            emit_u64(shift_bits2);
                            emit_nl();
                            emit("    shl r10, cl\n", 16);
                        } else {
                            emit("    mov r10, rdx\n", 17);
                        }
                        emit("    not r10\n", 12);
                        emit("    and rbx, r10\n", 17);
                    } else {
                        emit("    xor rbx, rbx\n", 17);
                    }

                    emit("    or rbx, r9\n", 15);
                    cg_lvalue(obj);
                    if (size_bytes2 == 1) {
                        emit("    mov [rax], bl\n", 18);
                    } else if (size_bytes2 == 2) {
                        emit("    mov [rax], bx\n", 18);
                    } else if (size_bytes2 == 4) {
                        emit("    mov [rax], ebx\n", 19);
                    } else {
                        emit("    mov [rax], rbx\n", 19);
                    }
                    return;
                }
            }
        }
    }
    if (target_kind == AST_IDENT) {
        var ident: *AstIdent = (*AstIdent)target;
        var name_ptr: u64 = ident->name_ptr;
        var name_len: u64 = ident->name_len;
        
        var target_type: u64 = symtab_get_type(symtab, name_ptr, name_len);
        var value_type: u64 = get_expr_type_with_symtab(value, symtab);
        
        if (target_type != 0 && value_type != 0) {
            var vt_info: *TypeInfo = (*TypeInfo)value_type;
            var vt_depth: u64 = vt_info->ptr_depth;
            if (vt_depth > 0) {
                var vt_base: u64 = vt_info->type_kind;
                symtab_update_type(symtab, name_ptr, name_len, vt_base, vt_depth);
            }
        }
    }

    var target_type_info: u64 = 0;
    if (target_kind == AST_IDENT) {
        var ident3: *AstIdent = (*AstIdent)target;
        target_type_info = symtab_get_type(symtab, ident3->name_ptr, ident3->name_len);
    }
    var value_type_info: u64 = get_expr_type_with_symtab(value, symtab);

    // Slice assignment: copy ptr+len
    if (target_kind == AST_IDENT || target_kind == AST_MEMBER_ACCESS) {
        var t_type: u64 = 0;
        if (target_kind == AST_IDENT) {
            var ident2: *AstIdent = (*AstIdent)target;
            var t_name_ptr: u64 = ident2->name_ptr;
            var t_name_len: u64 = ident2->name_len;
            t_type = symtab_get_type(symtab, t_name_ptr, t_name_len);
        } else {
            t_type = get_expr_type_with_symtab(target, symtab);
        }
        if (t_type != 0) {
            var tt: *TypeInfo = (*TypeInfo)t_type;
            if (tt->type_kind == TYPE_SLICE && tt->ptr_depth == 0) {
                if (value_kind == AST_SLICE) {
                    var slice_node: *AstSlice = (*AstSlice)value;
                    cg_expr(slice_node->ptr_expr);
                    emit("    mov rbx, rax\n", 17);
                    cg_expr(slice_node->len_expr);
                    emit("    mov rcx, rax\n", 17);
                    cg_lvalue(target);
                    emit("    mov [rax], rbx\n", 19);
                    emit("    mov [rax+8], rcx\n", 21);
                    return;
                }
                if (value_kind == AST_CALL) {
                    cg_expr(value);
                    emit("    mov rbx, rax\n", 17);
                    emit("    mov rcx, rdx\n", 17);
                    cg_lvalue(target);
                    emit("    mov [rax], rbx\n", 19);
                    emit("    mov [rax+8], rcx\n", 21);
                    return;
                }
                cg_lvalue(value);
                emit("    mov rbx, [rax]\n", 19);
                emit("    mov rcx, [rax+8]\n", 21);
                cg_lvalue(target);
                emit("    mov [rax], rbx\n", 19);
                emit("    mov [rax+8], rcx\n", 21);
                return;
            }
        }
    }
    
    cg_expr(value);
    if (target_type_info != 0) {
        var tt2: *TypeInfo = (*TypeInfo)target_type_info;
        if (tt2->ptr_depth > 0 && tt2->is_tagged == 1) {
            if (value_type_info != 0) {
                var vt2: *TypeInfo = (*TypeInfo)value_type_info;
                if (!(vt2->ptr_depth > 0 && vt2->is_tagged == 1)) {
                    emit_tagged_mask();
                }
            } else {
                emit_tagged_mask();
            }
        }
    }
    emit("    push rax\n", 13);
    cg_lvalue(target);
    emit("    pop rbx\n", 12);
    
    if (target_kind == AST_DEREF) {
        var deref: *AstDeref = (*AstDeref)target;
        var deref_operand: u64 = deref->operand;
        var op_type: u64 = get_expr_type_with_symtab(deref_operand, symtab);
        var ti: *TypeInfo = (*TypeInfo)op_type;
        var base_type: u64 = ti->type_kind;
        var ptr_depth: u64 = ti->ptr_depth;
        
        if (ptr_depth == 1) {
            if (base_type == TYPE_U8) {
                emit("    mov [rax], bl\n", 18);
                return;
            }
            if (base_type == TYPE_U16) {
                emit("    mov [rax], bx\n", 18);
                return;
            }
            if (base_type == TYPE_U32) {
                emit("    mov [rax], ebx\n", 19);
                return;
            }
        }
    }
    
    if (target_kind == AST_DEREF8) {
        emit("    mov [rax], bl\n", 18);
        return;
    }

    if (target_kind == AST_INDEX) {
        var idx_type: u64 = get_expr_type_with_symtab(target, symtab);
        if (idx_type != 0) {
            var it: *TypeInfo = (*TypeInfo)idx_type;
            if (it->ptr_depth == 0) {
                if (it->type_kind == TYPE_U8) {
                    emit("    mov [rax], bl\n", 18);
                    return;
                }
                if (it->type_kind == TYPE_U16) {
                    emit("    mov [rax], bx\n", 18);
                    return;
                }
                if (it->type_kind == TYPE_U32) {
                    emit("    mov [rax], ebx\n", 19);
                    return;
                }
            }
        }
        emit("    mov [rax], rbx\n", 19);
        return;
    }
    
    if (target_kind == AST_IDENT) {
        var ident: *AstIdent = (*AstIdent)target;
        var name_ptr: u64 = ident->name_ptr;
        var name_len: u64 = ident->name_len;
        var t_type: u64 = symtab_get_type(symtab, name_ptr, name_len);
        if (t_type != 0) {
            var tt: *TypeInfo = (*TypeInfo)t_type;
            if (tt->ptr_depth == 0) {
                if (tt->type_kind == TYPE_U8) {
                    emit("    mov [rax], bl\n", 18);
                    return;
                }
                if (tt->type_kind == TYPE_U16) {
                    emit("    mov [rax], bx\n", 18);
                    return;
                }
                if (tt->type_kind == TYPE_U32) {
                    emit("    mov [rax], ebx\n", 19);
                    return;
                }
            }
        }
    }
    
    // Check if this is a struct-to-struct copy
    var target_type: u64 = get_expr_type_with_symtab(target, symtab);
    if (target_type != 0) {
        var tt_info: *TypeInfo = (*TypeInfo)target_type;
        var tt_base: u64 = tt_info->type_kind;
        var tt_depth: u64 = tt_info->ptr_depth;
        
        // If it's a direct struct (not pointer), do multi-qword copy
        if (tt_base == TYPE_STRUCT && tt_depth == 0) {
            var struct_def: u64 = tt_info->struct_def;
            if (struct_def != 0) {
                // Get struct name to calculate size
                var sd: *AstStructDef = (*AstStructDef)struct_def;
                var struct_name_ptr: u64 = sd->name_ptr;
                var struct_name_len: u64 = sd->name_len;
                var struct_size: u64 = sizeof_type(TYPE_STRUCT, 0, struct_name_ptr, struct_name_len);
                
                // rax = dest address, rbx = value (but we need lvalue!)
                emit("    mov r8, rax  ; save dest addr\n", 34);
                
                // Get source address by evaluating value as lvalue
                emit("    pop rbx  ; discard rvalue\n", 30);
                cg_lvalue(value);
                
                // Now: rax = source address, r8 = dest address
                // Copy struct_size bytes (8 bytes at a time)
                for (var off: u64 = 0; off < struct_size; off = off + 8) {
                    emit("    mov rcx, [rax", 17);
                    if (off > 0) {
                        emit("+", 1);
                        emit_u64(off);
                    }
                    emit("]\n", 2);
                    emit("    mov [r8", 11);
                    if (off > 0) {
                        emit("+", 1);
                        emit_u64(off);
                    }
                    emit("], rcx\n", 7);
                }
                return;
            }
        }
    }
    
    emit("    mov [rax], rbx\n", 19);
}

// ============================================
// Control Flow Statements
// ============================================

func cg_if_stmt(node: u64) -> u64 {
    var if_stmt: *AstIf = (*AstIf)node;
    var cond: u64 = if_stmt->cond;
    var then_blk: u64 = if_stmt->then_block;
    var else_blk: u64 = if_stmt->else_block;
    
    var else_label: u64 = new_label();
    var end_label: u64 = new_label();
    
    cg_expr(cond);
    emit("    test rax, rax\n", 18);
    emit("    jz ", 7);
    emit_label(else_label);
    emit_nl();
    
    cg_block(then_blk);
    
    if (else_blk != 0) {
        emit("    jmp ", 8);
        emit_label(end_label);
        emit_nl();
    }
    
    emit_label_def(else_label);
    
    if (else_blk != 0) {
        cg_block(else_blk);
        emit_label_def(end_label);
    }
}

func cg_while_stmt(node: u64) -> u64 {
    var while_stmt: *AstWhile = (*AstWhile)node;
    var cond: u64 = while_stmt->cond;
    var body: u64 = while_stmt->body;
    
    var start_label: u64 = new_label();
    var end_label: u64 = new_label();
    
    emit_label_def(start_label);
    
    cg_expr(cond);
    emit("    test rax, rax\n", 18);
    emit("    jz ", 7);
    emit_label(end_label);
    emit_nl();
    
    var g_loop_labels: u64 = emitter_get_loop_labels();
    var g_loop_continue_labels: u64 = emitter_get_continue_labels();
    vec_push(g_loop_labels, end_label);
    vec_push(g_loop_continue_labels, start_label);
    
    cg_block(body);
    
    vec_pop(g_loop_labels);
    vec_pop(g_loop_continue_labels);
    
    emit("    jmp ", 8);
    emit_label(start_label);
    emit_nl();
    
    emit_label_def(end_label);
}

func cg_for_stmt(node: u64) -> u64 {
    var for_stmt: *AstFor = (*AstFor)node;
    var init: u64 = for_stmt->init;
    var cond: u64 = for_stmt->cond;
    var update: u64 = for_stmt->update;
    var body: u64 = for_stmt->body;
    
    if (init != 0) { cg_stmt(init); }
    
    var start_label: u64 = new_label();
    var update_label: u64 = new_label();
    var end_label: u64 = new_label();
    
    emit_label_def(start_label);
    
    if (cond != 0) {
        cg_expr(cond);
        emit("    test rax, rax\n", 18);
        emit("    jz ", 7);
        emit_label(end_label);
        emit_nl();
    }
    
    var g_loop_labels: u64 = emitter_get_loop_labels();
    var g_loop_continue_labels: u64 = emitter_get_continue_labels();
    vec_push(g_loop_labels, end_label);
    vec_push(g_loop_continue_labels, update_label);
    
    cg_block(body);
    
    vec_pop(g_loop_labels);
    vec_pop(g_loop_continue_labels);
    
    emit_label_def(update_label);
    
    if (update != 0) { cg_stmt(update); }
    
    emit("    jmp ", 8);
    emit_label(start_label);
    emit_nl();
    
    emit_label_def(end_label);
}

func cg_switch_stmt(node: u64) -> u64 {
    var switch_stmt: *AstSwitch = (*AstSwitch)node;
    var expr: u64 = switch_stmt->expr;
    var cases: u64 = switch_stmt->cases_vec;
    
    // Evaluate switch expression once
    cg_expr(expr);
    
    var end_label: u64 = new_label();
    var default_label: u64 = 0;
    var has_default: u64 = 0;
    
    // Push end_label to g_loop_labels so that break works
    var g_loop_labels: u64 = emitter_get_loop_labels();
    vec_push(g_loop_labels, end_label);
    
    var num_cases: u64 = vec_len(cases);
    
    // Analyze cases to decide optimization strategy
    var use_jump_table: u64 = 0;
    var min_val: i64 = 0;
    var max_val: i64 = 0;
    var case_count: u64 = 0;
    
    // Count non-default cases and find min/max values
    for (var i: u64 = 0; i < num_cases; i++) {
        var case_node: u64 = vec_get(cases, i);
        var case_stmt: *AstCase = (*AstCase)case_node;
        
        if (case_stmt->is_default == 0) {
            // Try to evaluate case value as constant
            var value_node: u64 = case_stmt->value;
            var value_kind: u64 = ast_kind(value_node);
            
            if (value_kind == AST_LITERAL) {
                var lit: *AstLiteral = (*AstLiteral)value_node;
                var val: i64 = (i64)(lit->value);
                
                if (case_count == 0) {
                    min_val = val;
                    max_val = val;
                } else {
                    if (val < min_val) { min_val = val; }
                    if (val > max_val) { max_val = val; }
                }
                case_count = case_count + 1;
            }
        } else {
            has_default = 1;
        }
        
    }
    
    // Use jump table if: 3+ cases, range <= 256, density > 40%
    var range: i64 = max_val - min_val + 1;
    if (case_count >= 3 && range > 0 && range <= 256) {
        var density: u64 = (case_count * 100) / (u64)range;
        if (density >= 40) {
            use_jump_table = 1;
        }
    }
    
    if (use_jump_table == 1) {
        cg_switch_jump_table(cases, min_val, max_val, end_label, has_default);
    } else {
        cg_switch_linear(cases, end_label, has_default);
    }
    
    // Pop end_label from g_loop_labels
    vec_pop(g_loop_labels);
    
    emit_label_def(end_label);
}

// Linear comparison switch (original behavior, improved)
func cg_switch_linear(cases: u64, end_label: u64, has_default: u64) -> u64 {
    emitln("    push rax    ; switch value");
    
    var num_cases: u64 = vec_len(cases);
    var default_label: u64 = 0;
    var symtab: u64 = emitter_get_symtab();
    
    // First pass: generate comparisons and find default
    var case_labels: u64 = vec_new(num_cases);
    for (var i: u64 = 0; i < num_cases; i++) {
        var case_node: u64 = vec_get(cases, i);
        var case_stmt: *AstCase = (*AstCase)case_node;
        var is_default: u64 = case_stmt->is_default;
        
        var case_label: u64 = new_label();
        vec_push(case_labels, case_label);
        
        if (is_default == 1) {
            default_label = case_label;
        } else {
            // Generate comparison for this case
            var value: u64 = case_stmt->value;
            var value_kind: u64 = ast_kind(value);
            
            // Check if we're comparing strings (AST_STRING or pointer type)
            var is_string_compare: u64 = 0;
            if (value_kind == AST_STRING) {
                is_string_compare = 1;
            }
            
            if (is_string_compare == 1) {
                // String comparison using str_eq(s1, len1, s2, len2)
                // Use System V ABI registers with a small temp spill area.
                
                // Compute s2 and len2
                cg_expr(value);
                emitln("    sub rsp, 16");
                emitln("    mov [rsp], rax    ; s2");
                emitln("    mov rdi, rax");
                emit_call_resolved("str_len", 7);
                emitln("    mov [rsp+8], rax    ; len2");
                
                // Compute len1 from switch value at [rsp+16]
                emitln("    mov rdi, [rsp+16]    ; s1");
                emit_call_resolved("str_len", 7);
                
                // Call str_eq(s1, len1, s2, len2)
                emitln("    mov rsi, rax    ; len1");
                emitln("    mov rdi, [rsp+16]    ; s1");
                emitln("    mov rdx, [rsp]    ; s2");
                emitln("    mov rcx, [rsp+8]    ; len2");
                emit_call_resolved("str_eq", 6);
                emitln("    add rsp, 16");
                emitln("    test rax, rax");
                emit("    jnz ", 8);
                emit_label(case_label);
                emit_nl();
            } else {
                // Integer comparison
                emitln("    mov rax, [rsp]    ; reload switch value");
                emitln("    push rax");
                cg_expr(value);
                emit("    mov rbx, rax\n", 17);
                emit("    pop rax\n", 12);
                emit("    cmp rax, rbx\n", 17);
                emit("    je ", 7);
                emit_label(case_label);
                emit_nl();
            }
        }
        
    }
    
    // If no match, jump to default or end
    if (has_default == 1) {
        emit("    jmp ", 8);
        emit_label(default_label);
        emit_nl();
    } else {
        emit("    jmp ", 8);
        emit_label(end_label);
        emit_nl();
    }
    
    // Second pass: generate case bodies
    for (var i: u64 = 0; i < num_cases; i++) {
        var case_node: u64 = vec_get(cases, i);
        var case_stmt: *AstCase = (*AstCase)case_node;
        var body: u64 = case_stmt->body;
        var case_label: u64 = vec_get(case_labels, i);
        
        emit_label_def(case_label);
        cg_block(body);
        
    }
    
    emit("    add rsp, 8    ; pop switch value\n", 37);
}

// Jump table switch (optimized for dense integer ranges)
func cg_switch_jump_table(cases: u64, min_val: i64, max_val: i64, end_label: u64, has_default: u64) -> u64 {
    var num_cases: u64 = vec_len(cases);
    var range: i64 = max_val - min_val + 1;
    var table_label: u64 = new_label();
    var default_label: u64 = end_label;
    
    // Create case label mapping
    var case_labels: u64 = vec_new(num_cases);
    var value_to_label: u64 = vec_new((u64)range);
    
    // Initialize all table entries to default
    for (var j: u64 = 0; j < (u64)range; j++) {
        vec_push(value_to_label, end_label);
    }
    
    // First pass: create labels and build value->label mapping
    for (var i: u64 = 0; i < num_cases; i++) {
        var case_node: u64 = vec_get(cases, i);
        var case_stmt: *AstCase = (*AstCase)case_node;
        var case_label: u64 = new_label();
        vec_push(case_labels, case_label);
        
        if (case_stmt->is_default == 1) {
            default_label = case_label;
            // Update all unassigned entries to point to default
            for (var j: u64 = 0; j < (u64)range; j++) {
                if (vec_get(value_to_label, j) == end_label) {
                    vec_set(value_to_label, j, default_label);
                }
            }
        } else {
            var value_node: u64 = case_stmt->value;
            var value_kind: u64 = ast_kind(value_node);
            if (value_kind == AST_LITERAL) {
                var lit: *AstLiteral = (*AstLiteral)value_node;
                var val: i64 = (i64)(lit->value);
                var idx: u64 = (u64)(val - min_val);
                vec_set(value_to_label, idx, case_label);
            }
        }
        
    }
    
    // Generate bounds check and jump table lookup
    emit("    ; Jump table switch (range: ", 30);
    emit_i64(min_val);
    emit(" to ", 4);
    emit_i64(max_val);
    emit(")\n", 2);
    
    // Check if value is in range [min_val, max_val]
    if (min_val != 0) {
        emit("    sub rax, ", 13);
        emit_i64(min_val);
        emit("    ; normalize to 0-based\n", 27);
    }
    emit("    cmp rax, ", 13);
    emit_u64((u64)range);
    emit_nl();
    emit("    jae ", 8);
    emit_label(default_label);
    emit("    ; out of range\n", 19);
    
    // Jump via table: jmp [table + rax*8]
    emit("    lea rbx, [rel ", 18);
    emit(" ", 1);
    emit_label(table_label);
    emit("]\n", 2);
    emit("    jmp [rbx + rax*8]\n", 21);
    
    // Emit jump table
    emit_nl();
    emit_label_def(table_label);
    for (var j: u64 = 0; j < (u64)range; j++) {
        emit("    dq ", 7);
        emit_label(vec_get(value_to_label, j));
        emit_nl();
    }
    emit_nl();
    
    // Second pass: generate case bodies
    for (var i: u64 = 0; i < num_cases; i++) {
        var case_node: u64 = vec_get(cases, i);
        var case_stmt: *AstCase = (*AstCase)case_node;
        var body: u64 = case_stmt->body;
        var case_label: u64 = vec_get(case_labels, i);
        
        emit_label_def(case_label);
        cg_block(body);
        
    }
}

func cg_asm_stmt(node: u64) -> u64 {
    var asm_stmt: *AstAsm = (*AstAsm)node;
    var text_vec: u64 = asm_stmt->text_vec;
    var asm_len: u64 = vec_len(text_vec);
    
    var at_line_start: u64 = 1;
    for (var i: u64 = 0; i < asm_len; i++) {
        var ch: u64 = vec_get(text_vec, i);
        if (ch == 10) {
            emit_nl();
            at_line_start = 1;
        } else {
            if (at_line_start == 1) {
                emit("    ", 4);
                at_line_start = 0;
            }
            emit_char(ch);
        }
    }
    emit_nl();
}

