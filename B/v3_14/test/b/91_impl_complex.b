// 91_impl_complex.b - Complex impl with nested calls
// Expect exit code: 42

struct Pair {
    first: i64;
    second: i64;
}

impl Pair {
    func init(self: *Pair, a: i64, b: i64) {
        self->first = a;
        self->second = b;
    }
    
    func sum(self: *Pair) -> i64 {
        return self->first + self->second;
    }
    
    func product(self: *Pair) -> i64 {
        return self->first * self->second;
    }
    
    func swap(self: *Pair) {
        var temp = self->first;
        self->first = self->second;
        self->second = temp;
    }
}

func process_pairs() -> i64 {
    var p1: Pair;
    var p2: Pair;
    
    Pair_init(&p1, 5, 7);   // 5, 7
    Pair_init(&p2, 3, 4);   // 3, 4
    
    var sum1 = Pair_sum(&p1);       // 12
    var sum2 = Pair_sum(&p2);       // 7
    var prod = Pair_product(&p2);   // 12
    
    return sum1 + sum2 + prod;  // 12 + 7 + 12 = 31
}

func main() -> i64 {
    var result = process_pairs();
    
    if (result == 31) {
        return 42;
    }
    return 1;
}
