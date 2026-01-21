// Test 32: SSA for/switch
// Mode: ssa
// Expect exit code: 0

func calc(n: i64) -> i64 {
    var sum: i64 = 0;
    for (var i: i64 = 0; i < n; i = i + 1) {
        if (i == 2) { continue; }
        switch (i) {
            case 0:
                sum = sum + 1;
                break;
            case 1:
                sum = sum + 10;
                break;
            default:
                sum = sum + 100;
        }
    }
    return sum;
}

func main(argc, argv) {
    var v = calc(4);
    if (v != 111) { return 1; }
    return 0;
}
