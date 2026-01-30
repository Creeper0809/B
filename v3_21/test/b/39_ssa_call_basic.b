// Test 39: SSA call basic
// Mode: ssa
// Expect exit code: 0

var g;

func add(a: i64, b: i64) -> i64 {
    return a + b;
}

func inc() -> i64 {
    g = g + 1;
    return g;
}

func main(argc, argv) {
    g = 0;
    var a: i64 = add(2, 3);
    if (a != 5) { return 1; }
    var b: i64 = inc();
    if (b != 1) { return 1; }
    var c: i64 = add(4, 6);
    if (c != 10) { return 1; }
    return 0;
}
