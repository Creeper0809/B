// Expect exit code: 100
// Mode: ssa
// Opt: O1

struct Small {
    val: i64;
}

func make_small(val: i64) -> Small {
    return Small { val };
}

func main() -> i64 {
    var s: Small = make_small(100);
    return s.val;
}
