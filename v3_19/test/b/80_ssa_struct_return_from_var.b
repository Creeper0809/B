// Expect exit code: 55
// Mode: ssa
// Opt: O1

struct Pair {
    a: i64;
    b: i64;
}

func get_pair() -> Pair {
    var p: Pair = Pair { 30, 25 };
    return p;
}

func main() -> i64 {
    var result: Pair = get_pair();
    return result.a + result.b;
}
