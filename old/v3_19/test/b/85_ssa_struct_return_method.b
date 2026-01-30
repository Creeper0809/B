// Covers: Struct return from method call
// Mode: ssa
// Opt: O1
// Expect exit code: 100

struct Counter {
    value: i64;
}

impl Counter {
    func get(self: *Counter) -> Counter {
        var c: Counter;
        c.value = self->value;
        return c;
    }

    func inc(self: *Counter) -> Counter {
        var c: Counter;
        c.value = self->value + 1;
        return c;
    }
}

func main() -> i64 {
    var c: Counter;
    c.value = 99;
    var c2: Counter = c.inc();
    return c2.value;
}
