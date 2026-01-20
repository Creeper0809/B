// 86_impl_chaining.b - Method chaining with impl blocks
// Expect exit code: 42

struct Counter {
    value: i64;
}

impl Counter {
    func init(self: *Counter, val: i64) {
        self->value = val;
    }
    
    func increment(self: *Counter) {
        self->value = self->value + 1;
    }
    
    func add(self: *Counter, n: i64) {
        self->value = self->value + n;
    }
    
    func multiply(self: *Counter, n: i64) {
        self->value = self->value * n;
    }
    
    func get(self: *Counter) -> i64 {
        return self->value;
    }
}

func main() -> i64 {
    var c: Counter;
    c.init(5);
    
    // Chain: 5 -> 6 -> 16 -> 32
    c.increment();
    c.add(10);
    c.multiply(2);
    
    var result = c.get();
    
    if (result == 32) {
        return 42;
    }
    return 1;
}
