// Test 40: SSA slice argument call
// Mode: ssa
// Expect exit code: 0

func first_byte(s: []u8) -> i64 {
    return s[0];
}

func last_byte(s: []u8, n: i64) -> i64 {
    return s[n - 1];
}

func main(argc, argv) {
    var v: i64 = first_byte(slice("ABC", 3));
    if (v != 65) { return 1; }
    var w: i64 = last_byte(slice("XYZ", 3), 3);
    if (w != 90) { return 2; }
    return 0;
}
