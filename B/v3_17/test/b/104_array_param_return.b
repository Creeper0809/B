// 104_array_param_return.b - Array param/return decay to pointer
// Expect exit code: 42

import std.io;
import std.emit;

func sum_arr(a: [3]i64) -> i64 {
    return a[0] + a[1] + a[2];
}

func pass_arr(a: [3]i64) -> [3]i64 {
    // Returns pointer to caller-owned array
    return a;
}

func main() -> i64 {
    var arr: [3]i64;
    arr[0] = 7;
    arr[1] = 8;
    arr[2] = 9;

    var total = sum_arr(arr);
    if (total != 24) { return 1; }

    var p: *i64 = pass_arr(arr);
    if (p[1] != 8) { return 2; }

    return 42;
}
