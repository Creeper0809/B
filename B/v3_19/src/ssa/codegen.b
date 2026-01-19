// ssa_codegen.b - SSA → x86-64 코드 생성 (v3_17)
//
// 주의:
// - SSA 빌더가 지원하는 최소 부분집합만 대상으로 한다.
// - 매개변수/글로벌 접근/복잡한 AST는 기존 코드젠으로 폴백한다.

import std.io;
import std.vec;
import std.util;
import types;
import ast;
import ssa.datastruct;
import ssa.core;
import ssa.regalloc;
import emitter.emitter;
import emitter.symtab;
import compiler;

const SSA_CODEGEN_DEBUG = 0;

// ============================================
// 지원 여부 판정
// ============================================

func _ssa_codegen_is_global(globals: u64, name_ptr: u64, name_len: u64) -> u64 {
    if (globals == 0) { return 0; }
    var n: u64 = vec_len(globals);
    var i: u64 = 0;
    while (i < n) {
        var ginfo: *GlobalInfo = (*GlobalInfo)vec_get(globals, i);
        if (str_eq(ginfo->name_ptr, ginfo->name_len, name_ptr, name_len) != 0) { return 1; }
        i = i + 1;
    }
    return 0;
}

func _ssa_codegen_expr_supported(node: u64, globals: u64) -> u64 {
    push_trace("_ssa_codegen_expr_supported", "ssa_codegen.b", __LINE__);
    pop_trace();
    if (node == 0) { return 1; }
    var kind: u64 = ast_kind(node);

    if (kind == AST_LITERAL) { return 1; }

    if (kind == AST_STRING) { return 1; }

    if (kind == AST_IDENT) {
        var idn: *AstIdent = (*AstIdent)node;
        if (_ssa_codegen_is_global(globals, idn->name_ptr, idn->name_len) != 0) { return 1; }
        return 1;
    }

    if (kind == AST_BINARY) {
        var bin: *AstBinary = (*AstBinary)node;
        var op: u64 = bin->op;
        if (op != TOKEN_PLUS && op != TOKEN_MINUS && op != TOKEN_STAR && op != TOKEN_SLASH &&
            op != TOKEN_PERCENT && op != TOKEN_CARET && op != TOKEN_AMPERSAND && op != TOKEN_PIPE &&
            op != TOKEN_LSHIFT && op != TOKEN_RSHIFT &&
            op != TOKEN_EQEQ && op != TOKEN_BANGEQ && op != TOKEN_LT && op != TOKEN_GT &&
            op != TOKEN_LTEQ && op != TOKEN_GTEQ && op != TOKEN_ANDAND && op != TOKEN_OROR) {
            return 0;
        }
        if (_ssa_codegen_expr_supported(bin->left, globals) == 0) { return 0; }
        if (_ssa_codegen_expr_supported(bin->right, globals) == 0) { return 0; }
        return 1;
    }

    if (kind == AST_UNARY) {
        var un: *AstUnary = (*AstUnary)node;
        if (un->op != TOKEN_MINUS && un->op != TOKEN_BANG) { return 0; }
        return _ssa_codegen_expr_supported(un->operand, globals);
    }

    if (kind == AST_ADDR_OF) {
        var a: *AstAddrOf = (*AstAddrOf)node;
        return _ssa_codegen_expr_supported(a->operand, globals);
    }

    if (kind == AST_DEREF || kind == AST_DEREF8) {
        var d: *AstDeref = (*AstDeref)node;
        return _ssa_codegen_expr_supported(d->operand, globals);
    }

    if (kind == AST_INDEX) {
        var idx: *AstIndex = (*AstIndex)node;
        if (_ssa_codegen_expr_supported(idx->base, globals) == 0) { return 0; }
        if (_ssa_codegen_expr_supported(idx->index, globals) == 0) { return 0; }
        return 1;
    }

    if (kind == AST_MEMBER_ACCESS) {
        var m: *AstMemberAccess = (*AstMemberAccess)node;
        return _ssa_codegen_expr_supported(m->object, globals);
    }

    if (kind == AST_CAST) {
        var c: *AstCast = (*AstCast)node;
        return _ssa_codegen_expr_supported(c->expr, globals);
    }

    if (kind == AST_SIZEOF) { return 1; }

    if (kind == AST_CALL) {
        var call: *AstCall = (*AstCall)node;
        var args: u64 = call->args_vec;
        var n: u64 = 0;
        if (args != 0) { n = vec_len(args); }
        var i: u64 = 0;
        while (i < n) {
            var arg: u64 = vec_get(args, i);
            if (ast_kind(arg) == AST_SLICE) {
                var s: *AstSlice = (*AstSlice)arg;
                if (_ssa_codegen_expr_supported(s->ptr_expr, globals) == 0) { return 0; }
                if (_ssa_codegen_expr_supported(s->len_expr, globals) == 0) { return 0; }
            } else {
                if (_ssa_codegen_expr_supported(arg, globals) == 0) { return 0; }
            }
            i = i + 1;
        }
        return 1;
    }

    if (kind == AST_CALL_PTR) {
        var cp: *AstCallPtr = (*AstCallPtr)node;
        if (_ssa_codegen_expr_supported(cp->callee, globals) == 0) { return 0; }
        var args2: u64 = cp->args_vec;
        var n2: u64 = 0;
        if (args2 != 0) { n2 = vec_len(args2); }
        var i2: u64 = 0;
        while (i2 < n2) {
            var arg2: u64 = vec_get(args2, i2);
            if (ast_kind(arg2) == AST_SLICE) {
                var s2: *AstSlice = (*AstSlice)arg2;
                if (_ssa_codegen_expr_supported(s2->ptr_expr, globals) == 0) { return 0; }
                if (_ssa_codegen_expr_supported(s2->len_expr, globals) == 0) { return 0; }
            } else {
                if (_ssa_codegen_expr_supported(arg2, globals) == 0) { return 0; }
            }
            i2 = i2 + 1;
        }
        return 1;
    }

    if (kind == AST_METHOD_CALL) {
        var mc: *AstMethodCall = (*AstMethodCall)node;
        if (_ssa_codegen_expr_supported(mc->receiver, globals) == 0) { return 0; }
        var args: u64 = mc->args_vec;
        var n: u64 = 0;
        if (args != 0) { n = vec_len(args); }
        var i: u64 = 0;
        while (i < n) {
            var arg: u64 = vec_get(args, i);
            if (ast_kind(arg) == AST_SLICE) {
                var s: *AstSlice = (*AstSlice)arg;
                if (_ssa_codegen_expr_supported(s->ptr_expr, globals) == 0) { return 0; }
                if (_ssa_codegen_expr_supported(s->len_expr, globals) == 0) { return 0; }
            } else {
                if (_ssa_codegen_expr_supported(arg, globals) == 0) { return 0; }
            }
            i = i + 1;
        }
        return 1;
    }

    if (kind == AST_STRUCT_LITERAL) {
        return _ssa_codegen_struct_literal_supported(node, globals);
    }

    return 0;
}

func _ssa_codegen_struct_literal_supported(init: u64, globals: u64) -> u64 {
    if (init == 0) { return 1; }
    var lit: *AstStructLiteral = (*AstStructLiteral)init;
    var values: u64 = lit->values_vec;
    if (values == 0) { return 1; }
    var n: u64 = vec_len(values);
    for (var i: u64 = 0; i < n; i++) {
        var v: u64 = vec_get(values, i);
        if (ast_kind(v) == AST_STRUCT_LITERAL) {
            if (_ssa_codegen_struct_literal_supported(v, globals) == 0) { return 0; }
        } else if (ast_kind(v) == AST_SLICE) {
            var s: *AstSlice = (*AstSlice)v;
            if (_ssa_codegen_expr_supported(s->ptr_expr, globals) == 0) { return 0; }
            if (_ssa_codegen_expr_supported(s->len_expr, globals) == 0) { return 0; }
        } else {
            if (_ssa_codegen_expr_supported(v, globals) == 0) { return 0; }
        }
    }
    return 1;
}

func _ssa_codegen_stmt_or_expr_supported(node: u64, globals: u64) -> u64 {
    if (node == 0) { return 1; }
    var kind: u64 = ast_kind(node);
    if (kind == AST_VAR_DECL || kind == AST_CONST_DECL || kind == AST_ASSIGN || kind == AST_EXPR_STMT) {
        return _ssa_codegen_stmt_supported(node, globals);
    }
    return _ssa_codegen_expr_supported(node, globals);
}

func _ssa_codegen_case_supported(node: u64, globals: u64) -> u64 {
    if (node == 0) { return 0; }
    var c: *AstCase = (*AstCase)node;
    if (c->is_default == 0) {
        if (_ssa_codegen_expr_supported(c->value, globals) == 0) { return 0; }
    }
    return _ssa_codegen_stmt_supported(c->body, globals);
}

func _ssa_codegen_stmt_supported(node: u64, globals: u64) -> u64 {
    push_trace("_ssa_codegen_stmt_supported", "ssa_codegen.b", __LINE__);
    pop_trace();
    if (node == 0) { return 1; }
    var kind: u64 = ast_kind(node);

    if (kind == AST_BLOCK) {
        var blk: *AstBlock = (*AstBlock)node;
        var stmts: u64 = blk->stmts_vec;
        var n: u64 = vec_len(stmts);
        var i: u64 = 0;
        while (i < n) {
            if (_ssa_codegen_stmt_supported(vec_get(stmts, i), globals) == 0) { return 0; }
            i = i + 1;
        }
        return 1;
    }

    if (kind == AST_IF) {
        var ifn: *AstIf = (*AstIf)node;
        if (_ssa_codegen_expr_supported(ifn->cond, globals) == 0) { return 0; }
        if (_ssa_codegen_stmt_supported(ifn->then_block, globals) == 0) { return 0; }
        if (ifn->else_block != 0 && _ssa_codegen_stmt_supported(ifn->else_block, globals) == 0) { return 0; }
        return 1;
    }

    if (kind == AST_WHILE) {
        var w: *AstWhile = (*AstWhile)node;
        if (_ssa_codegen_expr_supported(w->cond, globals) == 0) { return 0; }
        if (_ssa_codegen_stmt_supported(w->body, globals) == 0) { return 0; }
        return 1;
    }

    if (kind == AST_FOR) {
        var f: *AstFor = (*AstFor)node;
        if (_ssa_codegen_stmt_or_expr_supported(f->init, globals) == 0) { return 0; }
        if (_ssa_codegen_expr_supported(f->cond, globals) == 0) { return 0; }
        if (_ssa_codegen_stmt_or_expr_supported(f->update, globals) == 0) { return 0; }
        if (_ssa_codegen_stmt_supported(f->body, globals) == 0) { return 0; }
        return 1;
    }

    if (kind == AST_SWITCH) {
        var sw: *AstSwitch = (*AstSwitch)node;
        if (_ssa_codegen_expr_supported(sw->expr, globals) == 0) { return 0; }
        var cases: u64 = sw->cases_vec;
        var n: u64 = 0;
        if (cases != 0) { n = vec_len(cases); }
        var i: u64 = 0;
        while (i < n) {
            if (_ssa_codegen_case_supported(vec_get(cases, i), globals) == 0) { return 0; }
            i = i + 1;
        }
        return 1;
    }

    if (kind == AST_EXPR_STMT) {
        var es: *AstExprStmt = (*AstExprStmt)node;
        return _ssa_codegen_expr_supported(es->expr, globals);
    }

    if (kind == AST_VAR_DECL) {
        var vd: *AstVarDecl = (*AstVarDecl)node;
        if (vd->init_expr == 0) { return 1; }
        if (vd->type_kind == TYPE_SLICE && vd->ptr_depth == 0) {
            if (ast_kind(vd->init_expr) == AST_CALL) { return 0; }
        }
        if (ast_kind(vd->init_expr) == AST_STRUCT_LITERAL) {
            return _ssa_codegen_struct_literal_supported(vd->init_expr, globals);
        }
        return _ssa_codegen_expr_supported(vd->init_expr, globals);
    }

    if (kind == AST_CONST_DECL) {
        var cd: *AstConstDecl = (*AstConstDecl)node;
        return _ssa_codegen_expr_supported(ast_literal(cd->value), globals);
    }

    if (kind == AST_ASSIGN) {
        var asn: *AstAssign = (*AstAssign)node;
        var tk: u64 = ast_kind(asn->target);
        if (tk == AST_IDENT) {
            var idn2: *AstIdent = (*AstIdent)asn->target;
            if (_ssa_codegen_is_global(globals, idn2->name_ptr, idn2->name_len) != 0) { return 0; }
            if (ast_kind(asn->value) == AST_STRUCT_LITERAL) {
                return _ssa_codegen_struct_literal_supported(asn->value, globals);
            }
            return _ssa_codegen_expr_supported(asn->value, globals);
        }
        if (tk == AST_DEREF || tk == AST_DEREF8 || tk == AST_INDEX || tk == AST_MEMBER_ACCESS) {
            if (_ssa_codegen_expr_supported(asn->target, globals) == 0) { return 0; }
            return _ssa_codegen_expr_supported(asn->value, globals);
        }
        return 0;
    }

    if (kind == AST_RETURN) {
        var ret: *AstReturn = (*AstReturn)node;
        return _ssa_codegen_expr_supported(ret->expr, globals);
    }

    if (kind == AST_BREAK || kind == AST_CONTINUE) { return 1; }

    return 0;
}

func ssa_codegen_is_supported_func(fn_ptr: u64, globals: u64) -> u64 {
    push_trace("ssa_codegen_is_supported_func", "ssa_codegen.b", __LINE__);
    pop_trace();
    if (fn_ptr == 0) { return 0; }
    var fn: *AstFunc = (*AstFunc)fn_ptr;

    var params: u64 = fn->params_vec;
    if (params != 0) {
        var pn: u64 = vec_len(params);
        var pi: u64 = 0;
        while (pi < pn) {
            var p: *Param = (*Param)vec_get(params, pi);
            if (p->type_kind == TYPE_SLICE && p->ptr_depth == 0) { return 0; }
            pi = pi + 1;
        }
    }
    if (fn->ret_type == TYPE_STRUCT && fn->ret_ptr_depth == 0) { return 0; }
    return _ssa_codegen_stmt_supported(fn->body, globals);
}

// ============================================
// 레지스터/오퍼랜드 출력
// ============================================

func _ssa_emit_reg_name(phys: u64) -> u64 {
    if (phys == SSA_PHYS_RAX) { emit("rax", 3); return 0; }
    if (phys == SSA_PHYS_RBX) { emit("rbx", 3); return 0; }
    if (phys == SSA_PHYS_RCX) { emit("rcx", 3); return 0; }
    if (phys == SSA_PHYS_RDX) { emit("rdx", 3); return 0; }
    if (phys == SSA_PHYS_R8) { emit("r8", 2); return 0; }
    if (phys == SSA_PHYS_R9) { emit("r9", 2); return 0; }
    emit("rax", 3);
    return 0;
}

func _ssa_emit_imm(val: u64) -> u64 {
    emit_u64(val);
    return 0;
}

func _ssa_emit_opr(opr: u64) -> u64 {
    if (ssa_operand_is_const(opr) != 0) {
        _ssa_emit_imm(ssa_operand_value(opr));
        return 0;
    }
    _ssa_emit_reg_name(ssa_operand_value(opr));
    return 0;
}

func _ssa_emit_mov_reg_opr(dest: u64, opr: u64) -> u64 {
    emit("    mov ", 8);
    _ssa_emit_reg_name(dest);
    emit(", ", 2);
    _ssa_emit_opr(opr);
    emit_nl();
    return 0;
}

func _ssa_emit_push_reg(phys: u64) -> u64 {
    emit("    push ", 9);
    _ssa_emit_reg_name(phys);
    emit_nl();
    return 0;
}

func _ssa_emit_pop_reg(phys: u64) -> u64 {
    emit("    pop ", 8);
    _ssa_emit_reg_name(phys);
    emit_nl();
    return 0;
}

func _ssa_emit_restore_reg(dest: u64, phys: u64) -> u64 {
    if (dest != 0 && dest == phys) {
        emit("    add rsp, 8\n", 15);
        return 0;
    }
    _ssa_emit_pop_reg(phys);
    return 0;
}

func _ssa_emit_call(dest: u64, info_ptr: u64) -> u64 {
    var name_ptr: u64 = *(info_ptr);
    var name_len: u64 = *(info_ptr + 8);
    var args_vec: u64 = *(info_ptr + 16);
    var nargs: u64 = *(info_ptr + 24);
    var ret_type: u64 = *(info_ptr + 32);
    var ret_ptr_depth: u64 = *(info_ptr + 40);
    if (nargs == 0 && args_vec != 0) { nargs = vec_len(args_vec); }

    var keep_rax: u64 = 0;
    var keep_rdx: u64 = 0;
    if (ret_type == TYPE_SLICE && ret_ptr_depth == 0) {
        keep_rax = 1;
        keep_rdx = 1;
    }

    if (keep_rax == 0) { _ssa_emit_push_reg(SSA_PHYS_RAX); }
    _ssa_emit_push_reg(SSA_PHYS_RBX);
    _ssa_emit_push_reg(SSA_PHYS_RCX);
    if (keep_rdx == 0) { _ssa_emit_push_reg(SSA_PHYS_RDX); }
    _ssa_emit_push_reg(SSA_PHYS_R8);
    _ssa_emit_push_reg(SSA_PHYS_R9);

    var i: u64 = 0;
    while (i < nargs) {
        var reg: u64 = vec_get(args_vec, i);
        emit("    push ", 9);
        _ssa_emit_reg_name(reg);
        emit_nl();
        i = i + 1;
    }

    emit("    call ", 9);
    emit(name_ptr, name_len);
    emit_nl();

    if (nargs > 0) {
        emit("    add rsp, ", 13);
        emit_u64(nargs * 8);
        emit_nl();
    }

    if (dest != 0 && dest != SSA_PHYS_RAX) {
        _ssa_emit_mov_reg_opr(dest, ssa_operand_reg(SSA_PHYS_RAX));
    }

    _ssa_emit_restore_reg(dest, SSA_PHYS_R9);
    _ssa_emit_restore_reg(dest, SSA_PHYS_R8);
    if (keep_rdx == 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_RDX); }
    _ssa_emit_restore_reg(dest, SSA_PHYS_RCX);
    _ssa_emit_restore_reg(dest, SSA_PHYS_RBX);
    if (keep_rax == 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_RAX); }
    return 0;
}

func _ssa_emit_call_ptr(dest: u64, info_ptr: u64) -> u64 {
    var callee_reg: u64 = *(info_ptr);
    var args_vec: u64 = *(info_ptr + 8);
    var nargs: u64 = *(info_ptr + 16);
    var ret_type: u64 = *(info_ptr + 24);
    var ret_ptr_depth: u64 = *(info_ptr + 32);
    if (nargs == 0 && args_vec != 0) { nargs = vec_len(args_vec); }

    var keep_rax: u64 = 0;
    var keep_rdx: u64 = 0;
    if (ret_type == TYPE_SLICE && ret_ptr_depth == 0) {
        keep_rax = 1;
        keep_rdx = 1;
    }

    if (keep_rax == 0) { _ssa_emit_push_reg(SSA_PHYS_RAX); }
    _ssa_emit_push_reg(SSA_PHYS_RBX);
    _ssa_emit_push_reg(SSA_PHYS_RCX);
    if (keep_rdx == 0) { _ssa_emit_push_reg(SSA_PHYS_RDX); }
    _ssa_emit_push_reg(SSA_PHYS_R8);
    _ssa_emit_push_reg(SSA_PHYS_R9);

    var i: u64 = 0;
    while (i < nargs) {
        var reg: u64 = vec_get(args_vec, i);
        emit("    push ", 9);
        _ssa_emit_reg_name(reg);
        emit_nl();
        i = i + 1;
    }

    emit("    call ", 9);
    _ssa_emit_reg_name(callee_reg);
    emit_nl();

    if (nargs > 0) {
        emit("    add rsp, ", 13);
        emit_u64(nargs * 8);
        emit_nl();
    }

    if (dest != 0 && dest != SSA_PHYS_RAX) {
        _ssa_emit_mov_reg_opr(dest, ssa_operand_reg(SSA_PHYS_RAX));
    }

    _ssa_emit_restore_reg(dest, SSA_PHYS_R9);
    _ssa_emit_restore_reg(dest, SSA_PHYS_R8);
    if (keep_rdx == 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_RDX); }
    _ssa_emit_restore_reg(dest, SSA_PHYS_RCX);
    _ssa_emit_restore_reg(dest, SSA_PHYS_RBX);
    if (keep_rax == 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_RAX); }
    return 0;
}

func _ssa_emit_label_def(fn_id: u64, block_id: u64) -> u64 {
    emit(".Lssa_", 6);
    emit_u64(fn_id);
    emit("_", 1);
    emit_u64(block_id);
    emit(":", 1);
    emit_nl();
    return 0;
}

func _ssa_emit_label_ref(fn_id: u64, block_id: u64) -> u64 {
    emit(".Lssa_", 6);
    emit_u64(fn_id);
    emit("_", 1);
    emit_u64(block_id);
    return 0;
}

// ============================================
// 메모리 주소/로드/스토어
// ============================================

func _ssa_emit_lea_local(dest: u64, offset: u64) -> u64 {
    emit("    lea ", 8);
    _ssa_emit_reg_name(dest);
    emit(", [rbp", 7);
    var off: i64 = (i64)offset;
    if (off < 0) { emit_i64(off); }
    else { emit("+", 1); emit_u64(offset); }
    emit("]\n", 2);
    return 0;
}

func _ssa_emit_lea_global(dest: u64, name_ptr: u64, name_len: u64) -> u64 {
    emit("    lea ", 8);
    _ssa_emit_reg_name(dest);
    emit(", [rel _gvar_", 13);
    emit(name_ptr, name_len);
    emit("]\n", 2);
    return 0;
}

func _ssa_emit_lea_func(dest: u64, name_ptr: u64, name_len: u64) -> u64 {
    emit("    lea ", 8);
    _ssa_emit_reg_name(dest);
    emit(", [rel ", 7);
    emit(name_ptr, name_len);
    emit("]\n", 2);
    return 0;
}

func _ssa_emit_load(op: u64, dest: u64, addr_opr: u64) -> u64 {
    if (op == SSA_OP_LOAD8) {
        emit("    movzx ", 10);
        _ssa_emit_reg_name(dest);
        emit(", byte [", 9);
        _ssa_emit_reg_name(ssa_operand_value(addr_opr));
        emit("]\n", 2);
        return 0;
    }
    if (op == SSA_OP_LOAD16) {
        emit("    movzx ", 10);
        _ssa_emit_reg_name(dest);
        emit(", word [", 9);
        _ssa_emit_reg_name(ssa_operand_value(addr_opr));
        emit("]\n", 2);
        return 0;
    }
    if (op == SSA_OP_LOAD32) {
        emit("    mov ", 8);
        _ssa_emit_reg_name(dest);
        emit(", dword [", 11);
        _ssa_emit_reg_name(ssa_operand_value(addr_opr));
        emit("]\n", 2);
        return 0;
    }
    emit("    mov ", 8);
    _ssa_emit_reg_name(dest);
    emit(", [", 4);
    _ssa_emit_reg_name(ssa_operand_value(addr_opr));
    emit("]\n", 2);
    return 0;
}

func _ssa_emit_store(op: u64, addr_opr: u64, val_opr: u64) -> u64 {
    if (op == SSA_OP_STORE8) {
        emit("    mov byte [", 15);
    } else if (op == SSA_OP_STORE16) {
        emit("    mov word [", 15);
    } else if (op == SSA_OP_STORE32) {
        emit("    mov dword [", 16);
    } else {
        emit("    mov [", 9);
    }
    _ssa_emit_reg_name(ssa_operand_value(addr_opr));
    emit("], ", 3);
    _ssa_emit_opr(val_opr);
    emit_nl();
    return 0;
}

// ============================================
// 산술/비교 코드 생성
// ============================================

func _ssa_emit_binop(op: u64, dest: u64, src1: u64, src2: u64) -> u64 {
    if (op == SSA_OP_ADD || op == SSA_OP_MUL || op == SSA_OP_AND || op == SSA_OP_OR || op == SSA_OP_XOR) {
        if (!ssa_operand_is_const(src2) && ssa_operand_value(src2) == dest) {
            if (op == SSA_OP_ADD) { emit("    add ", 8); }
            else if (op == SSA_OP_MUL) { emit("    imul ", 9); }
            else if (op == SSA_OP_AND) { emit("    and ", 8); }
            else if (op == SSA_OP_OR) { emit("    or ", 7); }
            else { emit("    xor ", 8); }

            _ssa_emit_reg_name(dest);
            emit(", ", 2);
            _ssa_emit_opr(src1);
            emit_nl();
            return 0;
        }
    }

    _ssa_emit_mov_reg_opr(dest, src1);

    if (op == SSA_OP_ADD) { emit("    add ", 8); }
    else if (op == SSA_OP_SUB) { emit("    sub ", 8); }
    else if (op == SSA_OP_MUL) { emit("    imul ", 9); }
    else if (op == SSA_OP_AND) { emit("    and ", 8); }
    else if (op == SSA_OP_OR) { emit("    or ", 7); }
    else { emit("    xor ", 8); }

    _ssa_emit_reg_name(dest);
    emit(", ", 2);
    _ssa_emit_opr(src2);
    emit_nl();
    return 0;
}

func _ssa_emit_shift(op: u64, dest: u64, src1: u64, src2: u64) -> u64 {
    var save_rcx: u64 = 0;
    var save_rax: u64 = 0;


    if (ssa_operand_is_const(src2) != 0) {
        _ssa_emit_mov_reg_opr(dest, src1);
        if (op == SSA_OP_SHL) { emit("    shl ", 8); }
        else { emit("    shr ", 8); }
        _ssa_emit_reg_name(dest);
        emit(", ", 2);
        _ssa_emit_imm(ssa_operand_value(src2));
        emit_nl();
        return 0;
    }
    if (ssa_operand_is_const(src2) != 0) {
        _ssa_emit_mov_reg_opr(dest, src1);
        if (op == SSA_OP_SHL) { emit("    shl ", 8); }
        else { emit("    shr ", 8); }
        _ssa_emit_reg_name(dest);
        emit(", ", 2);
        _ssa_emit_opr(src2);
        emit_nl();
        return 0;
    }

    if (dest == SSA_PHYS_RCX) {
        emit("    push rax\n", 14);
        save_rax = 1;
        _ssa_emit_mov_reg_opr(SSA_PHYS_RAX, src1);
        emit("    mov rcx, ", 13);
        _ssa_emit_reg_name(ssa_operand_value(src2));
        emit_nl();
        if (op == SSA_OP_SHL) { emit("    shl rax, cl\n", 16); }
        else { emit("    shr rax, cl\n", 16); }
        emit("    mov rcx, rax\n", 18);
        if (save_rax != 0) { emit("    pop rax\n", 13); }
        return 0;
    }

    emit("    push rcx\n", 14);
    save_rcx = 1;
    _ssa_emit_mov_reg_opr(dest, src1);
    emit("    mov rcx, ", 13);
    _ssa_emit_reg_name(ssa_operand_value(src2));
    emit_nl();
    if (op == SSA_OP_SHL) { emit("    shl ", 8); }
    else { emit("    shr ", 8); }
    _ssa_emit_reg_name(dest);
    emit(", cl\n", 5);
    if (save_rcx != 0) { emit("    pop rcx\n", 13); }
    return 0;
}

func _ssa_emit_mod(dest: u64, src1: u64, src2: u64) -> u64 {
    var save_rax: u64 = 0;
    var save_rdx: u64 = 0;
    var save_rcx: u64 = 0;

    if (dest != SSA_PHYS_RAX) {
        emit("    push rax\n", 14);
        save_rax = 1;
    }
    if (dest != SSA_PHYS_RDX) {
        emit("    push rdx\n", 14);
        save_rdx = 1;
    }

    _ssa_emit_mov_reg_opr(SSA_PHYS_RAX, src1);
    emit("    cqo\n", 8);

    if (ssa_operand_is_const(src2) != 0) {
        if (dest != SSA_PHYS_RCX) {
            emit("    push rcx\n", 14);
            save_rcx = 1;
        }
        _ssa_emit_mov_reg_opr(SSA_PHYS_RCX, src2);
        emit("    idiv rcx\n", 14);
    } else {
        emit("    idiv ", 9);
        _ssa_emit_reg_name(ssa_operand_value(src2));
        emit_nl();
    }

    if (dest != SSA_PHYS_RDX) {
        emit("    mov ", 8);
        _ssa_emit_reg_name(dest);
        emit(", rdx\n", 6);
    }

    if (save_rcx != 0) { emit("    pop rcx\n", 13); }
    if (save_rdx != 0) { emit("    pop rdx\n", 13); }
    if (save_rax != 0) { emit("    pop rax\n", 13); }

    return 0;
}

func _ssa_emit_cmp_setcc(cc_ptr: u64, cc_len: u64, dest: u64, src1: u64, src2: u64) -> u64 {
    var saved_rax: u64 = 0;
    if (dest != SSA_PHYS_RAX) {
        emit("    push rax\n", 14);
        saved_rax = 1;
    }

    if (ssa_operand_is_const(src1) != 0) {
        _ssa_emit_mov_reg_opr(SSA_PHYS_RAX, src1);
        emit("    cmp rax, ", 13);
        _ssa_emit_opr(src2);
        emit_nl();
    } else {
        emit("    cmp ", 8);
        _ssa_emit_reg_name(ssa_operand_value(src1));
        emit(", ", 2);
        _ssa_emit_opr(src2);
        emit_nl();
    }

    emit("    set", 7);
    emit(cc_ptr, cc_len);
    emit(" al\n", 4);

    emit("    movzx ", 10);
    _ssa_emit_reg_name(dest);
    emit(", al\n", 6);

    if (saved_rax != 0) {
        emit("    pop rax\n", 13);
    }
    return 0;
}

func _ssa_emit_div(dest: u64, src1: u64, src2: u64) -> u64 {
    var save_rax: u64 = 0;
    var save_rdx: u64 = 0;
    var save_rcx: u64 = 0;

    if (dest != SSA_PHYS_RAX) {
        emit("    push rax\n", 14);
        save_rax = 1;
    }
    if (dest != SSA_PHYS_RDX) {
        emit("    push rdx\n", 14);
        save_rdx = 1;
    }

    _ssa_emit_mov_reg_opr(SSA_PHYS_RAX, src1);
    emit("    cqo\n", 8);

    if (ssa_operand_is_const(src2) != 0) {
        if (dest != SSA_PHYS_RCX) {
            emit("    push rcx\n", 14);
            save_rcx = 1;
        }
        _ssa_emit_mov_reg_opr(SSA_PHYS_RCX, src2);
        emit("    idiv rcx\n", 14);
    } else {
        emit("    idiv ", 9);
        _ssa_emit_reg_name(ssa_operand_value(src2));
        emit_nl();
    }

    if (dest != SSA_PHYS_RAX) {
        emit("    mov ", 8);
        _ssa_emit_reg_name(dest);
        emit(", rax\n", 6);
    }

    if (save_rcx != 0) { emit("    pop rcx\n", 13); }
    if (save_rdx != 0) { emit("    pop rdx\n", 13); }
    if (save_rax != 0) { emit("    pop rax\n", 13); }

    return 0;
}

// ============================================
// 제어 흐름/리턴 코드 생성
// ============================================

func _ssa_emit_br(fn_id: u64, inst: *SSAInstruction) -> u64 {
    var false_id: u64 = ssa_operand_value(inst->dest);
    var true_id: u64 = ssa_operand_value(inst->src2);

    if (ssa_operand_is_const(inst->src1) != 0) {
        var c: u64 = ssa_operand_value(inst->src1);
        if (c != 0) {
            emit("    jmp ", 8);
            _ssa_emit_label_ref(fn_id, true_id);
            emit_nl();
        } else {
            emit("    jmp ", 8);
            _ssa_emit_label_ref(fn_id, false_id);
            emit_nl();
        }
        return 0;
    }

    emit("    cmp ", 8);
    _ssa_emit_reg_name(ssa_operand_value(inst->src1));
    emit(", 0\n", 4);
    emit("    jne ", 8);
    _ssa_emit_label_ref(fn_id, true_id);
    emit_nl();
    emit("    jmp ", 8);
    _ssa_emit_label_ref(fn_id, false_id);
    emit_nl();
    return 0;
}

func _ssa_emit_jmp(fn_id: u64, inst: *SSAInstruction) -> u64 {
    var target_id: u64 = ssa_operand_value(inst->src1);
    emit("    jmp ", 8);
    _ssa_emit_label_ref(fn_id, target_id);
    emit_nl();
    return 0;
}

func _ssa_emit_ret(inst: *SSAInstruction) -> u64 {
    if (inst->src1 == 0) {
        emit("    xor eax, eax\n", 18);
    } else {
        if (ssa_operand_is_const(inst->src1) != 0) {
            _ssa_emit_mov_reg_opr(SSA_PHYS_RAX, inst->src1);
        } else {
            var r: u64 = ssa_operand_value(inst->src1);
            if (r != SSA_PHYS_RAX) {
                emit("    mov rax, ", 13);
                _ssa_emit_reg_name(r);
                emit_nl();
            }
        }
    }

    emit("    mov rsp, rbp\n", 20);
    emit("    pop rbp\n", 13);
    emit("    ret\n", 9);
    return 0;
}

// ============================================
// 명령어 디스패치
// ============================================

func _ssa_emit_inst(fn_id: u64, inst: *SSAInstruction) -> u64 {
    push_trace("_ssa_emit_inst", "ssa_codegen.b", __LINE__);
    pop_trace();
    var op: u64 = ssa_inst_get_op(inst);

    if (op == SSA_OP_NOP || op == SSA_OP_ENTRY || op == SSA_OP_PHI) { return 0; }

    if (op == SSA_OP_CONST) {
        _ssa_emit_mov_reg_opr(inst->dest, inst->src1);
        return 0;
    }

    if (op == SSA_OP_COPY) {
        _ssa_emit_mov_reg_opr(inst->dest, inst->src1);
        return 0;
    }

    if (op == SSA_OP_LEA_STR) {
        var info_ptr: u64 = ssa_operand_value(inst->src1);
        var str_ptr: u64 = *(info_ptr);
        var str_len: u64 = *(info_ptr + 8);
        var label_id: u64 = string_get_label(str_ptr, str_len);
        emit("    lea ", 8);
        _ssa_emit_reg_name(inst->dest);
        emit(", [rel _str", 12);
        emit_u64(label_id);
        emit("]\n", 2);
        return 0;
    }

    if (op == SSA_OP_LEA_LOCAL) {
        var offset: u64 = ssa_operand_value(inst->src1);
        _ssa_emit_lea_local(inst->dest, offset);
        return 0;
    }

    if (op == SSA_OP_LEA_GLOBAL) {
        var info_ptr2: u64 = ssa_operand_value(inst->src1);
        var name_ptr: u64 = *(info_ptr2);
        var name_len: u64 = *(info_ptr2 + 8);
        _ssa_emit_lea_global(inst->dest, name_ptr, name_len);
        return 0;
    }

    if (op == SSA_OP_LEA_FUNC) {
        var info_ptr2b: u64 = ssa_operand_value(inst->src1);
        var name_ptr2: u64 = *(info_ptr2b);
        var name_len2: u64 = *(info_ptr2b + 8);
        _ssa_emit_lea_func(inst->dest, name_ptr2, name_len2);
        return 0;
    }

    if (op == SSA_OP_PARAM) {
        var idx: u64 = ssa_operand_value(inst->src1);
        var offset: u64 = 16 + idx * 8;
        emit("    mov ", 8);
        _ssa_emit_reg_name(inst->dest);
        emit(", [rbp+", 7);
        emit_u64(offset);
        emit("]\n", 2);
        return 0;
    }

    if (op == SSA_OP_CALL) {
        var info_ptr3: u64 = ssa_operand_value(inst->src1);
        _ssa_emit_call(inst->dest, info_ptr3);
        return 0;
    }

    if (op == SSA_OP_CALL_PTR) {
        var info_ptr3b: u64 = ssa_operand_value(inst->src1);
        _ssa_emit_call_ptr(inst->dest, info_ptr3b);
        return 0;
    }

    if (op == SSA_OP_LOAD8 || op == SSA_OP_LOAD16 || op == SSA_OP_LOAD32 || op == SSA_OP_LOAD64) {
        _ssa_emit_load(op, inst->dest, inst->src1);
        return 0;
    }

    if (op == SSA_OP_STORE8 || op == SSA_OP_STORE16 || op == SSA_OP_STORE32 || op == SSA_OP_STORE64) {
        _ssa_emit_store(op, inst->src1, inst->src2);
        return 0;
    }

    if (op == SSA_OP_ADD || op == SSA_OP_SUB || op == SSA_OP_MUL || op == SSA_OP_AND || op == SSA_OP_OR || op == SSA_OP_XOR) {
        _ssa_emit_binop(op, inst->dest, inst->src1, inst->src2);
        return 0;
    }

    if (op == SSA_OP_DIV) {
        _ssa_emit_div(inst->dest, inst->src1, inst->src2);
        return 0;
    }

    if (op == SSA_OP_MOD) {
        _ssa_emit_mod(inst->dest, inst->src1, inst->src2);
        return 0;
    }

    if (op == SSA_OP_SHL || op == SSA_OP_SHR) {
        _ssa_emit_shift(op, inst->dest, inst->src1, inst->src2);
        return 0;
    }

    if (op == SSA_OP_EQ) {
        _ssa_emit_cmp_setcc("e", 1, inst->dest, inst->src1, inst->src2);
        return 0;
    }
    if (op == SSA_OP_NE) {
        _ssa_emit_cmp_setcc("ne", 2, inst->dest, inst->src1, inst->src2);
        return 0;
    }
    if (op == SSA_OP_LT) {
        _ssa_emit_cmp_setcc("l", 1, inst->dest, inst->src1, inst->src2);
        return 0;
    }
    if (op == SSA_OP_GT) {
        _ssa_emit_cmp_setcc("g", 1, inst->dest, inst->src1, inst->src2);
        return 0;
    }
    if (op == SSA_OP_LE) {
        _ssa_emit_cmp_setcc("le", 2, inst->dest, inst->src1, inst->src2);
        return 0;
    }
    if (op == SSA_OP_GE) {
        _ssa_emit_cmp_setcc("ge", 2, inst->dest, inst->src1, inst->src2);
        return 0;
    }

    if (op == SSA_OP_BR) { return _ssa_emit_br(fn_id, inst); }
    if (op == SSA_OP_JMP) { return _ssa_emit_jmp(fn_id, inst); }
    if (op == SSA_OP_RET) { return _ssa_emit_ret(inst); }

    return 0;
}

// ============================================
// 엔트리 포인트
// ============================================

func ssa_codegen_emit_func(fn_ptr: u64, ssa_fn_ptr: u64) -> u64 {
    push_trace("ssa_codegen_emit_func", "ssa_codegen.b", __LINE__);
    pop_trace();
    if (fn_ptr == 0 || ssa_fn_ptr == 0) { return 0; }
    var fn: *AstFunc = (*AstFunc)fn_ptr;
    var ssa_fn: *SSAFunction = (*SSAFunction)ssa_fn_ptr;

    if (SSA_CODEGEN_DEBUG != 0) {
        println("[DEBUG] ssa_codegen_emit_func: enter", 36);
    }

    set_current_module_for_func(fn->name_ptr, fn->name_len);
    emitter_set_ret_type(fn->ret_type);
    emitter_set_ret_ptr_depth(fn->ret_ptr_depth);
    emitter_set_ret_struct_name(fn->ret_struct_name_ptr, fn->ret_struct_name_len);

    var g_symtab: u64 = emitter_get_symtab();
    symtab_clear(g_symtab);

    emit(fn->name_ptr, fn->name_len);
    emit(":\n", 2);
    emit("    push rbp\n", 14);
    emit("    mov rbp, rsp\n", 19);
    emit("    sub rsp, 1024\n", 21);

    var blocks: u64 = ssa_fn->blocks_data;
    var bcount: u64 = ssa_fn->blocks_len;
    var bi: u64 = 0;
    while (bi < bcount) {
        var b_ptr: u64 = *(*u64)(blocks + bi * 8);
        var b: *SSABlock = (*SSABlock)b_ptr;

        _ssa_emit_label_def(ssa_fn->id, b->id);

        var phi: *SSAInstruction = b->phi_head;
        while (phi != 0) {
            phi = phi->next;
        }

        var cur: *SSAInstruction = b->inst_head;
        while (cur != 0) {
            _ssa_emit_inst(ssa_fn->id, cur);
            cur = cur->next;
        }

        bi = bi + 1;
    }

    emit("    xor eax, eax\n", 18);
    emit("    mov rsp, rbp\n", 20);
    emit("    pop rbp\n", 13);
    emit("    ret\n", 9);

    if (SSA_CODEGEN_DEBUG != 0) {
        println("[DEBUG] ssa_codegen_emit_func: done", 35);
    }

    return 0;
}
