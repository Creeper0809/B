// 105_tagged_ptr_basic.b - tagged pointer auto-masking
// Expect exit code: 42

import util;

func main() -> i64 {
    var mem = heap_alloc(8);
    var raw: u64 = (u64)mem;
    var tag: u64 = 4660;
    var tagged_val: u64 = (raw & 281474976710655) | (tag << 48);

    var tptr: *tagged u8 = (*tagged u8)tagged_val;
    *tptr = 55;

    var v = *tptr;
    if (v != 55) { return 1; }

    return 42;
}
