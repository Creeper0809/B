// Expect exit code: 90
// Mode: ssa
// Opt: O1

struct Point {
    x: i64;
    y: i64;
}

func make_point(x: i64, y: i64) -> Point {
    return Point { x, y };
}

func add_points(p1: Point, p2: Point) -> Point {
    return Point { p1.x + p2.x, p1.y + p2.y };
}

func main() -> i64 {
    // Test: use struct return directly in expression without intermediate variable
    var result: Point = add_points(make_point(10, 20), make_point(30, 30));
    return result.x + result.y;
}
