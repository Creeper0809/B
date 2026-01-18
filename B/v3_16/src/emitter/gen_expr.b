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
import compiler;

// ============================================
// Expression Codegen
// ============================================

func emit_tagged_mask() -> u64 {
    emit("    mov rbx, ", 13);
    emit_u64(281474976710655);
    emit_nl();
    emit("    and rax, rbx\n", 17);
}

func emit_mask_to_rdx(bit_width: u64) -> u64 {
    emit("    mov rdx, 1\n", 16);
    emit("    mov rcx, ", 13);
    emit_u64(bit_width);
    emit_nl();
    emit("    shl rdx, cl\n", 16);
    emit("    sub rdx, 1\n", 16);
}

func get_packed_layout_total_bits(struct_def: u64) -> u64 {
    var fields: u64 = *(struct_def + 24);
    var num_fields: u64 = vec_len(fields);
    var total_bits: u64 = 0;
    for (var i: u64 = 0; i < num_fields; i++) {
        var field: *FieldDesc = (*FieldDesc)vec_get(fields, i);
        if (field->bit_width > 0) {
            total_bits = total_bits + field->bit_width;
        } else {
            var fsize: u64 = sizeof_field_desc(field);
            total_bits = total_bits + fsize * 8;
        }
    }
    return total_bits;
}

func get_packed_field_bit_offset(struct_def: u64, field_name_ptr: u64, field_name_len: u64) -> u64 {
    var fields: u64 = *(struct_def + 24);
    var num_fields: u64 = vec_len(fields);
    var bit_cursor: u64 = 0;
    for (var i: u64 = 0; i < num_fields; i++) {
        var field: *FieldDesc = (*FieldDesc)vec_get(fields, i);
        if (str_eq(field->name_ptr, field->name_len, field_name_ptr, field_name_len)) {
            return bit_cursor;
        }
        if (field->bit_width > 0) {
            bit_cursor = bit_cursor + field->bit_width;
        } else {
            var fsize2: u64 = sizeof_field_desc(field);
            bit_cursor = bit_cursor + fsize2 * 8;
        }
    }
    emit("[ERROR] Packed field not found\n", 33);
    panic("Codegen error");
    return 0;
}

func get_packed_field_bit_width(struct_def: u64, field_name_ptr: u64, field_name_len: u64) -> u64 {
    var fields: u64 = *(struct_def + 24);
    var num_fields: u64 = vec_len(fields);
    for (var i: u64 = 0; i < num_fields; i++) {
        var field: *FieldDesc = (*FieldDesc)vec_get(fields, i);
        if (str_eq(field->name_ptr, field->name_len, field_name_ptr, field_name_len)) {
            if (field->bit_width > 0) { return field->bit_width; }
            return sizeof_field_desc(field) * 8;
        }
    }
    emit("[ERROR] Packed field not found\n", 33);
    panic("Codegen error");
    return 0;
}

func cg_index_addr(node: u64, symtab: u64) -> u64 {
    var idx: *AstIndex = (*AstIndex)node;
    var base: u64 = idx->base;
    var index: u64 = idx->index;

    var elem_size: u64 = 1;
    var use_array_addr: u64 = 0;
    var use_slice_ptr: u64 = 0;
    var use_tagged_ptr: u64 = 0;

    var base_type: u64 = get_expr_type_with_symtab(base, symtab);
    if (base_type != 0) {
        var bt: *TypeInfo = (*TypeInfo)base_type;
        if (bt->ptr_depth > 0) {
            elem_size = get_pointee_size(bt->type_kind, bt->ptr_depth);
            if (bt->is_tagged == 1) { use_tagged_ptr = 1; }
        } else if (bt->type_kind == TYPE_ARRAY) {
            elem_size = sizeof_type(bt->elem_type_kind, bt->elem_ptr_depth, bt->struct_name_ptr, bt->struct_name_len);
            use_array_addr = 1;
        } else if (bt->type_kind == TYPE_SLICE) {
            elem_size = sizeof_type(bt->elem_type_kind, bt->elem_ptr_depth, bt->struct_name_ptr, bt->struct_name_len);
            use_slice_ptr = 1;
        }
    }

    if (use_array_addr == 1) {
        cg_lvalue(base);
    } else if (use_slice_ptr == 1) {
        cg_lvalue(base);
        emit("    mov rax, [rax]\n", 19);
    } else {
        cg_expr(base);
        if (use_tagged_ptr == 1) {
            emit_tagged_mask();
        }
    }

    emit("    push rax\n", 13);
    cg_expr(index);
    if (elem_size != 1) {
        emit("    imul rax, ", 14);
        emit_u64(elem_size);
        emit_nl();
    }
    emit("    pop rbx\n", 12);
    emit("    add rax, rbx\n", 17);
    return;
}

func cg_expr(node: u64) -> u64 {
    var kind: u64 = ast_kind(node);
    var symtab: u64 = emitter_get_symtab();
    
    if (kind == AST_LITERAL) {
        var lit: *AstLiteral = (*AstLiteral)node;
        var val: u64 = lit->value;
        emit("    mov rax, ", 13);
        if (val < 0) {
            emit_i64(val);
        } else {
            emit_u64(val);
        }
        emit_nl();
        return;
    }
    
    if (kind == AST_STRING) {
        var str: *AstString = (*AstString)node;
        var str_ptr: u64 = str->str_ptr;
        var str_len: u64 = str->str_len;
        var label_id: u64 = string_get_label(str_ptr, str_len);
        emit("    lea rax, [rel _str", 22);
        emit_u64(label_id);
        emit("]\n", 2);
        return;
    }
    
    if (kind == AST_IDENT) {
        var ident: *AstIdent = (*AstIdent)node;
        var name_ptr: u64 = ident->name_ptr;
        var name_len: u64 = ident->name_len;
        
        var c_result: u64 = const_find(name_ptr, name_len);
        var result: *ConstResult = (*ConstResult)c_result;
        if (result->found == 1) {
            emit("    mov rax, ", 13);
            emit_u64(result->value);
            emit_nl();
            return;
        }
        
        if (is_global_var(name_ptr, name_len)) {
            emit("    mov rax, [rel _gvar_", 24);
            emit(name_ptr, name_len);
            emit("]\n", 2);
            return;
        }
        
        var offset: u64 = symtab_find(symtab, name_ptr, name_len);
        
        var var_type: u64 = symtab_get_type(symtab, name_ptr, name_len);
        if (var_type != 0) {
            var vt: *TypeInfo = (*TypeInfo)var_type;
            if (vt->ptr_depth == 0) {
                if (vt->type_kind == TYPE_ARRAY) {
                    emit("    lea rax, [rbp", 17);
                    if (offset < 0) { emit_i64(offset); }
                    else { emit("+", 1); emit_u64(offset); }
                    emit("]\n", 2);
                    return;
                }
                if (vt->type_kind == TYPE_SLICE) {
                    emit("    mov rax, [rbp", 17);
                    if (offset < 0) { emit_i64(offset); }
                    else { emit("+", 1); emit_u64(offset); }
                    emit("]\n", 2);
                    return;
                }
                if (vt->type_kind == TYPE_U8) {
                    emit("    movzx rax, byte [rbp", 24);
                    if (offset < 0) { emit_i64(offset); }
                    else { emit("+", 1); emit_u64(offset); }
                    emit("]\n", 2);
                    return;
                }
                if (vt->type_kind == TYPE_U16) {
                    emit("    movzx rax, word [rbp", 24);
                    if (offset < 0) { emit_i64(offset); }
                    else { emit("+", 1); emit_u64(offset); }
                    emit("]\n", 2);
                    return;
                }
                if (vt->type_kind == TYPE_U32) {
                    emit("    mov eax, [rbp", 17);
                    if (offset < 0) { emit_i64(offset); }
                    else { emit("+", 1); emit_u64(offset); }
                    emit("]\n", 2);
                    return;
                }
            }
        }
        
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
        var unary: *AstUnary = (*AstUnary)node;
        var op: u64 = unary->op;
        var operand: u64 = unary->operand;
        
        cg_expr(operand);
        if (op == TOKEN_MINUS) { emit("    neg rax\n", 12); }
        else if (op == TOKEN_BANG) {
            emit("    test rax, rax\n", 18);
            emit("    setz al\n", 12);
            emit("    movzx rax, al\n", 18);
        }
        return;
    }
    
    if (kind == AST_ADDR_OF) {
        var addr_of: *AstAddrOf = (*AstAddrOf)node;
        var operand: u64 = addr_of->operand;
        var ident: *AstIdent = (*AstIdent)operand;
        var name_ptr: u64 = ident->name_ptr;
        var name_len: u64 = ident->name_len;
        var offset: u64 = symtab_find(symtab, name_ptr, name_len);
        
        emit("    lea rax, [rbp", 17);
        if (offset < 0) { emit_i64(offset); }
        else { emit("+", 1); emit_u64(offset); }
        emit("]\n", 2);
        return;
    }
    
    if (kind == AST_DEREF) {
        var deref: *AstDeref = (*AstDeref)node;
        var operand: u64 = deref->operand;
        cg_expr(operand);
        
        var op_type: u64 = get_expr_type_with_symtab(operand, symtab);
        var type_info: *TypeInfo = (*TypeInfo)op_type;
        var base_type: u64 = type_info->type_kind;
        var ptr_depth: u64 = type_info->ptr_depth;
        if (ptr_depth > 0 && type_info->is_tagged == 1) {
            emit_tagged_mask();
        }
        
        if (ptr_depth == 1) {
            if (base_type == TYPE_U8) {
                emit("    movzx rax, byte [rax]\n", 26);
                return;
            }
            if (base_type == TYPE_U16) {
                emit("    movzx rax, word [rax]\n", 26);
                return;
            }
            if (base_type == TYPE_U32) {
                emit("    mov eax, [rax]\n", 19);
                return;
            }
        }
        emit("    mov rax, [rax]\n", 19);
        return;
    }
    
    if (kind == AST_DEREF8) {
        var deref8: *AstDeref8 = (*AstDeref8)node;
        var operand: u64 = deref8->operand;
        cg_expr(operand);
        var op_type2: u64 = get_expr_type_with_symtab(operand, symtab);
        if (op_type2 != 0) {
            var ti2: *TypeInfo = (*TypeInfo)op_type2;
            if (ti2->ptr_depth > 0 && ti2->is_tagged == 1) {
                emit_tagged_mask();
            }
        }
        emit("    movzx rax, byte [rax]\n", 26);
        return;
    }

    if (kind == AST_INDEX) {
        cg_index_addr(node, symtab);
        var elem_type: u64 = get_expr_type_with_symtab(node, symtab);
        if (elem_type != 0) {
            var et: *TypeInfo = (*TypeInfo)elem_type;
            if (et->ptr_depth == 0) {
                if (et->type_kind == TYPE_U8) {
                    emit("    movzx rax, byte [rax]\n", 26);
                    return;
                }
                if (et->type_kind == TYPE_U16) {
                    emit("    movzx rax, word [rax]\n", 26);
                    return;
                }
                if (et->type_kind == TYPE_U32) {
                    emit("    mov eax, [rax]\n", 19);
                    return;
                }
            }
        }
        emit("    mov rax, [rax]\n", 19);
        return;
    }

    if (kind == AST_SLICE) {
        emit_stderr("[ERROR] Slice literal cannot be used as rvalue\n", 47);
        panic("Codegen error");
    }
    
    if (kind == AST_CAST) {
        var cast: *AstCast = (*AstCast)node;
        var expr: u64 = cast->expr;
        cg_expr(expr);
        return;
    }
    
    if (kind == AST_SIZEOF) {
        var sizeof_node: *AstSizeof = (*AstSizeof)node;
        var type_kind: u64 = sizeof_node->type_kind;
        var ptr_depth: u64 = sizeof_node->ptr_depth;
        var struct_name_ptr: u64 = sizeof_node->struct_name_ptr;
        var struct_name_len: u64 = sizeof_node->struct_name_len;
        
        // Calculate size at compile time
        var size: u64 = sizeof_type(type_kind, ptr_depth, struct_name_ptr, struct_name_len);
        
        // Emit as literal constant
        emit("    mov rax, ", 13);
        emit_u64(size);
        emit_nl();
        return;
    }
    
    if (kind == AST_CALL) {
        var call: *AstCall = (*AstCall)node;
        var name_ptr: u64 = call->name_ptr;
        var name_len: u64 = call->name_len;
        var args: u64 = call->args_vec;
        var nargs: u64 = vec_len(args);
        var total_arg_bytes: u64 = 0;
        
        var i: u64 = nargs - 1;
        while (i >= 0) {
            var arg: u64 = vec_get(args, i);
            var arg_type: u64 = get_expr_type_with_symtab(arg, symtab);
            if (arg_type != 0) {
                var at: *TypeInfo = (*TypeInfo)arg_type;
                if (at->type_kind == TYPE_SLICE && at->ptr_depth == 0) {
                    var arg_kind: u64 = ast_kind(arg);
                    if (arg_kind == AST_SLICE) {
                        var slice_node: *AstSlice = (*AstSlice)arg;
                        cg_expr(slice_node->len_expr);
                        emit("    push rax\n", 13);
                        cg_expr(slice_node->ptr_expr);
                        emit("    push rax\n", 13);
                    } else {
                        cg_lvalue(arg);
                        emit("    mov rbx, [rax+8]\n", 21);
                        emit("    push rbx\n", 13);
                        emit("    mov rbx, [rax]\n", 19);
                        emit("    push rbx\n", 13);
                    }
                    total_arg_bytes = total_arg_bytes + 16;
                    i = i - 1;
                    continue;
                }
            }
            cg_expr(arg);
            emit("    push rax\n", 13);
            total_arg_bytes = total_arg_bytes + 8;
            i = i - 1;
        }
        
        emit("    call ", 9);
        emit(name_ptr, name_len);
        emit_nl();
        
        if (total_arg_bytes > 0) {
            emit("    add rsp, ", 13);
            emit_u64(total_arg_bytes);
            emit_nl();
        }
        return;
    }
    
    if (kind == AST_METHOD_CALL) {
        cg_method_call(node, symtab);
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
    var member_access: *AstMemberAccess = (*AstMemberAccess)node;
    var object: u64 = member_access->object;
    var member_ptr: u64 = member_access->member_ptr;
    var member_len: u64 = member_access->member_len;
    
    var obj_type: u64 = get_expr_type_with_symtab(object, symtab);
    if (obj_type != 0) {
        var ot: *TypeInfo = (*TypeInfo)obj_type;
        if (ot->ptr_depth > 0 && ot->is_tagged == 1 && ot->tag_layout_ptr != 0) {
            var layout_def: u64 = get_struct_def(ot->tag_layout_ptr, ot->tag_layout_len);
            if (layout_def == 0) {
                emit("[ERROR] Tagged layout struct not found\n", 41);
                panic("Codegen error");
            }
            var packed_flag: u64 = *(layout_def + 32);
            if (packed_flag == 0) {
                emit("[ERROR] Tagged layout must be packed struct\n", 49);
                panic("Codegen error");
            }
            var total_bits: u64 = get_packed_layout_total_bits(layout_def);
            var field_offset: u64 = get_packed_field_bit_offset(layout_def, member_ptr, member_len);
            var field_width: u64 = get_packed_field_bit_width(layout_def, member_ptr, member_len);
            var start_bit: u64 = 64 - total_bits;
            var shift_bits: u64 = start_bit + field_offset;

            cg_expr(object);
            if (shift_bits > 0) {
                emit("    mov rcx, ", 13);
                emit_u64(shift_bits);
                emit_nl();
                emit("    shr rax, cl\n", 16);
            }
            if (field_width < 64) {
                emit_mask_to_rdx(field_width);
                emit("    and rax, rdx\n", 17);
            }
            return;
        }
        if (ot->ptr_depth == 0 && ot->type_kind == TYPE_STRUCT && ot->struct_def != 0) {
            var packed_flag2: u64 = *(ot->struct_def + 32);
            if (packed_flag2 == 1) {
                var total_bits2: u64 = get_packed_layout_total_bits(ot->struct_def);
                var field_offset2: u64 = get_packed_field_bit_offset(ot->struct_def, member_ptr, member_len);
                var field_width2: u64 = get_packed_field_bit_width(ot->struct_def, member_ptr, member_len);
                var shift_bits2: u64 = field_offset2;
                var size_bytes2: u64 = (total_bits2 + 7) / 8;

                cg_lvalue(object);
                if (size_bytes2 == 1) {
                    emit("    movzx rax, byte [rax]\n", 30);
                } else if (size_bytes2 == 2) {
                    emit("    movzx rax, word [rax]\n", 30);
                } else if (size_bytes2 == 4) {
                    emit("    mov eax, [rax]\n", 19);
                } else {
                    emit("    mov rax, [rax]\n", 19);
                }
                if (shift_bits2 > 0) {
                    emit("    mov rcx, ", 13);
                    emit_u64(shift_bits2);
                    emit_nl();
                    emit("    shr rax, cl\n", 16);
                }
                if (field_width2 < 64) {
                    emit_mask_to_rdx(field_width2);
                    emit("    and rax, rdx\n", 17);
                }
                return;
            }
        }
    }

    var obj_kind: u64 = ast_kind(object);
    
    // Handle ptr->field (object is AST_DEREF)
    if (obj_kind == AST_DEREF) {
        var ptr_expr: u64 = *(object + 8);
        
        // Evaluate pointer expression to get pointer value
        cg_expr(ptr_expr);
        
        // Get pointer type to find struct_def
        var ptr_type: u64 = get_expr_type_with_symtab(ptr_expr, symtab);
        if (ptr_type == 0) {
            emit("    ; ERROR: Cannot determine pointer type in arrow operator\n", 64);
            return;
        }
        
        var ti: *TypeInfo = (*TypeInfo)ptr_type;
        var base_type: u64 = ti->type_kind;
        var ptr_depth: u64 = ti->ptr_depth;
        if (ptr_depth > 0 && ti->is_tagged == 1) {
            emit_tagged_mask();
        }
        emit("    push rax\n", 13);
        
        if (ptr_depth == 0 || base_type != TYPE_STRUCT) {
            emit("    ; ERROR: Arrow operator requires pointer to struct\n", 59);
            return;
        }
        
        // Get struct_def from pointer's base type
        var struct_def: u64 = ti->struct_def;
        if (struct_def == 0) {
            emit("    ; ERROR: Struct definition not found for pointer type\n", 64);
            return;
        }
        
        var field_offset: u64 = get_field_offset(struct_def, member_ptr, member_len);
        var field_desc: u64 = get_field_desc(struct_def, member_ptr, member_len);
        
        // Pop pointer value, add field offset
        emit("    pop rax\n", 12);
        if (field_offset > 0) {
            emit("    add rax, ", 13);
            emit_u64(field_offset);
            emit("\n", 1);
        }
        if (field_desc == 0) { return; }
        var fd: *FieldDesc = (*FieldDesc)field_desc;
        if (fd->type_kind == TYPE_ARRAY) { return; }
        if (fd->type_kind == TYPE_SLICE) { emit("    mov rax, [rax]\n", 19); return; }
        if (fd->ptr_depth == 0) {
            if (fd->type_kind == TYPE_U8) { emit("    movzx rax, byte [rax]\n", 26); return; }
            if (fd->type_kind == TYPE_U16) { emit("    movzx rax, word [rax]\n", 26); return; }
            if (fd->type_kind == TYPE_U32) { emit("    mov eax, [rax]\n", 19); return; }
        }
        emit("    mov rax, [rax]\n", 19);
        return;
    }
    
    // Handle nested member access: outer.inner.field
    if (obj_kind == AST_MEMBER_ACCESS) {
        // Recursively get the address of the nested object
        cg_lvalue(object);
        emit("    push rax\n", 13);
        
        // Get the type of the nested object
        var obj_type: u64 = get_expr_type_with_symtab(object, symtab);
        if (obj_type == 0) {
            emit("    ; ERROR: Cannot determine type of nested member access\n", 55);
            return;
        }
        
        var obj_ti: *TypeInfo = (*TypeInfo)obj_type;
        var base_type: u64 = obj_ti->type_kind;
        if (base_type != TYPE_STRUCT) {
            emit("    ; ERROR: Nested member access on non-struct\n", 44);
            return;
        }
        
        var struct_def: u64 = obj_ti->struct_def;
        if (struct_def == 0) {
            emit("    ; ERROR: Struct definition not found for nested access\n", 55);
            return;
        }
        
        var field_offset: u64 = get_field_offset(struct_def, member_ptr, member_len);
        var field_desc: u64 = get_field_desc(struct_def, member_ptr, member_len);
        
        // Pop base address and add field offset
        emit("    pop rax\n", 12);
        if (field_offset > 0) {
            emit("    add rax, ", 13);
            emit_u64(field_offset);
            emit("\n", 1);
        }
        if (field_desc == 0) { return; }
        var fd2: *FieldDesc = (*FieldDesc)field_desc;
        if (fd2->type_kind == TYPE_ARRAY) { return; }
        if (fd2->type_kind == TYPE_SLICE) { emit("    mov rax, [rax]\n", 19); return; }
        if (fd2->ptr_depth == 0) {
            if (fd2->type_kind == TYPE_U8) { emit("    movzx rax, byte [rax]\n", 26); return; }
            if (fd2->type_kind == TYPE_U16) { emit("    movzx rax, word [rax]\n", 26); return; }
            if (fd2->type_kind == TYPE_U32) { emit("    mov eax, [rax]\n", 19); return; }
        }
        emit("    mov rax, [rax]\n", 19);
        return;
    }
    
    // Handle obj.field (object is AST_IDENT)
    if (obj_kind != AST_IDENT) {
        emit("    ; ERROR: Member access on non-identifier\n", 41);
        return;
    }
    
    var obj_name_ptr: u64 = *(object + 8);
    var obj_name_len: u64 = *(object + 16);
    
    // Get variable info from symtab
    var var_offset: u64 = symtab_find(symtab, obj_name_ptr, obj_name_len);
    var var_type: u64 = symtab_get_type(symtab, obj_name_ptr, obj_name_len);
    var var_ti: *TypeInfo = (*TypeInfo)var_type;
    var type_kind: u64 = var_ti->type_kind;
    
    if (type_kind != TYPE_STRUCT) {
        emit("    ; ERROR: Member access on non-struct type\n", 42);
        return;
    }
    
    // Get struct_def directly from type_info
    var struct_def: u64 = var_ti->struct_def;
    
    if (struct_def == 0) {
        emit("    ; ERROR: Struct definition not found in type_info\n", 52);
        return;
    }
    
    var field_offset: u64 = get_field_offset(struct_def, member_ptr, member_len);
    var field_desc: u64 = get_field_desc(struct_def, member_ptr, member_len);
    
    // Calculate address: lea rax, [rbp + var_offset + field_offset]
    emit("    lea rax, [rbp", 17);
    var total_offset: u64 = var_offset + field_offset;
    if (total_offset < 0) { emit_i64(total_offset); }
    else { emit("+", 1); emit_u64(total_offset); }
    emit("]\n", 2);
    
    if (field_desc != 0) {
        var fd3: *FieldDesc = (*FieldDesc)field_desc;
        if (fd3->type_kind == TYPE_ARRAY) { return; }
        if (fd3->type_kind == TYPE_SLICE) { emit("    mov rax, [rax]\n", 19); return; }
        if (fd3->ptr_depth == 0) {
            if (fd3->type_kind == TYPE_U8) { emit("    movzx rax, byte [rax]\n", 26); return; }
            if (fd3->type_kind == TYPE_U16) { emit("    movzx rax, word [rax]\n", 26); return; }
            if (fd3->type_kind == TYPE_U32) { emit("    mov eax, [rax]\n", 19); return; }
        }
    }
    emit("    mov rax, [rax]\n", 19);
}

// ============================================
// Binary Expression
// ============================================

func cg_binary_expr(node: u64, symtab: u64) -> u64 {
    var binary: *AstBinary = (*AstBinary)node;
    var op: u64 = binary->op;
    var left: u64 = binary->left;
    var right: u64 = binary->right;

    // Short-circuit evaluation for && and ||
    if (op == TOKEN_ANDAND) {
        var l_false: u64 = new_label();
        var l_end: u64 = new_label();

        cg_expr(left);
        emit("    test rax, rax\n", 18);
        emit("    jz ", 7);
        emit_label(l_false);
        emit("\n", 1);

        cg_expr(right);
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

    if (op == TOKEN_OROR) {
        var l_true: u64 = new_label();
        var l_end: u64 = new_label();

        cg_expr(left);
        emit("    test rax, rax\n", 18);
        emit("    jnz ", 8);
        emit_label(l_true);
        emit("\n", 1);

        cg_expr(right);
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
    cg_expr(left);
    emit("    push rax\n", 13);
    cg_expr(right);
    emit("    mov rbx, rax\n", 17);
    emit("    pop rax\n", 12);
    
    // Pointer arithmetic scaling
    var left_type: u64 = get_expr_type_with_symtab(left, symtab);
    var left_ti: *TypeInfo = (*TypeInfo)left_type;
    var ptr_depth: u64 = left_ti->ptr_depth;
    
    if (ptr_depth > 0) {
        if (op == TOKEN_PLUS || op == TOKEN_MINUS) {
            var psize: u64 = get_pointee_size(left_ti->type_kind, ptr_depth);
            if (psize > 1) {
                emit("    imul rbx, ", 14);
                emit_u64(psize);
                emit_nl();
            }
        }
    }
    
    // Arithmetic operators
    if (op == TOKEN_PLUS) { emit("    add rax, rbx\n", 17); }
    else if (op == TOKEN_MINUS) { emit("    sub rax, rbx\n", 17); }
    else if (op == TOKEN_STAR) { emit("    imul rax, rbx\n", 18); }
    else if (op == TOKEN_SLASH) {
        emit("    xor rdx, rdx\n", 17);
        emit("    div rbx\n", 12);
    }
    else if (op == TOKEN_PERCENT) {
        emit("    xor rdx, rdx\n", 17);
        emit("    div rbx\n", 12);
        emit("    mov rax, rdx\n", 17);
    }
    // Bitwise operators
    else if (op == TOKEN_CARET) { emit("    xor rax, rbx\n", 17); }
    else if (op == TOKEN_AMPERSAND) { emit("    and rax, rbx\n", 17); }
    else if (op == TOKEN_PIPE) { emit("    or rax, rbx\n", 16); }
    // Shift operators
    else if (op == TOKEN_LSHIFT) { 
        emit("    mov rcx, rbx\n", 17);
        emit("    shl rax, cl\n", 16);
    }
    else if (op == TOKEN_RSHIFT) {
        emit("    mov rcx, rbx\n", 17);
        emit("    shr rax, cl\n", 16);
    }
    // Comparison operators
    else if (op == TOKEN_LT) {
        emit("    cmp rax, rbx\n", 17);
        emit("    setl al\n", 12);
        emit("    movzx rax, al\n", 18);
    }
    else if (op == TOKEN_GT) {
        emit("    cmp rax, rbx\n", 17);
        emit("    setg al\n", 12);
        emit("    movzx rax, al\n", 18);
    }
    else if (op == TOKEN_LTEQ) {
        emit("    cmp rax, rbx\n", 17);
        emit("    setle al\n", 13);
        emit("    movzx rax, al\n", 18);
    }
    else if (op == TOKEN_GTEQ) {
        emit("    cmp rax, rbx\n", 17);
        emit("    setge al\n", 13);
        emit("    movzx rax, al\n", 18);
    }
    else if (op == TOKEN_EQEQ) {
        emit("    cmp rax, rbx\n", 17);
        emit("    sete al\n", 12);
        emit("    movzx rax, al\n", 18);
    }
    else if (op == TOKEN_BANGEQ) {
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
        var ident: *AstIdent = (*AstIdent)node;
        var name_ptr: u64 = ident->name_ptr;
        var name_len: u64 = ident->name_len;
        
        if (is_global_var(name_ptr, name_len)) {
            emit("    lea rax, [rel _gvar_", 24);
            emit(name_ptr, name_len);
            emit("]\n", 2);
            return;
        }
        
        var offset: u64 = symtab_find(symtab, name_ptr, name_len);
        
        emit("    lea rax, [rbp", 17);
        if (offset < 0) { emit_i64(offset); }
        else { emit("+", 1); emit_u64(offset); }
        emit("]\n", 2);
        return;
    }
    
    if (kind == AST_DEREF) {
        var deref: *AstDeref = (*AstDeref)node;
        var operand: u64 = deref->operand;
        cg_expr(operand);
        var op_type: u64 = get_expr_type_with_symtab(operand, symtab);
        if (op_type != 0) {
            var ti: *TypeInfo = (*TypeInfo)op_type;
            if (ti->ptr_depth > 0 && ti->is_tagged == 1) {
                emit_tagged_mask();
            }
        }
        return;
    }
    
    if (kind == AST_DEREF8) {
        var deref8: *AstDeref8 = (*AstDeref8)node;
        var operand: u64 = deref8->operand;
        cg_expr(operand);
        var op_type2: u64 = get_expr_type_with_symtab(operand, symtab);
        if (op_type2 != 0) {
            var ti2: *TypeInfo = (*TypeInfo)op_type2;
            if (ti2->ptr_depth > 0 && ti2->is_tagged == 1) {
                emit_tagged_mask();
            }
        }
        return;
    }

    if (kind == AST_INDEX) {
        cg_index_addr(node, symtab);
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
    var member_access: *AstMemberAccess = (*AstMemberAccess)node;
    var object: u64 = member_access->object;
    var member_ptr: u64 = member_access->member_ptr;
    var member_len: u64 = member_access->member_len;
    
    var obj_kind: u64 = ast_kind(object);
    
    // Handle ptr->field (object is AST_DEREF)
    if (obj_kind == AST_DEREF) {
        var ptr_expr: u64 = *(object + 8);
        
        // Evaluate pointer expression to get pointer value
        cg_expr(ptr_expr);
        
        // Get pointer type to find struct_def
        var ptr_type: u64 = get_expr_type_with_symtab(ptr_expr, symtab);
        if (ptr_type == 0) {
            emit("    ; ERROR: Cannot determine pointer type in arrow operator\n", 64);
            return;
        }
        
        var ti: *TypeInfo = (*TypeInfo)ptr_type;
        var base_type: u64 = ti->type_kind;
        var ptr_depth: u64 = ti->ptr_depth;
        if (ptr_depth > 0 && ti->is_tagged == 1) {
            emit_tagged_mask();
        }
        emit("    push rax\n", 13);
        
        if (ptr_depth == 0 || base_type != TYPE_STRUCT) {
            emit("    ; ERROR: Arrow operator requires pointer to struct\n", 59);
            return;
        }
        
        // Get struct_def from pointer's base type
        var struct_def: u64 = ti->struct_def;
        if (struct_def == 0) {
            emit("    ; ERROR: Struct definition not found for pointer type\n", 64);
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
        cg_lvalue(object);
        emit("    push rax\n", 13);
        
        // Get the type of the nested object
        var obj_type: u64 = get_expr_type_with_symtab(object, symtab);
        if (obj_type == 0) {
            emit("    ; ERROR: Cannot determine type of nested member in lvalue\n", 58);
            return;
        }
        
        var obj_lv_ti: *TypeInfo = (*TypeInfo)obj_type;
        var base_type: u64 = obj_lv_ti->type_kind;
        if (base_type != TYPE_STRUCT) {
            emit("    ; ERROR: Nested member access on non-struct in lvalue\n", 54);
            return;
        }
        
        var struct_def: u64 = obj_lv_ti->struct_def;
        if (struct_def == 0) {
            emit("    ; ERROR: Struct definition not found for nested lvalue\n", 55);
            return;
        }
        
        var field_offset: u64 = get_field_offset(struct_def, member_ptr, member_len);
        
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
        emit("    ; ERROR: Member access on non-identifier in lvalue\n", 51);
        return;
    }
    
    var obj_name_ptr: u64 = *(object + 8);
    var obj_name_len: u64 = *(object + 16);
    
    // Get variable info from symtab
    var var_offset: u64 = symtab_find(symtab, obj_name_ptr, obj_name_len);
    var var_type: u64 = symtab_get_type(symtab, obj_name_ptr, obj_name_len);
    
    // Get struct_def directly from type_info
    var struct_def: u64 = 0;
    if (var_type != 0) {
        var var_lv_ti: *TypeInfo = (*TypeInfo)var_type;
        struct_def = var_lv_ti->struct_def;
    }
    
    if (struct_def == 0) {
        emit("    ; ERROR: Struct definition not found in lvalue\n", 47);
        return;
    }
    
    var field_offset: u64 = get_field_offset(struct_def, member_ptr, member_len);
    
    // Calculate address: lea rax, [rbp + var_offset + field_offset]
    emit("    lea rax, [rbp", 17);
    var total_offset: u64 = var_offset + field_offset;
    if (total_offset < 0) { emit_i64(total_offset); }
    else { emit("+", 1); emit_u64(total_offset); }
    emit("]\n", 2);
}

// ============================================
// Method Call Code Generation
// ============================================

func cg_method_call(node: u64, symtab: u64) -> u64 {
    var method_call: *AstMethodCall = (*AstMethodCall)node;
    var receiver: u64 = method_call->receiver;
    var method_ptr: u64 = method_call->method_ptr;
    var method_len: u64 = method_call->method_len;
    var args: u64 = method_call->args_vec;
    var nargs: u64 = vec_len(args);
    
    // Push user args (in reverse order)
    var i: u64 = nargs - 1;
    while (i >= 0) {
        cg_expr(vec_get(args, i));
        emit("    push rax\n", 13);
        i = i - 1;
    }
    
    // Push receiver address (first arg = self)
    cg_lvalue(receiver, symtab);
    emit("    push rax\n", 13);
    
    // Get receiver type to determine struct name
    var receiver_type: u64 = get_expr_type_with_symtab(receiver, symtab);
    var type_info: *TypeInfo = (*TypeInfo)receiver_type;
    var struct_name_ptr: u64 = type_info->struct_name_ptr;
    var struct_name_len: u64 = type_info->struct_name_len;
    
    // Call StructName_method()
    emit("    call ", 9);
    emit(struct_name_ptr, struct_name_len);
    emit("_", 1);
    emit(method_ptr, method_len);
    emit_nl();
    
    // Clean up stack (receiver + user args)
    var total_args: u64 = nargs + 1;
    if (total_args > 0) {
        emit("    add rsp, ", 13);
        emit_u64(total_args * 8);
        emit_nl();
    }
}
