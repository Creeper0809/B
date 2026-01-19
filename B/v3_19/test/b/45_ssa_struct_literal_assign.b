// Test 45: SSA struct literal assign
// Mode: ssa
// Expect exit code: 0

struct Pair {
    a: i64;
    b: i64;
}

func main(argc, argv) {
    var p: Pair;
    p = Pair { 5, 7 };
    if (p.a + p.b != 12) { return 1; }
    p = Pair { 1, 2 };
    if (p.a * 10 + p.b != 12) { return 1; }
    return 0;
}
