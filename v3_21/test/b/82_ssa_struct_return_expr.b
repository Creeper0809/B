// Covers: Struct return used directly in expression
// Mode: ssa
// Opt: O1
// Expect exit code: 50

struct Vec2 {
    x: i64;
    y: i64;
}

func get_vec() -> Vec2 {
    return Vec2 { 30, 20 };
}

func main() -> i64 {
    return get_vec().x + get_vec().y;
}
