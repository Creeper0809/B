// 50_struct_copy.b - 구조체 값 복사 테스트
// Expect exit code: 42

struct Point {
    x: i64;
    y: i64;
}

func main(argc, argv) {
    var p1: Point = Point { 10, 32 };
    var p2: Point;
    
    // 구조체 값 복사
    p2 = p1;
    
    // p2.x + p2.y = 10 + 32 = 42
    return p2.x + p2.y;
}
