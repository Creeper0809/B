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
    Counter_init(&c, 5);
    
    // Chain: 5 -> 6 -> 16 -> 32
    Counter_increment(&c);
    Counter_add(&c, 10);
    Counter_multiply(&c, 2);
    
    var result = Counter_get(&c);
    
    if (result == 32) {
        return 42;
    }
    return 1;
}
