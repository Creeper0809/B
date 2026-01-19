// Expect exit code: 0

import opt;

func main() -> i64 {
    opt_set_level(1);
    if (opt_get_level() != 1) { return 1; }

    opt_set_ir_mode(IR_3ADDR);
    if (opt_get_ir_mode() != IR_3ADDR) { return 2; }

    opt_set_ir_mode(IR_SSA);
    if (opt_get_ir_mode() != IR_SSA) { return 3; }

    opt_set_ir_mode(IR_NONE);
    if (opt_get_ir_mode() != IR_NONE) { return 4; }

    return 0;
}
