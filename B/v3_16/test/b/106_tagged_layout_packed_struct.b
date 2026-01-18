// 106_tagged_layout_packed_struct.b - tagged layout with packed struct
// Expect exit code: 42

import util;

packed struct TaggedPtrBits {
    addr: u64;
    tag: u64;
}

func main() -> i64 {
    var mem = heap_alloc(8);
    var raw: u64 = (u64)mem;
    var tag: u64 = 1;
    var tagged_val: u64 = (raw & 281474976710655) | (tag << 48);

    var p: *tagged(TaggedPtrBits) u8 = (*tagged(TaggedPtrBits) u8)tagged_val;
    *p = 77;

    var v = *p;
    if (v != 77) { return 1; }

    return 42;
}
