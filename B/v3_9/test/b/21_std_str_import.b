// Expect exit code: 0

import std.io;
import std.str;

func main() -> i64 {
    if (!str_eq("abc", 3, "abc", 3)) { return 1; }

    var s;
    s = str_concat("a", 1, "b", 1);
    if (!str_eq(s, 2, "ab", 2)) { return 2; }

    emit("ok\n", 3);
    return 0;
}
