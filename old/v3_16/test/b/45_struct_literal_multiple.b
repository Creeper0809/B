// 45_struct_literal_multiple.b - 여러 구조체 리터럴 초기화
// Expect exit code: 42

struct Point {
    x: i64;
    y: i64;
}

func main(argc, argv) {
    var p1: Point = Point { 5, 10 };
    var p2: Point = Point { 15, 12 };
    
    // p1.x + p1.y + p2.x + p2.y = 5 + 10 + 15 + 12 = 42
    return p1.x + p1.y + p2.x + p2.y;
}
