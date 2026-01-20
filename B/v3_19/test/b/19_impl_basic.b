// Test 19: Impl Suite (basic/multiple/chaining/return/recursive/mixed/stress/complex)
// Expect exit code: 0

import std.io;

struct PointBasic {
    x: i64;
    y: i64;
}

impl PointBasic {
    func init(self: *PointBasic, x: i64, y: i64) {
        self->x = x;
        self->y = y;
    }

    func sum(self: *PointBasic) -> i64 {
        return self->x + self->y;
    }

    func distance_squared(self: *PointBasic, other: *PointBasic) -> i64 {
        var dx = self->x - other->x;
        var dy = self->y - other->y;
        return dx * dx + dy * dy;
    }
}

struct Rect {
    width: i64;
    height: i64;
}

impl Rect {
    func init(self: *Rect, w: i64, h: i64) {
        self->width = w;
        self->height = h;
    }

    func area(self: *Rect) -> i64 {
        return self->width * self->height;
    }
}

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

struct Vec2 {
    x: i64;
    y: i64;
}

impl Vec2 {
    func new(x: i64, y: i64) -> Vec2 {
        var v: Vec2;
        v.x = x;
        v.y = y;
        return v;
    }

    func add(a: *Vec2, b: *Vec2) -> Vec2 {
        var result: Vec2;
        result.x = a->x + b->x;
        result.y = a->y + b->y;
        return result;
    }

    func scale(v: *Vec2, factor: i64) -> Vec2 {
        var result: Vec2;
        result.x = v->x * factor;
        result.y = v->y * factor;
        return result;
    }

    func magnitude_squared(v: *Vec2) -> i64 {
        return v->x * v->x + v->y * v->y;
    }
}

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

struct Data {
    value: i64;
}

impl Data {
    func init(self: *Data, val: i64) {
        self->value = val;
    }

    func get_value(self: *Data) -> i64 {
        return self->value;
    }

    func double(self: *Data) {
        self->value = self->value * 2;
    }
}

func sum_array(base: u64, count: i64) -> i64 {
    var sum = 0;
    for (var i = 0; i < count; i = i + 1) {
        var ptr = base + i * 8;
        var d: *Data = (*Data)ptr;
        sum = sum + d->get_value();
    }
    return sum;
}

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

    func square(self: *Calculator) {
        self->result = self->result * self->result;
    }

    func get(self: *Calculator) -> i64 {
        return self->result;
    }
}

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
}

func process_pairs() -> i64 {
    var p1: Pair;
    var p2: Pair;

    p1.init(5, 7);
    p2.init(3, 4);

    var sum1 = p1.sum();
    var sum2 = p2.sum();
    var prod = p2.product();

    return sum1 + sum2 + prod;
}

func main() -> i64 {
    var p1: PointBasic;
    var p2: PointBasic;
    p1.init(10, 20);
    p2.init(3, 4);
    var sum1 = p1.sum();
    var dist = p1.distance_squared(&p2);
    if (sum1 != 30) { return 1; }
    if (dist != 305) { return 2; }

    var r: Rect;
    r.init(3, 7);
    if (r.area() != 21) { return 3; }

    var c: Counter;
    c.init(5);
    c.increment();
    c.add(10);
    c.multiply(2);
    if (c.get() != 32) { return 4; }

    var v1: Vec2 = Vec2.new(3, 4);
    var v2: Vec2 = Vec2.new(1, 2);
    var sum: Vec2 = Vec2.add(&v1, &v2);
    var scaled: Vec2 = Vec2.scale(&sum, 2);
    if (scaled.magnitude_squared() != 208) { return 5; }

    if (Math.factorial(5) != 120) { return 6; }
    if (Math.fibonacci(7) != 13) { return 7; }
    if (Math.power(2, 5) != 32) { return 8; }

    var mem = heap_alloc(24);
    var d0: *Data = (*Data)mem;
    var d1: *Data = (*Data)(mem + 8);
    var d2: *Data = (*Data)(mem + 16);
    d0->init(10);
    d1->init(20);
    d2->init(12);
    var total = d0->get_value() + d1->get_value() + d2->get_value();
    if (total != 42) { return 9; }
    d0->double();
    d1->double();
    d2->double();
    var arr_sum = sum_array(mem, 3);
    if (arr_sum != 84) { return 10; }

    var calc: Calculator;
    calc.init();
    calc.add(10);
    calc.mul(5);
    calc.sub(8);
    calc.add(3);
    calc.div(3);
    calc.square();
    calc.mod(100);
    calc.add(17);
    if (calc.get() != 42) { return 11; }

    if (process_pairs() != 31) { return 12; }

    return 0;
}
