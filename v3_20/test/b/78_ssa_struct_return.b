// Expect exit code: 42
// Mode: ssa
// Opt: O1

struct Point {
    x: i64;
    y: i64;
}

func make_point(x: i64, y: i64) -> Point {
    return Point { x, y };
}

func main() -> i64 {
    var p: Point = make_point(20, 22);
    return p.x + p.y;
}
