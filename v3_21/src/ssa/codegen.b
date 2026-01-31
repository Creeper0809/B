// ssa_codegen.b - SSA → x86-64 코드 생성 (v3_17)
//
// 주의:
// - SSA 빌더가 지원하는 최소 부분집합만 대상으로 한다.
// - 매개변수/글로벌 접근/복잡한 AST는 기존 코드젠으로 폴백한다.

import std.io;
import std.vec;
import std.util;
import std.str;
import types;
import ast;
import ssa.datastruct;
import ssa.core;
import ssa.regalloc;
import emitter.emitter;
import emitter.symtab;
import emitter.typeinfo;
import compiler;

const SSA_CODEGEN_DEBUG = 0;

var g_live_mask_map;
var g_last_lea_local_off;
var g_last_lea_local_valid;

const SSA_LIVE_RAX = 1;
const SSA_LIVE_RBX = 2;
const SSA_LIVE_RCX = 4;
const SSA_LIVE_RDX = 8;
const SSA_LIVE_R8  = 16;
const SSA_LIVE_R9  = 32;
const SSA_LIVE_R10 = 64;
const SSA_LIVE_R11 = 128;

func _ssa_live_all_mask() -> u64 {
    return SSA_LIVE_RAX | SSA_LIVE_RBX | SSA_LIVE_RCX | SSA_LIVE_RDX | SSA_LIVE_R8 | SSA_LIVE_R9 | SSA_LIVE_R10 | SSA_LIVE_R11;
}

func _ssa_phys_mask(phys: u64) -> u64 {
    if (phys == SSA_PHYS_RAX) { return SSA_LIVE_RAX; }
    if (phys == SSA_PHYS_RBX) { return SSA_LIVE_RBX; }
    if (phys == SSA_PHYS_RCX) { return SSA_LIVE_RCX; }
    if (phys == SSA_PHYS_RDX) { return SSA_LIVE_RDX; }
    if (phys == SSA_PHYS_R8) { return SSA_LIVE_R8; }
    if (phys == SSA_PHYS_R9) { return SSA_LIVE_R9; }
    if (phys == SSA_PHYS_R10) { return SSA_LIVE_R10; }
    if (phys == SSA_PHYS_R11) { return SSA_LIVE_R11; }
    return 0;
}

func _ssa_operand_use_mask(opr: u64) -> u64 {
    if (opr == 0) { return 0; }
    if (ssa_operand_is_const(opr) != 0) { return 0; }
    return _ssa_phys_mask(ssa_operand_value(opr));
}

func _ssa_block_index(blocks: u64, bcount: u64, id: u64) -> u64 {
    for (var i: u64 = 0; i < bcount; i++) {
        var b_ptr: u64 = *(*u64)(blocks + i * 8);
        var b: *SSABlock = (*SSABlock)b_ptr;
        if (b->id == id) { return i + 1; }
    }
    return 0;
}

func _ssa_phi_use_mask(block: *SSABlock) -> u64 {
    var mask: u64 = 0;
    var phi: *SSAInstruction = block->phi_head;
    while (phi != 0) {
        var args: *SSAPhiArg = (*SSAPhiArg)phi->src1;
        while (args != 0) {
            mask = mask | _ssa_phys_mask(args->val);
            args = args->next;
        }
        phi = phi->next;
    }
    return mask;
}

func _ssa_call_use_mask(info_ptr: u64) -> u64 {
    var mask: u64 = 0;
    var info: *SSACallInfo = (*SSACallInfo)info_ptr;
    var arg_regs: u64 = info->args_vec;
    var total_regs: u64 = info->nargs;
    if (total_regs == 0 && arg_regs != 0) { total_regs = vec_len(arg_regs); }
    for (var i: u64 = 0; i < total_regs; i++) {
        mask = mask | _ssa_phys_mask(vec_get(arg_regs, i));
    }
    return mask;
}

func _ssa_call_ptr_use_mask(info_ptr: u64) -> u64 {
    var mask: u64 = 0;
    var info: *SSACallPtrInfo = (*SSACallPtrInfo)info_ptr;
    var callee_reg: u64 = info->callee_reg;
    mask = mask | _ssa_phys_mask(callee_reg);
    var arg_regs: u64 = info->args_vec;
    var total_regs: u64 = info->nargs;
    if (total_regs == 0 && arg_regs != 0) { total_regs = vec_len(arg_regs); }
    for (var i: u64 = 0; i < total_regs; i++) {
        mask = mask | _ssa_phys_mask(vec_get(arg_regs, i));
    }
    return mask;
}

func _ssa_call_slice_store_use_mask(info_ptr: u64) -> u64 {
    var mask: u64 = 0;
    var info: *SSACallSliceStoreInfo = (*SSACallSliceStoreInfo)info_ptr;
    if (info->is_ptr > 1) {
        var info_call: *SSACallInfo = (*SSACallInfo)info_ptr;
        var arg_regs: u64 = info_call->args_vec;
        var total_regs: u64 = info_call->nargs;
        if (total_regs == 0 && arg_regs != 0) { total_regs = vec_len(arg_regs); }
        for (var i: u64 = 0; i < total_regs; i++) {
            mask = mask | _ssa_phys_mask(vec_get(arg_regs, i));
        }
    } else {
        if (info->is_ptr != 0) {
            mask = mask | _ssa_phys_mask(info->callee_reg);
        }
        var arg_regs: u64 = info->args_vec;
        var total_regs: u64 = info->nargs;
        if (total_regs == 0 && arg_regs != 0) { total_regs = vec_len(arg_regs); }
        for (var i: u64 = 0; i < total_regs; i++) {
            mask = mask | _ssa_phys_mask(vec_get(arg_regs, i));
        }
    }
    return mask;
}

func _ssa_inst_use_def_mask(inst: *SSAInstruction, use_out: u64, def_out: u64) -> u64 {
    var op: u64 = ssa_inst_get_op(inst);
    var use_mask: u64 = 0;
    var def_mask: u64 = 0;

    if (op == SSA_OP_PHI) {
        var args: *SSAPhiArg = (*SSAPhiArg)inst->src1;
        while (args != 0) {
            use_mask = use_mask | _ssa_phys_mask(args->val);
            args = args->next;
        }
        def_mask = _ssa_phys_mask(inst->dest);
        *(use_out) = use_mask;
        *(def_out) = def_mask;
        return 0;
    }

    if (op == SSA_OP_CALL) {
        use_mask = _ssa_call_use_mask(ssa_operand_value(inst->src1));
        if (inst->dest != 0) { def_mask = _ssa_phys_mask(inst->dest); }
        if (inst->src2 != 0 && ssa_operand_is_const(inst->src2) == 0) {
            def_mask = def_mask | _ssa_phys_mask(ssa_operand_value(inst->src2));
        }
        *(use_out) = use_mask;
        *(def_out) = def_mask;
        return 0;
    }

    if (op == SSA_OP_CALL_PTR) {
        use_mask = _ssa_call_ptr_use_mask(ssa_operand_value(inst->src1));
        if (inst->dest != 0) { def_mask = _ssa_phys_mask(inst->dest); }
        if (inst->src2 != 0 && ssa_operand_is_const(inst->src2) == 0) {
            def_mask = def_mask | _ssa_phys_mask(ssa_operand_value(inst->src2));
        }
        *(use_out) = use_mask;
        *(def_out) = def_mask;
        return 0;
    }

    if (op == SSA_OP_CALL_SLICE_STORE) {
        use_mask = _ssa_call_slice_store_use_mask(ssa_operand_value(inst->src1));
        use_mask = use_mask | _ssa_operand_use_mask(inst->src2);
        *(use_out) = use_mask;
        *(def_out) = def_mask;
        return 0;
    }

    if (op == SSA_OP_RET) {
        use_mask = _ssa_operand_use_mask(inst->src1) | _ssa_operand_use_mask(inst->src2);
        *(use_out) = use_mask;
        *(def_out) = def_mask;
        return 0;
    }
    if (op == SSA_OP_RET_SLICE_HEAP) {
        use_mask = _ssa_operand_use_mask(inst->src1) | _ssa_operand_use_mask(inst->src2);
        *(use_out) = use_mask;
        *(def_out) = def_mask;
        return 0;
    }

    if (op == SSA_OP_BR) {
        use_mask = _ssa_operand_use_mask(inst->src1);
        *(use_out) = use_mask;
        *(def_out) = def_mask;
        return 0;
    }

    if (op == SSA_OP_JMP) {
        *(use_out) = 0;
        *(def_out) = 0;
        return 0;
    }

    if (op == SSA_OP_ASM) {
        *(use_out) = 0;
        *(def_out) = 0;
        return 0;
    }

    use_mask = _ssa_operand_use_mask(inst->src1) | _ssa_operand_use_mask(inst->src2);
    if (inst->dest != 0) {
        def_mask = _ssa_phys_mask(inst->dest);
    }
    *(use_out) = use_mask;
    *(def_out) = def_mask;
    return 0;
}

func _ssa_emit_asm(text_vec: u64) -> u64 {
    if (text_vec == 0) { return 0; }
    var asm_len: u64 = vec_len(text_vec);
    var i: u64 = 0;
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
    return 0;
}

func _ssa_emit_asm_with_save(text_vec: u64, live_mask: u64) -> u64 {
    var all_mask: u64 = _ssa_live_all_mask();
    var save_mask: u64 = live_mask & all_mask;

    if ((save_mask & SSA_LIVE_RAX) != 0) { _ssa_emit_push_reg(SSA_PHYS_RAX); }
    if ((save_mask & SSA_LIVE_RBX) != 0) { _ssa_emit_push_reg(SSA_PHYS_RBX); }
    if ((save_mask & SSA_LIVE_RCX) != 0) { _ssa_emit_push_reg(SSA_PHYS_RCX); }
    if ((save_mask & SSA_LIVE_RDX) != 0) { _ssa_emit_push_reg(SSA_PHYS_RDX); }
    if ((save_mask & SSA_LIVE_R8) != 0) { _ssa_emit_push_reg(SSA_PHYS_R8); }
    if ((save_mask & SSA_LIVE_R9) != 0) { _ssa_emit_push_reg(SSA_PHYS_R9); }
    if ((save_mask & SSA_LIVE_R10) != 0) { _ssa_emit_push_reg(SSA_PHYS_R10); }
    if ((save_mask & SSA_LIVE_R11) != 0) { _ssa_emit_push_reg(SSA_PHYS_R11); }

    _ssa_emit_asm(text_vec);

    if ((save_mask & SSA_LIVE_R11) != 0) { _ssa_emit_restore_reg(0, SSA_PHYS_R11); }
    if ((save_mask & SSA_LIVE_R10) != 0) { _ssa_emit_restore_reg(0, SSA_PHYS_R10); }
    if ((save_mask & SSA_LIVE_R9) != 0) { _ssa_emit_restore_reg(0, SSA_PHYS_R9); }
    if ((save_mask & SSA_LIVE_R8) != 0) { _ssa_emit_restore_reg(0, SSA_PHYS_R8); }
    if ((save_mask & SSA_LIVE_RDX) != 0) { _ssa_emit_restore_reg(0, SSA_PHYS_RDX); }
    if ((save_mask & SSA_LIVE_RCX) != 0) { _ssa_emit_restore_reg(0, SSA_PHYS_RCX); }
    if ((save_mask & SSA_LIVE_RBX) != 0) { _ssa_emit_restore_reg(0, SSA_PHYS_RBX); }
    if ((save_mask & SSA_LIVE_RAX) != 0) { _ssa_emit_restore_reg(0, SSA_PHYS_RAX); }
    return 0;
}

func _ssa_ensure_heap_brk_global() -> u64 {
    var globals: u64 = emitter_get_globals();
    if (globals == 0) { return 0; }
    if (is_global_var("__cg_heap_brk", 13) != 0) { return 0; }
    var ginfo: *GlobalInfo = (*GlobalInfo)heap_alloc(sizeof(GlobalInfo));
    ginfo->name_ptr = "__cg_heap_brk";
    ginfo->name_len = 13;
    vec_push(globals, (u64)ginfo);
    return 0;
}

func _ssa_emit_call_slice_store(info_ptr: u64, addr_opr: u64, live_mask: u64) -> u64 {
    var info: *SSACallSliceStoreInfo = (*SSACallSliceStoreInfo)info_ptr;
    var is_ptr: u64 = info->is_ptr;
    var name_ptr: u64 = info->name_ptr;
    var name_len: u64 = info->name_len;
    var callee_reg: u64 = info->callee_reg;
    var args_vec: u64 = info->args_vec;
    var nargs: u64 = info->nargs;
    var ret_type: u64 = info->ret_type;
    var ret_ptr_depth: u64 = info->ret_ptr_depth;
    if (is_ptr > 1) {
        var info_call: *SSACallInfo = (*SSACallInfo)info_ptr;
        is_ptr = 0;
        name_ptr = info_call->name_ptr;
        name_len = info_call->name_len;
        callee_reg = 0;
        args_vec = info_call->args_vec;
        nargs = info_call->nargs;
        ret_type = info_call->ret_type;
        ret_ptr_depth = info_call->ret_ptr_depth;
    }
    if (nargs == 0 && args_vec != 0) { nargs = vec_len(args_vec); }

    var keep_rax: u64 = 0;
    var keep_rdx: u64 = 0;
    if (ret_type == TYPE_SLICE && ret_ptr_depth == 0) {
        keep_rax = 1;
        keep_rdx = 1;
    }

    var all_mask: u64 = _ssa_live_all_mask();
    var save_mask: u64 = live_mask & all_mask;
    if (keep_rax != 0) { save_mask = save_mask & (all_mask ^ SSA_LIVE_RAX); }
    if (keep_rdx != 0) { save_mask = save_mask & (all_mask ^ SSA_LIVE_RDX); }

    if ((save_mask & SSA_LIVE_RAX) != 0) { _ssa_emit_push_reg(SSA_PHYS_RAX); }
    if ((save_mask & SSA_LIVE_RBX) != 0) { _ssa_emit_push_reg(SSA_PHYS_RBX); }
    if ((save_mask & SSA_LIVE_RCX) != 0) { _ssa_emit_push_reg(SSA_PHYS_RCX); }
    if ((save_mask & SSA_LIVE_RDX) != 0) { _ssa_emit_push_reg(SSA_PHYS_RDX); }
    if ((save_mask & SSA_LIVE_R8) != 0) { _ssa_emit_push_reg(SSA_PHYS_R8); }
    if ((save_mask & SSA_LIVE_R9) != 0) { _ssa_emit_push_reg(SSA_PHYS_R9); }
    if ((save_mask & SSA_LIVE_R10) != 0) { _ssa_emit_push_reg(SSA_PHYS_R10); }
    if ((save_mask & SSA_LIVE_R11) != 0) { _ssa_emit_push_reg(SSA_PHYS_R11); }

    _ssa_emit_push_reg(ssa_operand_value(addr_opr));

    var stack_args: u64 = 0;
    for (var si: i64 = (i64)nargs - 1; si >= 0; si = si - 1) {
        var sreg: u64 = vec_get(args_vec, (u64)si);
        emit("    push ", 9);
        _ssa_emit_reg_name(sreg);
        emit_nl();
        stack_args = stack_args + 1;
    }

    var reg_count: u64 = nargs;
    if (reg_count > 6) { reg_count = 6; }
    for (var i: u64 = 0; i < reg_count; i++) {
        emit("    pop ", 8);
        if (i == 0) { emit("rdi", 3); }
        else if (i == 1) { emit("rsi", 3); }
        else if (i == 2) { emit("rdx", 3); }
        else if (i == 3) { emit("rcx", 3); }
        else if (i == 4) { emit("r8", 2); }
        else if (i == 5) { emit("r9", 2); }
        emit_nl();
    }
    stack_args = stack_args - reg_count;

    emit("    call ", 9);
    if (is_ptr != 0) {
        _ssa_emit_reg_name(callee_reg);
    } else {
        emit(name_ptr, name_len);
    }
    emit_nl();

    emit("    mov rbx, [rsp", 19);
    if (stack_args > 0) {
        emit("+", 1);
        emit_u64(stack_args * 8);
    }
    emit("]\n", 2);
    emit("    mov [rbx], rax\n", 20);
    emit("    mov [rbx+8], rdx\n", 24);
    emit("    add rsp, ", 13);
    emit_u64((stack_args + 1) * 8);
    emit_nl();

    if ((save_mask & SSA_LIVE_R11) != 0) { _ssa_emit_restore_reg(0, SSA_PHYS_R11); }
    if ((save_mask & SSA_LIVE_R10) != 0) { _ssa_emit_restore_reg(0, SSA_PHYS_R10); }
    if ((save_mask & SSA_LIVE_R9) != 0) { _ssa_emit_restore_reg(0, SSA_PHYS_R9); }
    if ((save_mask & SSA_LIVE_R8) != 0) { _ssa_emit_restore_reg(0, SSA_PHYS_R8); }
    if ((save_mask & SSA_LIVE_RDX) != 0) { _ssa_emit_restore_reg(0, SSA_PHYS_RDX); }
    if ((save_mask & SSA_LIVE_RCX) != 0) { _ssa_emit_restore_reg(0, SSA_PHYS_RCX); }
    if ((save_mask & SSA_LIVE_RBX) != 0) { _ssa_emit_restore_reg(0, SSA_PHYS_RBX); }
    if ((save_mask & SSA_LIVE_RAX) != 0) { _ssa_emit_restore_reg(0, SSA_PHYS_RAX); }
    return 0;
}

func _ssa_live_map_put(map: u64, inst_ptr: u64, mask: u64) -> u64 {
    vec_push(map, inst_ptr);
    vec_push(map, mask);
    return 0;
}

func _ssa_live_map_get(map: u64, inst_ptr: u64) -> u64 {
    if (map == 0) { return 0; }
    var n: u64 = vec_len(map);
    for (var i: u64 = 0; i + 1 < n; i = i + 2) {
        if (vec_get(map, i) == inst_ptr) { return vec_get(map, i + 1); }
    }
    return 0;
}

func _ssa_block_collect_insts(block: *SSABlock) -> u64 {
    var v: u64 = vec_new(16);
    var cur: *SSAInstruction = block->inst_head;
    while (cur != 0) {
        vec_push(v, (u64)cur);
        cur = cur->next;
    }
    return v;
}

func _ssa_build_live_map(fn: *SSAFunction) -> u64 {
    var blocks: u64 = fn->blocks_data;
    var bcount: u64 = fn->blocks_len;

    var live_in: u64 = vec_new(bcount + 1);
    var live_out: u64 = vec_new(bcount + 1);
    var phi_use: u64 = vec_new(bcount + 1);

    for (var i: u64 = 0; i < bcount; i++) {
        vec_push(live_in, 0);
        vec_push(live_out, 0);
        var b_ptr: u64 = *(*u64)(blocks + i * 8);
        var b: *SSABlock = (*SSABlock)b_ptr;
        vec_push(phi_use, _ssa_phi_use_mask(b));
    }

    var changed: u64 = 1;
    while (changed != 0) {
        changed = 0;
        for (var bi: i64 = (i64)bcount - 1; bi >= 0; bi = bi - 1) {
            var b_ptr2: u64 = *(*u64)(blocks + (u64)bi * 8);
            var b2: *SSABlock = (*SSABlock)b_ptr2;

            var out_mask: u64 = 0;
            for (var si: u64 = 0; si < b2->succs_len; si++) {
                var succ_ptr: u64 = *(*u64)(b2->succs_data + si * 8);
                var succ: *SSABlock = (*SSABlock)succ_ptr;
                var sidx: u64 = _ssa_block_index(blocks, bcount, succ->id);
                if (sidx != 0) {
                    out_mask = out_mask | vec_get(live_in, sidx - 1);
                    out_mask = out_mask | vec_get(phi_use, sidx - 1);
                }
            }

            var live: u64 = out_mask;
            var insts: u64 = _ssa_block_collect_insts(b2);
            for (var idx: i64 = (i64)vec_len(insts) - 1; idx >= 0; idx = idx - 1) {
                var cur: *SSAInstruction = (*SSAInstruction)vec_get(insts, (u64)idx);
                var use_mask: u64 = 0;
                var def_mask: u64 = 0;
                _ssa_inst_use_def_mask(cur, &use_mask, &def_mask);
                live = (live & (_ssa_live_all_mask() ^ def_mask)) | use_mask;
            }

            if (vec_get(live_out, (u64)bi) != out_mask) {
                vec_set(live_out, (u64)bi, out_mask);
                changed = 1;
            }
            if (vec_get(live_in, (u64)bi) != live) {
                vec_set(live_in, (u64)bi, live);
                changed = 1;
            }

        }
    }

    var map: u64 = vec_new(256);
    for (var bi2: u64 = 0; bi2 < bcount; bi2++) {
        var b_ptr3: u64 = *(*u64)(blocks + bi2 * 8);
        var b3: *SSABlock = (*SSABlock)b_ptr3;
        var live2: u64 = vec_get(live_out, bi2);
        var insts2: u64 = _ssa_block_collect_insts(b3);
        for (var idx2: i64 = (i64)vec_len(insts2) - 1; idx2 >= 0; idx2 = idx2 - 1) {
            var cur2: *SSAInstruction = (*SSAInstruction)vec_get(insts2, (u64)idx2);
            _ssa_live_map_put(map, (u64)cur2, live2);
            var use_mask2: u64 = 0;
            var def_mask2: u64 = 0;
            _ssa_inst_use_def_mask(cur2, &use_mask2, &def_mask2);
            live2 = (live2 & (_ssa_live_all_mask() ^ def_mask2)) | use_mask2;
        }
    }

    return map;
}

func _ssa_fn_has_ret_slice_heap(fn: *SSAFunction) -> u64 {
    if (fn == 0) { return 0; }
    var blocks: u64 = fn->blocks_data;
    var bcount: u64 = fn->blocks_len;
    for (var bi: u64 = 0; bi < bcount; bi++) {
        var b_ptr: u64 = *(*u64)(blocks + bi * 8);
        var b: *SSABlock = (*SSABlock)b_ptr;
        var cur: *SSAInstruction = b->inst_head;
        while (cur != 0) {
            if (ssa_inst_get_op(cur) == SSA_OP_RET_SLICE_HEAP) { return 1; }
            cur = cur->next;
        }
    }
    return 0;
}

// ============================================
// 지원 여부 판정
// ============================================

func _ssa_codegen_is_global(globals: u64, name_ptr: u64, name_len: u64) -> u64 {
    if (globals == 0) { return 0; }
    var n: u64 = vec_len(globals);
    for (var i: u64 = 0; i < n; i++) {
        var ginfo: *GlobalInfo = (*GlobalInfo)vec_get(globals, i);
        if (str_eq(ginfo->name_ptr, ginfo->name_len, name_ptr, name_len) != 0) { return 1; }
    }
    return 0;
}

func _ssa_codegen_call_returns_large_struct(call_ptr: u64) -> u64 {
    if (call_ptr == 0) { return 0; }
    var call: *AstCall = (*AstCall)call_ptr;
    var fn_ptr: u64 = compiler_get_func(call->name_ptr, call->name_len);
    if (fn_ptr == 0) { return 0; }
    var fn: *AstFunc = (*AstFunc)fn_ptr;
    if (fn->ret_type != TYPE_STRUCT) { return 0; }
    if (fn->ret_ptr_depth != 0) { return 0; }
    if (fn->ret_struct_name_ptr == 0 || fn->ret_struct_name_len == 0) { return 0; }
    var struct_size: u64 = sizeof_type(TYPE_STRUCT, 0, fn->ret_struct_name_ptr, fn->ret_struct_name_len);
    if (struct_size <= 16) { return 0; }
    return 1;
}

func _ssa_codegen_call_ptr_returns_large_struct(cp_ptr: u64) -> u64 {
    if (cp_ptr == 0) { return 0; }
    var cp: *AstCallPtr = (*AstCallPtr)cp_ptr;
    var callee: u64 = cp->callee;
    var name_ptr: u64 = 0;
    var name_len: u64 = 0;
    var ck: u64 = ast_kind(callee);
    if (ck == AST_IDENT) {
        var idn: *AstIdent = (*AstIdent)callee;
        name_ptr = idn->name_ptr;
        name_len = idn->name_len;
    } else if (ck == AST_ADDR_OF) {
        var a: *AstAddrOf = (*AstAddrOf)callee;
        if (ast_kind(a->operand) == AST_IDENT) {
            var idn2: *AstIdent = (*AstIdent)a->operand;
            name_ptr = idn2->name_ptr;
            name_len = idn2->name_len;
        }
    }
    if (name_ptr == 0) { return 0; }
    var resolved_ptr: u64 = name_ptr;
    var resolved_len: u64 = name_len;
    var resolved: u64 = resolve_name(name_ptr, name_len);
    if (resolved != 0) {
        var resolved_info: *NameInfo = (*NameInfo)resolved;
        resolved_ptr = resolved_info->ptr;
        resolved_len = resolved_info->len;
    }
    var fn_ptr: u64 = compiler_get_func(resolved_ptr, resolved_len);
    if (fn_ptr == 0) { return 0; }
    var fn: *AstFunc = (*AstFunc)fn_ptr;
    if (fn->ret_type != TYPE_STRUCT) { return 0; }
    if (fn->ret_ptr_depth != 0) { return 0; }
    if (fn->ret_struct_name_ptr == 0 || fn->ret_struct_name_len == 0) { return 0; }
    var struct_size: u64 = sizeof_type(TYPE_STRUCT, 0, fn->ret_struct_name_ptr, fn->ret_struct_name_len);
    if (struct_size <= 16) { return 0; }
    return 1;
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
        if (un->op != TOKEN_MINUS && un->op != TOKEN_BANG && un->op != TOKEN_TILDE) { return 0; }
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
        var ok: u64 = _ssa_codegen_expr_supported(m->object, globals);
        if (ok != 0) { return 1; }
        var obj_kind: u64 = ast_kind(m->object);
        if (obj_kind == AST_CALL) {
            if (_ssa_codegen_call_returns_large_struct(m->object) != 0) { return 1; }
        }
        if (obj_kind == AST_CALL_PTR) {
            if (_ssa_codegen_call_ptr_returns_large_struct(m->object) != 0) { return 1; }
        }
        return 0;
    }

    if (kind == AST_CAST) {
        var c: *AstCast = (*AstCast)node;
        return _ssa_codegen_expr_supported(c->expr, globals);
    }

    if (kind == AST_SIZEOF || kind == AST_SIZEOF_EXPR) { return 1; }

    if (kind == AST_CALL) {
        var call: *AstCall = (*AstCall)node;
        var args: u64 = call->args_vec;
        var n: u64 = 0;
        if (args != 0) { n = vec_len(args); }
        for (var i: u64 = 0; i < n; i++) {
            var arg: u64 = vec_get(args, i);
            if (ast_kind(arg) == AST_SLICE) {
                var s: *AstSlice = (*AstSlice)arg;
                if (_ssa_codegen_expr_supported(s->ptr_expr, globals) == 0) { return 0; }
                if (_ssa_codegen_expr_supported(s->len_expr, globals) == 0) { return 0; }
            } else {
                if (_ssa_codegen_expr_supported(arg, globals) == 0) { return 0; }
            }
        }
        var fn_ptr: u64 = compiler_get_func(call->name_ptr, call->name_len);
        if (fn_ptr != 0) {
            var fn: *AstFunc = (*AstFunc)fn_ptr;
            if (fn->ret_type == TYPE_STRUCT && fn->ret_ptr_depth == 0) {
                var struct_size: u64 = sizeof_type(TYPE_STRUCT, 0, fn->ret_struct_name_ptr, fn->ret_struct_name_len);
            }
        }
        return 1;
    }

    if (kind == AST_SLICE) {
        var s3: *AstSlice = (*AstSlice)node;
        if (_ssa_codegen_expr_supported(s3->ptr_expr, globals) == 0) { return 0; }
        if (_ssa_codegen_expr_supported(s3->len_expr, globals) == 0) { return 0; }
        return 1;
    }

    if (kind == AST_CALL_PTR) {
        var cp: *AstCallPtr = (*AstCallPtr)node;
        if (_ssa_codegen_expr_supported(cp->callee, globals) == 0) { return 0; }
        var args2: u64 = cp->args_vec;
        var n2: u64 = 0;
        if (args2 != 0) { n2 = vec_len(args2); }
        for (var i2: u64 = 0; i2 < n2; i2++) {
            var arg2: u64 = vec_get(args2, i2);
            if (ast_kind(arg2) == AST_SLICE) {
                var s2: *AstSlice = (*AstSlice)arg2;
                if (_ssa_codegen_expr_supported(s2->ptr_expr, globals) == 0) { return 0; }
                if (_ssa_codegen_expr_supported(s2->len_expr, globals) == 0) { return 0; }
            } else {
                if (_ssa_codegen_expr_supported(arg2, globals) == 0) { return 0; }
            }
        }
        return 1;
    }

    if (kind == AST_METHOD_CALL) {
        var mc: *AstMethodCall = (*AstMethodCall)node;
        if (_ssa_codegen_expr_supported(mc->receiver, globals) == 0) { return 0; }
        var args: u64 = mc->args_vec;
        var n: u64 = 0;
        if (args != 0) { n = vec_len(args); }
        for (var i: u64 = 0; i < n; i++) {
            var arg: u64 = vec_get(args, i);
            if (ast_kind(arg) == AST_SLICE) {
                var s: *AstSlice = (*AstSlice)arg;
                if (_ssa_codegen_expr_supported(s->ptr_expr, globals) == 0) { return 0; }
                if (_ssa_codegen_expr_supported(s->len_expr, globals) == 0) { return 0; }
            } else {
                if (_ssa_codegen_expr_supported(arg, globals) == 0) { return 0; }
            }
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
        if (stmts == 0) { return 1; }
        var n: u64 = vec_len(stmts);
        for (var i: u64 = 0; i < n; i++) {
            if (_ssa_codegen_stmt_supported(vec_get(stmts, i), globals) == 0) { return 0; }
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
        for (var i: u64 = 0; i < n; i++) {
            if (_ssa_codegen_case_supported(vec_get(cases, i), globals) == 0) { return 0; }
        }
        return 1;
    }

    if (kind == AST_ASM) { return 1; }

    if (kind == AST_EXPR_STMT) {
        var es: *AstExprStmt = (*AstExprStmt)node;
        if (es->expr == 0) { return 1; }
        if (ast_kind(es->expr) == AST_CALL) {
            if (_ssa_codegen_call_returns_large_struct(es->expr) != 0) { return 1; }
        }
        if (ast_kind(es->expr) == AST_CALL_PTR) {
            if (_ssa_codegen_call_ptr_returns_large_struct(es->expr) != 0) { return 1; }
        }
        return _ssa_codegen_expr_supported(es->expr, globals);
    }

    if (kind == AST_VAR_DECL) {
        var vd: *AstVarDecl = (*AstVarDecl)node;
        if (vd->init_expr == 0) { return 1; }
        if (vd->type_kind == TYPE_SLICE && vd->ptr_depth == 0) {
            if (ast_kind(vd->init_expr) == AST_CALL || ast_kind(vd->init_expr) == AST_CALL_PTR || ast_kind(vd->init_expr) == AST_METHOD_CALL) { return 1; }
        }
        if (vd->type_kind == TYPE_STRUCT && vd->ptr_depth == 0) {
            var struct_size: u64 = sizeof_type(TYPE_STRUCT, 0, vd->struct_name_ptr, vd->struct_name_len);
            if (struct_size > 16) {
                var ik: u64 = ast_kind(vd->init_expr);
                if (ik == AST_CALL || ik == AST_CALL_PTR || ik == AST_METHOD_CALL) { return 1; }
            }
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
        if (ast_kind(asn->value) == AST_CALL) {
            var call2: *AstCall = (*AstCall)asn->value;
            var fn_ptr2: u64 = compiler_get_func(call2->name_ptr, call2->name_len);
            if (fn_ptr2 != 0) {
                var fn2: *AstFunc = (*AstFunc)fn_ptr2;
                if (fn2->ret_type == TYPE_STRUCT && fn2->ret_ptr_depth == 0) {
                    var struct_size2: u64 = sizeof_type(TYPE_STRUCT, 0, fn2->ret_struct_name_ptr, fn2->ret_struct_name_len);
                    if (struct_size2 > 16) { return 1; }
                }
            }
        }
        if (ast_kind(asn->value) == AST_CALL_PTR) {
            if (_ssa_codegen_call_ptr_returns_large_struct(asn->value) != 0) { return 1; }
        }
        if (tk == AST_IDENT) {
            var idn2: *AstIdent = (*AstIdent)asn->target;
            if (ast_kind(asn->value) == AST_STRUCT_LITERAL) {
                return _ssa_codegen_struct_literal_supported(asn->value, globals);
            }
            return _ssa_codegen_expr_supported(asn->value, globals);
        }
        if (tk == AST_DEREF || tk == AST_DEREF8 || tk == AST_INDEX || tk == AST_MEMBER_ACCESS) {
            if (_ssa_codegen_expr_supported(asn->target, globals) == 0) { return 0; }
            if (ast_kind(asn->value) == AST_STRUCT_LITERAL) {
                return _ssa_codegen_struct_literal_supported(asn->value, globals);
            }
            return _ssa_codegen_expr_supported(asn->value, globals);
        }
        return 0;
    }

    if (kind == AST_RETURN) {
        var ret: *AstReturn = (*AstReturn)node;
        if (ret->expr == 0) { return 1; }
        if (ast_kind(ret->expr) == AST_CALL) {
            if (_ssa_codegen_call_returns_large_struct(ret->expr) != 0) { return 1; }
        }
        if (ast_kind(ret->expr) == AST_CALL_PTR) {
            if (_ssa_codegen_call_ptr_returns_large_struct(ret->expr) != 0) { return 1; }
        }
        return _ssa_codegen_expr_supported(ret->expr, globals);
    }

    if (kind == AST_BREAK || kind == AST_CONTINUE) { return 1; }

    return 1;
}

func ssa_codegen_is_supported_func(fn_ptr: u64, globals: u64) -> u64 {
    push_trace("ssa_codegen_is_supported_func", "ssa_codegen.b", __LINE__);
    pop_trace();
    if (fn_ptr == 0) { return 0; }
    var fn: *AstFunc = (*AstFunc)fn_ptr;

    var params: u64 = fn->params_vec;
    if (params != 0) {
        var pn: u64 = vec_len(params);
        for (var pi: u64 = 0; pi < pn; pi++) {
            var p: *Param = (*Param)vec_get(params, pi);
            if (p->type_kind == TYPE_SLICE && p->ptr_depth == 0) {
                continue;
            }
        }
    }
    if (fn->ret_type == TYPE_STRUCT && fn->ret_ptr_depth == 0) {
        if (fn->ret_struct_name_ptr == 0 || fn->ret_struct_name_len == 0) { return 0; }
        var struct_size: u64 = sizeof_type(TYPE_STRUCT, 0, fn->ret_struct_name_ptr, fn->ret_struct_name_len);
        if (struct_size == 0) { return 0; }
    }
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
    if (phys == SSA_PHYS_R10) { emit("r10", 3); return 0; }
    if (phys == SSA_PHYS_R11) { emit("r11", 3); return 0; }
    emit("rax", 3);
    return 0;
}

func _ssa_emit_reg_name_size(phys: u64, size: u64) -> u64 {
    if (size == 1) {
        if (phys == SSA_PHYS_RAX) { emit("al", 2); return 0; }
        if (phys == SSA_PHYS_RBX) { emit("bl", 2); return 0; }
        if (phys == SSA_PHYS_RCX) { emit("cl", 2); return 0; }
        if (phys == SSA_PHYS_RDX) { emit("dl", 2); return 0; }
        if (phys == SSA_PHYS_R8) { emit("r8b", 3); return 0; }
        if (phys == SSA_PHYS_R9) { emit("r9b", 3); return 0; }
        if (phys == SSA_PHYS_R10) { emit("r10b", 4); return 0; }
        if (phys == SSA_PHYS_R11) { emit("r11b", 4); return 0; }
        emit("al", 2);
        return 0;
    }
    if (size == 2) {
        if (phys == SSA_PHYS_RAX) { emit("ax", 2); return 0; }
        if (phys == SSA_PHYS_RBX) { emit("bx", 2); return 0; }
        if (phys == SSA_PHYS_RCX) { emit("cx", 2); return 0; }
        if (phys == SSA_PHYS_RDX) { emit("dx", 2); return 0; }
        if (phys == SSA_PHYS_R8) { emit("r8w", 3); return 0; }
        if (phys == SSA_PHYS_R9) { emit("r9w", 3); return 0; }
        if (phys == SSA_PHYS_R10) { emit("r10w", 4); return 0; }
        if (phys == SSA_PHYS_R11) { emit("r11w", 4); return 0; }
        emit("ax", 2);
        return 0;
    }
    if (size == 4) {
        if (phys == SSA_PHYS_RAX) { emit("eax", 3); return 0; }
        if (phys == SSA_PHYS_RBX) { emit("ebx", 3); return 0; }
        if (phys == SSA_PHYS_RCX) { emit("ecx", 3); return 0; }
        if (phys == SSA_PHYS_RDX) { emit("edx", 3); return 0; }
        if (phys == SSA_PHYS_R8) { emit("r8d", 3); return 0; }
        if (phys == SSA_PHYS_R9) { emit("r9d", 3); return 0; }
        if (phys == SSA_PHYS_R10) { emit("r10d", 4); return 0; }
        if (phys == SSA_PHYS_R11) { emit("r11d", 4); return 0; }
        emit("eax", 3);
        return 0;
    }
    return _ssa_emit_reg_name(phys);
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

func _ssa_emit_call(dest: u64, extra_dest: u64, info_ptr: u64, live_mask: u64) -> u64 {
    var info: *SSACallInfo = (*SSACallInfo)info_ptr;
    var name_ptr: u64 = info->name_ptr;
    var name_len: u64 = info->name_len;
    var args_vec: u64 = info->args_vec;
    var nargs: u64 = info->nargs;
    var ret_type: u64 = info->ret_type;
    var ret_ptr_depth: u64 = info->ret_ptr_depth;
    var ret_struct_size: u64 = info->ret_struct_size;
    if (nargs == 0 && args_vec != 0) { nargs = vec_len(args_vec); }
    var is_sret: u64 = 0;
    if (ret_type == TYPE_STRUCT && ret_ptr_depth == 0 && ret_struct_size > 16) {
        is_sret = 1;
    }

    var keep_rax: u64 = 0;
    var keep_rdx: u64 = 0;
    if (dest == SSA_PHYS_RAX) {
        keep_rax = 1;
    }
    if (extra_dest == SSA_PHYS_RDX) {
        keep_rdx = 1;
    }
    if (ret_type == TYPE_SLICE && ret_ptr_depth == 0) {
        if (dest == SSA_PHYS_RAX) { keep_rax = 1; }
        if (extra_dest == SSA_PHYS_RDX) { keep_rdx = 1; }
    }

    var all_mask: u64 = _ssa_live_all_mask();
    var save_mask: u64 = live_mask & all_mask;
    if (keep_rax != 0) { save_mask = save_mask & (all_mask ^ SSA_LIVE_RAX); }
    if (keep_rdx != 0) { save_mask = save_mask & (all_mask ^ SSA_LIVE_RDX); }
    if (dest != 0) {
        save_mask = save_mask & (all_mask ^ _ssa_phys_mask(dest));
    }
    if (extra_dest != 0) {
        save_mask = save_mask & (all_mask ^ _ssa_phys_mask(extra_dest));
    }

    if ((save_mask & SSA_LIVE_RAX) != 0) { _ssa_emit_push_reg(SSA_PHYS_RAX); }
    if ((save_mask & SSA_LIVE_RBX) != 0) { _ssa_emit_push_reg(SSA_PHYS_RBX); }
    if ((save_mask & SSA_LIVE_RCX) != 0) { _ssa_emit_push_reg(SSA_PHYS_RCX); }
    if ((save_mask & SSA_LIVE_RDX) != 0) { _ssa_emit_push_reg(SSA_PHYS_RDX); }
    if ((save_mask & SSA_LIVE_R8) != 0) { _ssa_emit_push_reg(SSA_PHYS_R8); }
    if ((save_mask & SSA_LIVE_R9) != 0) { _ssa_emit_push_reg(SSA_PHYS_R9); }

    var stack_args: u64 = 0;
    for (var si2: i64 = (i64)nargs - 1; si2 >= 0; si2 = si2 - 1) {
        var sreg2: u64 = vec_get(args_vec, (u64)si2);
        emit("    push ", 9);
        _ssa_emit_reg_name(sreg2);
        emit_nl();
        stack_args = stack_args + 1;
    }

    var reg_count2: u64 = nargs;
    if (reg_count2 > 6) { reg_count2 = 6; }
    for (var i: u64 = 0; i < reg_count2; i++) {
        emit("    pop ", 8);
        if (i == 0) { emit("rdi", 3); }
        else if (i == 1) { emit("rsi", 3); }
        else if (i == 2) { emit("rdx", 3); }
        else if (i == 3) { emit("rcx", 3); }
        else if (i == 4) { emit("r8", 2); }
        else if (i == 5) { emit("r9", 2); }
        emit_nl();
    }
    stack_args = stack_args - reg_count2;

    emit("    call ", 9);
    emit(name_ptr, name_len);
    emit_nl();

    if (is_sret == 0) {
        if (dest != 0 && dest != SSA_PHYS_RAX) {
            _ssa_emit_mov_reg_opr(dest, ssa_operand_reg(SSA_PHYS_RAX));
        }
        if (extra_dest != 0 && extra_dest != SSA_PHYS_RDX) {
            emit("    mov ", 8);
            _ssa_emit_reg_name(extra_dest);
            emit(", rdx\n", 7);
        }
    }

    if (stack_args > 0) {
        emit("    add rsp, ", 13);
        emit_u64(stack_args * 8);
        emit_nl();
    }

    if ((save_mask & SSA_LIVE_R11) != 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_R11); }
    if ((save_mask & SSA_LIVE_R10) != 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_R10); }
    if ((save_mask & SSA_LIVE_R11) != 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_R11); }
    if ((save_mask & SSA_LIVE_R10) != 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_R10); }
    if ((save_mask & SSA_LIVE_R9) != 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_R9); }
    if ((save_mask & SSA_LIVE_R8) != 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_R8); }
    if ((save_mask & SSA_LIVE_RDX) != 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_RDX); }
    if ((save_mask & SSA_LIVE_RCX) != 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_RCX); }
    if ((save_mask & SSA_LIVE_RBX) != 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_RBX); }
    if ((save_mask & SSA_LIVE_RAX) != 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_RAX); }
    return 0;
}

func _ssa_emit_call_ptr(dest: u64, extra_dest: u64, info_ptr: u64, live_mask: u64) -> u64 {
    var info: *SSACallPtrInfo = (*SSACallPtrInfo)info_ptr;
    var callee_reg: u64 = info->callee_reg;
    var args_vec: u64 = info->args_vec;
    var nargs: u64 = info->nargs;
    var ret_type: u64 = info->ret_type;
    var ret_ptr_depth: u64 = info->ret_ptr_depth;
    var ret_struct_size: u64 = info->ret_struct_size;
    if (nargs == 0 && args_vec != 0) { nargs = vec_len(args_vec); }
    var is_sret: u64 = 0;
    if (ret_type == TYPE_STRUCT && ret_ptr_depth == 0 && ret_struct_size > 16) {
        is_sret = 1;
    }

    var keep_rax: u64 = 0;
    var keep_rdx: u64 = 0;
    if (dest == SSA_PHYS_RAX) {
        keep_rax = 1;
    }
    if (extra_dest == SSA_PHYS_RDX) {
        keep_rdx = 1;
    }
    if (ret_type == TYPE_SLICE && ret_ptr_depth == 0) {
        if (dest == SSA_PHYS_RAX) { keep_rax = 1; }
        if (extra_dest == SSA_PHYS_RDX) { keep_rdx = 1; }
    }

    var all_mask2: u64 = _ssa_live_all_mask();
    var save_mask: u64 = live_mask & all_mask2;
    if (keep_rax != 0) { save_mask = save_mask & (all_mask2 ^ SSA_LIVE_RAX); }
    if (keep_rdx != 0) { save_mask = save_mask & (all_mask2 ^ SSA_LIVE_RDX); }
    if (dest != 0) {
        save_mask = save_mask & (all_mask2 ^ _ssa_phys_mask(dest));
    }
    if (extra_dest != 0) {
        save_mask = save_mask & (all_mask2 ^ _ssa_phys_mask(extra_dest));
    }

    if ((save_mask & SSA_LIVE_RAX) != 0) { _ssa_emit_push_reg(SSA_PHYS_RAX); }
    if ((save_mask & SSA_LIVE_RBX) != 0) { _ssa_emit_push_reg(SSA_PHYS_RBX); }
    if ((save_mask & SSA_LIVE_RCX) != 0) { _ssa_emit_push_reg(SSA_PHYS_RCX); }
    if ((save_mask & SSA_LIVE_RDX) != 0) { _ssa_emit_push_reg(SSA_PHYS_RDX); }
    if ((save_mask & SSA_LIVE_R8) != 0) { _ssa_emit_push_reg(SSA_PHYS_R8); }
    if ((save_mask & SSA_LIVE_R9) != 0) { _ssa_emit_push_reg(SSA_PHYS_R9); }

    var stack_args: u64 = 0;
    for (var si3: i64 = (i64)nargs - 1; si3 >= 0; si3 = si3 - 1) {
        var sreg3: u64 = vec_get(args_vec, (u64)si3);
        emit("    push ", 9);
        _ssa_emit_reg_name(sreg3);
        emit_nl();
        stack_args = stack_args + 1;
    }

    var reg_count0: u64 = nargs;
    if (reg_count0 > 6) { reg_count0 = 6; }
    for (var i: u64 = 0; i < reg_count0; i++) {
        emit("    pop ", 8);
        if (i == 0) { emit("rdi", 3); }
        else if (i == 1) { emit("rsi", 3); }
        else if (i == 2) { emit("rdx", 3); }
        else if (i == 3) { emit("rcx", 3); }
        else if (i == 4) { emit("r8", 2); }
        else if (i == 5) { emit("r9", 2); }
        emit_nl();
    }
    stack_args = stack_args - reg_count0;

    emit("    call ", 9);
    _ssa_emit_reg_name(callee_reg);
    emit_nl();

    if (is_sret == 0) {
        if (dest != 0 && dest != SSA_PHYS_RAX) {
            _ssa_emit_mov_reg_opr(dest, ssa_operand_reg(SSA_PHYS_RAX));
        }
        if (extra_dest != 0 && extra_dest != SSA_PHYS_RDX) {
            emit("    mov ", 8);
            _ssa_emit_reg_name(extra_dest);
            emit(", rdx\n", 7);
        }
    }

    if (stack_args > 0) {
        emit("    add rsp, ", 13);
        emit_u64(stack_args * 8);
        emit_nl();
    }

    if ((save_mask & SSA_LIVE_R9) != 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_R9); }
    if ((save_mask & SSA_LIVE_R8) != 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_R8); }
    if ((save_mask & SSA_LIVE_RDX) != 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_RDX); }
    if ((save_mask & SSA_LIVE_RCX) != 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_RCX); }
    if ((save_mask & SSA_LIVE_RBX) != 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_RBX); }
    if ((save_mask & SSA_LIVE_RAX) != 0) { _ssa_emit_restore_reg(dest, SSA_PHYS_RAX); }
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

func _ssa_emit_lea_local(dest: u64, offset: i64) -> u64 {
    g_last_lea_local_off = offset;
    g_last_lea_local_valid = 1;
    emit("    lea ", 8);
    _ssa_emit_reg_name(dest);
    emit(", [rbp", 7);
    if (offset < 0) { emit_i64(offset); }
    else { emit("+", 1); emit_u64((u64)offset); }
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
    if (op == SSA_OP_STORE8 || op == SSA_OP_STORE16 || op == SSA_OP_STORE32) {
        if (ssa_operand_is_const(val_opr) != 0) {
            _ssa_emit_opr(val_opr);
        } else {
            var size: u64 = 4;
            if (op == SSA_OP_STORE8) { size = 1; }
            else if (op == SSA_OP_STORE16) { size = 2; }
            _ssa_emit_reg_name_size(ssa_operand_value(val_opr), size);
        }
    } else {
        _ssa_emit_opr(val_opr);
    }
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
    if (ssa_operand_value(src2) == dest) {
        emit("    mov rcx, ", 13);
        _ssa_emit_reg_name(dest);
        emit_nl();
    }
    _ssa_emit_mov_reg_opr(dest, src1);
    if (ssa_operand_value(src2) != dest) {
        emit("    mov rcx, ", 13);
        _ssa_emit_reg_name(ssa_operand_value(src2));
        emit_nl();
    }
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
    var src2_in_rax: u64 = 0;
    if (inst->src2 != 0 && ssa_operand_is_const(inst->src2) == 0) {
        if (ssa_operand_value(inst->src2) == SSA_PHYS_RAX) { src2_in_rax = 1; }
    }
    var src1_moves_rax: u64 = 0;
    if (inst->src1 == 0) {
        src1_moves_rax = 1;
    } else if (ssa_operand_is_const(inst->src1) != 0) {
        src1_moves_rax = 1;
    } else {
        var r1: u64 = ssa_operand_value(inst->src1);
        if (r1 != SSA_PHYS_RAX) { src1_moves_rax = 1; }
    }
    if (src2_in_rax != 0 && src1_moves_rax != 0) {
        emit("    mov rdx, rax\n", 18);
    }

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

    if (inst->src2 != 0 && src2_in_rax == 0) {
        if (ssa_operand_is_const(inst->src2) != 0) {
            _ssa_emit_mov_reg_opr(SSA_PHYS_RDX, inst->src2);
        } else {
            var r2: u64 = ssa_operand_value(inst->src2);
            if (r2 != SSA_PHYS_RDX) {
                emit("    mov rdx, ", 13);
                _ssa_emit_reg_name(r2);
                emit_nl();
            }
        }
    }

    emit("    mov rsp, rbp\n", 20);
    emit("    pop rbp\n", 13);
    emit("    ret\n", 9);
    return 0;
}

func _ssa_emit_ret_slice_heap(inst: *SSAInstruction) -> u64 {
    _ssa_ensure_heap_brk_global();
    var elem_size: u64 = inst->dest;
    if (elem_size == 0) {
        elem_size = ssa_ret_slice_heap_get((u64)inst);
    }

    var ex_elem: u64 = 0;
    var ex_ptr_val: u64 = 0;
    var ex_len_val: u64 = 0;
    var ex_ptr_is_reg: u64 = 0;
    var ex_len_is_reg: u64 = 0;
    var has_ex: u64 = ssa_ret_slice_heap_get_ex((u64)inst, &ex_elem, &ex_ptr_val, &ex_len_val, &ex_ptr_is_reg, &ex_len_is_reg);
    if (has_ex != 0 && ex_elem != 0) {
        elem_size = ex_elem;
    }

    if (has_ex != 0 && ex_len_is_reg == 0) {
        emit("    mov r12, ", 13);
        emit_u64(ex_len_val);
        emit_nl();
        emit("    mov r8, ", 12);
        emit_u64(ex_len_val);
        emit_nl();
    } else {
        emit("    mov r12, ", 13);
        _ssa_emit_opr(inst->src2);
        emit_nl();
        emit("    mov r8, ", 12);
        _ssa_emit_opr(inst->src2);
        emit_nl();
    }

    var src1_bad: u64 = 0;
    if (ssa_operand_is_const(inst->src1) == 0) {
        var r_src1: u64 = ssa_operand_value(inst->src1);
        if (r_src1 < SSA_PHYS_RAX || r_src1 > SSA_PHYS_R11) { src1_bad = 1; }
    }

    if (has_ex != 0 && ex_ptr_is_reg != 0) {
        emit("    mov r13, ", 13);
        _ssa_emit_reg_name(ex_ptr_val);
        emit_nl();
    } else if (g_last_lea_local_valid != 0 && (ssa_operand_is_const(inst->src1) != 0 || src1_bad != 0 || inst->src1 == inst->src2)) {
        emit("    lea r13, [rbp", 20);
        if (g_last_lea_local_off < 0) { emit_i64(g_last_lea_local_off); }
        else { emit("+", 1); emit_u64((u64)g_last_lea_local_off); }
        emit("]\n", 2);
    } else {
        emit("    mov r13, ", 13);
        _ssa_emit_opr(inst->src1);
        emit_nl();
    }
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
    emit("    mov rsi, r13\n", 17);
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
        var info: *NameInfo = (*NameInfo)info_ptr;
        var str_ptr: u64 = info->ptr;
        var str_len: u64 = info->len;
        var label_id: u64 = string_get_label(str_ptr, str_len);
        emit("    lea ", 8);
        _ssa_emit_reg_name(inst->dest);
        emit(", [rel _str", 12);
        emit_u64(label_id);
        emit("]\n", 2);
        return 0;
    }

    if (op == SSA_OP_LEA_LOCAL) {
        // Preserve signed stack offsets embedded in const operands.
        var offset_val: u64 = ssa_operand_value(inst->src1);
        var bias: u64 = 4611686018427387904; // 1<<62
        var signed_off: i64 = (i64)(offset_val - bias);
        _ssa_emit_lea_local(inst->dest, signed_off);
        return 0;
    }

    if (op == SSA_OP_LEA_GLOBAL) {
        var info_ptr2: u64 = ssa_operand_value(inst->src1);
        var info: *NameInfo = (*NameInfo)info_ptr2;
        var name_ptr: u64 = info->ptr;
        var name_len: u64 = info->len;
        _ssa_emit_lea_global(inst->dest, name_ptr, name_len);
        return 0;
    }

    if (op == SSA_OP_LEA_FUNC) {
        var info_ptr2b: u64 = ssa_operand_value(inst->src1);
        var info: *NameInfo = (*NameInfo)info_ptr2b;
        var name_ptr2: u64 = info->ptr;
        var name_len2: u64 = info->len;
        _ssa_emit_lea_func(inst->dest, name_ptr2, name_len2);
        return 0;
    }

    if (op == SSA_OP_PARAM) {
        var idx: u64 = ssa_operand_value(inst->src1);
        if (idx <= 5) {
            var save_offset: u64 = 1032 + idx * 8;
            emit("    mov ", 8);
            _ssa_emit_reg_name(inst->dest);
            emit(", [rbp-", 7);
            emit_u64(save_offset);
            emit("]\n", 2);
        } else {
            // Stack parameters (7th onwards)
            var offset: u64 = 16 + (idx - 6) * 8;
            emit("    mov ", 8);
            _ssa_emit_reg_name(inst->dest);
            emit(", [rbp+", 7);
            emit_u64(offset);
            emit("]\n", 2);
        }
        return 0;
    }

    if (op == SSA_OP_CALL) {
        var info_ptr3: u64 = ssa_operand_value(inst->src1);
        var extra_dest: u64 = 0;
        if (inst->src2 != 0 && ssa_operand_is_const(inst->src2) == 0) {
            extra_dest = ssa_operand_value(inst->src2);
        }
        _ssa_emit_call(inst->dest, extra_dest, info_ptr3, _ssa_live_map_get(g_live_mask_map, (u64)inst));
        return 0;
    }

    if (op == SSA_OP_CALL_PTR) {
        var info_ptr3b: u64 = ssa_operand_value(inst->src1);
        var extra_dest2: u64 = 0;
        if (inst->src2 != 0 && ssa_operand_is_const(inst->src2) == 0) {
            extra_dest2 = ssa_operand_value(inst->src2);
        }
        _ssa_emit_call_ptr(inst->dest, extra_dest2, info_ptr3b, _ssa_live_map_get(g_live_mask_map, (u64)inst));
        return 0;
    }

    if (op == SSA_OP_CALL_SLICE_STORE) {
        var info_ptr4: u64 = ssa_operand_value(inst->src1);
        _ssa_emit_call_slice_store(info_ptr4, inst->src2, _ssa_live_map_get(g_live_mask_map, (u64)inst));
        return 0;
    }

    if (op == SSA_OP_ASM) {
        var text_vec: u64 = ssa_operand_value(inst->src1);
        var live_mask: u64 = _ssa_live_map_get(g_live_mask_map, (u64)inst);
        if (g_live_mask_map == 0) {
            _ssa_emit_asm(text_vec);
        } else {
            _ssa_emit_asm_with_save(text_vec, live_mask);
        }
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
    if (op == SSA_OP_RET_SLICE_HEAP) { return _ssa_emit_ret_slice_heap(inst); }

    return 0;
}

// ============================================
// 엔트리 포인트
// ============================================

func ssa_codegen_emit_func(fn_ptr: u64, ssa_fn_ptr: u64) -> u64 {
    push_trace("ssa_codegen_emit_func", "ssa_codegen.b", __LINE__);
    pop_trace();
    g_last_lea_local_valid = 0;
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

    if (_ssa_fn_has_ret_slice_heap(ssa_fn) != 0) {
        g_live_mask_map = 0;
    } else {
        g_live_mask_map = _ssa_build_live_map(ssa_fn);
    }

    emit(fn->name_ptr, fn->name_len);
    emit(":\n", 2);
    emit("    push rbp\n", 14);
    emit("    mov rbp, rsp\n", 19);
    emit("    sub rsp, 1088\n", 21);
    emit("    mov [rbp-1032], rdi\n", 27);
    emit("    mov [rbp-1040], rsi\n", 27);
    emit("    mov [rbp-1048], rdx\n", 27);
    emit("    mov [rbp-1056], rcx\n", 27);
    emit("    mov [rbp-1064], r8\n", 26);
    emit("    mov [rbp-1072], r9\n", 26);

    var blocks: u64 = ssa_fn->blocks_data;
    var bcount: u64 = ssa_fn->blocks_len;
    for (var bi: u64 = 0; bi < bcount; bi++) {
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

    }

    emit("    xor eax, eax\n", 18);
    emit("    mov rsp, rbp\n", 20);
    emit("    pop rbp\n", 13);
    emit("    ret\n", 9);

    g_live_mask_map = 0;

    if (SSA_CODEGEN_DEBUG != 0) {
        println("[DEBUG] ssa_codegen_emit_func: done", 35);
    }

    return 0;
}
