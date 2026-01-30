// Covers: SSA sizeof(expr)
// Mode: ssa
// Opt: O1
// Expect exit code: 48

struct Pair {
    a: i64;
    b: i64;
}

func main() -> i64 {
    var p: Pair;
    var arr: [3]i64;
    var sz1: i64 = sizeof(p);
    var sz2: i64 = sizeof(arr);
    var sz3: i64 = sizeof(&p);
    return sz1 + sz2 + sz3;
}
