// Test: Nested struct access with . operator
// Expect exit code: 42

struct Inner {
    a: u64;
    b: u64;
}

struct Outer {
    inner: Inner;
    c: u64;
}

func main(argc, argv) {
    var outer: Outer;
    
    // Access nested struct members
    outer.inner.a = 10;
    outer.inner.b = 15;
    outer.c = 17;
    
    return outer.inner.a + outer.inner.b + outer.c;  // 10 + 15 + 17 = 42
}
