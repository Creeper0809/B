// v3.6 토큰 혼합 스트레스 테스트
// 여러 토큰을 복잡하게 조합하여 파서/코드생성 검증

// ==========================================
// 1. 연산자 우선순위 스트레스
// ==========================================
func test_precedence() -> i64 {
    var a: i64;
    var b: i64;
    var c: i64;
    var d: i64;
    a = 2;
    b = 3;
    c = 4;
    d = 5;
    
    // 2 + 3 * 4 - 5 = 2 + 12 - 5 = 9
    var r1: i64;
    r1 = a + b * c - d;
    if (r1 != 9) { return 1; }
    
    // (2 + 3) * (4 - 5) = 5 * -1 = -5
    // 음수는 exit code에서 256으로 wrap됨
    var r2: i64;
    r2 = (a + b) * (c - d);
    if (r2 != 0 - 5) { return 2; }
    
    // 2 * 3 + 4 * 5 = 6 + 20 = 26
    var r3: i64;
    r3 = a * b + c * d;
    if (r3 != 26) { return 3; }
    
    // 20 / 4 / 5 = 5 / 5 = 1 (왼쪽 결합)
    var r4: i64;
    r4 = 20 / c / d;
    if (r4 != 1) { return 4; }
    
    return 0;
}

// ==========================================
// 2. 비교 연산자 복합
// ==========================================
func test_cmp_complex() -> i64 {
    var x: i64;
    var y: i64;
    var z: i64;
    x = 10;
    y = 20;
    z = 10;
    
    // x == z && x < y
    if (x == z) {
        if (x < y) {
            // pass
        } else {
            return 10;
        }
    } else {
        return 11;
    }
    
    // x != y && y > z
    if (x != y) {
        if (y > z) {
            // pass
        } else {
            return 12;
        }
    } else {
        return 13;
    }
    
    // x <= z && y >= x
    if (x <= z) {
        if (y >= x) {
            // pass
        } else {
            return 14;
        }
    } else {
        return 15;
    }
    
    return 0;
}

// ==========================================
// 3. 제어문 + 연산자 + 포인터 혼합
// ==========================================
func test_mixed_control() -> i64 {
    var arr4: i64;
    var arr3: i64;
    var arr2: i64;
    var arr1: i64;
    var arr0: i64;
    arr0 = 1;
    arr1 = 2;
    arr2 = 3;
    arr3 = 4;
    arr4 = 5;
    
    var sum: i64;
    sum = 0;
    
    // 스택: arr4(rbp-8), arr3(rbp-16), arr2(rbp-24), arr1(rbp-32), arr0(rbp-40)
    // arr0 주소에서 +8 하면 arr1
    var base: i64;
    base = &arr0;
    
    var i: i64;
    i = 0;
    while (i < 5) {
        var addr: i64;
        addr = base + i * 8;
        var val: i64;
        val = *addr;
        
        if (val > 2) {
            sum = sum + val;
        }
        
        i = i + 1;
    }
    
    // sum = 3 + 4 + 5 = 12
    if (sum != 12) { return 20; }
    
    return 0;
}

// ==========================================
// 4. 함수 호출 체인
// ==========================================
func add1(x: i64) -> i64 {
    return x + 1;
}

func mul2(x: i64) -> i64 {
    return x * 2;
}

func sub3(x: i64) -> i64 {
    return x - 3;
}

func test_call_chain() -> i64 {
    // sub3(mul2(add1(5))) = sub3(mul2(6)) = sub3(12) = 9
    var r: i64;
    r = sub3(mul2(add1(5)));
    if (r != 9) { return 30; }
    
    // add1(add1(add1(0))) = 3
    r = add1(add1(add1(0)));
    if (r != 3) { return 31; }
    
    // mul2(mul2(mul2(1))) = 8
    r = mul2(mul2(mul2(1)));
    if (r != 8) { return 32; }
    
    return 0;
}

// ==========================================
// 5. 복잡한 조건식
// ==========================================
func absval(x: i64) -> i64 {
    if (x < 0) {
        return 0 - x;
    }
    return x;
}

func max(a: i64, b: i64) -> i64 {
    if (a > b) {
        return a;
    }
    return b;
}

func min(a: i64, b: i64) -> i64 {
    if (a < b) {
        return a;
    }
    return b;
}

func clamp(x: i64, lo: i64, hi: i64) -> i64 {
    if (x < lo) {
        return lo;
    }
    if (x > hi) {
        return hi;
    }
    return x;
}

func test_util_funcs() -> i64 {
    if (absval(0 - 5) != 5) { return 40; }
    if (absval(5) != 5) { return 41; }
    if (max(3, 7) != 7) { return 42; }
    if (max(7, 3) != 7) { return 43; }
    if (min(3, 7) != 3) { return 44; }
    if (min(7, 3) != 3) { return 45; }
    if (clamp(5, 0, 10) != 5) { return 46; }
    if (clamp(0 - 5, 0, 10) != 0) { return 47; }
    if (clamp(15, 0, 10) != 10) { return 48; }
    return 0;
}

// ==========================================
// 6. 포인터를 통한 배열 수정
// ==========================================
func zero_val(p: i64) {
    *p = 0;
}

func test_array_ops() -> i64 {
    var a: i64;
    var b: i64;
    var c: i64;
    a = 99;
    b = 88;
    c = 77;
    
    // 포인터로 값 변경
    zero_val(&a);
    zero_val(&b);
    zero_val(&c);
    
    if (a != 0) { return 50; }
    if (b != 0) { return 51; }
    if (c != 0) { return 52; }
    
    // 포인터로 값 설정
    var pa: i64;
    pa = &a;
    *pa = 10;
    
    var pb: i64;
    pb = &b;
    *pb = 20;
    
    var pc: i64;
    pc = &c;
    *pc = 30;
    
    if (a != 10) { return 53; }
    if (b != 20) { return 54; }
    if (c != 30) { return 55; }
    
    // 합
    if (a + b + c != 60) { return 56; }
    
    return 0;
}

// ==========================================
// 7. 복잡한 수식 + 제어문
// ==========================================
func is_prime(n: i64) -> i64 {
    if (n < 2) { return 0; }
    if (n == 2) { return 1; }
    if (n / 2 * 2 == n) { return 0; }
    
    var i: i64;
    i = 3;
    while (i * i <= n) {
        if (n / i * i == n) {
            return 0;
        }
        i = i + 2;
    }
    return 1;
}

func test_prime() -> i64 {
    // 2,3,5,7,11,13 are prime
    if (is_prime(2) != 1) { return 60; }
    if (is_prime(3) != 1) { return 61; }
    if (is_prime(4) != 0) { return 62; }
    if (is_prime(5) != 1) { return 63; }
    if (is_prime(6) != 0) { return 64; }
    if (is_prime(7) != 1) { return 65; }
    if (is_prime(9) != 0) { return 66; }
    if (is_prime(11) != 1) { return 67; }
    if (is_prime(13) != 1) { return 68; }
    if (is_prime(15) != 0) { return 69; }
    return 0;
}

// ==========================================
// 8. GCD (유클리드 알고리즘)
// ==========================================
func gcd(a: i64, b: i64) -> i64 {
    while (b != 0) {
        var t: i64;
        t = b;
        b = a - a / b * b;
        a = t;
    }
    return a;
}

func test_gcd() -> i64 {
    if (gcd(48, 18) != 6) { return 70; }
    if (gcd(100, 35) != 5) { return 71; }
    if (gcd(17, 13) != 1) { return 72; }
    if (gcd(12, 12) != 12) { return 73; }
    return 0;
}

// ==========================================
// 메인
// ==========================================
func main() -> i64 {
    var r: i64;
    
    r = test_precedence();
    if (r != 0) { return r; }
    
    r = test_cmp_complex();
    if (r != 0) { return r; }
    
    r = test_mixed_control();
    if (r != 0) { return r; }
    
    r = test_call_chain();
    if (r != 0) { return r; }
    
    r = test_util_funcs();
    if (r != 0) { return r; }
    
    r = test_array_ops();
    if (r != 0) { return r; }
    
    r = test_prime();
    if (r != 0) { return r; }
    
    r = test_gcd();
    if (r != 0) { return r; }
    
    // 모든 테스트 통과
    return 0;
}
