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
    calc.init();
    
    // Complex calculation sequence
    calc.add(10);      // 10
    calc.mul(5);       // 50
    calc.sub(8);       // 42
    calc.add(3);       // 45
    calc.div(3);       // 15
    calc.square();     // 225
    calc.mod(100);     // 25
    calc.add(17);      // 42
    
    var result = calc.get();
    
    if (result == 42) {
        return 42;
    }
    return 1;
}
