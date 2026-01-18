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
        var expr_stmt: *AstExprStmt = (*AstExprStmt)node;
        var expr: u64 = expr_stmt->expr;
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
            emit("    ; ERROR: break outside loop\n", 29);
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
            emit("    ; ERROR: continue outside loop\n", 32);
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
            
            // For simplicity, support up to 16 bytes (rax + rdx)
            if (struct_size > 16) {
                emit("    ; ERROR: Struct return size > 16 bytes not supported\n", 53);
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
    var decl: *AstVarDecl = (*AstVarDecl)node;
    var name_ptr: u64 = decl->name_ptr;
    var name_len: u64 = decl->name_len;
    var type_kind: u64 = decl->type_kind;
    var ptr_depth: u64 = decl->ptr_depth;
    var init: u64 = decl->init_expr;
    var struct_name_ptr: u64 = decl->struct_name_ptr;
    var struct_name_len: u64 = decl->struct_name_len;
    
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
                var it_info: *TypeInfo = (*TypeInfo)init_type;
                var it_base: u64 = it_info->type_kind;
                var it_depth: u64 = it_info->ptr_depth;
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
    var assign: *AstAssign = (*AstAssign)node;
    var target: u64 = assign->target;
    var value: u64 = assign->value;
    
    var target_kind: u64 = ast_kind(target);
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
    
    cg_expr(value);
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
    
    var len: u64 = vec_len(g_loop_labels);
    *(g_loop_labels + 8) = len - 1;  // Set length
    len = vec_len(g_loop_continue_labels);
    *(g_loop_continue_labels + 8) = len - 1;  // Set length
    
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
    var i: u64 = 0;
    while (i < num_cases) {
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
        
        i = i + 1;
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
    var len: u64 = vec_len(g_loop_labels);
    *(g_loop_labels + 8) = len - 1;
    
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
    var i: u64 = 0;
    while (i < num_cases) {
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
                // Push in reverse order (stack grows down)
                
                // Get case string and its length first
                cg_expr(value);
                emitln("    push rax");
                emitln("    call str_len");
                emitln("    mov rbx, rax    ; len2");
                emitln("    pop rax    ; s2");
                emitln("    push rbx    ; len2");
                emitln("    push rax    ; s2");
                
                // Get switch value and its length
                emitln("    mov rax, [rsp+16]    ; reload switch value");
                emitln("    push rax");
                emitln("    call str_len");
                emitln("    mov rbx, rax    ; len1");
                emitln("    pop rax    ; s1");
                emitln("    push rbx    ; len1");
                emitln("    push rax    ; s1");
                
                // Call str_eq(s1, len1, s2, len2)
                emitln("    call str_eq");
                emitln("    add rsp, 32");
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
        
        i = i + 1;
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
    i = 0;
    while (i < num_cases) {
        var case_node: u64 = vec_get(cases, i);
        var case_stmt: *AstCase = (*AstCase)case_node;
        var body: u64 = case_stmt->body;
        var case_label: u64 = vec_get(case_labels, i);
        
        emit_label_def(case_label);
        cg_block(body);
        
        i = i + 1;
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
    var j: u64 = 0;
    while (j < (u64)range) {
        vec_push(value_to_label, end_label);
        j = j + 1;
    }
    
    // First pass: create labels and build value->label mapping
    var i: u64 = 0;
    while (i < num_cases) {
        var case_node: u64 = vec_get(cases, i);
        var case_stmt: *AstCase = (*AstCase)case_node;
        var case_label: u64 = new_label();
        vec_push(case_labels, case_label);
        
        if (case_stmt->is_default == 1) {
            default_label = case_label;
            // Update all unassigned entries to point to default
            j = 0;
            while (j < (u64)range) {
                if (vec_get(value_to_label, j) == end_label) {
                    vec_set(value_to_label, j, default_label);
                }
                j = j + 1;
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
        
        i = i + 1;
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
    j = 0;
    while (j < (u64)range) {
        emit("    dq ", 7);
        emit_label(vec_get(value_to_label, j));
        emit_nl();
        j = j + 1;
    }
    emit_nl();
    
    // Second pass: generate case bodies
    i = 0;
    while (i < num_cases) {
        var case_node: u64 = vec_get(cases, i);
        var case_stmt: *AstCase = (*AstCase)case_node;
        var body: u64 = case_stmt->body;
        var case_label: u64 = vec_get(case_labels, i);
        
        emit_label_def(case_label);
        cg_block(body);
        
        i = i + 1;
    }
}

func cg_asm_stmt(node: u64) -> u64 {
    var asm_stmt: *AstAsm = (*AstAsm)node;
    var text_vec: u64 = asm_stmt->text_vec;
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
