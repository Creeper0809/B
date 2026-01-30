// Test 62: SSA struct literal assign to deref
// Mode: ssa
// Expect exit code: 0

struct Pair {
    a: i64;
    b: i64;
}

func main(argc, argv) {
    var p: Pair;
    var q: Pair;
    var pp: *Pair = &p;

    *pp = Pair { 1, 2 };
    if (p.a != 1) { return 1; }
    if (p.b != 2) { return 2; }

    q = Pair { 3, 4 };
    if (q.a != 3) { return 3; }
    if (q.b != 4) { return 4; }

    return 0;
}
