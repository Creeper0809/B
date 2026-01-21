// Test 34: SSA string literal
// Mode: ssa
// Expect exit code: 0

func main(argc, argv) {
    var a = "hello";
    var b = "hello";
    var c = "world";

    if (a != b) { return 1; }
    if (a == c) { return 2; }
    return 0;
}
