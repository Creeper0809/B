// 57_struct_copy_with_ptr.b - 포인터 필드를 가진 구조체 복사
// Expect exit code: 42

struct Data {
    value: i64;
}

struct Container {
    ptr: *Data;
    offset: i64;
}

func main(argc, argv) {
    var d: Data;
    d.value = 30;
    
    var c1: Container;
    c1.ptr = &d;
    c1.offset = 12;
    
    // 구조체 복사 (포인터도 복사됨)
    var c2: Container;
    c2 = c1;
    
    // 두 컨테이너가 같은 Data를 가리킴
    // c2.ptr->value + c2.offset = 30 + 12 = 42
    return c2.ptr->value + c2.offset;
}
