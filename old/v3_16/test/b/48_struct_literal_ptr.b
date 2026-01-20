// 48_struct_literal_ptr.b - 구조체 리터럴과 포인터
// Expect exit code: 42

struct Point {
    x: i64;
    y: i64;
}

func main(argc, argv) {
    var p: Point = Point { 10, 32 };
    var ptr: *Point = &p;
    
    // 포인터로 접근
    return ptr->x + ptr->y;
}
