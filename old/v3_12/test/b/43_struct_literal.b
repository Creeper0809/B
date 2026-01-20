// 43_struct_literal.b - 구조체 리터럴 초기화 테스트
// Expect exit code: 42

struct Point {
    x: i64;
    y: i64;
}

func main(argc, argv) {
    // 구조체 리터럴 초기화
    var p: Point = Point { 10, 32 };
    
    // x + y = 10 + 32 = 42
    return p.x + p.y;
}
