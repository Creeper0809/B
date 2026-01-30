// Test 60: SSA method call pointer liveness
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

    if (p->get() != 1) { return 1; }

    p->add(2);
    if (p->get() != 3) { return 2; }

    p->add(4);
    if (p->get() != 7) { return 3; }

    return 0;
}
