// 87_impl_with_struct_return.b - impl methods returning struct by value
// Expect exit code: 42

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

func main() -> i64 {
    var v1: Vec2 = Vec2.new(3, 4);  // static method
    var v2: Vec2 = Vec2.new(1, 2);  // static method
    
    var sum: Vec2 = Vec2.add(&v1, &v2);  // static method
    var scaled: Vec2 = Vec2.scale(&sum, 2);  // static method
    
    var mag_sq = scaled.magnitude_squared();  // instance method with self
    
    if (mag_sq == 208) {
        return 42;
    }
    return 1;
}
