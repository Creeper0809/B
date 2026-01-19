// Test 49: SSA slice struct field init
// Mode: ssa
// Expect exit code: 0

struct Wrap {
    s: []u8;
}

func main(argc, argv) {
    var w: Wrap = Wrap { slice("HI", 2) };
    if (w.s[0] != 72) { return 1; }
    if (w.s[1] != 73) { return 2; }
    return 0;
}
