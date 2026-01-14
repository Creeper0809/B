// 56_struct_nested_ptr.b - 구조체 내부에 포인터 필드
// Expect exit code: 42

struct Data {
    value: i64;
}

struct Container {
    ptr: *Data;
    multiplier: i64;
}

func main(argc, argv) {
    var d: Data;
    d.value = 21;
    
    var c: Container;
    c.ptr = &d;
    c.multiplier = 2;
    
    // 포인터 역참조: d.value * c.multiplier = 21 * 2 = 42
    return c.ptr->value * c.multiplier;
}
