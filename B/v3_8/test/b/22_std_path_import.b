// Expect exit code: 0

import std.io;
import std.path;
import std.str;

func main() -> i64 {
    var s;
    s = module_to_path("abc", 3);
    if (!str_eq(s, 5, "abc.b", 5)) { return 1; }

    var j;
    j = path_join("a", 1, "b", 1);
    if (!str_eq(j, 3, "a/b", 3)) { return 2; }

    var d1;
    d1 = path_dirname("a/b/c", 5);
    if (!str_eq(d1, 3, "a/b", 3)) { return 3; }

    var d2;
    d2 = path_dirname("abc", 3);
    if (!str_eq(d2, 1, ".", 1)) { return 4; }

    emit("ok\n", 3);
    return 0;
}
