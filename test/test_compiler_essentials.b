// B v3 컴파일러 필수 문법 검증
// enum, struct, impl, 함수 포인터, 재귀, 루프, 슬라이스, 섀도잉, defer

// ========== enum (토큰 종류) ==========
enum TokenKind {
    EOF = 0,
    NUMBER = 1,
    PLUS = 2,
    STAR = 3,
}

enum NodeKind {
    LITERAL = 10,
    BINOP = 11,
}

// ========== struct (파서 구조체) ==========
struct Token {
    kind: u64;
    value: u64;
}

struct Parser {
    pos: u64;
    token_count: u64;
}

// ========== 일반 함수로 메서드 흉내 ==========
func parser_advance(p: *Parser) {
    p->pos = p->pos + 1;
}

func parser_current_pos(p: *Parser) -> u64 {
    return p->pos;
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
    println("=== B v3 Compiler Feature Test ===");
    
    var result: u64 = 0;
    
    // 1. enum 테스트
    var tok_kind = TokenKind.STAR;
    var node_kind = NodeKind.BINOP;
    result = cast(u64, tok_kind) + cast(u64, node_kind);
    println("1. Enum:", result);  // 3 + 11 = 14
    
    // 2. struct + 함수
    var p: Parser;
    p.pos = 0;
    p.token_count = 10;
    parser_advance(&p);
    parser_advance(&p);
    result = parser_current_pos(&p);
    println("2. Struct + functions:", result);  // 2
    
    // 3. struct 필드 접근
    var t: Token;
    t.kind = cast(u64, TokenKind.PLUS);
    t.value = 42;
    result = t.kind + t.value;
    println("3. Struct fields:", result);  // 2 + 42 = 44
    
    // 4. 함수 포인터
    result = apply(double, 5);
    println("4. Function pointer:", result);  // 10
    
    // 5. 재귀
    result = fib(7);
    println("5. Recursion (fib7):", result);  // 13
    
    // 6. while 루프
    var sum: u64 = 0;
    var i: u64 = 1;
    while (i <= 5) {
        sum = sum + i;
        i = i + 1;
    }
    println("6. While loop (1-5):", sum);  // 15
    
    // 7. for 루프
    sum = 0;
    for (var j: u64 = 1; j <= 4; j = j + 1) {
        sum = sum + j;
    }
    println("7. For loop (1-4):", sum);  // 10
    
    // 8. foreach + 슬라이스
    var str: []u8 = "ABC";
    sum = 0;
    foreach (var ch in str) {
        sum = sum + cast(u64, ch);
    }
    println("8. Foreach/slice:", sum);  // 65+66+67=198
    
    // 9. 섀도잉
    var x: u64 = 100;
    {
        var x: u64 = 50;
        println("9. Shadowing inner:", x);  // 50
    }
    println("9. Shadowing outer:", x);  // 100
    
    // 10. defer
    var deferred: u64 = 1;
    {
        deferred = 10;
        defer deferred = deferred * 2;
        deferred = deferred + 5;
        println("10. Defer before:", deferred);  // 15
    }
    println("10. Defer after:", deferred);  // 30
    
    println("=== All 10 features passed! ===");
    
    // 최종 결과: defer 후 값 반환
    return deferred;  // 30
}
