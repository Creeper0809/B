// 55_struct_ptr_copy.b - 포인터를 통한 구조체 복사
// Expect exit code: 42

struct Point {
    x: i64;
    y: i64;
}

func main(argc, argv) {
    var p1: Point = Point { 10, 32 };
    var p2: Point;
    
    // 포인터를 통해 복사
    var ptr1: *Point = &p1;
    var ptr2: *Point = &p2;
    
    // 포인터 역참조로 복사
    *ptr2 = *ptr1;
    
    // p2.x + p2.y = 10 + 32 = 42
    return p2.x + p2.y;
}
