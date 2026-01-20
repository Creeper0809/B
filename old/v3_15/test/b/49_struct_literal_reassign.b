// 49_struct_literal_reassign.b - 리터럴 초기화 후 재할당
// Expect exit code: 42

struct Point {
    x: i64;
    y: i64;
}

func main(argc, argv) {
    var p: Point = Point { 5, 10 };
    
    // 필드 재할당
    p.x = 20;
    p.y = 22;
    
    // 20 + 22 = 42
    return p.x + p.y;
}
