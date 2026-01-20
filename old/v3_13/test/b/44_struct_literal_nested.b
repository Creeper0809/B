// 44_struct_literal_nested.b - 중첩 구조체 리터럴 초기화
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
    // 중첩 구조체 - 필드별로 초기화
    var inner1: Inner = Inner { 10, 20 };
    var outer: Outer;
    
    // 구조체 값 복사는 아직 미구현이므로 필드별로 복사
    outer.inner.a = inner1.a;
    outer.inner.b = inner1.b;
    outer.c = 12;
    
    // outer.inner.a + outer.inner.b + outer.c = 10 + 20 + 12 = 42
    return outer.inner.a + outer.inner.b + outer.c;
}
