// 51_struct_copy_nested.b - 중첩 구조체 값 복사
// Expect exit code: 42

struct Inner {
    a: i64;
    b: i64;
}

struct Outer {
    inner: Inner;
    c: i64;
}

func main(argc, argv) {
    var inner1: Inner = Inner { 10, 20 };
    var outer: Outer;
    
    // 중첩 구조체 값 복사
    outer.inner = inner1;
    outer.c = 12;
    
    // outer.inner.a + outer.inner.b + outer.c = 10 + 20 + 12 = 42
    return outer.inner.a + outer.inner.b + outer.c;
}
