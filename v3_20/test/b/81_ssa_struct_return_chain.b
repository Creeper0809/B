// Covers: Struct return function chaining
// Mode: ssa
// Opt: O1
// Expect exit code: 42

struct Point {
    x: i64;
    y: i64;
}

func make_point(x: i64, y: i64) -> Point {
    return Point { x, y };
}

func pass_through(p: Point) -> Point {
    return p;
}

func main() -> i64 {
    var p1: Point = make_point(20, 22);
    var p2: Point = pass_through(p1);
    return p2.x + p2.y;
}
