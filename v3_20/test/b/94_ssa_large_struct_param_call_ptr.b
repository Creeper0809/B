// Covers: SSA large struct param in call_ptr
// Mode: ssa
// Opt: O1
// Expect exit code: 18

struct Large {
    a: i64;
    b: i64;
    c: i64;
}

func sum_large(l: Large) -> i64 {
    return l.a + l.b + l.c;
}

func main() -> i64 {
    var l: Large;
    l.a = 3;
    l.b = 4;
    l.c = 5;

    var fp: u64 = &sum_large;
    var v1: i64 = fp(l);
    var v2: i64 = fp(Large { 1, 2, 3 });
    return v1 + v2;
}
