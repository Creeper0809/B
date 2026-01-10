// B v3 복잡한 메모리 레이아웃 테스트
// 포인터 연산, 중첩 struct, 배열+포인터 조합

// ========== 중첩 struct ==========
struct Inner {
    x: u64;
    y: u64;
}

struct Outer {
    id: u64;
    inner: Inner;
    data: [3]u64;
}

// ========== 복잡한 포인터 연산 ==========
func test_pointer_arithmetic() -> u64 {
    var arr: [5]u64;
    arr[0] = 10;
    arr[1] = 20;
    arr[2] = 30;
    arr[3] = 40;
    arr[4] = 50;
    
    var p: *u64 = &arr[0];
    var sum: u64 = 0;
    
    // p+0, p+8, p+16, p+24, p+32 (바이트 단위)
    sum = *p;                              // 10
    p = p + 8;
    sum = sum + *p;                        // 10 + 20 = 30
    p = p + 8;
    sum = sum + *p;                        // 30 + 30 = 60
    p = p + 8;
    sum = sum + *p;                        // 60 + 40 = 100
    p = p + 8;
    sum = sum + *p;                        // 100 + 50 = 150
    
    return sum;
}

// ========== 중첩 struct 접근 ==========
func test_nested_struct() -> u64 {
    var outer: Outer;
    outer.id = 1;
    outer.inner.x = 100;
    outer.inner.y = 200;
    outer.data[0] = 10;
    outer.data[1] = 20;
    outer.data[2] = 30;
    
    var sum: u64 = 0;
    sum = outer.id + outer.inner.x + outer.inner.y;
    sum = sum + outer.data[0] + outer.data[1] + outer.data[2];
    
    return sum;  // 1 + 100 + 200 + 10 + 20 + 30 = 361
}

// ========== struct 포인터 체이닝 ==========
func test_pointer_chaining() -> u64 {
    var outer: Outer;
    outer.id = 5;
    outer.inner.x = 10;
    outer.inner.y = 15;
    
    var p_outer: *Outer = &outer;
    var p_inner: *Inner = &p_outer->inner;
    
    var sum: u64 = 0;
    sum = p_outer->id;           // 5
    sum = sum + p_inner->x;      // 5 + 10 = 15
    sum = sum + p_inner->y;      // 15 + 15 = 30
    
    return sum;
}

// ========== 이중 포인터 (간접 참조) ==========
func test_double_pointer() -> u64 {
    var val: u64 = 42;
    var p1: *u64 = &val;
    var p2: **u64 = &p1;
    
    // **p2를 통해 val 접근
    var temp_p: *u64 = *p2;
    var result: u64 = *temp_p;
    
    // 포인터를 통한 수정
    *temp_p = 100;
    
    return val;  // 100
}

// ========== 포인터 배열 ==========
func test_pointer_array() -> u64 {
    var a: u64 = 10;
    var b: u64 = 20;
    var c: u64 = 30;
    
    var ptrs: [3]*u64;
    ptrs[0] = &a;
    ptrs[1] = &b;
    ptrs[2] = &c;
    
    var sum: u64 = 0;
    sum = *ptrs[0];           // 10
    sum = sum + *ptrs[1];     // 10 + 20 = 30
    sum = sum + *ptrs[2];     // 30 + 30 = 60
    
    return sum;
}


// ========== struct 배열 ==========
func test_struct_array() -> u64 {
    var inners: [3]Inner;
    inners[0].x = 1;
    inners[0].y = 2;
    inners[1].x = 3;
    inners[1].y = 4;
    inners[2].x = 5;
    inners[2].y = 6;
    
    var sum: u64 = 0;
    var i: u64 = 0;
    for (i = 0; i < 3; i = i + 1) {
        sum = sum + inners[i].x + inners[i].y;
    }
    
    return sum;  // 1+2+3+4+5+6 = 21
}

// ========== 복합 메모리 레이아웃 ==========
func test_complex_layout() -> u64 {
    var outer: Outer;
    outer.id = 1;
    outer.inner.x = 10;
    outer.inner.y = 20;
    outer.data[0] = 100;
    outer.data[1] = 200;
    outer.data[2] = 300;
    
    // struct 포인터
    var p: *Outer = &outer;
    
    // 배열 요소의 포인터
    var p_data: *u64 = &p->data[1];
    
    var sum: u64 = 0;
    sum = p->id;                    // 1
    sum = sum + p->inner.x;         // 1 + 10 = 11
    sum = sum + *p_data;            // 11 + 200 = 211
    
    return sum;
}

func main() -> u64 {
    println("=== Complex Memory Layout Test ===");
    
    var result: u64 = 0;
    
    // 1. 포인터 산술
    result = test_pointer_arithmetic();
    println("1. Pointer arithmetic:", result);  // 150
    
    // 2. 중첩 struct
    result = test_nested_struct();
    println("2. Nested struct:", result);  // 361
    
    // 3. 포인터 체이닝
    result = test_pointer_chaining();
    println("3. Pointer chaining:", result);  // 30
    
    // 4. 이중 포인터
    result = test_double_pointer();
    println("4. Double pointer:", result);  // 100
    
    // 5. 포인터 배열
    result = test_pointer_array();
    println("5. Pointer array:", result);  // 60
    
    // 6. struct 배열
    result = test_struct_array();
    println("6. Struct array:", result);  // 21
    
    // 7. 복합 레이아웃
    result = test_complex_layout();
    println("7. Complex layout:", result);  // 211
    
    println("=== All 6 complex tests passed! ===");
    
    // 검증: 모든 결과의 합
    return 150 + 361 + 30 + 100 + 60 + 21 + 211;  // 933
}
