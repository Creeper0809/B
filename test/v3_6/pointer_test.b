// v3.6 포인터 기능 테스트

// 주소 연산자 & 테스트
func test_address() -> i64 {
    var x: i64;
    x = 10;
    var p: i64;
    p = &x;
    return *p;
}

// 역참조 * 테스트 (읽기)
func test_deref_read() -> i64 {
    var x: i64;
    x = 20;
    var p: i64;
    p = &x;
    return *p;
}

// 역참조 * 테스트 (쓰기)
func test_deref_write() -> i64 {
    var x: i64;
    x = 0;
    var p: i64;
    p = &x;
    *p = 30;
    return x;
}

// 이중 포인터 테스트
func test_double_ptr() -> i64 {
    var x: i64;
    x = 40;
    var p: i64;
    p = &x;
    var pp: i64;
    pp = &p;
    // pp -> p -> x
    var inner: i64;
    inner = *pp;
    return *inner;
}

func main() -> i64 {
    var r: i64;
    r = 0;
    r = r + test_address();
    r = r + test_deref_read();
    r = r + test_deref_write();
    r = r + test_double_ptr();
    return r;
}
