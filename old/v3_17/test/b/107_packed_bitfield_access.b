// 107_packed_bitfield_access.b - packed struct bitfield access
// Expect exit code: 42

packed struct Bits {
    ver: u4;
    id: u12;
}

func main() -> i64 {
    var b: Bits;
    b.ver = 3;
    b.id = 4095;

    if (b.ver != 3) { return 1; }
    if (b.id != 4095) { return 2; }

    return 42;
}
