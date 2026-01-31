// ssa_dump.b - SSA/3addr 텍스트 덤프 (v3_17)

import std.io;
import std.util;
import std.vec;
import ssa.datastruct;
import ssa.core;

func _ssa_dump_op_name(op: u64) -> u64 {
    push_trace("_ssa_dump_op_name", "ssa_dump.b", __LINE__);
    if (op == SSA_OP_NOP) { emit("nop", 3); pop_trace(); return 0; }
    if (op == SSA_OP_ENTRY) { emit("entry", 5); pop_trace(); return 0; }
    if (op == SSA_OP_PHI) { emit("phi", 3); pop_trace(); return 0; }
    if (op == SSA_OP_CONST) { emit("const", 5); pop_trace(); return 0; }
    if (op == SSA_OP_ADD) { emit("add", 3); pop_trace(); return 0; }
    if (op == SSA_OP_SUB) { emit("sub", 3); pop_trace(); return 0; }
    if (op == SSA_OP_MUL) { emit("mul", 3); pop_trace(); return 0; }
    if (op == SSA_OP_DIV) { emit("div", 3); pop_trace(); return 0; }
    if (op == SSA_OP_EQ) { emit("eq", 2); pop_trace(); return 0; }
    if (op == SSA_OP_NE) { emit("ne", 2); pop_trace(); return 0; }
    if (op == SSA_OP_LT) { emit("lt", 2); pop_trace(); return 0; }
    if (op == SSA_OP_GT) { emit("gt", 2); pop_trace(); return 0; }
    if (op == SSA_OP_LE) { emit("le", 2); pop_trace(); return 0; }
    if (op == SSA_OP_GE) { emit("ge", 2); pop_trace(); return 0; }
    if (op == SSA_OP_MOD) { emit("mod", 3); pop_trace(); return 0; }
    if (op == SSA_OP_AND) { emit("and", 3); pop_trace(); return 0; }
    if (op == SSA_OP_OR) { emit("or", 2); pop_trace(); return 0; }
    if (op == SSA_OP_XOR) { emit("xor", 3); pop_trace(); return 0; }
    if (op == SSA_OP_SHL) { emit("shl", 3); pop_trace(); return 0; }
    if (op == SSA_OP_SHR) { emit("shr", 3); pop_trace(); return 0; }
    if (op == SSA_OP_LOAD) { emit("load", 4); pop_trace(); return 0; }
    if (op == SSA_OP_STORE) { emit("store", 5); pop_trace(); return 0; }
    if (op == SSA_OP_PARAM) { emit("param", 5); pop_trace(); return 0; }
    if (op == SSA_OP_CALL) { emit("call", 4); pop_trace(); return 0; }
    if (op == SSA_OP_CALL_PTR) { emit("call_ptr", 8); pop_trace(); return 0; }
    if (op == SSA_OP_JMP) { emit("jmp", 3); pop_trace(); return 0; }
    if (op == SSA_OP_BR) { emit("br", 2); pop_trace(); return 0; }
    if (op == SSA_OP_RET) { emit("ret", 3); pop_trace(); return 0; }
    if (op == SSA_OP_RET_SLICE_HEAP) { emit("ret_slice_heap", 14); pop_trace(); return 0; }
    if (op == SSA_OP_COPY) { emit("copy", 4); pop_trace(); return 0; }
    if (op == SSA_OP_LEA_STR) { emit("lea_str", 7); pop_trace(); return 0; }
    if (op == SSA_OP_LEA_LOCAL) { emit("lea_local", 9); pop_trace(); return 0; }
    if (op == SSA_OP_LEA_GLOBAL) { emit("lea_global", 10); pop_trace(); return 0; }
    if (op == SSA_OP_LEA_FUNC) { emit("lea_func", 8); pop_trace(); return 0; }
    if (op == SSA_OP_LOAD8) { emit("load8", 5); pop_trace(); return 0; }
    if (op == SSA_OP_LOAD16) { emit("load16", 6); pop_trace(); return 0; }
    if (op == SSA_OP_LOAD32) { emit("load32", 6); pop_trace(); return 0; }
    if (op == SSA_OP_LOAD64) { emit("load64", 6); pop_trace(); return 0; }
    if (op == SSA_OP_STORE8) { emit("store8", 6); pop_trace(); return 0; }
    if (op == SSA_OP_STORE16) { emit("store16", 7); pop_trace(); return 0; }
    if (op == SSA_OP_STORE32) { emit("store32", 7); pop_trace(); return 0; }
    if (op == SSA_OP_STORE64) { emit("store64", 7); pop_trace(); return 0; }
    if (op == SSA_OP_STORE_SLICE) { emit("store_slice", 11); pop_trace(); return 0; }
    if (op == SSA_OP_ASM) { emit("asm", 3); pop_trace(); return 0; }
    if (op == SSA_OP_CALL_SLICE_STORE) { emit("call_slice_store", 16); pop_trace(); return 0; }
    emit("op", 2);
    pop_trace();
    return 0;
}

func _ssa_dump_operand(opr: u64) -> u64 {
    push_trace("_ssa_dump_operand", "ssa_dump.b", __LINE__);
    if (ssa_operand_is_const(opr) != 0) {
        emit("#", 1);
        emit_u64(ssa_operand_value(opr));
        pop_trace();
        return 0;
    }
    emit("r", 1);
    emit_u64(ssa_operand_value(opr));
    pop_trace();
    return 0;
}

func _ssa_dump_inst(inst: *SSAInstruction) -> u64 {
    push_trace("_ssa_dump_inst", "ssa_dump.b", __LINE__);
    var op: u64 = ssa_inst_get_op(inst);
    if (op == SSA_OP_NOP || op == SSA_OP_ENTRY) { pop_trace(); return 0; }

    if (op == SSA_OP_RET) {
        emit("  ret ", 6);
        if (inst->src1 != 0) {
            _ssa_dump_operand(inst->src1);
        }
        if (inst->src2 != 0) {
            emit(", ", 2);
            _ssa_dump_operand(inst->src2);
        }
        emit_nl();
        pop_trace();
        return 0;
    }
    if (op == SSA_OP_RET_SLICE_HEAP) {
        emit("  ret_slice_heap ", 17);
        if (inst->dest != 0) {
            _ssa_dump_operand(inst->dest);
        }
        emit(", ", 2);
        _ssa_dump_operand(inst->src1);
        emit(", ", 2);
        _ssa_dump_operand(inst->src2);
        emit_nl();
        pop_trace();
        return 0;
    }

    if (op == SSA_OP_JMP) {
        emit("  jmp b", 7);
        emit_u64(ssa_operand_value(inst->src1));
        emit_nl();
        pop_trace();
        return 0;
    }

    if (op == SSA_OP_BR) {
        emit("  br ", 5);
        _ssa_dump_operand(inst->src1);
        emit(" ? b", 4);
        emit_u64(ssa_operand_value(inst->src2));
        emit(" : b", 4);
        emit_u64(ssa_operand_value(inst->dest));
        emit_nl();
        pop_trace();
        return 0;
    }

    if (op == SSA_OP_CALL_PTR) {
        var info_ptr2: u64 = ssa_operand_value(inst->src1);
        var info2: *SSACallPtrInfo = (*SSACallPtrInfo)info_ptr2;
        var callee_reg: u64 = info2->callee_reg;
        var args_vec2: u64 = info2->args_vec;
        var nargs2: u64 = info2->nargs;
        if (nargs2 == 0 && args_vec2 != 0) { nargs2 = vec_len(args_vec2); }
        emit("  r", 3);
        emit_u64(inst->dest);
        if (inst->src2 != 0 && ssa_operand_is_const(inst->src2) == 0) {
            emit(", r", 3);
            emit_u64(ssa_operand_value(inst->src2));
        }
        emit(" = call_ptr r", 13);
        emit_u64(callee_reg);
        emit("(", 1);
        for (var i2: u64 = 0; i2 < nargs2; i2++) {
            if (i2 > 0) { emit(", ", 2); }
            emit("r", 1);
            emit_u64(vec_get(args_vec2, i2));
        }
        emit(")\n", 2);
        pop_trace();
        return 0;
    }

    if (op == SSA_OP_CALL_SLICE_STORE) {
        var info_ptrs: u64 = ssa_operand_value(inst->src1);
        var info_s: *SSACallSliceStoreInfo = (*SSACallSliceStoreInfo)info_ptrs;
        if (info_s->is_ptr > 1) {
            var info_call: *SSACallInfo = (*SSACallInfo)info_ptrs;
            var name_ptrs: u64 = info_call->name_ptr;
            var name_lens: u64 = info_call->name_len;
            var args_vecs: u64 = info_call->args_vec;
            var nargss: u64 = info_call->nargs;
            if (nargss == 0 && args_vecs != 0) { nargss = vec_len(args_vecs); }
            emit("  call_slice_store ", 20);
            emit(name_ptrs, name_lens);
            emit("(", 1);
            for (var is: u64 = 0; is < nargss; is++) {
                if (is > 0) { emit(", ", 2); }
                emit("r", 1);
                emit_u64(vec_get(args_vecs, is));
            }
            emit(")\n", 2);
        } else {
            var args_vecs2: u64 = info_s->args_vec;
            var nargss2: u64 = info_s->nargs;
            if (nargss2 == 0 && args_vecs2 != 0) { nargss2 = vec_len(args_vecs2); }
            emit("  call_slice_store ", 20);
            if (info_s->is_ptr != 0) {
                emit("r", 1);
                emit_u64(info_s->callee_reg);
            } else {
                emit(info_s->name_ptr, info_s->name_len);
            }
            emit("(", 1);
            for (var is2: u64 = 0; is2 < nargss2; is2++) {
                if (is2 > 0) { emit(", ", 2); }
                emit("r", 1);
                emit_u64(vec_get(args_vecs2, is2));
            }
            emit(")\n", 2);
        }
        pop_trace();
        return 0;
    }

    if (op == SSA_OP_CALL) {
        var info_ptr: u64 = ssa_operand_value(inst->src1);
        var info: *SSACallInfo = (*SSACallInfo)info_ptr;
        var name_ptr: u64 = info->name_ptr;
        var name_len: u64 = info->name_len;
        var args_vec: u64 = info->args_vec;
        var nargs: u64 = info->nargs;
        if (nargs == 0 && args_vec != 0) { nargs = vec_len(args_vec); }
        emit("  r", 3);
        emit_u64(inst->dest);
        if (inst->src2 != 0 && ssa_operand_is_const(inst->src2) == 0) {
            emit(", r", 3);
            emit_u64(ssa_operand_value(inst->src2));
        }
        emit(" = call ", 8);
        emit(name_ptr, name_len);
        emit("(", 1);
        for (var i: u64 = 0; i < nargs; i++) {
            if (i > 0) { emit(", ", 2); }
            emit("r", 1);
            emit_u64(vec_get(args_vec, i));
        }
        emit(")\n", 2);
        pop_trace();
        return 0;
    }

    emit("  r", 3);
    emit_u64(inst->dest);
    emit(" = ", 3);
    _ssa_dump_op_name(op);

    if (op == SSA_OP_CONST || op == SSA_OP_COPY || op == SSA_OP_PARAM) {
        emit(" ", 1);
        _ssa_dump_operand(inst->src1);
        emit_nl();
        pop_trace();
        return 0;
    }

    if (op == SSA_OP_LOAD || op == SSA_OP_STORE) {
        emit(" ", 1);
        _ssa_dump_operand(inst->src1);
        if (op == SSA_OP_STORE) {
            emit(", ", 2);
            _ssa_dump_operand(inst->src2);
        }
        emit_nl();
        pop_trace();
        return 0;
    }

    if (op == SSA_OP_STORE_SLICE) {
        emit(" ", 1);
        _ssa_dump_operand(inst->src1);
        emit_nl();
        pop_trace();
        return 0;
    }

    emit(" ", 1);
    _ssa_dump_operand(inst->src1);
    emit(", ", 2);
    _ssa_dump_operand(inst->src2);
    emit_nl();
    pop_trace();
    return 0;
}

func _ssa_dump_phi(phi: *SSAInstruction) -> u64 {
    push_trace("_ssa_dump_phi", "ssa_dump.b", __LINE__);
    emit("  r", 3);
    emit_u64(phi->dest);
    emit(" = phi", 6);
    var arg: *SSAPhiArg = (*SSAPhiArg)phi->src1;
    while (arg != 0) {
        emit(" (b", 3);
        emit_u64(arg->block_id);
        emit(", r", 3);
        emit_u64(arg->val);
        emit(")", 1);
        arg = arg->next;
    }
    emit_nl();
    pop_trace();
    return 0;
}

func ssa_dump_ctx(ctx: *SSAContext, with_phi: u64) -> u64 {
    push_trace("ssa_dump_ctx", "ssa_dump.b", __LINE__);
    if (ctx == 0) { pop_trace(); return 0; }
    var funcs: u64 = ctx->funcs_data;
    var n: u64 = ctx->funcs_len;
    var funcs_u64: *u64 = (*u64)funcs;
    for (var i: u64 = 0; i < n; i++) {
        var f_ptr: u64 = *(funcs_u64 + i);
        var fn: *SSAFunction = (*SSAFunction)f_ptr;

        emit("func ", 5);
        emit(fn->name_ptr, fn->name_len);
        emit_nl();

        var blocks: u64 = fn->blocks_data;
        var bcount: u64 = fn->blocks_len;
        var blocks_u64: *u64 = (*u64)blocks;
        for (var bi: u64 = 0; bi < bcount; bi++) {
            var b_ptr: u64 = *(blocks_u64 + bi);
            var b: *SSABlock = (*SSABlock)b_ptr;

            emit("b", 1);
            emit_u64(b->id);
            emit(":\n", 2);

            if (with_phi != 0) {
                var phi: *SSAInstruction = b->phi_head;
                while (phi != 0) {
                    _ssa_dump_phi(phi);
                    phi = phi->next;
                }
            }

            var cur: *SSAInstruction = b->inst_head;
            while (cur != 0) {
                _ssa_dump_inst(cur);
                cur = cur->next;
            }

        }
    }
    pop_trace();
    return 0;
}
