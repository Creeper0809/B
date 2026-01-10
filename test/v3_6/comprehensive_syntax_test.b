// v3.6 완전 종합 테스트 - 구현된 모든 문법 엄격 검증
// 지원 문법: const, func, var, return, if, else, while, &, *, [], 타입, 모든 연산자

// ==========================================
// 1. 타입 시스템 테스트
// ==========================================
func test_types() -> i64 {
    var a: i64;
    var b: u8;
    var c: u16;
    var d: u32;
    var e: u64;
    
    a = 10;
    b = 20;
    c = 30;
    d = 40;
    e = 50;
    
    // 모든 타입이 i64로 처리됨 (현재 구현)
    var sum: i64;
    sum = a + b + c + d + e;
    
    if (sum != 150) { return 1; }
    return 0;
}

// ==========================================
// 2. const 선언 테스트
// ==========================================
const MAX_SIZE = 100;
const MIN_SIZE = 10;
const DEFAULT_VAL = 42;

func test_const() -> i64 {
    if (MAX_SIZE != 100) { return 10; }
    if (MIN_SIZE != 10) { return 11; }
    if (DEFAULT_VAL != 42) { return 12; }
    
    var x: i64;
    x = MAX_SIZE - MIN_SIZE;
    if (x != 90) { return 13; }
    
    return 0;
}

// ==========================================
// 3. 모든 산술 연산자
// ==========================================
func test_arithmetic() -> i64 {
    var a: i64;
    var b: i64;
    a = 20;
    b = 3;
    
    // +
    if (a + b != 23) { return 20; }
    
    // -
    if (a - b != 17) { return 21; }
    
    // *
    if (a * b != 60) { return 22; }
    
    // /
    if (a / b != 6) { return 23; }
    
    // 복합
    if (a + b * 2 != 26) { return 24; }
    if ((a + b) * 2 != 46) { return 25; }
    
    return 0;
}

// ==========================================
// 4. 모든 비교 연산자
// ==========================================
func test_comparison() -> i64 {
    var a: i64;
    var b: i64;
    var c: i64;
    a = 10;
    b = 20;
    c = 10;
    
    // ==
    if (a == b) { return 30; }
    if (a == c) { } else { return 31; }
    
    // !=
    if (a != b) { } else { return 32; }
    if (a != c) { return 33; }
    
    // <
    if (a < b) { } else { return 34; }
    if (b < a) { return 35; }
    
    // >
    if (b > a) { } else { return 36; }
    if (a > b) { return 37; }
    
    // <=
    if (a <= b) { } else { return 38; }
    if (a <= c) { } else { return 39; }
    if (b <= a) { return 40; }
    
    // >=
    if (b >= a) { } else { return 41; }
    if (a >= c) { } else { return 42; }
    if (a >= b) { return 43; }
    
    return 0;
}

// ==========================================
// 5. if-else 완전 테스트
// ==========================================
func test_if_simple(x: i64) -> i64 {
    if (x > 0) {
        return 1;
    }
    return 0;
}

func test_if_else(x: i64) -> i64 {
    if (x > 0) {
        return 1;
    } else {
        return 0 - 1;
    }
}

func test_if_elif(x: i64) -> i64 {
    if (x < 0) {
        return 0 - 1;
    } else {
        if (x == 0) {
            return 0;
        } else {
            return 1;
        }
    }
}

func test_if_all() -> i64 {
    if (test_if_simple(5) != 1) { return 50; }
    if (test_if_simple(0 - 5) != 0) { return 51; }
    
    if (test_if_else(5) != 1) { return 52; }
    if (test_if_else(0 - 5) != 0 - 1) { return 53; }
    
    if (test_if_elif(0 - 1) != 0 - 1) { return 54; }
    if (test_if_elif(0) != 0) { return 55; }
    if (test_if_elif(1) != 1) { return 56; }
    
    return 0;
}

// ==========================================
// 6. while 루프 완전 테스트
// ==========================================
func test_while_count() -> i64 {
    var cnt: i64;
    cnt = 0;
    var i: i64;
    i = 0;
    while (i < 10) {
        cnt = cnt + 1;
        i = i + 1;
    }
    return cnt;
}

func test_while_sum() -> i64 {
    var sum: i64;
    sum = 0;
    var i: i64;
    i = 1;
    while (i <= 10) {
        sum = sum + i;
        i = i + 1;
    }
    return sum;
}

func test_while_nested() -> i64 {
    var sum: i64;
    sum = 0;
    var i: i64;
    i = 0;
    while (i < 3) {
        var j: i64;
        j = 0;
        while (j < 3) {
            sum = sum + 1;
            j = j + 1;
        }
        i = i + 1;
    }
    return sum;
}

func test_while_all() -> i64 {
    if (test_while_count() != 10) { return 60; }
    if (test_while_sum() != 55) { return 61; }
    if (test_while_nested() != 9) { return 62; }
    return 0;
}

// ==========================================
// 7. 포인터 완전 테스트
// ==========================================
func test_ptr_basic() -> i64 {
    var x: i64;
    x = 42;
    var p: i64;
    p = &x;
    
    if (*p != 42) { return 70; }
    
    *p = 100;
    if (x != 100) { return 71; }
    
    return 0;
}

func test_ptr_chain() -> i64 {
    var x: i64;
    x = 10;
    var p1: i64;
    p1 = &x;
    var p2: i64;
    p2 = &p1;
    var p3: i64;
    p3 = &p2;
    
    // p3 -> p2 -> p1 -> x
    var v1: i64;
    v1 = *p3;
    var v2: i64;
    v2 = *v1;
    var v3: i64;
    v3 = *v2;
    
    if (v3 != 10) { return 72; }
    return 0;
}

func modify_via_ptr(p: i64, val: i64) {
    *p = val;
}

func test_ptr_param() -> i64 {
    var x: i64;
    x = 0;
    modify_via_ptr(&x, 99);
    if (x != 99) { return 73; }
    return 0;
}

func test_ptr_all() -> i64 {
    var r: i64;
    r = test_ptr_basic();
    if (r != 0) { return r; }
    
    r = test_ptr_chain();
    if (r != 0) { return r; }
    
    r = test_ptr_param();
    if (r != 0) { return r; }
    
    return 0;
}

// ==========================================
// 8. 배열 인덱스 (포인터 산술) 테스트
// ==========================================
func test_array_index() -> i64 {
    var arr3: i64;
    var arr2: i64;
    var arr1: i64;
    var arr0: i64;
    arr0 = 10;
    arr1 = 20;
    arr2 = 30;
    arr3 = 40;
    
    var base: i64;
    base = &arr0;
    
    // 직접 역참조
    if (*base != 10) { return 80; }
    
    // 포인터 산술
    var p1: i64;
    p1 = base + 8;
    if (*p1 != 20) { return 81; }
    
    var p2: i64;
    p2 = base + 16;
    if (*p2 != 30) { return 82; }
    
    var p3: i64;
    p3 = base + 24;
    if (*p3 != 40) { return 83; }
    
    // 수정
    *p1 = 200;
    if (arr1 != 200) { return 84; }
    
    return 0;
}

// ==========================================
// 9. 복잡한 표현식
// ==========================================
func test_complex_expr() -> i64 {
    var a: i64;
    var b: i64;
    var c: i64;
    a = 5;
    b = 3;
    c = 2;
    
    // a * b + c = 15 + 2 = 17
    if (a * b + c != 17) { return 90; }
    
    // (a + b) * c = 8 * 2 = 16
    if ((a + b) * c != 16) { return 91; }
    
    // a * (b + c) = 5 * 5 = 25
    if (a * (b + c) != 25) { return 92; }
    
    // a + b * c - a / c = 5 + 6 - 2 = 9
    if (a + b * c - a / c != 9) { return 93; }
    
    return 0;
}

// ==========================================
// 10. 함수 호출 체인
// ==========================================
func inc(x: i64) -> i64 {
    return x + 1;
}

func double(x: i64) -> i64 {
    return x * 2;
}

func square(x: i64) -> i64 {
    return x * x;
}

func test_call_chain() -> i64 {
    // inc(inc(inc(0))) = 3
    if (inc(inc(inc(0))) != 3) { return 100; }
    
    // double(double(1)) = 4
    if (double(double(1)) != 4) { return 101; }
    
    // square(square(2)) = 16
    if (square(square(2)) != 16) { return 102; }
    
    // double(inc(square(3))) = double(inc(9)) = double(10) = 20
    if (double(inc(square(3))) != 20) { return 103; }
    
    return 0;
}

// ==========================================
// 11. 재귀 함수
// ==========================================
func sum_recursive(n: i64) -> i64 {
    if (n <= 0) {
        return 0;
    }
    return n + sum_recursive(n - 1);
}

func power(base: i64, exp: i64) -> i64 {
    if (exp == 0) {
        return 1;
    }
    return base * power(base, exp - 1);
}

func test_recursive() -> i64 {
    // sum(10) = 55
    if (sum_recursive(10) != 55) { return 110; }
    
    // sum(5) = 15
    if (sum_recursive(5) != 15) { return 111; }
    
    // power(2, 5) = 32
    if (power(2, 5) != 32) { return 112; }
    
    // power(3, 3) = 27
    if (power(3, 3) != 27) { return 113; }
    
    return 0;
}

// ==========================================
// 12. 변수 스코프 (제한적)
// ==========================================
func test_scope() -> i64 {
    var x: i64;
    x = 10;
    
    if (1 == 1) {
        var y: i64;
        y = 20;
        if (y != 20) { return 120; }
        x = 30;
    }
    
    // x가 if 내부에서 변경됨
    if (x != 30) { return 121; }
    
    var cnt: i64;
    cnt = 0;
    while (cnt < 5) {
        var z: i64;
        z = 100;
        cnt = cnt + 1;
    }
    
    if (cnt != 5) { return 122; }
    
    return 0;
}

// ==========================================
// 메인
// ==========================================
func main() -> i64 {
    var r: i64;
    
    r = test_types();
    if (r != 0) { return r; }
    
    r = test_const();
    if (r != 0) { return r; }
    
    r = test_arithmetic();
    if (r != 0) { return r; }
    
    r = test_comparison();
    if (r != 0) { return r; }
    
    r = test_if_all();
    if (r != 0) { return r; }
    
    r = test_while_all();
    if (r != 0) { return r; }
    
    r = test_ptr_all();
    if (r != 0) { return r; }
    
    r = test_array_index();
    if (r != 0) { return r; }
    
    r = test_complex_expr();
    if (r != 0) { return r; }
    
    r = test_call_chain();
    if (r != 0) { return r; }
    
    r = test_recursive();
    if (r != 0) { return r; }
    
    r = test_scope();
    if (r != 0) { return r; }
    
    // 모든 테스트 통과
    return 0;
}
