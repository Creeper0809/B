// B 컴파일러 v3 핵심 기능 테스트
// 모든 컴파일러 개발 필수 문법 검증

enum TokenKind {
    EOF = 0,
    NUMBER = 1,
    PLUS = 2,
}

struct Parser {
    pos: u64;
}

impl Parser {
    func inc(self: *Parser) {
        self->pos = self->pos + 1;
    }
}

func double(x: u64) -> u64 {
    return x * 2;
}

func apply(f: func(u64) -> u64, x: u64) -> u64 {
    return f(x);
}

func fib(n: u64) -> u64 {
    if (n < 2) {
        return n;
    }
    return fib(n - 1) + fib(n - 2);
}

func main() -> u64 {
    println("=== B v3 Feature Test ===");
    
    var total: u64 = 0;
    
    // 1. enum
    total = total + cast(u64, TokenKind.PLUS);
    println("✓ enum");
    
    // 2. struct + impl + 포인터
    var p: Parser;
    p.pos = 5;
    p.inc(&p);
    total = total + p.pos;
    println("✓ struct/impl/pointer");
    
    // 3. 함수 포인터
    total = total + apply(double, 10);
    println("✓ function pointer");
    
    // 4. 재귀
    total = total + fib(6);
    println("✓ recursion");
    
    // 5. while
    var i: u64 = 0;
    while (i < 3) {
        total = total + i;
        i = i + 1;
    }
    println("✓ while");
    
    // 6. for
    for (var j: u64 = 0; j < 2; j = j + 1) {
        total = total + j;
    }
    println("✓ for");
    
    // 7. foreach + 슬라이스
    var str: []u8 = "AB";
    foreach (var ch in str) {
        total = total + cast(u64, ch);
    }
    println("✓ foreach/slice");
    
    // 8. 섀도잉
    var x: u64 = 100;
    {
        var x: u64 = 50;
        total = total + x;
    }
    total = total - x;
    println("✓ shadowing");
    
    // 9. defer
    {
        var v: u64 = 10;
        defer v = v * 2;
        v = v + 5;
        total = total + v;
    }
    println("✓ defer");
    
    println("=== All features working! ===");
    println("Result:", total);
    
    // 계산: 2 + 6 + 20 + 8 + (0+1+2) + (0+1) + (65+66) + 50 - 100 + 15
    //     = 2 + 6 + 20 + 8 + 3 + 1 + 131 + 50 - 100 + 15 = 136
    
    return total;
}
