// Covers: SSA large struct return member access (call + call_ptr)
// Mode: ssa
// Opt: O1
// Expect exit code: 8

struct Large {
    a: i64;
    b: i64;
    c: i64;
}

func make_large(x: i64, y: i64, z: i64) -> Large {
    var l: Large;
    l.a = x;
    l.b = y;
    l.c = z;
    return l;
}

func main() -> i64 {
    var fp: u64 = &make_large;
    var v1: i64 = make_large(1, 2, 3).b;
    var v2: i64 = fp(4, 5, 6).c;
    return v1 + v2;
}
