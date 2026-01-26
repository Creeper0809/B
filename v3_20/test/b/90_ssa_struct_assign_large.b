// Test 90: SSA large struct assignment/copy
// Mode: ssa
// Opt: O1
// Expect exit code: 0

struct Big {
    a: u64;
    b: u64;
    c: u64;
    d: u64;
    e: u64;
}

func make_big(x: u64) -> Big {
    var r: Big;
    r.a = x;
    r.b = x + 1;
    r.c = x + 2;
    r.d = x + 3;
    r.e = x + 4;
    return r;
}

func main(argc, argv) {
    var b: Big;
    b = make_big(10);
    if (b.c != 12) { return 1; }

    var c: Big;
    c = b;
    if (c.e != 14) { return 2; }

    return 0;
}
