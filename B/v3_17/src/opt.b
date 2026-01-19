// opt.b - optimization flags (v3_17)

var g_opt_level;

func opt_set_level(level: u64) -> u64 {
    g_opt_level = level;
    return 0;
}

func opt_get_level() -> u64 {
    return g_opt_level;
}
