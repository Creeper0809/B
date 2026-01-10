// v3.6 Compiler - Part 5: Code Generator
// Generates x86-64 NASM assembly

// ============================================
// Symbol Table
// Structure: [names_vec, offsets_vec, types_vec, count, stack_offset]
// ============================================

var g_symtab;
var g_label_counter;
var g_consts;  // Global constants table: Vec of [name_ptr, name_len, value]

func symtab_new() {
    var s;
    s = heap_alloc(40);
    ptr64[s] = vec_new(64);       // names (ptr to name structs)
    ptr64[s + 8] = vec_new(64);   // stack offsets
    ptr64[s + 16] = vec_new(64);  // types
    ptr64[s + 24] = 0;            // count
    ptr64[s + 32] = 0;            // current stack offset
    return s;
}

func symtab_clear(s) {
    // Reset count and stack offset
    ptr64[s + 24] = 0;
    ptr64[s + 32] = 0;
    
    // Reset Vec lengths to 0 (crucial for correct indexing)
    var names;
    names = ptr64[s];
    ptr64[names + 8] = 0;  // names.len = 0
    
    var offsets;
    offsets = ptr64[s + 8];
    ptr64[offsets + 8] = 0;  // offsets.len = 0
    
    var types;
    types = ptr64[s + 16];
    ptr64[types + 8] = 0;  // types.len = 0
}

// Add symbol, returns stack offset
func symtab_add(s, name_ptr, name_len, type_kind, ptr_depth) {
    var names;
    names = ptr64[s];
    var offsets;
    offsets = ptr64[s + 8];
    var types;
    types = ptr64[s + 16];
    var count;
    count = ptr64[s + 24];
    
    // Calculate size based on type
    var size;
    size = 8;  // Default to 8 bytes
    if (ptr_depth > 0) {
        size = 8;  // Pointers are 8 bytes
    } else if (type_kind == TYPE_U8) {
        size = 8;  // Still allocate 8 for alignment
    }
    
    // Update stack offset (grows downward)
    var offset;
    offset = ptr64[s + 32] - size;
    ptr64[s + 32] = offset;
    
    // Store name info
    var name_info;
    name_info = heap_alloc(16);
    ptr64[name_info] = name_ptr;
    ptr64[name_info + 8] = name_len;
    vec_push(names, name_info);
    
    // Store offset and type
    vec_push(offsets, offset);
    
    var type_info;
    type_info = heap_alloc(16);
    ptr64[type_info] = type_kind;
    ptr64[type_info + 8] = ptr_depth;
    vec_push(types, type_info);
    
    ptr64[s + 24] = count + 1;
    
    return offset;
}

// Update type of existing symbol (used during assignment)
func symtab_update_type(s, name_ptr, name_len, type_kind, ptr_depth) {
    var names;
    names = ptr64[s];
    var types;
    types = ptr64[s + 16];
    var count;
    count = ptr64[s + 24];
    
    var i;
    i = 0;
    while (i < count) {
        var name_info;
        name_info = vec_get(names, i);
        var n_ptr;
        n_ptr = ptr64[name_info];
        var n_len;
        n_len = ptr64[name_info + 8];
        
        if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
            var type_info;
            type_info = vec_get(types, i);
            ptr64[type_info] = type_kind;
            ptr64[type_info + 8] = ptr_depth;
            return;
        }
        i = i + 1;
    }
}

// Find symbol, returns stack offset or 0 if not found
func symtab_find(s, name_ptr, name_len) {
    var names;
    names = ptr64[s];
    var offsets;
    offsets = ptr64[s + 8];
    var count;
    count = ptr64[s + 24];
    
    var i;
    i = 0;
    while (i < count) {
        var name_info;
        name_info = vec_get(names, i);
        var n_ptr;
        n_ptr = ptr64[name_info];
        var n_len;
        n_len = ptr64[name_info + 8];
        
        if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
            return vec_get(offsets, i);
        }
        i = i + 1;
    }
    
    return 0;  // Not found
}

func symtab_get_type(s, name_ptr, name_len) {
    var names;
    names = ptr64[s];
    var types;
    types = ptr64[s + 16];
    var count;
    count = ptr64[s + 24];
    
    var i;
    i = 0;
    while (i < count) {
        var name_info;
        name_info = vec_get(names, i);
        var n_ptr;
        n_ptr = ptr64[name_info];
        var n_len;
        n_len = ptr64[name_info + 8];
        
        if (str_eq(n_ptr, n_len, name_ptr, name_len)) {
            return vec_get(types, i);
        }
        i = i + 1;
    }
    
    return 0;
}

// Get expression type info: returns [base_type, ptr_depth] or 0
// This is used for pointer arithmetic
func get_expr_type(node) {
    var kind;
    kind = ast_kind(node);
    
    // Identifier - lookup in symbol table
    if (kind == AST_IDENT) {
        var name_ptr;
        name_ptr = ptr64[node + 8];
        var name_len;
        name_len = ptr64[node + 16];
        var type_info;
        type_info = symtab_get_type(g_symtab, name_ptr, name_len);
        // If not found, return default i64
        if (type_info == 0) {
            var result;
            result = heap_alloc(16);
            ptr64[result] = TYPE_I64;
            ptr64[result + 8] = 0;
            return result;
        }
        return type_info;
    }
    
    // Cast - use target type
    if (kind == AST_CAST) {
        var result;
        result = heap_alloc(16);
        ptr64[result] = ptr64[node + 16];      // target_type
        ptr64[result + 8] = ptr64[node + 24];  // ptr_depth
        return result;
    }
    
    // Address-of - pointer to operand's type
    if (kind == AST_ADDR_OF) {
        var operand;
        operand = ptr64[node + 8];
        var op_type;
        op_type = get_expr_type(operand);
        if (op_type != 0) {
            var result;
            result = heap_alloc(16);
            ptr64[result] = ptr64[op_type];        // same base type
            ptr64[result + 8] = ptr64[op_type + 8] + 1;  // increase ptr_depth
            return result;
        }
    }
    
    // Deref - dereference type
    if (kind == AST_DEREF) {
        var operand;
        operand = ptr64[node + 8];
        var op_type;
        op_type = get_expr_type(operand);
        if (op_type != 0) {
            var depth;
            depth = ptr64[op_type + 8];
            if (depth > 0) {
                var result;
                result = heap_alloc(16);
                ptr64[result] = ptr64[op_type];       // same base type
                ptr64[result + 8] = depth - 1;        // decrease ptr_depth
                return result;
            }
        }
    }
    
    // Binary - for pointer arithmetic, result is same type as pointer operand
    if (kind == AST_BINARY) {
        var left;
        left = ptr64[node + 16];
        var right;
        right = ptr64[node + 24];
        
        // Check left operand type
        var left_type;
        left_type = get_expr_type(left);
        if (left_type != 0) {
            var l_depth;
            l_depth = ptr64[left_type + 8];
            if (l_depth > 0) {
                // Left is pointer - result is same pointer type
                var result;
                result = heap_alloc(16);
                ptr64[result] = ptr64[left_type];
                ptr64[result + 8] = l_depth;
                return result;
            }
        }
        
        // Check right operand type (for ptr - ptr case)
        var right_type;
        right_type = get_expr_type(right);
        if (right_type != 0) {
            var r_depth;
            r_depth = ptr64[right_type + 8];
            if (r_depth > 0) {
                // Right is pointer - result is same pointer type
                var result;
                result = heap_alloc(16);
                ptr64[result] = ptr64[right_type];
                ptr64[result + 8] = r_depth;
                return result;
            }
        }
        
        // Both are non-pointers - result is i64
    }
    
    // Literal - assume i64
    if (kind == AST_LITERAL) {
        var result;
        result = heap_alloc(16);
        ptr64[result] = TYPE_I64;
        ptr64[result + 8] = 0;
        return result;
    }
    
    // Unknown - return default i64
    var result;
    result = heap_alloc(16);
    ptr64[result] = TYPE_I64;
    ptr64[result + 8] = 0;
    return result;
}

// ============================================
// Global Constants
// ============================================

// Find constant by name, returns [found, value]
func const_find(name_ptr, name_len) {
    var len;
    len = vec_len(g_consts);
    var i;
    i = 0;
    while (i < len) {
        var c;
        c = vec_get(g_consts, i);
        var c_ptr;
        c_ptr = ptr64[c];
        var c_len;
        c_len = ptr64[c + 8];
        if (str_eq(c_ptr, c_len, name_ptr, name_len)) {
            var result;
            result = heap_alloc(16);
            ptr64[result] = 1;  // found
            ptr64[result + 8] = ptr64[c + 16];  // value
            return result;
        }
        i = i + 1;
    }
    var result;
    result = heap_alloc(16);
    ptr64[result] = 0;  // not found
    return result;
}

// ============================================
// Label Generation
// ============================================

func new_label() {
    var l;
    l = g_label_counter;
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
// Expression Codegen
// Result in RAX
// ============================================

func cg_expr(node) {
    var kind;
    kind = ast_kind(node);
    
    // Literal
    if (kind == AST_LITERAL) {
        emit("    mov rax, ", 13);
        emit_u64(ptr64[node + 8]);
        emit_nl();
        return;
    }
    
    // Identifier - check constants first, then stack
    if (kind == AST_IDENT) {
        var name_ptr;
        name_ptr = ptr64[node + 8];
        var name_len;
        name_len = ptr64[node + 16];
        
        // Check if it's a constant
        var c_result;
        c_result = const_find(name_ptr, name_len);
        if (ptr64[c_result] == 1) {
            emit("    mov rax, ", 13);
            emit_u64(ptr64[c_result + 8]);
            emit_nl();
            return;
        }
        
        var offset;
        offset = symtab_find(g_symtab, name_ptr, name_len);
        
        emit("    mov rax, [rbp", 17);
        if (offset < 0) {
            emit_i64(offset);
        } else {
            emit("+", 1);
            emit_u64(offset);
        }
        emit("]\n", 2);
        return;
    }
    
    // Binary operation
    if (kind == AST_BINARY) {
        var op;
        op = ptr64[node + 8];
        var left;
        left = ptr64[node + 16];
        var right;
        right = ptr64[node + 24];
        
        cg_expr(left);
        emit("    push rax", 12);
        emit_nl();
        cg_expr(right);
        emit("    mov rbx, rax", 16);
        emit_nl();
        emit("    pop rax", 11);
        emit_nl();
        
        // Pointer arithmetic: if left is pointer, scale index by pointee size
        var left_type;
        left_type = get_expr_type(left);
        var ptr_depth;
        ptr_depth = ptr64[left_type + 8];
        
        if (ptr_depth > 0) {
            // Left is a pointer - scale RHS for add/sub
            if (op == TOKEN_PLUS) {
                var psize;
                psize = get_pointee_size(ptr64[left_type], ptr_depth);
                if (psize > 1) {
                    emit("    imul rbx, ", 14);
                    emit_u64(psize);
                    emit_nl();
                }
            } else if (op == TOKEN_MINUS) {
                var psize;
                psize = get_pointee_size(ptr64[left_type], ptr_depth);
                if (psize > 1) {
                    emit("    imul rbx, ", 14);
                    emit_u64(psize);
                    emit_nl();
                }
            }
        }
        
        if (op == TOKEN_PLUS) {
            emit("    add rax, rbx", 16);
            emit_nl();
        } else if (op == TOKEN_MINUS) {
            emit("    sub rax, rbx", 16);
            emit_nl();
        } else if (op == TOKEN_STAR) {
            emit("    imul rax, rbx", 17);
            emit_nl();
        } else if (op == TOKEN_SLASH) {
            emit("    cqo", 7);
            emit_nl();
            emit("    idiv rbx", 12);
            emit_nl();
        } else if (op == TOKEN_LT) {
            emit("    cmp rax, rbx", 16);
            emit_nl();
            emit("    setl al", 11);
            emit_nl();
            emit("    movzx rax, al", 17);
            emit_nl();
        } else if (op == TOKEN_GT) {
            emit("    cmp rax, rbx", 16);
            emit_nl();
            emit("    setg al", 11);
            emit_nl();
            emit("    movzx rax, al", 17);
            emit_nl();
        } else if (op == TOKEN_LTEQ) {
            emit("    cmp rax, rbx", 16);
            emit_nl();
            emit("    setle al", 12);
            emit_nl();
            emit("    movzx rax, al", 17);
            emit_nl();
        } else if (op == TOKEN_GTEQ) {
            emit("    cmp rax, rbx", 16);
            emit_nl();
            emit("    setge al", 12);
            emit_nl();
            emit("    movzx rax, al", 17);
            emit_nl();
        } else if (op == TOKEN_EQEQ) {
            emit("    cmp rax, rbx", 16);
            emit_nl();
            emit("    sete al", 11);
            emit_nl();
            emit("    movzx rax, al", 17);
            emit_nl();
        } else if (op == TOKEN_BANGEQ) {
            emit("    cmp rax, rbx", 16);
            emit_nl();
            emit("    setne al", 12);
            emit_nl();
            emit("    movzx rax, al", 17);
            emit_nl();
        }
        return;
    }
    
    // Unary minus
    if (kind == AST_UNARY) {
        var op;
        op = ptr64[node + 8];
        var operand;
        operand = ptr64[node + 16];
        
        cg_expr(operand);
        if (op == TOKEN_MINUS) {
            emit("    neg rax\n", 12);
        }
        return;
    }
    
    // Address-of
    if (kind == AST_ADDR_OF) {
        var operand;
        operand = ptr64[node + 8];
        // operand should be AST_IDENT
        var name_ptr;
        name_ptr = ptr64[operand + 8];
        var name_len;
        name_len = ptr64[operand + 16];
        var offset;
        offset = symtab_find(g_symtab, name_ptr, name_len);
        
        emit("    lea rax, [rbp", 17);
        if (offset < 0) {
            emit_i64(offset);
        } else {
            emit("+", 1);
            emit_u64(offset);
        }
        emit("]\n", 2);
        return;
    }
    
    // Dereference - type-aware memory read
    if (kind == AST_DEREF) {
        var operand;
        operand = ptr64[node + 8];
        cg_expr(operand);
        
        // Get operand type to determine memory access size
        var op_type;
        op_type = get_expr_type(operand);
        var base_type;
        base_type = ptr64[op_type];
        var ptr_depth;
        ptr_depth = ptr64[op_type + 8];
        
        // After dereference, ptr_depth decreases by 1
        // If ptr_depth was 1, we're reading the base type
        if (ptr_depth == 1) {
            if (base_type == TYPE_U8) {
                emit("    movzx rax, byte [rax]", 25);
                emit_nl();
                return;
            }
            if (base_type == TYPE_U16) {
                emit("    movzx rax, word [rax]", 25);
                emit_nl();
                return;
            }
            if (base_type == TYPE_U32) {
                emit("    mov eax, [rax]", 18);
                emit_nl();
                return;
            }
        }
        // Default: 8-byte read (i64, u64, or pointer)
        emit("    mov rax, [rax]", 18);
        emit_nl();
        return;
    }
    
    // Index syntax removed - use *ptr dereference instead
    
    // Cast: (type)expr - mostly no-op in our system
    if (kind == AST_CAST) {
        var expr;
        expr = ptr64[node + 8];
        // target_type = ptr64[node + 16]
        // ptr_depth = ptr64[node + 24]
        // For now, just evaluate the expression
        // Type info will be used in Phase 3 for pointer arithmetic
        cg_expr(expr);
        return;
    }
    
    // Function call
    if (kind == AST_CALL) {
        var name_ptr;
        name_ptr = ptr64[node + 8];
        var name_len;
        name_len = ptr64[node + 16];
        var args;
        args = ptr64[node + 24];
        var nargs;
        nargs = vec_len(args);
        
        // Push args in reverse order
        var i;
        i = nargs - 1;
        while (i >= 0) {
            cg_expr(vec_get(args, i));
            emit("    push rax\n", 13);
            i = i - 1;
        }
        
        // Call
        emit("    call ", 9);
        emit(name_ptr, name_len);
        emit_nl();
        
        // Clean up stack
        if (nargs > 0) {
            emit("    add rsp, ", 13);
            emit_u64(nargs * 8);
            emit_nl();
        }
        return;
    }
}

// ============================================
// LValue Codegen (for assignment targets)
// Result: address in RAX
// ============================================

func cg_lvalue(node) {
    var kind;
    kind = ast_kind(node);
    
    // Identifier
    if (kind == AST_IDENT) {
        var name_ptr;
        name_ptr = ptr64[node + 8];
        var name_len;
        name_len = ptr64[node + 16];
        var offset;
        offset = symtab_find(g_symtab, name_ptr, name_len);
        
        emit("    lea rax, [rbp", 17);
        if (offset < 0) {
            emit_i64(offset);
        } else {
            emit("+", 1);
            emit_u64(offset);
        }
        emit("]\n", 2);
        return;
    }
    
    // Dereference: *ptr = val
    if (kind == AST_DEREF) {
        var operand;
        operand = ptr64[node + 8];
        cg_expr(operand);  // Address is already the result
        return;
    }
    
    // Index syntax removed - use *ptr dereference instead
}

// ============================================
// Statement Codegen
// ============================================

func cg_stmt(node) {
    var kind;
    kind = ast_kind(node);
    
    // Return
    if (kind == AST_RETURN) {
        var expr;
        expr = ptr64[node + 8];
        if (expr != 0) {
            cg_expr(expr);
        } else {
            emit("    xor eax, eax\n", 17);
        }
        emit("    mov rsp, rbp\n", 17);
        emit("    pop rbp\n", 12);
        emit("    ret\n", 8);
        return;
    }
    
    // Variable declaration
    if (kind == AST_VAR_DECL) {
        var name_ptr;
        name_ptr = ptr64[node + 8];
        var name_len;
        name_len = ptr64[node + 16];
        var type_kind;
        type_kind = ptr64[node + 24];
        var ptr_depth;
        ptr_depth = ptr64[node + 32];
        var init;
        init = ptr64[node + 40];
        
        var offset;
        offset = symtab_add(g_symtab, name_ptr, name_len, type_kind, ptr_depth);
        
        // Allocate stack space
        emit("    sub rsp, 8", 14);
        emit_nl();
        
        // Initialize if provided
        if (init != 0) {
            // Type check: compare declared type with initializer type
            if (type_kind != 0) {
                var init_type;
                init_type = get_expr_type(init);
                if (init_type != 0) {
                    var it_base;
                    it_base = ptr64[init_type];
                    var it_depth;
                    it_depth = ptr64[init_type + 8];
                    
                    var compat;
                    compat = check_type_compat(it_base, it_depth, type_kind, ptr_depth);
                    if (compat == 1) {
                        warn("implicit type conversion in initialization", 43);
                    }
                }
            }
            
            cg_expr(init);
            emit("    mov [rbp", 12);
            if (offset < 0) {
                emit_i64(offset);
            } else {
                emit("+", 1);
                emit_u64(offset);
            }
            emit("], rax", 6);
            emit_nl();
        }
        return;
    }
    
    // Assignment
    if (kind == AST_ASSIGN) {
        var target;
        target = ptr64[node + 8];
        var value;
        value = ptr64[node + 16];
        
        // Type checking and propagation for identifier targets
        var target_kind;
        target_kind = ast_kind(target);
        if (target_kind == AST_IDENT) {
            var name_ptr;
            name_ptr = ptr64[target + 8];
            var name_len;
            name_len = ptr64[target + 16];
            
            // Get target type from symbol table
            var target_type;
            target_type = symtab_get_type(g_symtab, name_ptr, name_len);
            
            // Get value type
            var value_type;
            value_type = get_expr_type(value);
            
            if (target_type != 0) {
                if (value_type != 0) {
                    var tt_base;
                    tt_base = ptr64[target_type];
                    var tt_depth;
                    tt_depth = ptr64[target_type + 8];
                    var vt_base;
                    vt_base = ptr64[value_type];
                    var vt_depth;
                    vt_depth = ptr64[value_type + 8];
                    
                    // Check type compatibility
                    var compat;
                    compat = check_type_compat(vt_base, vt_depth, tt_base, tt_depth);
                    if (compat == 1) {
                        // Compatible but not exact - emit warning
                        warn("implicit type conversion in assignment", 39);
                    }
                    
                    // Type propagation: update target type if value is pointer
                    if (vt_depth > 0) {
                        symtab_update_type(g_symtab, name_ptr, name_len, vt_base, vt_depth);
                    }
                }
            } else {
                // Target has no type - propagate from value if it's a pointer
                if (value_type != 0) {
                    var vt_depth;
                    vt_depth = ptr64[value_type + 8];
                    if (vt_depth > 0) {
                        var vt_base;
                        vt_base = ptr64[value_type];
                        symtab_update_type(g_symtab, name_ptr, name_len, vt_base, vt_depth);
                    }
                }
            }
        }
        
        cg_expr(value);
        emit("    push rax", 12);
        emit_nl();
        cg_lvalue(target);
        emit("    pop rbx", 11);
        emit_nl();
        
        // Type-aware memory write for dereference targets
        if (target_kind == AST_DEREF) {
            var deref_operand;
            deref_operand = ptr64[target + 8];
            var op_type;
            op_type = get_expr_type(deref_operand);
            var base_type;
            base_type = ptr64[op_type];
            var ptr_depth;
            ptr_depth = ptr64[op_type + 8];
            
            if (ptr_depth == 1) {
                if (base_type == TYPE_U8) {
                    emit("    mov [rax], bl", 17);
                    emit_nl();
                    return;
                }
                if (base_type == TYPE_U16) {
                    emit("    mov [rax], bx", 17);
                    emit_nl();
                    return;
                }
                if (base_type == TYPE_U32) {
                    emit("    mov [rax], ebx", 18);
                    emit_nl();
                    return;
                }
            }
        }
        
        // Default: 8-byte write
        emit("    mov [rax], rbx", 18);
        emit_nl();
        return;
    }
    
    // Expression statement
    if (kind == AST_EXPR_STMT) {
        var expr;
        expr = ptr64[node + 8];
        cg_expr(expr);
        return;
    }
    
    // If statement
    if (kind == AST_IF) {
        var cond;
        cond = ptr64[node + 8];
        var then_blk;
        then_blk = ptr64[node + 16];
        var else_blk;
        else_blk = ptr64[node + 24];
        
        var else_label;
        else_label = new_label();
        var end_label;
        end_label = new_label();
        
        cg_expr(cond);
        emit("    test rax, rax", 17);
        emit_nl();
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
    
    // While statement
    if (kind == AST_WHILE) {
        var cond;
        cond = ptr64[node + 8];
        var body;
        body = ptr64[node + 16];
        
        var start_label;
        start_label = new_label();
        var end_label;
        end_label = new_label();
        
        emit_label_def(start_label);
        
        cg_expr(cond);
        emit("    test rax, rax", 17);
        emit_nl();
        emit("    jz ", 7);
        emit_label(end_label);
        emit_nl();
        
        cg_block(body);
        
        emit("    jmp ", 8);
        emit_label(start_label);
        emit_nl();
        
        emit_label_def(end_label);
        return;
    }
    
    // For statement
    if (kind == AST_FOR) {
        var init;
        init = ptr64[node + 8];
        var cond;
        cond = ptr64[node + 16];
        var update;
        update = ptr64[node + 24];
        var body;
        body = ptr64[node + 32];
        
        if (init != 0) {
            cg_stmt(init);
        }
        
        var start_label;
        start_label = new_label();
        var end_label;
        end_label = new_label();
        
        emit_label_def(start_label);
        
        if (cond != 0) {
            cg_expr(cond);
            emit("    test rax, rax", 17);
            emit_nl();
            emit("    jz ", 7);
            emit_label(end_label);
            emit_nl();
        }
        
        cg_block(body);
        
        if (update != 0) {
            cg_stmt(update);
        }
        
        emit("    jmp ", 8);
        emit_label(start_label);
        emit_nl();
        
        emit_label_def(end_label);
        return;
    }
    
    // Switch statement
    if (kind == AST_SWITCH) {
        var expr;
        expr = ptr64[node + 8];
        var cases;
        cases = ptr64[node + 16];
        
        cg_expr(expr);
        emit("    push rax\n", 13);
        
        var end_label;
        end_label = new_label();
        
        var num_cases;
        num_cases = vec_len(cases);
        var i;
        i = 0;
        while (i < num_cases) {
            var case_node;
            case_node = vec_get(cases, i);
            var is_default;
            is_default = ptr64[case_node + 24];
            
            if (is_default == 0) {
                var value;
                value = ptr64[case_node + 8];
                var next_label;
                next_label = new_label();
                
                emit("    mov rax, [rsp]\n", 19);
                emit("    push rax\n", 13);
                cg_expr(value);
                emit("    mov rbx, rax\n", 17);
                emit("    pop rax\n", 12);
                emit("    cmp rax, rbx\n", 17);
                emit("    jne ", 8);
                emit_label(next_label);
                emit_nl();
                
                var body;
                body = ptr64[case_node + 16];
                cg_block(body);
                
                emit("    jmp ", 8);
                emit_label(end_label);
                emit_nl();
                
                emit_label_def(next_label);
            } else {
                var body;
                body = ptr64[case_node + 16];
                cg_block(body);
            }
            
            i = i + 1;
        }
        
        emit("    add rsp, 8", 14);
        emit_nl();
        emit_label_def(end_label);
        return;
    }
    
    // Break statement
    if (kind == AST_BREAK) {
        emit("    ; break not fully supported yet\n", 37);
        return;
    }
    
    // Block
    if (kind == AST_BLOCK) {
        cg_block(node);
        return;
    }
}

func cg_block(node) {
    var stmts;
    stmts = ptr64[node + 8];
    var len;
    len = vec_len(stmts);
    var i;
    i = 0;
    while (i < len) {
        cg_stmt(vec_get(stmts, i));
        i = i + 1;
    }
}

// ============================================
// Function Codegen
// ============================================

func cg_func(node) {
    var name_ptr;
    name_ptr = ptr64[node + 8];
    var name_len;
    name_len = ptr64[node + 16];
    var params;
    params = ptr64[node + 24];
    var body;
    body = ptr64[node + 40];
    
    // Clear symbol table for new function
    symtab_clear(g_symtab);
    
    // Emit function label
    emit(name_ptr, name_len);
    emit(":\n", 2);
    
    // Prologue
    emit("    push rbp\n", 13);
    emit("    mov rbp, rsp\n", 17);
    
    // Add parameters to symbol table (pushed by caller)
    var nparams;
    nparams = vec_len(params);
    var i;
    i = 0;
    while (i < nparams) {
        var param;
        param = vec_get(params, i);
        var pname;
        pname = ptr64[param];
        var plen;
        plen = ptr64[param + 8];
        var ptype;
        ptype = ptr64[param + 16];
        var pdepth;
        pdepth = ptr64[param + 24];
        
        // Parameters are at [rbp + 16 + i*8] (return addr at [rbp+8])
        // Just add to symbol table with positive offset
        var names;
        names = ptr64[g_symtab];
        var offsets;
        offsets = ptr64[g_symtab + 8];
        var types;
        types = ptr64[g_symtab + 16];
        
        var name_info;
        name_info = heap_alloc(16);
        ptr64[name_info] = pname;
        ptr64[name_info + 8] = plen;
        vec_push(names, name_info);
        
        vec_push(offsets, 16 + i * 8);
        
        var type_info;
        type_info = heap_alloc(16);
        ptr64[type_info] = ptype;
        ptr64[type_info + 8] = pdepth;
        vec_push(types, type_info);
        
        ptr64[g_symtab + 24] = ptr64[g_symtab + 24] + 1;
        
        i = i + 1;
    }
    
    // Generate body
    cg_block(body);
    
    // Default return if no explicit return
    emit("    xor eax, eax\n", 17);
    emit("    mov rsp, rbp\n", 17);
    emit("    pop rbp\n", 12);
    emit("    ret\n", 8);
}

// ============================================
// Program Codegen
// ============================================

func cg_program(prog) {
    var funcs;
    funcs = ptr64[prog + 8];
    var consts;
    consts = ptr64[prog + 16];
    
    // Initialize globals
    g_symtab = symtab_new();
    g_label_counter = 0;
    
    // Process constants: store in g_consts for lookup
    g_consts = vec_new(64);
    var clen;
    clen = vec_len(consts);
    var ci;
    ci = 0;
    while (ci < clen) {
        var c;
        c = vec_get(consts, ci);
        // AST_CONST_DECL: [kind, name_ptr, name_len, value]
        var cinfo;
        cinfo = heap_alloc(24);
        ptr64[cinfo] = ptr64[c + 8];       // name_ptr
        ptr64[cinfo + 8] = ptr64[c + 16];  // name_len
        ptr64[cinfo + 16] = ptr64[c + 24]; // value
        vec_push(g_consts, cinfo);
        ci = ci + 1;
    }
    
    // Emit header
    emit("section .text\n", 14);
    emit("global _start\n", 14);
    emit("_start:\n", 8);
    emit("    call main\n", 14);
    emit("    mov rdi, rax\n", 17);
    emit("    mov rax, 60\n", 16);
    emit("    syscall\n", 12);
    
    // Emit functions
    var len;
    len = vec_len(funcs);
    var i;
    i = 0;
    while (i < len) {
        cg_func(vec_get(funcs, i));
        i = i + 1;
    }
}

