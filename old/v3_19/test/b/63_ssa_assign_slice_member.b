// Test 63: SSA slice assign to member/deref
// Mode: ssa
// Expect exit code: 0

struct Wrap {
    s: []u8;
}

func main(argc, argv) {
    var w: Wrap;
    w.s = slice("HI", 2);
    if (w.s[1] != 73) { return 1; }

    var pw: *Wrap = &w;
    pw->s = slice("OK", 2);
    if (w.s[0] != 79) { return 2; }

    return 0;
}
