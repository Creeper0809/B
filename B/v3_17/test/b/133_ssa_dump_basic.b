// Expect exit code: 0

import ssa;
import ssa_dump;

func main() -> i64 {
    var ctx: *SSAContext = (*SSAContext)ssa_context_new();
    var fn_ptr: u64 = ssa_new_function(ctx, "f", 1);
    var fn: *SSAFunction = (*SSAFunction)fn_ptr;
    var b0: *SSABlock = fn->entry;

    var c1_ptr: u64 = ssa_new_inst(ctx, SSA_OP_CONST, 1, ssa_operand_const(1), 0);
    var c2_ptr: u64 = ssa_new_inst(ctx, SSA_OP_CONST, 2, ssa_operand_const(2), 0);
    var add_ptr: u64 = ssa_new_inst(ctx, SSA_OP_ADD, 3, ssa_operand_reg(1), ssa_operand_reg(2));
    var ret_ptr: u64 = ssa_new_inst(ctx, SSA_OP_RET, 0, ssa_operand_reg(3), 0);

    ssa_inst_append(b0, (*SSAInstruction)c1_ptr);
    ssa_inst_append(b0, (*SSAInstruction)c2_ptr);
    ssa_inst_append(b0, (*SSAInstruction)add_ptr);
    ssa_inst_append(b0, (*SSAInstruction)ret_ptr);

    ssa_dump_ctx(ctx, 1);
    return 0;
}
