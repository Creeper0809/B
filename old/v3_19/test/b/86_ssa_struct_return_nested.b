// Covers: Nested struct return
// Mode: ssa
// Opt: O1
// Expect exit code: 150

struct Inner {
    val: i64;
}

struct Outer {
    inner: Inner;
    extra: i64;
}

func make_outer(v: i64) -> Outer {
    return Outer { Inner { v }, v * 2 };
}

func main() -> i64 {
    var o: Outer = make_outer(50);
    return o.inner.val + o.extra;
}
