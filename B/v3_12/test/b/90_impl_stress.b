// 90_impl_stress.b - Stress test with many impl methods
// Expect exit code: 42

struct Calculator {
    result: i64;
}

impl Calculator {
    func init(self: *Calculator) {
        self->result = 0;
    }
    
    func add(self: *Calculator, n: i64) {
        self->result = self->result + n;
    }
    
    func sub(self: *Calculator, n: i64) {
        self->result = self->result - n;
    }
    
    func mul(self: *Calculator, n: i64) {
        self->result = self->result * n;
    }
    
    func div(self: *Calculator, n: i64) {
        if (n != 0) {
            self->result = self->result / n;
        }
    }
    
    func mod(self: *Calculator, n: i64) {
        if (n != 0) {
            self->result = self->result % n;
        }
    }
    
    func abs(self: *Calculator) {
        if (self->result < 0) {
            self->result = 0 - self->result;
        }
    }
    
    func negate(self: *Calculator) {
        self->result = 0 - self->result;
    }
    
    func square(self: *Calculator) {
        self->result = self->result * self->result;
    }
    
    func reset(self: *Calculator) {
        self->result = 0;
    }
    
    func get(self: *Calculator) -> i64 {
        return self->result;
    }
}

func main() -> i64 {
    var calc: Calculator;
    Calculator_init(&calc);
    
    // Complex calculation sequence
    Calculator_add(&calc, 10);      // 10
    Calculator_mul(&calc, 5);       // 50
    Calculator_sub(&calc, 8);       // 42
    Calculator_add(&calc, 3);       // 45
    Calculator_div(&calc, 3);       // 15
    Calculator_square(&calc);       // 225
    Calculator_mod(&calc, 100);     // 25
    Calculator_add(&calc, 17);      // 42
    
    var result = Calculator_get(&calc);
    
    if (result == 42) {
        return 42;
    }
    return 1;
}
