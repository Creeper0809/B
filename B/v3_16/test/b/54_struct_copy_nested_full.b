// 54_struct_copy_nested_full.b - 중첩 구조체 전체 복사
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
    var o1: Outer;
    o1.inner.a = 10;
    o1.inner.b = 20;
    o1.c = 12;
    
    // Outer 전체를 복사 (Inner 포함)
    var o2: Outer;
    o2 = o1;
    
    // o2 수정해도 o1은 변하지 않음
    o2.inner.a = 100;
    o2.inner.b = 200;
    o2.c = 120;
    
    // o1은 원본 유지: 10 + 20 + 12 = 42
    return o1.inner.a + o1.inner.b + o1.c;
}
