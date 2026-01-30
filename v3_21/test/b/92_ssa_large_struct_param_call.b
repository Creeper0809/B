// Covers: SSA large struct param byval (direct call + literal)
// Mode: ssa
// Opt: O1
// Expect exit code: 21

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
    l.a = 1;
    l.b = 2;
    l.c = 3;

    var v1: i64 = sum_large(l);
    var v2: i64 = sum_large(Large { 4, 5, 6 });
    return v1 + v2;
}
