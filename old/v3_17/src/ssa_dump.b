// ssa_dump.b - SSA/3addr 텍스트 덤프 (v3_17)

import std.io;
import std.util;
import ssa;

func _ssa_dump_op_name(op: u64) -> u64 {
    if (op == SSA_OP_NOP) { emit("nop", 3); return 0; }
    if (op == SSA_OP_ENTRY) { emit("entry", 5); return 0; }
    if (op == SSA_OP_PHI) { emit("phi", 3); return 0; }
    if (op == SSA_OP_CONST) { emit("const", 5); return 0; }
    if (op == SSA_OP_ADD) { emit("add", 3); return 0; }
    if (op == SSA_OP_SUB) { emit("sub", 3); return 0; }
    if (op == SSA_OP_MUL) { emit("mul", 3); return 0; }
    if (op == SSA_OP_DIV) { emit("div", 3); return 0; }
    if (op == SSA_OP_EQ) { emit("eq", 2); return 0; }
    if (op == SSA_OP_NE) { emit("ne", 2); return 0; }
    if (op == SSA_OP_LT) { emit("lt", 2); return 0; }
    if (op == SSA_OP_GT) { emit("gt", 2); return 0; }
    if (op == SSA_OP_LE) { emit("le", 2); return 0; }
    if (op == SSA_OP_GE) { emit("ge", 2); return 0; }
    if (op == SSA_OP_LOAD) { emit("load", 4); return 0; }
    if (op == SSA_OP_STORE) { emit("store", 5); return 0; }
    if (op == SSA_OP_PARAM) { emit("param", 5); return 0; }
    if (op == SSA_OP_JMP) { emit("jmp", 3); return 0; }
    if (op == SSA_OP_BR) { emit("br", 2); return 0; }
    if (op == SSA_OP_RET) { emit("ret", 3); return 0; }
    if (op == SSA_OP_COPY) { emit("copy", 4); return 0; }
    emit("op", 2);
    return 0;
}

func _ssa_dump_operand(opr: u64) -> u64 {
    if (ssa_operand_is_const(opr) != 0) {
        emit("#", 1);
        emit_u64(ssa_operand_value(opr));
        return 0;
    }
    emit("r", 1);
    emit_u64(ssa_operand_value(opr));
    return 0;
}

func _ssa_dump_inst(inst: *SSAInstruction) -> u64 {
    var op: u64 = ssa_inst_get_op(inst);
    if (op == SSA_OP_NOP || op == SSA_OP_ENTRY) { return 0; }

    if (op == SSA_OP_RET) {
        emit("  ret ", 6);
        if (inst->src1 != 0) {
            _ssa_dump_operand(inst->src1);
        }
        emit_nl();
        return 0;
    }

    if (op == SSA_OP_JMP) {
        emit("  jmp b", 7);
        emit_u64(ssa_operand_value(inst->src1));
        emit_nl();
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
        return 0;
    }

    emit(" ", 1);
    _ssa_dump_operand(inst->src1);
    emit(", ", 2);
    _ssa_dump_operand(inst->src2);
    emit_nl();
    return 0;
}

func _ssa_dump_phi(phi: *SSAInstruction) -> u64 {
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
    return 0;
}

func ssa_dump_ctx(ctx: *SSAContext, with_phi: u64) -> u64 {
    if (ctx == 0) { return 0; }
    var funcs: u64 = ctx->funcs_data;
    var n: u64 = ctx->funcs_len;
    var i: u64 = 0;
    while (i < n) {
        var f_ptr: u64 = *(*u64)(funcs + i * 8);
        var fn: *SSAFunction = (*SSAFunction)f_ptr;

        emit("func ", 5);
        emit(fn->name_ptr, fn->name_len);
        emit_nl();

        var blocks: u64 = fn->blocks_data;
        var bcount: u64 = fn->blocks_len;
        var bi: u64 = 0;
        while (bi < bcount) {
            var b_ptr: u64 = *(*u64)(blocks + bi * 8);
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

            bi = bi + 1;
        }

        i = i + 1;
    }
    return 0;
}
