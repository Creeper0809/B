// Test 37: SSA destroy COPY before terminator
// Mode: ssa
// Expect exit code: 0

func choose(n: i64) -> i64 {
    var x: i64 = 0;
    if (n > 0) {
        x = 1;
    } else {
        x = 2;
    }
    return x;
}

func main(argc, argv) {
    var a: i64 = choose(1);
    if (a != 1) { return 1; }
    var b: i64 = choose(0);
    if (b != 2) { return 1; }
    return 0;
}
