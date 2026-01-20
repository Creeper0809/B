// 92_static_var.b - Test static variables in impl blocks
// Expect exit code: 42

struct Counter {
    value: i64;
}

impl Counter {
    static var count: i64 = 0;
    
    static func new() -> Counter {
        Counter_count = Counter_count + 1;
        var c: Counter;
        c.value = Counter_count;
        return c;
    }
    
    static func get_total() -> i64 {
        return Counter_count;
    }
}

func main() -> i64 {
    var c1: Counter = Counter.new();
    var c2: Counter = Counter.new();
    var c3: Counter = Counter.new();
    
    var total = Counter.get_total();
    
    // Should be 3
    if (total == 3) {
        return 42;
    }
    
    return 1;
}
