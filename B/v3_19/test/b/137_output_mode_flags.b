// Expect exit code: 0

import opt;

func main() -> i64 {
    opt_set_output_mode(OUT_EXEC);
    if (opt_get_output_mode() != OUT_EXEC) { return 1; }

    opt_set_output_mode(OUT_IR);
    if (opt_get_output_mode() != OUT_IR) { return 2; }

    opt_set_output_mode(OUT_ASM);
    if (opt_get_output_mode() != OUT_ASM) { return 3; }

    return 0;
}
