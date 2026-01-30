// Regression: TypeInfo(40 bytes) 전달/해석 검증 (중첩 . / -> 체인)
// Expect exit code: 42
// Mode: ssa
// Opt: O1

struct Inner {
    a: u64;
}

struct Outer {
    inner: Inner;
    p: *Inner;
}

func main(argc, argv) {
    var inner: Inner;
    inner.a = 0;

    var outer: Outer;
    outer.inner = inner;
    outer.p = &inner;

    var o: *Outer;
    o = &outer;

    // -> 다음에 . 체인
    o->inner.a = 0;

    // -> 다음에 -> 체인
    o->p->a = 42;

    return o->inner.a + o->p->a;
}
