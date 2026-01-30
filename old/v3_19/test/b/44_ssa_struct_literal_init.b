// Test 44: SSA struct literal init
// Mode: ssa
// Expect exit code: 0

struct Point {
    x: i64;
    y: i64;
}

func main(argc, argv) {
    var p: Point = Point { 10, 32 };
    if (p.x + p.y != 42) { return 1; }
    return 0;
}
