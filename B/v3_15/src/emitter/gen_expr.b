// gen_expr.b - Expression code generation
//
// Generates x86-64 assembly for expressions:
// - cg_expr: evaluate expression, result in RAX
// - cg_lvalue: compute address of lvalue, result in RAX

import std.io;
import std.vec;
import std.util;
import types;
import ast;

// ============================================
// Expression Codegen
// ============================================

func cg_expr(node: u64) -> u64 {
    var kind: u64 = ast_kind(node);
    var symtab: u64 = emitter_get_symtab();
    
    if (kind == AST_LITERAL) {
        var n: *AstLiteral = (*AstLiteral)node;
        emit("    mov rax, ", 13);
        if (n->val < 0) {
            emit_i64(n->val);
        } else {
            emit_u64(n->val);
        }
        emit_nl();
        return;
    }
    
    if (kind == AST_STRING) {
        var n: *AstString = (*AstString)node;
        var label_id: u64 = string_get_label(n->ptr, n->len);
        emit("    lea rax, [rel _str", 22);
        emit_u64(label_id);
        emit("]\n", 2);
        return;
    }
    
    if (kind == AST_IDENT) {
        var n: *AstIdent = (*AstIdent)node;
        
        var c_result: *ConstLookupResult = (*ConstLookupResult)const_find(n->name_ptr, n->name_len);
        if (c_result->found == 1) {
            emit("    mov rax, ", 13);
            emit_u64(c_result->value);
            emit_nl();
            return;
        }
        
        if (is_global_var(n->name_ptr, n->name_len)) {
            emit("    mov rax, [rel _gvar_", 24);
            emit(n->name_ptr, n->name_len);
            emit("]\n", 2);
            return;
        }
        
        var offset: u64 = symtab_find(symtab, n->name_ptr, n->name_len);
        
        emit("    mov rax, [rbp", 17);
        if (offset < 0) { emit_i64(offset); }
        else { emit("+", 1); emit_u64(offset); }
        emit("]\n", 2);
        return;
    }
    
    if (kind == AST_MEMBER_ACCESS) {
        cg_member_access_expr(node, symtab);
        return;
    }
    
    if (kind == AST_BINARY) {
        cg_binary_expr(node, symtab);
        return;
    }
    
    if (kind == AST_UNARY) {
        var n: *AstUnary = (*AstUnary)node;
        
        cg_expr(n->operand);
        if (n->op == TOKEN_MINUS) { emit("    neg rax\n", 12); }
        else if (n->op == TOKEN_BANG) {
            emit("    test rax, rax\n", 18);
            emit("    setz al\n", 12);
            emit("    movzx rax, al\n", 18);
        }
        return;
    }
    
    if (kind == AST_ADDR_OF) {
        var n: *AstAddrOf = (*AstAddrOf)node;
        var operand_ident: *AstIdent = (*AstIdent)n->operand;
        var offset: u64 = symtab_find(symtab, operand_ident->name_ptr, operand_ident->name_len);
        
        emit("    lea rax, [rbp", 17);
        if (offset < 0) { emit_i64(offset); }
        else { emit("+", 1); emit_u64(offset); }
        emit("]\n", 2);
        return;
    }
    
    if (kind == AST_DEREF) {
        var n: *AstDeref = (*AstDeref)node;
        cg_expr(n->operand);
        
        var op_type: *TypeInfo = (*TypeInfo)get_expr_type_with_symtab(n->operand, symtab);
        
        if (op_type->ptr_depth == 1) {
            if (op_type->type_kind == TYPE_U8) {
                emit("    movzx rax, byte [rax]\n", 26);
                return;
            }
            if (op_type->type_kind == TYPE_U16) {
                emit("    movzx rax, word [rax]\n", 26);
                return;
            }
            if (op_type->type_kind == TYPE_U32) {
                emit("    mov eax, [rax]\n", 19);
                return;
            }
        }
        emit("    mov rax, [rax]\n", 19);
        return;
    }
    
    if (kind == AST_DEREF8) {
        var n: *AstDeref8 = (*AstDeref8)node;
        cg_expr(n->operand);
        emit("    movzx rax, byte [rax]\n", 26);
        return;
    }
    
    if (kind == AST_CAST) {
        var n: *AstCast = (*AstCast)node;
        cg_expr(n->expr);
        return;
    }
    
    if (kind == AST_CALL) {
        var n: *AstCall = (*AstCall)node;
        var nargs: u64 = vec_len(n->args);
        
        var i: u64 = nargs - 1;
        while (i >= 0) {
            cg_expr(vec_get(n->args, i));
            emit("    push rax\n", 13);
            i = i - 1;
        }
        
        emit("    call ", 9);
        emit(n->name_ptr, n->name_len);
        emit_nl();
        
        if (nargs > 0) {
            emit("    add rsp, ", 13);
            emit_u64(nargs * 8);
            emit_nl();
        }
        return;
    }
    
    if (kind == AST_STRUCT_LITERAL) {
        // Struct literals should only appear in var initializers (handled in cg_stmt)
        emit("    xor eax, eax\n", 17);
        return;
    }
}

// ============================================
// Member Access Expression
// ============================================

func cg_member_access_expr(node: u64, symtab: u64) -> u64 {
    var n: *AstMemberAccess = (*AstMemberAccess)node;
    
    var obj_kind: u64 = ast_kind(n->object);
    
    // Handle ptr->field (object is AST_DEREF)
    if (obj_kind == AST_DEREF) {
        var obj_deref: *AstDeref = (*AstDeref)n->object;
        
        // Evaluate pointer expression to get pointer value
        cg_expr(ptr_expr);
        emit("    push rax\n", 13);
        
        // Get pointer type to find struct_def
        var ptr_type: u64 = get_expr_type_with_symtab(ptr_expr, symtab);
        if (ptr_type == 0) {
            emit_stderr("[ERROR] Cannot determine pointer type in arrow operator\n", 57);
            return;
        }
        
        var base_type: u64 = *(ptr_type);
        var ptr_depth: u64 = *(ptr_type + 8);
        
        if (ptr_depth == 0 || base_type != TYPE_STRUCT) {
            emit_stderr("[ERROR] Arrow operator requires pointer to struct\n", 51);
            return;
        }
        
        // Get struct_def from pointer's base type
        var struct_def: u64 = *(ptr_type + 16);
        if (struct_def == 0) {
            emit_stderr("[ERROR] Struct definition not found for pointer type\n", 54);
            return;
        }
        
        var field_offset: u64 = get_field_offset(struct_def, member_ptr, member_len);
        
        // Pop pointer value, add field offset, and load value
        emit("    pop rax\n", 12);
        if (field_offset > 0) {
            emit("    add rax, ", 13);
            emit_u64(field_offset);
            emit("\n", 1);
        }
        emit("    mov rax, [rax]\n", 19);
        return;
    }
    
    // Handle nested member access: outer.inner.field
    if (obj_kind == AST_MEMBER_ACCESS) {
        // Recursively get the address of the nested object
        cg_lvalue(n->object);
        emit("    push rax\n", 13);
        
        // Get the type of the nested object
        var obj_type: *TypeInfo = (*TypeInfo)get_expr_type_with_symtab(n->object, symtab);
        if (obj_type == 0) {
            emit_stderr("[ERROR] Cannot determine type of nested member access\n", 55);
            return;
        }
        
        if (obj_type->type_kind != TYPE_STRUCT) {
            emit_stderr("[ERROR] Nested member access on non-struct\n", 44);
            return;
        }
        
        if (obj_type->struct_def == 0) {
            emit_stderr("[ERROR] Struct definition not found for nested access\n", 55);
            return;
        }
        
        var field_offset: u64 = get_field_offset(obj_type->struct_def, n->member_ptr, n->member_len);
        
        // Pop base address and add field offset
        emit("    pop rax\n", 12);
        if (field_offset > 0) {
            emit("    add rax, ", 13);
            emit_u64(field_offset);
            emit("\n", 1);
        }
        emit("    mov rax, [rax]\n", 19);
        return;
    }
    
    // Handle obj.field (object is AST_IDENT)
    if (obj_kind != AST_IDENT) {
        emit_stderr("[ERROR] Member access on non-identifier\n", 41);
        return;
    }
    
    var obj_ident: *AstIdent = (*AstIdent)n->object;
    
    // Get variable info from symtab
    var var_offset: u64 = symtab_find(symtab, obj_ident->name_ptr, obj_ident->name_len);
    var var_type: *TypeInfo = (*TypeInfo)symtab_get_type(symtab, obj_ident->name_ptr, obj_ident->name_len);
    
    if (var_type->type_kind != TYPE_STRUCT) {
        emit_stderr("[ERROR] Member access on non-struct type\n", 42);
        return;
    }
    
    // Get struct_def directly from type_info
    if (var_type->struct_def == 0) {
        emit_stderr("[ERROR] Struct definition not found in type_info\n", 52);
        return;
    }
    
    var field_offset: u64 = get_field_offset(var_type->struct_def, n->member_ptr, n->member_len);
    
    // Calculate address: lea rax, [rbp + var_offset + field_offset]
    emit("    lea rax, [rbp", 17);
    var total_offset: u64 = var_offset + field_offset;
    if (total_offset < 0) { emit_i64(total_offset); }
    else { emit("+", 1); emit_u64(total_offset); }
    emit("]\n", 2);
    
    // Load value from address
    emit("    mov rax, [rax]\n", 19);
}

// ============================================
// Binary Expression
// ============================================

func cg_binary_expr(node: u64, symtab: u64) -> u64 {
    var n: *AstBinary = (*AstBinary)node;

    // Short-circuit evaluation for && and ||
    if (n->op == TOKEN_ANDAND) {
        var l_false: u64 = new_label();
        var l_end: u64 = new_label();

        cg_expr(n->left);
        emit("    test rax, rax\n", 18);
        emit("    jz ", 7);
        emit_label(l_false);
        emit("\n", 1);

        cg_expr(n->right);
        emit("    test rax, rax\n", 18);
        emit("    setne al\n", 13);
        emit("    movzx rax, al\n", 18);
        emit("    jmp ", 8);
        emit_label(l_end);
        emit("\n", 1);

        emit_label_def(l_false);
        emit("    xor eax, eax\n", 17);
        emit_label_def(l_end);
        return;
    }

    if (n->op == TOKEN_OROR) {
        var l_true: u64 = new_label();
        var l_end: u64 = new_label();

        cg_expr(n->left);
        emit("    test rax, rax\n", 18);
        emit("    jnz ", 8);
        emit_label(l_true);
        emit("\n", 1);

        cg_expr(n->right);
        emit("    test rax, rax\n", 18);
        emit("    setne al\n", 13);
        emit("    movzx rax, al\n", 18);
        emit("    jmp ", 8);
        emit_label(l_end);
        emit("\n", 1);

        emit_label_def(l_true);
        emit("    mov eax, 1\n", 15);
        emit_label_def(l_end);
        return;
    }
    
    // Standard binary: evaluate both sides
    cg_expr(n->left);
    emit("    push rax\n", 13);
    cg_expr(n->right);
    emit("    mov rbx, rax\n", 17);
    emit("    pop rax\n", 12);
    
    // Pointer arithmetic scaling
    var left_type: *TypeInfo = (*TypeInfo)get_expr_type_with_symtab(n->left, symtab);
    
    if (left_type->ptr_depth > 0) {
        if (n->op == TOKEN_PLUS || n->op == TOKEN_MINUS) {
            var psize: u64 = get_pointee_size(left_type->type_kind, left_type->ptr_depth);
            if (psize > 1) {
                emit("    imul rbx, ", 14);
                emit_u64(psize);
                emit_nl();
            }
        }
    }
    
    // Arithmetic operators
    if (n->op == TOKEN_PLUS) { emit("    add rax, rbx\n", 17); }
    else if (n->op == TOKEN_MINUS) { emit("    sub rax, rbx\n", 17); }
    else if (n->op == TOKEN_STAR) { emit("    imul rax, rbx\n", 18); }
    else if (n->op == TOKEN_SLASH) {
        emit("    xor rdx, rdx\n", 17);
        emit("    div rbx\n", 12);
    }
    else if (n->op == TOKEN_PERCENT) {
        emit("    xor rdx, rdx\n", 17);
        emit("    div rbx\n", 12);
        emit("    mov rax, rdx\n", 17);
    }
    // Bitwise operators
    else if (n->op == TOKEN_CARET) { emit("    xor rax, rbx\n", 17); }
    else if (n->op == TOKEN_AMPERSAND) { emit("    and rax, rbx\n", 17); }
    else if (n->op == TOKEN_PIPE) { emit("    or rax, rbx\n", 16); }
    // Shift operators
    else if (n->op == TOKEN_LSHIFT) { 
        emit("    mov rcx, rbx\n", 17);
        emit("    shl rax, cl\n", 16);
    }
    else if (n->op == TOKEN_RSHIFT) {
        emit("    mov rcx, rbx\n", 17);
        emit("    shr rax, cl\n", 16);
    }
    // Comparison operators
    else if (n->op == TOKEN_LT) {
        emit("    cmp rax, rbx\n", 17);
        emit("    setl al\n", 12);
        emit("    movzx rax, al\n", 18);
    }
    else if (n->op == TOKEN_GT) {
        emit("    cmp rax, rbx\n", 17);
        emit("    setg al\n", 12);
        emit("    movzx rax, al\n", 18);
    }
    else if (n->op == TOKEN_LTEQ) {
        emit("    cmp rax, rbx\n", 17);
        emit("    setle al\n", 13);
        emit("    movzx rax, al\n", 18);
    }
    else if (n->op == TOKEN_GTEQ) {
        emit("    cmp rax, rbx\n", 17);
        emit("    setge al\n", 13);
        emit("    movzx rax, al\n", 18);
    }
    else if (n->op == TOKEN_EQEQ) {
        emit("    cmp rax, rbx\n", 17);
        emit("    sete al\n", 12);
        emit("    movzx rax, al\n", 18);
    }
    else if (n->op == TOKEN_BANGEQ) {
        emit("    cmp rax, rbx\n", 17);
        emit("    setne al\n", 13);
        emit("    movzx rax, al\n", 18);
    }
}

// ============================================
// LValue Codegen
// ============================================

func cg_lvalue(node: u64) -> u64 {
    var kind: u64 = ast_kind(node);
    var symtab: u64 = emitter_get_symtab();
    
    if (kind == AST_IDENT) {
        var n: *AstIdent = (*AstIdent)node;
        
        if (is_global_var(n->name_ptr, n->name_len)) {
            emit("    lea rax, [rel _gvar_", 24);
            emit(n->name_ptr, n->name_len);
            emit("]\n", 2);
            return;
        }
        
        var offset: u64 = symtab_find(symtab, n->name_ptr, n->name_len);
        
        emit("    lea rax, [rbp", 17);
        if (offset < 0) { emit_i64(offset); }
        else { emit("+", 1); emit_u64(offset); }
        emit("]\n", 2);
        return;
    }
    
    if (kind == AST_DEREF) {
        var n: *AstDeref = (*AstDeref)node;
        cg_expr(n->operand);
        return;
    }
    
    if (kind == AST_DEREF8) {
        var n: *AstDeref8 = (*AstDeref8)node;
        cg_expr(n->operand);
        return;
    }
    
    if (kind == AST_MEMBER_ACCESS) {
        cg_member_access_lvalue(node, symtab);
        return;
    }
}

// ============================================
// Member Access LValue
// ============================================

func cg_member_access_lvalue(node: u64, symtab: u64) -> u64 {
    var n: *AstMemberAccess = (*AstMemberAccess)node;
    
    var obj_kind: u64 = ast_kind(n->object);
    
    // Handle ptr->field (object is AST_DEREF)
    if (obj_kind == AST_DEREF) {
        var obj_deref: *AstDeref = (*AstDeref)n->object;
        
        // Evaluate pointer expression to get pointer value
        cg_expr(ptr_expr);
        emit("    push rax\n", 13);
        
        // Get pointer type to find struct_def
        var ptr_type: u64 = get_expr_type_with_symtab(ptr_expr, symtab);
        if (ptr_type == 0) {
            emit_stderr("[ERROR] Cannot determine pointer type in arrow operator\n", 57);
            return;
        }
        
        var base_type: u64 = *(ptr_type);
        var ptr_depth: u64 = *(ptr_type + 8);
        
        if (ptr_depth == 0 || base_type != TYPE_STRUCT) {
            emit_stderr("[ERROR] Arrow operator requires pointer to struct\n", 51);
            return;
        }
        
        // Get struct_def from pointer's base type
        var struct_def: u64 = *(ptr_type + 16);
        if (struct_def == 0) {
            emit_stderr("[ERROR] Struct definition not found for pointer type\n", 54);
            return;
        }
        
        var field_offset: u64 = get_field_offset(struct_def, member_ptr, member_len);
        
        // Pop pointer value and add field offset
        emit("    pop rax\n", 12);
        if (field_offset > 0) {
            emit("    add rax, ", 13);
            emit_u64(field_offset);
            emit("\n", 1);
        }
        return;
    }
    
    // Handle nested member access: outer.inner.field (lvalue)
    if (obj_kind == AST_MEMBER_ACCESS) {
        // Recursively get the address of the nested object
        cg_lvalue(n->object);
        emit("    push rax\n", 13);
        
        // Get the type of the nested object
        var obj_type: *TypeInfo = (*TypeInfo)get_expr_type_with_symtab(n->object, symtab);
        if (obj_type == 0) {
            emit_stderr("[ERROR] Cannot determine type of nested member in lvalue\n", 58);
            return;
        }
        
        if (obj_type->type_kind != TYPE_STRUCT) {
            emit_stderr("[ERROR] Nested member access on non-struct in lvalue\n", 54);
            return;
        }
        
        if (obj_type->struct_def == 0) {
            emit_stderr("[ERROR] Struct definition not found for nested lvalue\n", 55);
            return;
        }
        
        var field_offset: u64 = get_field_offset(obj_type->struct_def, n->member_ptr, n->member_len);
        
        // Pop base address and add field offset
        emit("    pop rax\n", 12);
        if (field_offset > 0) {
            emit("    add rax, ", 13);
            emit_u64(field_offset);
            emit("\n", 1);
        }
        return;
    }
    
    // Handle obj.field (object is AST_IDENT)
    if (obj_kind != AST_IDENT) {
        emit_stderr("[ERROR] Member access on non-identifier in lvalue\n", 51);
        return;
    }
    
    var obj_ident: *AstIdent = (*AstIdent)n->object;
    
    // Get variable info from symtab
    var var_offset: u64 = symtab_find(symtab, obj_ident->name_ptr, obj_ident->name_len);
    var var_type: *TypeInfo = (*TypeInfo)symtab_get_type(symtab, obj_ident->name_ptr, obj_ident->name_len);
    
    // Get struct_def directly from type_info
    var struct_def: u64 = 0;
    if (var_type != 0) {
        struct_def = var_type->struct_def;
    }
    
    if (struct_def == 0) {
        emit_stderr("[ERROR] Struct definition not found in lvalue\n", 47);
        return;
    }
    
    var field_offset: u64 = get_field_offset(struct_def, n->member_ptr, n->member_len);
    
    // Calculate address: lea rax, [rbp + var_offset + field_offset]
    emit("    lea rax, [rbp", 17);
    var total_offset: u64 = var_offset + field_offset;
    if (total_offset < 0) { emit_i64(total_offset); }
    else { emit("+", 1); emit_u64(total_offset); }
    emit("]\n", 2);
}
