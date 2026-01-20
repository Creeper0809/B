// 83_struct_return_complex.b - Complex struct return scenarios
// Expect exit code: 42

struct Pair {
    first: i64;
    second: i64;
}

func Pair_new(a: i64, b: i64) -> Pair {
    var p: Pair;
    p.first = a;
    p.second = b;
    return p;
}

func Pair_swap(p: *Pair) -> Pair {
    return Pair_new(p->second, p->first);
}

func fibonacci_pair(n: i64) -> Pair {
    if (n == 0) {
        return Pair_new(0, 1);
    }
    if (n == 1) {
        return Pair_new(1, 1);
    }
    
    var prev: Pair = fibonacci_pair(n - 1);
    return Pair_new(prev.second, prev.first + prev.second);
}

func main() -> i64 {
    // Test swap
    var p1: Pair = Pair_new(10, 20);
    var p2: Pair = Pair_swap(&p1);
    
    if (p2.first != 20 || p2.second != 10) {
        return 1;
    }
    
    // Test fibonacci (5th number: 0,1,1,2,3,5)
    var fib: Pair = fibonacci_pair(5);
    
    if (fib.first != 5) {
        return 2;
    }
    
    return 42;
}
