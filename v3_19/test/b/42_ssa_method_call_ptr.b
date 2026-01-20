// Test 42: SSA method call via pointer receiver
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
    c.init(1);
    var p: *Counter = &c;
    p->add(6);
    if (p->get() != 7) { return 1; }
    p->add(2);
    if (p->get() != 9) { return 1; }
    return 0;
}
