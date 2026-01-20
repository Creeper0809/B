// Expect exit code: 0

import std.io;
import std.char;

func main() -> i64 {
    if (!is_alpha(65)) { return 1; }      // 'A'
    if (!is_alpha(95)) { return 2; }      // '_'
    if (!is_digit(57)) { return 3; }      // '9'
    if (!is_alnum(122)) { return 4; }     // 'z'
    if (!is_whitespace(10)) { return 5; } // '\n'

    emit("ok\n", 3);
    return 0;
}
