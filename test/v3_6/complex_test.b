// v3.6 종합 테스트 - 복잡한 시나리오

// ==========================================
// 1. 중첩 제어문 테스트
// ==========================================
func test_nested_loops() -> i64 {
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

// ==========================================
// 2. 중첩 if 테스트
// ==========================================
func test_nested_if(a: i64, b: i64, c: i64) -> i64 {
    if (a > 0) {
        if (b > 0) {
            if (c > 0) {
                return 7;
            } else {
                return 6;
            }
        } else {
            return 5;
        }
    } else {
        return 4;
    }
    return 0;
}

// ==========================================
// 3. 복잡한 산술 표현식
// ==========================================
func test_complex_expr() -> i64 {
    var a: i64;
    var b: i64;
    var c: i64;
    a = 10;
    b = 3;
    c = 2;
    // (10 + 3) * 2 - 10 / 2 = 13 * 2 - 5 = 26 - 5 = 21
    return (a + b) * c - a / c;
}

// ==========================================
// 4. 포인터 체인
// ==========================================
func test_ptr_chain() -> i64 {
    var x: i64;
    x = 5;
    var p1: i64;
    p1 = &x;
    var p2: i64;
    p2 = &p1;
    var p3: i64;
    p3 = &p2;
    // p3 -> p2 -> p1 -> x
    var t1: i64;
    t1 = *p3;
    var t2: i64;
    t2 = *t1;
    return *t2;
}

// ==========================================
// 5. 포인터로 swap
// ==========================================
func swap(pa: i64, pb: i64) {
    var tmp: i64;
    tmp = *pa;
    *pa = *pb;
    *pb = tmp;
}

func test_swap() -> i64 {
    var a: i64;
    var b: i64;
    a = 10;
    b = 20;
    swap(&a, &b);
    // a=20, b=10
    return a - b;
}

// ==========================================
// 6. 재귀 (팩토리얼)
// ==========================================
func factorial(n: i64) -> i64 {
    if (n <= 1) {
        return 1;
    }
    return n * factorial(n - 1);
}

func test_factorial() -> i64 {
    return factorial(5);
}

// ==========================================
// 7. 재귀 (피보나치)
// ==========================================
func fib(n: i64) -> i64 {
    if (n <= 1) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}

func test_fib() -> i64 {
    return fib(10);
}

// ==========================================
// 메인
// ==========================================
func main() -> i64 {
    var r: i64;
    r = 0;
    
    // test_nested_loops: 9
    if (test_nested_loops() != 9) { return 1; }
    
    // test_nested_if(1,1,1): 7
    if (test_nested_if(1, 1, 1) != 7) { return 2; }
    
    // test_nested_if(1,1,0): 6
    if (test_nested_if(1, 1, 0) != 6) { return 3; }
    
    // test_nested_if(1,0,1): 5
    if (test_nested_if(1, 0, 1) != 5) { return 4; }
    
    // test_nested_if(0,1,1): 4
    if (test_nested_if(0, 1, 1) != 4) { return 5; }
    
    // test_complex_expr: 21
    if (test_complex_expr() != 21) { return 6; }
    
    // test_ptr_chain: 5
    if (test_ptr_chain() != 5) { return 7; }
    
    // test_swap: 10 (20-10)
    if (test_swap() != 10) { return 8; }
    
    // test_factorial: 120
    if (test_factorial() != 120) { return 9; }
    
    // test_fib: 55
    if (test_fib() != 55) { return 10; }
    
    // 모든 테스트 통과
    return 0;
}
