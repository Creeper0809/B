// 102_slice_basic.b - Test slice type basics
// Expect exit code: 42

import std.io;
import std.emit;

func main() -> i64 {
    var arr: [5]i64;
    arr[0] = 10;
    arr[1] = 20;
    arr[2] = 30;
    arr[3] = 40;
    arr[4] = 50;

    var p: *i64 = arr;
    var s: []i64 = slice(p, 5);

    if (s[0] != 10) { return 1; }
    if (s[4] != 50) { return 2; }

    var sum = 0;
    var i = 0;
    for (i = 0; i < 5; i++) {
        sum = sum + s[i];
    }
    if (sum != 150) { return 3; }

    return 42;
}
