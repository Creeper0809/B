// Test 46: SSA struct literal with expressions
// Mode: ssa
// Expect exit code: 0

struct Vec2 {
    x: i64;
    y: i64;
}

func main(argc, argv) {
    var a: i64 = 3;
    var b: i64 = 4;
    var v: Vec2 = Vec2 { a * 2, b + 1 };
    if (v.x + v.y != 11) { return 1; }
    return 0;
}
