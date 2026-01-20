// Test 64: O1 SSA slice return
// Mode: ssa
// Opt: O1
// Expect exit code: 0

func make_slice(p: *u8, n: i64) -> []u8 {
    var s: []u8 = slice(p, n);
    return s;
}

func main(argc, argv) {
    var arr: [4]u8;
    arr[0] = 65;
    arr[1] = 66;
    arr[2] = 67;
    arr[3] = 68;

    var s: []u8 = make_slice(arr, 4);
    if (s[0] != 65) { return 1; }
    if (s[3] != 68) { return 2; }
    return 0;
}
