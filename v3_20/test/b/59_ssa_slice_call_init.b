// Test 59: SSA slice init from call
// Mode: ssa
// Expect exit code: 0

func make_slice(p: *u8, n: i64) -> []u8 {
    return slice(p, n);
}

func main(argc, argv) {
    var arr: [3]u8;
    arr[0] = 11;
    arr[1] = 22;
    arr[2] = 33;

    var s: []u8 = make_slice(arr, 3);
    if (s[0] != 11) { return 1; }
    if (s[2] != 33) { return 2; }
    return 0;
}
