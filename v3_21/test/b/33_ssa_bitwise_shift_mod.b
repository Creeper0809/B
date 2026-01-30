// Test 33: SSA bitwise/shift/mod
// Mode: ssa
// Expect exit code: 0

func main(argc, argv) {
    var a: i64 = 42;
    var b: i64 = 5;
    var r = (a % b) + ((a & 7) << 2) + ((a | 3) ^ 1) + (a >> 1);
    if (r != 73) { return 1; }
    return 0;
}
