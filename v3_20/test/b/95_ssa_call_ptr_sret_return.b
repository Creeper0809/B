// Covers: SSA call_ptr sret return
// Mode: ssa
// Opt: O1
// Expect exit code: 6

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
    var out: Large = fp(1, 2, 3);
    return out.a + out.b + out.c;
}
