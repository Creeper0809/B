// 79_struct_return_chain.b - Chain struct value return calls
// Expect exit code: 42

struct Point {
    x: i64;
    y: i64;
}

func Point_new(x: i64, y: i64) -> Point {
    var p: Point;
    p.x = x;
    p.y = y;
    return p;
}

func Point_add(a: *Point, b: *Point) -> Point {
    var result: Point;
    result.x = a->x + b->x;
    result.y = a->y + b->y;
    return result;
}

func Point_scale(p: *Point, factor: i64) -> Point {
    var result: Point;
    result.x = p->x * factor;
    result.y = p->y * factor;
    return result;
}

func main() -> i64 {
    var p1: Point = Point_new(5, 10);
    var p2: Point = Point_new(3, 7);
    
    // Chain: add then scale
    var sum: Point = Point_add(&p1, &p2);  // (8, 17)
    var scaled: Point = Point_scale(&sum, 2);  // (16, 34)
    
    var result = scaled.x + scaled.y;  // 16 + 34 = 50
    
    if (result == 50) {
        return 42;
    }
    return 1;
}
