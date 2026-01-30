// Test 52: SSA nested struct literal fields
// Mode: ssa
// Expect exit code: 0

struct Inner {
    a: i64;
    b: i64;
}

struct Outer {
    x: i64;
    inner: Inner;
    y: i64;
}

func main(argc, argv) {
    var o: Outer = Outer { 1, Inner { 2, 3 }, 4 };
    if (o.x != 1) { return 1; }
    if (o.inner.a != 2) { return 2; }
    if (o.inner.b != 3) { return 3; }
    if (o.y != 4) { return 4; }
    return 0;
}
