// gen_stmt.b - Statement code generation
//
// Generates x86-64 assembly for statements:
// - cg_stmt: generate code for a single statement
// - cg_block: generate code for a block of statements

import std.io;
import std.vec;
import std.util;
import types;
import ast;

// ============================================
// Block Codegen
// ============================================

func cg_block(node: u64) -> u64 {
    var stmts: u64 = *(node + 8);
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
    
    if (kind == AST_RETURN) {
        cg_return_stmt(node, symtab);
        return;
    }
    
    if (kind == AST_VAR_DECL) {
        cg_var_decl_stmt(node, symtab, g_structs_vec);
        return;
    }
    
    if (kind == AST_ASSIGN) {
        cg_assign_stmt(node, symtab);
        return;
    }
    
    if (kind == AST_EXPR_STMT) {
        var expr: u64 = *(node + 8);
        cg_expr(expr);
        return;
    }
    
    if (kind == AST_IF) {
        cg_if_stmt(node);
        return;
    }
    
    if (kind == AST_WHILE) {
        cg_while_stmt(node);
        return;
    }
    
    if (kind == AST_FOR) {
        cg_for_stmt(node);
        return;
    }
    
    if (kind == AST_SWITCH) {
        cg_switch_stmt(node);
        return;
    }
    
    if (kind == AST_BREAK) {
        var g_loop_labels: u64 = emitter_get_loop_labels();
        var len: u64 = vec_len(g_loop_labels);
        if (len == 0) {
            emit_stderr("[ERROR] break outside loop\n", 29);
            panic();
        }
        var label: u64 = vec_get(g_loop_labels, len - 1);
        emit("    jmp ", 8);
        emit_label(label);
        emit_nl();
        return;
    }

    if (kind == AST_CONTINUE) {
        var g_loop_continue_labels: u64 = emitter_get_continue_labels();
        var len: u64 = vec_len(g_loop_continue_labels);
        if (len == 0) {
            emit_stderr("[ERROR] continue outside loop\n", 32);
            panic();
        }
        var label: u64 = vec_get(g_loop_continue_labels, len - 1);
        emit("    jmp ", 8);
        emit_label(label);
        emit_nl();
        return;
    }
    
    if (kind == AST_ASM) {
        cg_asm_stmt(node);
        return;
    }
    
    if (kind == AST_BLOCK) {
        cg_block(node);
        return;
    }
}

// ============================================
// Return Statement
// ============================================

func cg_return_stmt(node: u64, symtab: u64) -> u64 {
    var expr: u64 = *(node + 8);
    
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
            
            // For simplicity, support up to 16 bytes (rax + rdx)
            if (struct_size > 16) {
                emit_stderr("[ERROR] Struct return size > 16 bytes not supported\n", 53);
                panic();
            }
            
            // If expression is a function call, it already returns struct in rax/rdx
            if (expr_kind == AST_CALL) {
                cg_expr(expr);
                // rax and rdx already contain the struct value
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
    var name_ptr: u64 = *(node + 8);
    var name_len: u64 = *(node + 16);
    var type_kind: u64 = *(node + 24);
    var ptr_depth: u64 = *(node + 32);
    var init: u64 = *(node + 40);
    var struct_name_ptr: u64 = *(node + 48);
    var struct_name_len: u64 = *(node + 56);
    
    // Calculate size based on type
    var size: u64 = sizeof_type(type_kind, ptr_depth, struct_name_ptr, struct_name_len);
    
    var offset: u64 = symtab_add(symtab, name_ptr, name_len, type_kind, ptr_depth, size);
    
    // If base type is struct, find struct_def and store pointer in type_info
    if (type_kind == TYPE_STRUCT) {
        var struct_def: u64 = 0;
        if (g_structs_vec != 0) {
            var num_structs: u64 = vec_len(g_structs_vec);
            for (var i: u64 = 0; i < num_structs; i++) {
                var sd: u64 = vec_get(g_structs_vec, i);
                var sname_ptr: u64 = *(sd + 8);
                var sname_len: u64 = *(sd + 16);
                if (str_eq(sname_ptr, sname_len, struct_name_ptr, struct_name_len)) {
                    struct_def = sd;
                    break;
                }
            }
        }
        var type_info: u64 = symtab_get_type(symtab, name_ptr, name_len);
        *(type_info + 16) = struct_def;
    }
    
    if (init != 0) {
        var init_kind: u64 = ast_kind(init);
        
        // Handle struct literal initialization specially
        if (init_kind == AST_STRUCT_LITERAL) {
            cg_struct_literal_init(init, offset);
            return;
        }
        
        if (type_kind != 0) {
            var init_type: u64 = get_expr_type_with_symtab(init, symtab);
            if (init_type != 0) {
                var it_base: u64 = *(init_type);
                var it_depth: u64 = *(init_type + 8);
                check_type_compat(it_base, it_depth, type_kind, ptr_depth);
            }
        }
        
        cg_expr(init);
        
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
    var struct_def: u64 = *(init + 8);
    var values: u64 = *(init + 16);
    var num_values: u64 = vec_len(values);
    var fields: u64 = *(struct_def + 24);
    var num_fields: u64 = vec_len(fields);
    
    // Initialize each field
    var field_offset: u64 = 0;
    for (var i: u64 = 0; i < num_values; i++) {
        if (i < num_fields) {
            var field: *FieldDesc = (*FieldDesc)vec_get(fields, i);
            var field_size: u64 = sizeof_type(field->type_kind, field->ptr_depth, field->struct_name_ptr, field->struct_name_len);
            
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
    var target: u64 = *(node + 8);
    var value: u64 = *(node + 16);
    
    var target_kind: u64 = ast_kind(target);
    if (target_kind == AST_IDENT) {
        var name_ptr: u64 = *(target + 8);
        var name_len: u64 = *(target + 16);
        
        var target_type: u64 = symtab_get_type(symtab, name_ptr, name_len);
        var value_type: u64 = get_expr_type_with_symtab(value, symtab);
        
        if (target_type != 0 && value_type != 0) {
            var vt_depth: u64 = *(value_type + 8);
            if (vt_depth > 0) {
                var vt_base: u64 = *(value_type);
                symtab_update_type(symtab, name_ptr, name_len, vt_base, vt_depth);
            }
        }
    }
    
    cg_expr(value);
    emit("    push rax\n", 13);
    cg_lvalue(target);
    emit("    pop rbx\n", 12);
    
    if (target_kind == AST_DEREF) {
        var deref_operand: u64 = *(target + 8);
        var op_type: u64 = get_expr_type_with_symtab(deref_operand, symtab);
        var base_type: u64 = *(op_type);
        var ptr_depth: u64 = *(op_type + 8);
        
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
    
    // Check if this is a struct-to-struct copy
    var target_type: u64 = get_expr_type_with_symtab(target, symtab);
    if (target_type != 0) {
        var tt_base: u64 = *(target_type);
        var tt_depth: u64 = *(target_type + 8);
        
        // If it's a direct struct (not pointer), do multi-qword copy
        if (tt_base == TYPE_STRUCT && tt_depth == 0) {
            var struct_def: u64 = *(target_type + 16);
            if (struct_def != 0) {
                // Get struct name to calculate size
                var struct_name_ptr: u64 = *(struct_def + 8);
                var struct_name_len: u64 = *(struct_def + 16);
                var struct_size: u64 = sizeof_type(TYPE_STRUCT, 0, struct_name_ptr, struct_name_len);
                
                // rax = dest address, rbx = value (but we need lvalue!)
                emit("    mov r8, rax  ; save dest addr\n", 34);
                
                // Get source address by evaluating value as lvalue
                emit("    pop rbx  ; discard rvalue\n", 30);
                cg_lvalue(value);
                
                // Now: rax = source address, r8 = dest address
                // Copy struct_size bytes (8 bytes at a time)
                var off: u64 = 0;
                while (off < struct_size) {
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
                    off = off + 8;
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
    var cond: u64 = *(node + 8);
    var then_blk: u64 = *(node + 16);
    var else_blk: u64 = *(node + 24);
    
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
    var cond: u64 = *(node + 8);
    var body: u64 = *(node + 16);
    
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
    
    var len: u64 = vec_len(g_loop_labels);
    *(g_loop_labels + 8) = len - 1;
    len = vec_len(g_loop_continue_labels);
    *(g_loop_continue_labels + 8) = len - 1;
    
    emit("    jmp ", 8);
    emit_label(start_label);
    emit_nl();
    
    emit_label_def(end_label);
}

func cg_for_stmt(node: u64) -> u64 {
    var init: u64 = *(node + 8);
    var cond: u64 = *(node + 16);
    var update: u64 = *(node + 24);
    var body: u64 = *(node + 32);
    
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
    
    var labels_len: u64 = vec_len(g_loop_labels);
    *(g_loop_labels + 8) = labels_len - 1;
    labels_len = vec_len(g_loop_continue_labels);
    *(g_loop_continue_labels + 8) = labels_len - 1;
    
    emit_label_def(update_label);
    
    if (update != 0) { cg_stmt(update); }
    
    emit("    jmp ", 8);
    emit_label(start_label);
    emit_nl();
    
    emit_label_def(end_label);
}

func cg_switch_stmt(node: u64) -> u64 {
    var expr: u64 = *(node + 8);
    var cases: u64 = *(node + 16);
    
    cg_expr(expr);
    emit("    push rax\n", 13);
    
    var end_label: u64 = new_label();
    
    // Push end_label to g_loop_labels so that break works
    var g_loop_labels: u64 = emitter_get_loop_labels();
    vec_push(g_loop_labels, end_label);
    
    var num_cases: u64 = vec_len(cases);
    var i: u64 = 0;
    while (i < num_cases) {
        var case_node: u64 = vec_get(cases, i);
        var is_default: u64 = *(case_node + 24);
        
        if (is_default == 0) {
            var value: u64 = *(case_node + 8);
            var next_label: u64 = new_label();
            
            emit("    mov rax, [rsp]\n", 19);
            emit("    push rax\n", 13);
            cg_expr(value);
            emit("    mov rbx, rax\n", 17);
            emit("    pop rax\n", 12);
            emit("    cmp rax, rbx\n", 17);
            emit("    jne ", 8);
            emit_label(next_label);
            emit_nl();
            
            var body: u64 = *(case_node + 16);
            cg_block(body);
            
            emit("    jmp ", 8);
            emit_label(end_label);
            emit_nl();
            
            emit_label_def(next_label);
        } else {
            var body: u64 = *(case_node + 16);
            cg_block(body);
        }
        
        i = i + 1;
    }
    
    // Pop end_label from g_loop_labels
    var len: u64 = vec_len(g_loop_labels);
    *(g_loop_labels + 8) = len - 1;
    
    emit("    add rsp, 8\n", 15);
    emit_label_def(end_label);
}

func cg_asm_stmt(node: u64) -> u64 {
    var text_vec: u64 = *(node + 8);
    var asm_len: u64 = vec_len(text_vec);
    
    var i: u64 = 0;
    var at_line_start: u64 = 1;
    while (i < asm_len) {
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
        i = i + 1;
    }
    emit_nl();
}

// ============================================
// Helper to get structs (from typeinfo module)
// ============================================

func typeinfo_get_structs() -> u64 {
    // This is a bit of a workaround - in a cleaner design,
    // we'd pass this around or use a proper global accessor
    return 0;  // Will be set by codegen.b
}
