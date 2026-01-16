// 82_struct_return_multiple_types.b - Multiple struct types with return
// Expect exit code: 42

struct Point {
    x: i64;
    y: i64;
}

struct Color {
    r: i64;
    g: i64;
}

func Point_new(x: i64, y: i64) -> Point {
    var p: Point;
    p.x = x;
    p.y = y;
    return p;
}

func Color_new(r: i64, g: i64) -> Color {
    var c: Color;
    c.r = r;
    c.g = g;
    return c;
}

func compute(p: *Point, c: *Color) -> i64 {
    return p->x + p->y + c->r + c->g;
}

func main() -> i64 {
    var p1: Point = Point_new(5, 10);
    var p2: Point = Point_new(3, 7);
    var c1: Color = Color_new(100, 200);
    var c2: Color = Color_new(50, 75);
    
    var sum1 = compute(&p1, &c1);  // 5 + 10 + 100 + 200 = 315
    var sum2 = compute(&p2, &c2);  // 3 + 7 + 50 + 75 = 135
    
    var total = sum1 + sum2;  // 315 + 135 = 450
    
    if (total == 450) {
        return 42;
    }
    return 1;
}
