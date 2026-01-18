// 103_slice_struct_fields.b - Slice params/returns and struct fields
// Expect exit code: 42

import io;
import util;

struct Holder {
    arr: [3]i64;
    s: []i64;
}

func sum_slice(s: []i64, n: i64) -> i64 {
    var sum = 0;
    var i = 0;
    for (i = 0; i < n; i++) {
        sum = sum + s[i];
    }
    return sum;
}

func make_slice(p: *i64, n: i64) -> []i64 {
    return slice(p, n);
}

func main() -> i64 {
    var h: Holder;

    h.arr[0] = 1;
    h.arr[1] = 2;
    h.arr[2] = 3;

    var base: [3]i64;
    base[0] = 10;
    base[1] = 20;
    base[2] = 30;

    var p: *i64 = base;
    h.s = slice(p, 3);

    if (h.arr[1] != 2) { return 1; }
    if (h.s[2] != 30) { return 2; }

    var s2: []i64 = make_slice(p, 3);
    var total = sum_slice(s2, 3);
    if (total != 60) { return 3; }

    return 42;
}
