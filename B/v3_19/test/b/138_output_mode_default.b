// Expect exit code: 0

import opt;

func main() -> i64 {
    if (opt_get_output_mode() != OUT_EXEC) { return 1; }
    return 0;
}
