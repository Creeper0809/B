// Test 50: SSA function pointer call
// Mode: ssa
// Expect exit code: 0

var g;

func add(a: i64, b: i64) -> i64 {
    return a + b;
}

func main(argc, argv) {
    var fp: u64 = &add;
    var v: i64 = fp(7, 8);
    if (v != 15) { return 1; }

    var pg: *i64 = &g;
    *pg = 9;
    if (g != 9) { return 2; }

    var fp2: u64 = &add;
    var v2: i64 = fp2(1, 2);
    if (v2 != 3) { return 3; }

    return 0;
}
