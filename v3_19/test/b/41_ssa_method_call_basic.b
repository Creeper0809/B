// Test 41: SSA method call basic
// Mode: ssa
// Expect exit code: 0

struct Counter {
    value: i64;
}

impl Counter {
    func init(self: *Counter, v: i64) {
        self->value = v;
    }

    func add(self: *Counter, n: i64) {
        self->value = self->value + n;
    }

    func get(self: *Counter) -> i64 {
        return self->value;
    }
}

func main(argc, argv) {
    var c: Counter;
    c.init(3);
    c.add(4);
    if (c.get() != 7) { return 1; }
    c.add(5);
    if (c.get() != 12) { return 1; }
    return 0;
}
