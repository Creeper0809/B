// 109_memset.b - std.mem memset basic test
// Expect exit code: 42

import std.mem;
import std.io;

func main() -> i64 {
    var buf = heap_alloc(16);
    memset(buf, 171, 16);

    var ok: u64 = 1;
    for (var i: u64 = 0; i < 16; i++) {
        if (*(*u8)(buf + i) != 171) { ok = 0; }
    }

    if (ok == 0) { return 0; }
    return 42;
}
