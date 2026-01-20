// 60_struct_ptr_member_modify.b - 포인터 멤버를 통한 수정
// Expect exit code: 42

struct Point {
    x: i64;
    y: i64;
}

struct PointRef {
    ref: *Point;
}

func main(argc, argv) {
    var p: Point = Point { 5, 10 };
    
    var r1: PointRef;
    r1.ref = &p;
    
    // r1을 복사
    var r2: PointRef;
    r2 = r1;
    
    // r2를 통해 원본 p 수정
    r2.ref->x = 20;
    r2.ref->y = 22;
    
    // p가 수정됨: 20 + 22 = 42
    return p.x + p.y;
}
