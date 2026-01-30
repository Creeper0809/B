// Covers: Unary bitwise NOT (~) in SSA codegen
// Mode: ssa
// Opt: O1
// Expect exit code: 14

func main() -> i64 {
    var v: i64 = ~1;
    var r: i64 = v & 15;
    return r;
}
