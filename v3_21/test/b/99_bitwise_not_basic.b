// Covers: Unary bitwise NOT (~) in AST codegen
// Mode: nossa
// Opt: O0
// Expect exit code: 14

func main() -> i64 {
    var v: i64 = ~1;
    var r: i64 = v & 15;
    return r;
}
