// Covers: SSA nested struct literal byval arg
// Mode: ssa
// Opt: O1
// Expect exit code: 10

struct Inner {
    a: i64;
    b: i64;
}

struct Outer {
    inner: Inner;
    c: i64;
    d: i64;
}

func sum_outer(o: Outer) -> i64 {
    return o.inner.a + o.inner.b + o.c + o.d;
}

func main() -> i64 {
    return sum_outer(Outer { Inner { 1, 2 }, 3, 4 });
}
