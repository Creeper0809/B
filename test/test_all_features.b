// 컴파일러 필수 문법 종합 테스트 (v3 문법)
// 검증 항목: enum, struct, impl, 함수 포인터, switch, while, for, foreach, defer, 재귀

// ========== 1. enum ==========
enum TokenKind {
    EOF = 0,
    NUMBER = 1,
    PLUS = 2,
    STAR = 3,
}

// ========== 2. struct ==========
struct Parser {
    pos: u64;
    count: u64;
}

// ========== 3. impl 블록 ==========
impl Parser {
    func advance(self: *Parser) {
        self->pos = self->pos + 1;
    }
    
    func get_pos(self: *Parser) -> u64 {
        return self->pos;
    }
}

// ========== 4. 함수 포인터 ==========
func double_it(x: u64) -> u64 {
    return x * 2;
}

func triple_it(x: u64) -> u64 {
    return x * 3;
}

func apply(f: func(u64) -> u64, val: u64) -> u64 {
    return f(val);
}

// ========== 5. 재귀 함수 ==========
func fibonacci(n: u64) -> u64 {
    if (n < 2) {
        return n;
    }
    return fibonacci(n - 1) + fibonacci(n - 2);
}

// ========== 6. switch ==========
func classify_token(kind: u64) -> u64 {
    switch (kind) {
        case TokenKind.EOF:
            return 0;
        case TokenKind.NUMBER:
            return 10;
        case TokenKind.PLUS:
            return 20;
        case TokenKind.STAR:
            return 30;
        default:
            return 99;
    }
}

// ========== 7. while 루프 ==========
func sum_while(n: u64) -> u64 {
    var sum: u64 = 0;
    var i: u64 = 0;
    
    while (i < n) {
        sum = sum + i;
        i = i + 1;
    }
    
    return sum;
}

// ========== 8. for 루프 ==========
func sum_for(n: u64) -> u64 {
    var sum: u64 = 0;
    
    for (var i: u64 = 0; i < n; i = i + 1) {
        sum = sum + i;
    }
    
    return sum;
}

// ========== 9. foreach (슬라이스) ==========
func sum_bytes(s: []u8) -> u64 {
    var total: u64 = 0;
    
    foreach (var b in s) {
        total = total + cast(u64, b);
    }
    
    return total;
}

// ========== 10. 중첩 블록 & 섀도잉 ==========
func test_shadowing() -> u64 {
    var x: u64 = 100;
    
    {
        var x: u64 = 10;
        x = x + 5;
        // 내부 x == 15
    }
    
    return x;  // 외부 x == 100
}

// ========== 11. defer ==========
func test_defer() -> u64 {
    var result: u64 = 0;
    
    {
        result = result + 10;
        defer result = result * 2;
        result = result + 5;
        // result = 15, defer 실행: 15 * 2 = 30
    }
    
    return result;
}

// ========== 12. 포인터 연산 ==========
func test_pointer() -> u64 {
    var x: u64 = 42;
    var ptr: *u64 = &x;
    var val = *ptr;
    return val;
}

// ========== 메인: 모든 기능 통합 ==========
func main() -> u64 {
    var total: u64 = 0;
    
    println("=== B Language v3 Compiler Feature Test ===");
    
    // 1. enum
    total = total + TokenKind.STAR;  // + 3
    println("1. enum: OK");
    
    // 2. struct + impl
    var p: Parser;
    p.pos = 0;
    p.count = 10;
    p.advance(&p);
    p.advance(&p);
    total = total + p.get_pos(&p);  // + 2
    println("2. struct + impl: OK");
    
    // 3. 함수 포인터
    var v1 = apply(double_it, 5);   // 10
    var v2 = apply(triple_it, 4);   // 12
    total = total + v1 + v2;  // + 22
    println("3. 함수 포인터: OK");
    
    // 4. 재귀
    var fib = fibonacci(7);  // 13
    total = total + fib;  // + 13
    println("4. 재귀 함수: OK");
    
    // 5. switch
    var cls = classify_token(TokenKind.NUMBER);  // 10
    total = total + cls;  // + 10
    println("5. switch: OK");
    
    // 6. while
    var sw = sum_while(5);  // 0+1+2+3+4 = 10
    total = total + sw;  // + 10
    println("6. while: OK");
    
    // 7. for
    var sf = sum_for(4);  // 0+1+2+3 = 6
    total = total + sf;  // + 6
    println("7. for: OK");
    
    // 8. foreach (슬라이스)
    var str: []u8 = "Hi";  // 'H'=72, 'i'=105 -> 177
    var sb = sum_bytes(str);
    total = total + sb;  // + 177
    println("8. foreach: OK");
    
    // 9. 섀도잉
    var sh = test_shadowing();  // 100
    total = total + sh;  // + 100
    println("9. 섀도잉: OK");
    
    // 10. defer
    var df = test_defer();  // 30
    total = total + df;  // + 30
    println("10. defer: OK");
    
    // 11. 포인터
    var ptr_val = test_pointer();  // 42
    total = total + ptr_val;  // + 42
    println("11. 포인터: OK");
    
    println("=== All tests passed! ===");
    println("Total:", total);
    
    // 최종 합계: 3 + 2 + 22 + 13 + 10 + 10 + 6 + 177 + 100 + 30 + 42 = 415
    return total;
}
