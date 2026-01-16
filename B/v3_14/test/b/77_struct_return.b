// 77_struct_return.b - Test struct value return
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

func Point_sum(p: *Point) -> i64 {
    return p->x + p->y;
}

func main() -> i64 {
    var p1: Point = Point_new(10, 20);
    var sum = Point_sum(&p1);
    
    // sum should be 30
    if (sum == 30) {
        return 42;
    }
    
    return 1;
}
