// 108_forward_call.b - forward call without prior declaration
// Expect exit code: 42
// Mode: ssa
// Opt: O1

func main() -> i64 {
    var v: u64 = add_one(41);
    if (v != 42) { return 0; }
    return 42;
}

func add_one(x: u64) -> u64 {
    return x + 1;
}
