// codegen.b - Code generator for v3.8

import std.io;
import types;
import std.util;
import std.vec;
import ast;

// ============================================
// Global State
// ============================================

var g_symtab;         // Symbol table for current function
var g_label_counter;  // Label counter for unique labels
var g_consts;         // Global constants table
var g_strings;        // String literals table
var g_loop_labels;    // Stack of loop end labels for break
var g_loop_continue_labels;  // Stack of loop continue labels
var g_globals;        // Global variables list

// ============================================
// Type Helpers
// ============================================

func get_type_size(base_type, ptr_depth) {
    if (ptr_depth > 0) { return 8; }
    if (base_type == TYPE_U8) { return 1; }
    if (base_type == TYPE_U16) { return 2; }
    if (base_type == TYPE_U32) { return 4; }
    if (base_type == TYPE_U64) { return 8; }
    if (base_type == TYPE_I64) { return 8; }
    return 8;
}

func get_pointee_size(base_type, ptr_depth) {
    if (ptr_depth > 1) { return 8; }
    if (ptr_depth == 1) {
        if (base_type == TYPE_U8) { return 1; }
        if (base_type == TYPE_U16) { return 2; }
        if (base_type == TYPE_U32) { return 4; }
        if (base_type == TYPE_U64) { return 8; }
        if (base_type == TYPE_I64) { return 8; }
    }
    return 8;
}

func check_type_compat(from_base, from_depth, to_base, to_depth) {
    if (from_base == to_base) {
        if (from_depth == to_depth) { return 0; }
    }
    if (from_depth > 0) {
        if (to_depth > 0) { return 1; }
    }
    if (from_depth == 0) {
        if (to_depth == 0) {
            var from_size;
            from_size = get_type_size(from_base, 0);
            var to_size;
            to_size = get_type_size(to_base, 0);
            if (from_size == to_size) { return 0; }
            return 1;
        }
    }
    if (from_depth == 0) {
        if (to_depth > 0) { return 1; }
    }
    if (from_depth > 0) {
        if (to_depth == 0) { return 1; }
    }
    return 1;
}

// ============================================
// Symbol Table
// ============================================

func symtab_new() {
    var s = heap_alloc(40);
    *(s) = vec_new(64);
    *(s + 8) = vec_new(64);
    *(s + 16) = vec_new(64);
    *(s + 24) = 0;
    *(s + 32) = 0;
    return s;
}

func symtab_clear(s) {
    *(s + 24) = 0;
    *(s + 32) = 0;
    var names = *(s);
    *(names + 8) = 0;
    var offsets = *(s + 8);
    *(offsets + 8) = 0;
    var types = *(s + 16);
    *(types + 8) = 0;
}

func symtab_add(s, name_ptr, name_len, type_kind, ptr_depth) {
    var names = *(s);
    var offsets = *(s + 8);
    var types = *(s + 16);
    var count = *(s + 24);
    
    var size = 8;
    
    var offset = *(s + 32) - size;
    *(s + 32) = offset;
    
    var name_info = heap_alloc(16);
    *(name_info) = name_ptr;
    *(name_info + 8) = name_len;
    vec_push(names, name_info);
    
    vec_push(offsets, offset);
    
    var type_info = heap_alloc(16);
    *(type_info) = type_kind;
    *(type_info + 8) = ptr_depth;
    vec_push(types, type_info);
    
    *(s + 24) = count + 1;
    
    return offset;
}

func symtab_find(s, name_ptr, name_len) {
    var names = *(s);
    var offsets = *(s + 8);
    var count = *(s + 24);
    
    var i = count - 1;
    while (i >= 0) {
        var name_info = vec_get(names, i);
        var n_ptr = *(name_info);
        var n_len = *(name_info + 8);
        
        if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
            return vec_get(offsets, i);
        }
        i = i - 1;
    }
    
    return 0;
}

func symtab_get_type(s, name_ptr, name_len) {
    var names = *(s);
    var types = *(s + 16);
    var count = *(s + 24);
    
    var i = count - 1;
    while (i >= 0) {
        var name_info = vec_get(names, i);
        var n_ptr = *(name_info);
        var n_len = *(name_info + 8);
        
        if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
            return vec_get(types, i);
        }
        i = i - 1;
    }
    
    return 0;
}

func symtab_update_type(s, name_ptr, name_len, type_kind, ptr_depth) {
    var names = *(s);
    var types = *(s + 16);
    var count = *(s + 24);
    
    var i = count - 1;
    while (i >= 0) {
        var name_info = vec_get(names, i);
        var n_ptr = *(name_info);
        var n_len = *(name_info + 8);
        
        if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
            var type_info = vec_get(types, i);
            *(type_info) = type_kind;
            *(type_info + 8) = ptr_depth;
            return;
        }
        i = i - 1;
    }
}

// ============================================
// Global Variable Check
// ============================================

func is_global_var(name_ptr, name_len) {
    var len = vec_len(g_globals);
    var i = 0;
    while (i < len) {
        var ginfo = vec_get(g_globals, i);
        var g_ptr = *(ginfo);
        var g_len = *(ginfo + 8);
        if (str_eq(g_ptr, g_len, name_ptr, name_len)) {
            return 1;
        }
        i = i + 1;
    }
    return 0;
}

// ============================================
// String Literals Table
// ============================================

func string_table_init() {
    g_strings = vec_new(32);
}

func string_get_label(str_ptr, str_len) {
    var i = 0;
    var count = vec_len(g_strings);
    
    while (i < count) {
        var entry = vec_get(g_strings, i);
        var e_ptr = *(entry);
        var e_len = *(entry + 8);
        
        if (str_eq(e_ptr, e_len, str_ptr, str_len)) {
            return *(entry + 16);
        }
        i = i + 1;
    }
    
    var label_id = g_label_counter;
    g_label_counter = g_label_counter + 1;
    
    var entry = heap_alloc(24);
    *(entry) = str_ptr;
    *(entry + 8) = str_len;
    *(entry + 16) = label_id;
    vec_push(g_strings, entry);
    
    return label_id;
}

func string_emit_data() {
    var count = vec_len(g_strings);
    
    if (count == 0) { return; }
    
    emit("\nsection .data\n", 15);
    
    var i = 0;
    while (i < count) {
        var entry = vec_get(g_strings, i);
        var str_ptr = *(entry);
        var str_len = *(entry + 8);
        var label_id = *(entry + 16);
        
        emit("_str", 4);
        emit_u64(label_id);
        emit(": db ", 5);
        
        var j = 1;
        while (j < str_len - 1) {
            var c = *(*u8)(str_ptr + j);
            
            if (c == 92) {
                j = j + 1;
                if (j < str_len - 1) {
                    var ec = *(*u8)(str_ptr + j);
                    if (ec == 110) { emit("10", 2); }
                    else if (ec == 116) { emit("9", 1); }
                    else if (ec == 48) { emit("0", 1); }
                    else if (ec == 92) { emit("92", 2); }
                    else if (ec == 34) { emit("34", 2); }
                    else { emit_u64(ec); }
                }
            } else {
                emit_u64(c);
            }
            
            j = j + 1;
            if (j < str_len - 1) { emit(",", 1); }
        }
        
        emit(",0\n", 3);
        i = i + 1;
    }
}

func globals_emit_bss() {
    var count = vec_len(g_globals);
    
    if (count == 0) { return; }
    
    emit("\nsection .bss\n", 14);
    
    var i = 0;
    while (i < count) {
        var ginfo = vec_get(g_globals, i);
        var name_ptr = *(ginfo);
        var name_len  = *(ginfo + 8);
        
        emit("_gvar_", 6);
        emit(name_ptr, name_len);
        emit(": resq 1\n", 9);
        
        i = i + 1;
    }
}

// ============================================
// Constants
// ============================================

func const_find(name_ptr, name_len) {
    var len = vec_len(g_consts);
    var i = 0;
    while (i < len) {
        var c = vec_get(g_consts, i);
        var c_ptr = *(c);
        var c_len  = *(c + 8);
        if (str_eq(c_ptr, c_len, name_ptr, name_len)) {
            var result  = heap_alloc(16);
            *(result) = 1;
            *(result + 8) = *(c + 16);
            return result;
        }
        i = i + 1;
    }
    var result = heap_alloc(16);
    *(result) = 0;
    return result;
}

// ============================================
// Labels
// ============================================

func new_label() {
    var l = g_label_counter;
    g_label_counter = g_label_counter + 1;
    return l;
}

func emit_label(n) {
    emit(".L", 2);
    emit_u64(n);
}

func emit_label_def(n) {
    emit_label(n);
    emit(":", 1);
    emit_nl();
}

// ============================================
// Expression Type
// ============================================

func get_expr_type(node) {
    var kind = ast_kind(node);
    
    if (kind == AST_IDENT) {
        var name_ptr = *(node + 8);
        var name_len = *(node + 16);
        var type_info = symtab_get_type(g_symtab, name_ptr, name_len);
        if (type_info == 0) {
            var result = heap_alloc(16);
            *(result) = TYPE_I64;
            *(result + 8) = 0;
            return result;
        }
        return type_info;
    }
    
    if (kind == AST_STRING) {
        var result = heap_alloc(16);
        *(result) = TYPE_U8;
        *(result + 8) = 1;
        return result;
    }
    
    if (kind == AST_CAST) {
        var result = heap_alloc(16);
        *(result) = *(node + 16);
        *(result + 8) = *(node + 24);
        return result;
    }
    
    if (kind == AST_ADDR_OF) {
        var operand  = *(node + 8);
        var op_type = get_expr_type(operand);
        if (op_type != 0) {
            var result = heap_alloc(16);
            *(result) = *(op_type);
            *(result + 8) = *(op_type + 8) + 1;
            return result;
        }
    }
    
    if (kind == AST_DEREF) {
        var operand = *(node + 8);
        var op_type = get_expr_type(operand);
        if (op_type != 0) {
            var depth = *(op_type + 8);
            if (depth > 0) {
                var result = heap_alloc(16);
                *(result) = *(op_type);
                *(result + 8) = depth - 1;
                return result;
            }
        }
    }
    
    if (kind == AST_DEREF8) {
        var result  = heap_alloc(16);
        *(result) = TYPE_U8;
        *(result + 8) = 0;
        return result;
    }
    
    if (kind == AST_BINARY) {
        var op = *(node + 8);

        if (op == TOKEN_ANDAND) {
            var result = heap_alloc(16);
            *(result) = TYPE_I64;
            *(result + 8) = 0;
            return result;
        }

        if (op == TOKEN_OROR) {
            var result = heap_alloc(16);
            *(result) = TYPE_I64;
            *(result + 8) = 0;
            return result;
        }

        if (op == TOKEN_LT) {
            var result = heap_alloc(16);
            *(result) = TYPE_I64;
            *(result + 8) = 0;
            return result;
        }
        if (op == TOKEN_GT) {
            var result = heap_alloc(16);
            *(result) = TYPE_I64;
            *(result + 8) = 0;
            return result;
        }
        if (op == TOKEN_LTEQ) {
            var result = heap_alloc(16);
            *(result) = TYPE_I64;
            *(result + 8) = 0;
            return result;
        }
        if (op == TOKEN_GTEQ) {
            var result  = heap_alloc(16);
            *(result) = TYPE_I64;
            *(result + 8) = 0;
            return result;
        }
        if (op == TOKEN_EQEQ) {
            var result = heap_alloc(16);
            *(result) = TYPE_I64;
            *(result + 8) = 0;
            return result;
        }
        if (op == TOKEN_BANGEQ) {
            var result = heap_alloc(16);
            *(result) = TYPE_I64;
            *(result + 8) = 0;
            return result;
        }

        var left = *(node + 16);
        var right = *(node + 24);
        
        if (op == TOKEN_PLUS) {
            var left_type  = get_expr_type(left);
            if (left_type != 0) {
                var l_depth = *(left_type + 8);
                if (l_depth > 0) {
                    var result = heap_alloc(16);
                    *(result) = *(left_type);
                    *(result + 8) = l_depth;
                    return result;
                }
            }

            var right_type = get_expr_type(right);
            if (right_type != 0) {
                var r_depth = *(right_type + 8);
                if (r_depth > 0) {
                    var result = heap_alloc(16);
                    *(result) = *(right_type);
                    *(result + 8) = r_depth;
                    return result;
                }
            }
        } else if (op == TOKEN_MINUS) {
            var left_type = get_expr_type(left);
            if (left_type != 0) {
                var l_depth = *(left_type + 8);
                if (l_depth > 0) {
                    var result = heap_alloc(16);
                    *(result) = *(left_type);
                    *(result + 8) = l_depth;
                    return result;
                }
            }

            var right_type = get_expr_type(right);
            if (right_type != 0) {
                var r_depth = *(right_type + 8);
                if (r_depth > 0) {
                    var result = heap_alloc(16);
                    *(result) = *(right_type);
                    *(result + 8) = r_depth;
                    return result;
                }
            }
        }
    }
    
    if (kind == AST_LITERAL) {
        var result = heap_alloc(16);
        *(result) = TYPE_I64;
        *(result + 8) = 0;
        return result;
    }
    
    var result = heap_alloc(16);
    *(result) = TYPE_I64;
    *(result + 8) = 0;
    return result;
}

// ============================================
// Expression Codegen
// ============================================

func cg_expr(node) {
    var kind = ast_kind(node);
    
    if (kind == AST_LITERAL) {
        emit("    mov rax, ", 13);
        emit_u64(*(node + 8));
        emit_nl();
        return;
    }
    
    if (kind == AST_STRING) {
        var str_ptr  = *(node + 8);
        var str_len = *(node + 16);
        var label_id = string_get_label(str_ptr, str_len);
        emit("    lea rax, [rel _str", 22);
        emit_u64(label_id);
        emit("]\n", 2);
        return;
    }
    
    if (kind == AST_IDENT) {
        var name_ptr = *(node + 8);
        var name_len = *(node + 16);
        
        var c_result  = const_find(name_ptr, name_len);
        if (*(c_result) == 1) {
            emit("    mov rax, ", 13);
            emit_u64(*(c_result + 8));
            emit_nl();
            return;
        }
        
        if (is_global_var(name_ptr, name_len)) {
            emit("    mov rax, [rel _gvar_", 24);
            emit(name_ptr, name_len);
            emit("]\n", 2);
            return;
        }
        
        var offset = symtab_find(g_symtab, name_ptr, name_len);
        
        emit("    mov rax, [rbp", 17);
        if (offset < 0) { emit_i64(offset); }
        else { emit("+", 1); emit_u64(offset); }
        emit("]\n", 2);
        return;
    }
    
    if (kind == AST_BINARY) {
        var op  = *(node + 8);
        var left = *(node + 16);
        var right = *(node + 24);

        if (op == TOKEN_ANDAND) {
            var l_false  = new_label();
            var l_end = new_label();

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
            var l_true = new_label();
            var l_end = new_label();

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
        
        cg_expr(left);
        emit("    push rax\n", 13);
        cg_expr(right);
        emit("    mov rbx, rax\n", 17);
        emit("    pop rax\n", 12);
        
        var left_type  = get_expr_type(left);
        var ptr_depth = *(left_type + 8);
        
        if (ptr_depth > 0) {
            if (op == TOKEN_PLUS) {
                var psize  = get_pointee_size(*(left_type), ptr_depth);
                if (psize > 1) {
                    emit("    imul rbx, ", 14);
                    emit_u64(psize);
                    emit_nl();
                }
            } else if (op == TOKEN_MINUS) {
                var psize  = get_pointee_size(*(left_type), ptr_depth);
                if (psize > 1) {
                    emit("    imul rbx, ", 14);
                    emit_u64(psize);
                    emit_nl();
                }
            }
        }
        
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
        else if (op == TOKEN_CARET) { emit("    xor rax, rbx\n", 17); }
        else if (op == TOKEN_AMPERSAND) { emit("    and rax, rbx\n", 17); }
        else if (op == TOKEN_PIPE) { emit("    or rax, rbx\n", 16); }
        else if (op == TOKEN_LSHIFT) { 
            emit("    mov rcx, rbx\n", 17);
            emit("    shl rax, cl\n", 16);
        }
        else if (op == TOKEN_RSHIFT) {
            emit("    mov rcx, rbx\n", 17);
            emit("    shr rax, cl\n", 16);
        }
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
        return;
    }
    
    if (kind == AST_UNARY) {
        var op = *(node + 8);
        var operand  = *(node + 16);
        
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
        var operand  = *(node + 8);
        var name_ptr = *(operand + 8);
        var name_len = *(operand + 16);
        var offset = symtab_find(g_symtab, name_ptr, name_len);
        
        emit("    lea rax, [rbp", 17);
        if (offset < 0) { emit_i64(offset); }
        else { emit("+", 1); emit_u64(offset); }
        emit("]\n", 2);
        return;
    }
    
    if (kind == AST_DEREF) {
        var operand = *(node + 8);
        cg_expr(operand);
        
        var op_type = get_expr_type(operand);
        var base_type  = *(op_type);
        var ptr_depth = *(op_type + 8);
        
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
        var operand = *(node + 8);
        cg_expr(operand);
        emit("    movzx rax, byte [rax]\n", 26);
        return;
    }
    
    if (kind == AST_CAST) {
        var expr = *(node + 8);
        cg_expr(expr);
        return;
    }
    
    if (kind == AST_CALL) {
        var name_ptr = *(node + 8);
        var name_len = *(node + 16);
        var args = *(node + 24);
        var nargs  = vec_len(args);
        
        var i = nargs - 1;
        while (i >= 0) {
            cg_expr(vec_get(args, i));
            emit("    push rax\n", 13);
            i = i - 1;
        }
        
        emit("    call ", 9);
        emit(name_ptr, name_len);
        emit_nl();
        
        if (nargs > 0) {
            emit("    add rsp, ", 13);
            emit_u64(nargs * 8);
            emit_nl();
        }
        return;
    }
}

// ============================================
// LValue Codegen
// ============================================

func cg_lvalue(node) {
    var kind = ast_kind(node);
    
    if (kind == AST_IDENT) {
        var name_ptr = *(node + 8);
        var name_len = *(node + 16);
        
        if (is_global_var(name_ptr, name_len)) {
            emit("    lea rax, [rel _gvar_", 24);
            emit(name_ptr, name_len);
            emit("]\n", 2);
            return;
        }
        
        var offset = symtab_find(g_symtab, name_ptr, name_len);
        
        emit("    lea rax, [rbp", 17);
        if (offset < 0) { emit_i64(offset); }
        else { emit("+", 1); emit_u64(offset); }
        emit("]\n", 2);
        return;
    }
    
    if (kind == AST_DEREF) {
        var operand = *(node + 8);
        cg_expr(operand);
        return;
    }
    
    if (kind == AST_DEREF8) {
        var operand = *(node + 8);
        cg_expr(operand);
        return;
    }
}

// ============================================
// Statement Codegen
// ============================================

func cg_block(node) {
    var stmts = *(node + 8);
    var len = vec_len(stmts);
    var i = 0;
    while (i < len) {
        cg_stmt(vec_get(stmts, i));
        i = i + 1;
    }
}

func cg_stmt(node) {
    var kind = ast_kind(node);
    
    if (kind == AST_RETURN) {
        var expr = *(node + 8);
        if (expr != 0) { cg_expr(expr); }
        else { emit("    xor eax, eax\n", 17); }
        emit("    mov rsp, rbp\n", 17);
        emit("    pop rbp\n", 12);
        emit("    ret\n", 8);
        return;
    }
    
    if (kind == AST_VAR_DECL) {
        var name_ptr = *(node + 8);
        var name_len  = *(node + 16);
        var type_kind = *(node + 24);
        var ptr_depth = *(node + 32);
        var init = *(node + 40);
        
        var offset = symtab_add(g_symtab, name_ptr, name_len, type_kind, ptr_depth);
        
        if (init != 0) {
            if (type_kind != 0) {
                var init_type = get_expr_type(init);
                if (init_type != 0) {
                    var it_base = *(init_type);
                    var it_depth  = *(init_type + 8);
                    
                    var compat = check_type_compat(it_base, it_depth, type_kind, ptr_depth);
                    if (compat == 1) {
                        warn("implicit type conversion in initialization", 43);
                    }
                }
            }
            
            cg_expr(init);
            emit("    mov [rbp", 12);
            if (offset < 0) { emit_i64(offset); }
            else { emit("+", 1); emit_u64(offset); }
            emit("], rax\n", 7);
        }
        return;
    }
    
    if (kind == AST_ASSIGN) {
        var target  = *(node + 8);
        var value = *(node + 16);
        
        var target_kind = ast_kind(target);
        if (target_kind == AST_IDENT) {
            var name_ptr = *(target + 8);
            var name_len = *(target + 16);
            
            var target_type = symtab_get_type(g_symtab, name_ptr, name_len);
            var value_type = get_expr_type(value);
            
            if (target_type != 0) {
                if (value_type != 0) {
                    var tt_base = *(target_type);
                    var tt_depth = *(target_type + 8);
                    var vt_base = *(value_type);
                    var vt_depth  = *(value_type + 8);
                    
                    var compat = check_type_compat(vt_base, vt_depth, tt_base, tt_depth);
                    if (compat == 1) {
                        warn("implicit type conversion in assignment", 39);
                    }
                    
                    if (vt_depth > 0) {
                        symtab_update_type(g_symtab, name_ptr, name_len, vt_base, vt_depth);
                    }
                }
            } else {
                if (value_type != 0) {
                    var vt_depth = *(value_type + 8);
                    if (vt_depth > 0) {
                        var vt_base  = *(value_type);
                        symtab_update_type(g_symtab, name_ptr, name_len, vt_base, vt_depth);
                    }
                }
            }
        }
        
        cg_expr(value);
        emit("    push rax\n", 13);
        cg_lvalue(target);
        emit("    pop rbx\n", 12);
        
        if (target_kind == AST_DEREF) {
            var deref_operand = *(target + 8);
            var op_type = get_expr_type(deref_operand);
            var base_type = *(op_type);
            var ptr_depth = *(op_type + 8);
            
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
        
        emit("    mov [rax], rbx\n", 19);
        return;
    }
    
    if (kind == AST_EXPR_STMT) {
        var expr = *(node + 8);
        cg_expr(expr);
        return;
    }
    
    if (kind == AST_IF) {
        var cond = *(node + 8);
        var then_blk  = *(node + 16);
        var else_blk = *(node + 24);
        
        var else_label = new_label();
        var end_label = new_label();
        
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
        return;
    }
    
    if (kind == AST_WHILE) {
        var cond = *(node + 8);
        var body = *(node + 16);
        
        var start_label = new_label();
        var end_label = new_label();
        
        emit_label_def(start_label);
        
        cg_expr(cond);
        emit("    test rax, rax\n", 18);
        emit("    jz ", 7);
        emit_label(end_label);
        emit_nl();
        
        vec_push(g_loop_labels, end_label);
        vec_push(g_loop_continue_labels, start_label);
        
        cg_block(body);
        
        var len = vec_len(g_loop_labels);
        *(g_loop_labels + 8) = len - 1;
        len = vec_len(g_loop_continue_labels);
        *(g_loop_continue_labels + 8) = len - 1;
        
        emit("    jmp ", 8);
        emit_label(start_label);
        emit_nl();
        
        emit_label_def(end_label);
        return;
    }
    
    if (kind == AST_FOR) {
        var init = *(node + 8);
        var cond = *(node + 16);
        var update = *(node + 24);
        var body = *(node + 32);
        
        if (init != 0) { cg_stmt(init); }
        
        var start_label = new_label();
        var update_label = new_label();
        var end_label  = new_label();
        
        emit_label_def(start_label);
        
        if (cond != 0) {
            cg_expr(cond);
            emit("    test rax, rax\n", 18);
            emit("    jz ", 7);
            emit_label(end_label);
            emit_nl();
        }
        
        vec_push(g_loop_labels, end_label);
        vec_push(g_loop_continue_labels, update_label);
        
        cg_block(body);
        
        var labels_len = vec_len(g_loop_labels);
        *(g_loop_labels + 8) = labels_len - 1;
        labels_len = vec_len(g_loop_continue_labels);
        *(g_loop_continue_labels + 8) = labels_len - 1;
        
        emit_label_def(update_label);
        
        if (update != 0) { cg_stmt(update); }
        
        emit("    jmp ", 8);
        emit_label(start_label);
        emit_nl();
        
        emit_label_def(end_label);
        return;
    }
    
    if (kind == AST_SWITCH) {
        var expr = *(node + 8);
        var cases = *(node + 16);
        
        cg_expr(expr);
        emit("    push rax\n", 13);
        
        var end_label;
        end_label = new_label();
        
        var num_cases = vec_len(cases);
        var i = 0;
        while (i < num_cases) {
            var case_node = vec_get(cases, i);
            var is_default = *(case_node + 24);
            
            if (is_default == 0) {
                var value = *(case_node + 8);
                var next_label = new_label();
                
                emit("    mov rax, [rsp]\n", 19);
                emit("    push rax\n", 13);
                cg_expr(value);
                emit("    mov rbx, rax\n", 17);
                emit("    pop rax\n", 12);
                emit("    cmp rax, rbx\n", 17);
                emit("    jne ", 8);
                emit_label(next_label);
                emit_nl();
                
                var body = *(case_node + 16);
                cg_block(body);
                
                emit("    jmp ", 8);
                emit_label(end_label);
                emit_nl();
                
                emit_label_def(next_label);
            } else {
                var body = *(case_node + 16);
                cg_block(body);
            }
            
            i = i + 1;
        }
        
        emit("    add rsp, 8\n", 15);
        emit_label_def(end_label);
        return;
    }
    
    if (kind == AST_BREAK) {
        var len = vec_len(g_loop_labels);
        if (len == 0) {
            emit_stderr("[ERROR] break outside loop\n", 29);
            panic();
        }
        var label = vec_get(g_loop_labels, len - 1);
        emit("    jmp ", 8);
        emit_label(label);
        emit_nl();
        return;
    }

    if (kind == AST_CONTINUE) {
        var len = vec_len(g_loop_continue_labels);
        if (len == 0) {
            emit_stderr("[ERROR] continue outside loop\n", 32);
            panic();
        }
        var label = vec_get(g_loop_continue_labels, len - 1);
        emit("    jmp ", 8);
        emit_label(label);
        emit_nl();
        return;
    }
    
    if (kind == AST_ASM) {
        var text_vec  = *(node + 8);
        var asm_len = vec_len(text_vec);
        
        var i = 0;
        var at_line_start = 1;
        while (i < asm_len) {
            var ch = vec_get(text_vec, i);
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
        return;
    }
    
    if (kind == AST_BLOCK) {
        cg_block(node);
        return;
    }
}

// ============================================
// Function Codegen
// ============================================

func cg_func(node) {
    var name_ptr = *(node + 8);
    var name_len = *(node + 16);
    var params = *(node + 24);
    var body = *(node + 40);
    
    symtab_clear(g_symtab);
    
    emit(name_ptr, name_len);
    emit(":\n", 2);
    
    emit("    push rbp\n", 13);
    emit("    mov rbp, rsp\n", 17);
    emit("    sub rsp, 1024\n", 18);
    
    var nparams = vec_len(params);
    var i = 0;
    while (i < nparams) {
        var param = vec_get(params, i);
        var pname = *(param);
        var plen = *(param + 8);
        var ptype = *(param + 16);
        var pdepth  = *(param + 24);
        
        var names  = *(g_symtab);
        var offsets = *(g_symtab + 8);
        var types = *(g_symtab + 16);
        
        var name_info = heap_alloc(16);
        *(name_info) = pname;
        *(name_info + 8) = plen;
        vec_push(names, name_info);
        
        vec_push(offsets, 16 + i * 8);
        
        var type_info = heap_alloc(16);
        *(type_info) = ptype;
        *(type_info + 8) = pdepth;
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

func cg_program(prog) {
    var funcs = *(prog + 8);
    var consts = *(prog + 16);
    var globals  = *(prog + 32);
    
    g_symtab = symtab_new();
    g_label_counter = 0;
    string_table_init();
    g_loop_labels = vec_new(16);
    g_loop_continue_labels = vec_new(16);
    
    if (globals == 0) {
        g_globals = vec_new(32);
    } else {
        g_globals = globals;
    }
    
    g_consts = vec_new(64);
    var clen  = vec_len(consts);
    var ci = 0;
    while (ci < clen) {
        var c = vec_get(consts, ci);
        var cinfo = heap_alloc(24);
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
    
    var len = vec_len(funcs);
    var i = 0;
    while (i < len) {
        cg_func(vec_get(funcs, i));
        i = i + 1;
    }
    
    string_emit_data();
    globals_emit_bss();
}
