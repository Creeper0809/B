// Expect exit code: 0
// Covers: std.str/std.path/std.char imports

import std.io;
import std.str;
import std.path;
import std.char;

func main() -> i64 {
    if (!str_eq("abc", 3, "abc", 3)) { return 1; }

    var s;
    s = str_concat("a", 1, "b", 1);
    if (!str_eq(s, 2, "ab", 2)) { return 2; }

    var p;
    p = module_to_path("abc", 3);
    if (!str_eq(p, 5, "abc.b", 5)) { return 3; }

    var j;
    j = path_join("a", 1, "b", 1);
    if (!str_eq(j, 3, "a/b", 3)) { return 4; }

    var d1;
    d1 = path_dirname("a/b/c", 5);
    if (!str_eq(d1, 3, "a/b", 3)) { return 5; }

    var d2;
    d2 = path_dirname("abc", 3);
    if (!str_eq(d2, 1, ".", 1)) { return 6; }

    if (!is_alpha(65)) { return 7; }      // 'A'
    if (!is_alpha(95)) { return 8; }      // '_'
    if (!is_digit(57)) { return 9; }      // '9'
    if (!is_alnum(122)) { return 10; }    // 'z'
    if (!is_whitespace(10)) { return 11; } // '\n'

    emit("ok\n", 3);
    return 0;
}
