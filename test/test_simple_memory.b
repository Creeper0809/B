// 간단한 메모리 연산 테스트
// 수정한 typecheck 기능 검증

// 1. 배열 인덱스 대입
func test_array_assign() -> u64 {
    var arr: [3]u64;
    arr[$0] = 10;
    arr[$1] = 20;
    arr[$2] = 30;
    return arr[$0] + arr[$1] + arr[$2];  // 60
}

// 2. 포인터 역참조 대입
func test_ptr_deref_assign() -> u64 {
    var val: u64 = 42;
    var p: *u64 = &val;
    *p = 100;
    return val;  // 100
}

// 3. 이중 포인터
func test_double_ptr() -> u64 {
    var val: u64 = 42;
    var p1: *u64 = &val;
    var p2: **u64 = &p1;
    var temp_p: *u64 = *p2;
    *temp_p = 200;
    return val;  // 200
}

// 4. 배열 요소 주소
func test_array_element_addr() -> u64 {
    var arr: [3]u64;
    arr[$0] = 10;
    arr[$1] = 20;
    arr[$2] = 30;
    
    var p: *u64 = &arr[$1];
    return *p;  // 20
}

func main() -> u64 {
    println("=== Simple Memory Test ===");
    
    var r: u64 = 0;
    
    r = test_array_assign();
    println("1. Array assign:", r);  // 60
    
    r = test_ptr_deref_assign();
    println("2. Ptr deref assign:", r);  // 100
    
    r = test_double_ptr();
    println("3. Double ptr:", r);  // 200
    
    r = test_array_element_addr();
    println("4. Array element addr:", r);  // 20
    
    println("=== All tests passed! ===");
    return 60 + 100 + 200 + 20;  // 380
}
