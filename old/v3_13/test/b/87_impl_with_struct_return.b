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
    var v1: Vec2 = Vec2_new(3, 4);
    var v2: Vec2 = Vec2_new(1, 2);
    
    var sum: Vec2 = Vec2_add(&v1, &v2);  // (4, 6)
    var scaled: Vec2 = Vec2_scale(&sum, 2);  // (8, 12)
    
    var mag_sq = Vec2_magnitude_squared(&scaled);  // 64 + 144 = 208
    
    if (mag_sq == 208) {
        return 42;
    }
    return 1;
}
