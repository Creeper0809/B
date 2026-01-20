// Expect exit code: 0

import std.str;
import str_eq as eq from std.str;
import str_concat as join from std.str;

func main() -> i64 {
    if (!eq("abc", 3, "abc", 3)) { return 1; }

    var s;
    s = join("a", 1, "b", 1);
    if (!str_eq(s, 2, "ab", 2)) { return 2; }

    return 0;
}
