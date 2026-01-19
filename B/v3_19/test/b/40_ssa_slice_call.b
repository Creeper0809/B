// Test 40: SSA slice argument call
// Mode: ssa
// Expect exit code: 0

func first_byte(s: []u8) -> i64 {
    return s[0];
}

func main(argc, argv) {
    var v: i64 = first_byte(slice("ABC", 3));
    if (v != 65) { return 1; }
    return 0;
}
