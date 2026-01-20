// Test 43: SSA method call expression
// Mode: ssa
// Expect exit code: 0

struct Pair {
    a: i64;
    b: i64;
}

impl Pair {
    func init(self: *Pair, x: i64, y: i64) {
        self->a = x;
        self->b = y;
    }

    func sum(self: *Pair) -> i64 {
        return self->a + self->b;
    }
}

func main(argc, argv) {
    var p: Pair;
    p.init(10, 20);
    var s: i64 = p.sum();
    if (s != 30) { return 1; }
    return 0;
}
