// Expect exit code: 70
// Mode: ssa
// Opt: O1

struct Inner {
    val: i64;
}

struct Outer {
    a: Inner;
    b: Inner;
}

func make_inner(v: i64) -> Inner {
    return Inner { v };
}

func make_outer(x: i64, y: i64) -> Outer {
    return Outer { make_inner(x), make_inner(y) };
}

func main() -> i64 {
    var o: Outer = make_outer(30, 40);
    return o.a.val + o.b.val;
}
