// 52_struct_copy_chain.b - 연속 구조체 값 복사
// Expect exit code: 42

struct Point {
    x: i64;
    y: i64;
}

func main(argc, argv) {
    var p1: Point = Point { 5, 10 };
    var p2: Point;
    var p3: Point;
    
    // 연속 복사
    p2 = p1;
    p3 = p2;
    
    // 수정해도 원본은 변하지 않음
    p3.x = 20;
    p3.y = 22;
    
    // p1은 그대로 (5 + 10 = 15)
    // p3는 변경됨 (20 + 22 = 42)
    return p1.x + p1.y + p3.x + p3.y - 15;  // 15 + 42 - 15 = 42
}
