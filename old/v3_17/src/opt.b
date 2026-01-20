// opt.b - optimization flags (v3_17)

var g_opt_level;
var g_ir_mode;

const IR_NONE = 0;
const IR_3ADDR = 1;
const IR_SSA = 2;

func opt_set_level(level: u64) -> u64 {
    g_opt_level = level;
    return 0;
}

func opt_get_level() -> u64 {
    return g_opt_level;
}

func opt_set_ir_mode(mode: u64) -> u64 {
    g_ir_mode = mode;
    return 0;
}

func opt_get_ir_mode() -> u64 {
    return g_ir_mode;
}
