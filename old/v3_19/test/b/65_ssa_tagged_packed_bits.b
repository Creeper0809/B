// Test 65: SSA tagged pointer + packed bitfield access
// Mode: ssa
// Expect exit code: 0

import std.io;

packed struct TaggedPtrBits {
    tag: u16;
}

packed struct Bits {
    ver: u4;
    id: u12;
}

func test_tagged_ptr_basic() -> i64 {
    var buf: [8]u8;
    var raw: u64 = (u64)&buf[0];
    var tag: u64 = 4660;
    var tagged_val: u64 = (raw & 281474976710655) | (tag << 48);

    var tptr: *tagged u8 = (*tagged u8)tagged_val;
    *tptr = 55;
    tptr[0] = 66;

    var v = *tptr;
    if (v != 66) { return 1; }
    if (tptr[0] != 66) { return 2; }

    return 0;
}

func test_tagged_layout_packed_struct() -> i64 {
    var buf: [8]u8;
    var raw: u64 = (u64)&buf[0];
    var p: *tagged(TaggedPtrBits) u8 = (*tagged(TaggedPtrBits) u8)(raw & 281474976710655);
    p.tag = 1;
    *p = 77;

    if (p.tag != 1) { return 3; }
    if (*p != 77) { return 4; }

    return 0;
}

func test_packed_bitfield_access() -> i64 {
    var b: Bits;
    b.ver = 3;
    b.id = 4095;

    if (b.ver != 3) { return 5; }
    if (b.id != 4095) { return 6; }

    return 0;
}

func main() -> i64 {
    var r = 0;

    r = test_tagged_ptr_basic();
    if (r != 0) { return r; }

    r = test_tagged_layout_packed_struct();
    if (r != 0) { return r; }

    r = test_packed_bitfield_access();
    if (r != 0) { return r; }

    return 0;
}
