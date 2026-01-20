// 43a_struct_literal_simple.b - 매우 단순한 구조체 리터럴 테스트

struct Point {
    x: i64,
    y: i64
}

func main() -> i64 {
    // 구조체 직접 접근만 테스트
    var p: Point;
    p.x = 10;
    p.y = 32;
    return p.x + p.y;
}
