// Expect exit code: 0

import std.os;

func main() -> i64 {
    var r: i64 = (i64)os_sys_dup2(1, 1);
    if (r < 0) { return 1; }
    return 0;
}
