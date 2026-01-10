// v3.6 캐스트 테스트

// ==========================================
// 1. 기본 타입 캐스트
// ==========================================
func test_basic_cast() -> i64 {
    var x: i64;
    x = 100;
    
    // i64 -> u8 캐스트 (no-op in our system)
    var y: i64;
    y = (u8)x;
    
    if (y != 100) { return 1; }
    
    // u64 캐스트
    var z: i64;
    z = (u64)x;
    if (z != 100) { return 2; }
    
    return 0;
}

// ==========================================
// 2. 포인터 타입 캐스트
// ==========================================
func test_pointer_cast() -> i64 {
    var x: i64;
    x = 42;
    
    var p: i64;
    p = &x;
    
    // 포인터 캐스트: 주소를 *i64로 캐스트
    var q: i64;
    q = (*i64)p;
    
    // 역참조
    var val: i64;
    val = *q;
    
    if (val != 42) { return 10; }
    
    return 0;
}

// ==========================================
// 3. 정수 <-> 포인터 변환
// ==========================================
func test_int_ptr_cast() -> i64 {
    // 스택 변수들로 테스트
    var v1: i64;
    var v2: i64;
    v1 = 111;
    v2 = 222;
    
    // 주소를 정수로
    var addr1: i64;
    addr1 = &v1;
    
    // 정수를 포인터로 캐스트하여 역참조
    var p: i64;
    p = (*i64)addr1;
    
    var read1: i64;
    read1 = *p;
    if (read1 != 111) { return 20; }
    
    // v2 주소로 캐스트
    var addr2: i64;
    addr2 = &v2;
    var p2: i64;
    p2 = (*i64)addr2;
    
    var read2: i64;
    read2 = *p2;
    if (read2 != 222) { return 21; }
    
    return 0;
}

// ==========================================
// 4. 캐스트 체인
// ==========================================
func test_cast_chain() -> i64 {
    var x: i64;
    x = 50;
    
    // (u64)(u32)(u16)(u8)x
    var y: i64;
    y = (u64)(u32)(u16)(u8)x;
    
    if (y != 50) { return 30; }
    
    return 0;
}

// ==========================================
// 5. 표현식 캐스트
// ==========================================
func test_expr_cast() -> i64 {
    var a: i64;
    a = 10;
    var b: i64;
    b = 20;
    
    // 산술 결과 캐스트
    var c: i64;
    c = (i64)(a + b);
    
    if (c != 30) { return 40; }
    
    // 비교 결과 캐스트 (0 or 1)
    var d: i64;
    d = (i64)(a < b);
    
    if (d != 1) { return 41; }
    
    return 0;
}

// ==========================================
// 메인
// ==========================================
func main() -> i64 {
    var r: i64;
    
    r = test_basic_cast();
    if (r != 0) { return r; }
    
    r = test_pointer_cast();
    if (r != 0) { return r; }
    
    r = test_int_ptr_cast();
    if (r != 0) { return r; }
    
    r = test_cast_chain();
    if (r != 0) { return r; }
    
    r = test_expr_cast();
    if (r != 0) { return r; }
    
    // 모든 테스트 통과
    return 0;
}
