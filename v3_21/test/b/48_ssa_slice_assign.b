// Test 48: SSA slice assign
// Mode: ssa
// Expect exit code: 0

func main(argc, argv) {
    var s: []u8;
    s = slice("XYZ", 3);
    if (s[2] != 90) { return 1; }
    var t: []u8;
    t = s;
    if (t[0] != 88) { return 2; }
    return 0;
}
