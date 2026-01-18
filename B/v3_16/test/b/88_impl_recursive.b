// 88_impl_recursive.b - Recursive impl method
// Expect exit code: 42

struct Math {
    dummy: i64;
}

impl Math {
    func factorial(n: i64) -> i64 {
        if (n <= 1) {
            return 1;
        }
        return n * Math.factorial(n - 1);
    }
    
    func fibonacci(n: i64) -> i64 {
        if (n == 0) {
            return 0;
        }
        if (n == 1) {
            return 1;
        }
        return Math.fibonacci(n - 1) + Math.fibonacci(n - 2);
    }
    
    func power(base: i64, exp: i64) -> i64 {
        if (exp == 0) {
            return 1;
        }
        return base * Math.power(base, exp - 1);
    }
}

func main() -> i64 {
    var fact5 = Math.factorial(5);  // 120
    var fib7 = Math.fibonacci(7);   // 13
    var pow = Math.power(2, 5);     // 32
    
    var sum = fact5 + fib7 + pow;   // 120 + 13 + 32 = 165
    
    if (sum == 165) {
        return 42;
    }
    return 1;
}
