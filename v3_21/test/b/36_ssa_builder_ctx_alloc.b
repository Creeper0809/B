// Test 36: SSA builder ctx alloc regression
// Mode: ssa
// Expect exit code: 0

func foo() -> i64 {
    var a: i64 = 1;
    var b: i64 = 2;
    return a + b;
}

func main(argc, argv) {
    var v = foo();
    if (v != 3) { return 1; }
    return 0;
}
