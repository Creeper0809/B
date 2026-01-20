// 106_tagged_layout_packed_struct.b - tagged layout with packed struct
// Expect exit code: 42



packed struct TaggedPtrBits {
    tag: u16;
}

func main() -> i64 {
    var mem = heap_alloc(8);
    var raw: u64 = (u64)mem;
    var p: *tagged(TaggedPtrBits) u8 = (*tagged(TaggedPtrBits) u8)raw;
    p.tag = 1;
    *p = 77;

    if (p.tag != 1) { return 0; }
    if (*p != 77) { return 1; }

    return 42;
}
