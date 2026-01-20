// 93_static_func.b - Test static functions in impl blocks
// Expect exit code: 42

struct Math {
    dummy: i64;
}

impl Math {
    static func add(a: i64, b: i64) -> i64 {
        return a + b;
    }
    
    static func multiply(a: i64, b: i64) -> i64 {
        return a * b;
    }
    
    static func calculate(x: i64) -> i64 {
        var sum = Math.add(x, 10);
        var product = Math.multiply(sum, 2);
        return product;
    }
}

func main() -> i64 {
    var result = Math.calculate(11);
    
    // (11 + 10) * 2 = 42
    if (result == 42) {
        return 42;
    }
    
    return 1;
}
