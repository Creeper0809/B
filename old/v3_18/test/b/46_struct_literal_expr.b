// 46_struct_literal_expr.b - 표현식을 사용한 구조체 리터럴
// Expect exit code: 42

struct Point {
    x: i64;
    y: i64;
}

func main(argc, argv) {
    var a: i64 = 5;
    var b: i64 = 10;
    
    // 표현식으로 초기화
    var p: Point = Point { a * 2, b + 22 };
    
    // p.x + p.y = (5*2) + (10+22) = 10 + 32 = 42
    return p.x + p.y;
}
