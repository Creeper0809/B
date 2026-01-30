// Test 47: SSA slice init/copy
// Mode: ssa
// Expect exit code: 0

func main(argc, argv) {
    var s: []u8 = slice("ABC", 3);
    var t: []u8 = s;
    if (t[0] != 65) { return 1; }
    if (t[1] != 66) { return 2; }
    if (t[2] != 67) { return 3; }
    return 0;
}
