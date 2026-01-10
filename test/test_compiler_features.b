// 복잡한 통합 테스트: 컴파일러 개발에 필요한 모든 문법 검증
// - enum, struct, 포인터, 슬라이스, 배열
// - impl 메서드, 함수 포인터
// - switch, while, for, foreach
// - defer, 재귀, 중첩 블록
// - 변수 섀도잉

// ========== 토큰 정의 (enum) ==========
enum TokenKind {
    EOF = 0,
    IDENT = 1,
    NUMBER = 2,
    PLUS = 10,
    MINUS = 11,
    STAR = 12,
    SLASH = 13,
    LPAREN = 20,
    RPAREN = 21,
}

// ========== 구조체 정의 ==========
struct Token {
    kind: u64;
    value: u64;
}

struct Lexer {
    input: []u8;
    pos: u64;
}

struct Node {
    kind: u64;      // 0=Number, 1=BinOp
    value: u64;     // number value or operator
    left: *Node?;
    right: *Node?;
}

struct Parser {
    tokens: [10]Token;
    count: u64;
    pos: u64;
}

// ========== Lexer 구현 (impl 블록) ==========
impl Lexer {
    func next_token(self: *Lexer) -> Token {
        // 공백 건너뛰기
        while (self.pos < self.input.len) {
            var ch = self.input[self.pos];
            if (ch != 32) {  // space
                break;
            }
            self.pos = self.pos + 1;
        }
        
        // EOF 체크
        if (self.pos >= self.input.len) {
            var tok: Token;
            tok.kind = TokenKind.EOF;
            tok.value = 0;
            return tok;
        }
        
        var ch = self.input[self.pos];
        self.pos = self.pos + 1;
        
        var tok: Token;
        
        // switch로 토큰 분류
        switch (ch) {
            43 => {  // '+'
                tok.kind = TokenKind.PLUS;
                tok.value = 0;
            },
            45 => {  // '-'
                tok.kind = TokenKind.MINUS;
                tok.value = 0;
            },
            42 => {  // '*'
                tok.kind = TokenKind.STAR;
                tok.value = 0;
            },
            47 => {  // '/'
                tok.kind = TokenKind.SLASH;
                tok.value = 0;
            },
            40 => {  // '('
                tok.kind = TokenKind.LPAREN;
                tok.value = 0;
            },
            41 => {  // ')'
                tok.kind = TokenKind.RPAREN;
                tok.value = 0;
            },
            default => {
                // 숫자 파싱 (48-57 = '0'-'9')
                if (ch >= 48 and ch <= 57) {
                    tok.kind = TokenKind.NUMBER;
                    tok.value = ch - 48;
                } else {
                    tok.kind = TokenKind.IDENT;
                    tok.value = ch;
                }
            },
        }
        
        return tok;
    }
}

// ========== Parser 구현 ==========
impl Parser {
    func peek(self: *Parser) -> Token {
        if (self.pos < self.count) {
            return self.tokens[self.pos];
        }
        var tok: Token;
        tok.kind = TokenKind.EOF;
        return tok;
    }
    
    func advance(self: *Parser) {
        if (self.pos < self.count) {
            self.pos = self.pos + 1;
        }
    }
}

// ========== 메모리 할당 함수 (포인터 연산) ==========
var arena_offset: u64;
var arena: [1000]u8;

func alloc_node() -> *Node {
    var ptr = cast(*Node, cast(u64, &arena) + arena_offset);
    arena_offset = arena_offset + sizeof(Node);
    return ptr;
}

// ========== AST 생성 함수들 ==========
func make_number_node(val: u64) -> *Node {
    var node = alloc_node();
    node.kind = 0;  // Number
    node.value = val;
    node.left = null;
    node.right = null;
    return node;
}

func make_binop_node(op: u64, left: *Node, right: *Node) -> *Node {
    var node = alloc_node();
    node.kind = 1;  // BinOp
    node.value = op;
    node.left = left;
    node.right = right;
    return node;
}

// ========== 재귀 파서 함수 ==========
func parse_primary(p: *Parser) -> *Node? {
    var tok = p.peek(p);
    
    if (tok.kind == TokenKind.NUMBER) {
        p.advance(p);
        return make_number_node(tok.value);
    }
    
    if (tok.kind == TokenKind.LPAREN) {
        p.advance(p);
        var expr = parse_expr(p);
        var rparen = p.peek(p);
        if (rparen.kind == TokenKind.RPAREN) {
            p.advance(p);
        }
        return expr;
    }
    
    return null;
}

func parse_term(p: *Parser) -> *Node? {
    var left = parse_primary(p);
    if (left == null) {
        return null;
    }
    
    // while로 좌결합 연산자 처리
    while (1 == 1) {
        var tok = p.peek(p);
        if (tok.kind != TokenKind.STAR and tok.kind != TokenKind.SLASH) {
            break;
        }
        
        p.advance(p);
        var right = parse_primary(p);
        if (right == null) {
            return left;
        }
        
        left = make_binop_node(tok.kind, left, right);
    }
    
    return left;
}

func parse_expr(p: *Parser) -> *Node? {
    var left = parse_term(p);
    if (left == null) {
        return null;
    }
    
    while (1 == 1) {
        var tok = p.peek(p);
        if (tok.kind != TokenKind.PLUS and tok.kind != TokenKind.MINUS) {
            break;
        }
        
        p.advance(p);
        var right = parse_term(p);
        if (right == null) {
            return left;
        }
        
        left = make_binop_node(tok.kind, left, right);
    }
    
    return left;
}

// ========== 평가기 (재귀, nullable 포인터 처리) ==========
func eval(node: *Node?) -> u64 {
    if (node == null) {
        return 0;
    }
    
    var n = unwrap_ptr(node);
    
    if (n.kind == 0) {  // Number
        return n.value;
    }
    
    // BinOp
    var left_val = eval(n.left);
    var right_val = eval(n.right);
    
    // switch로 연산자 처리
    switch (n.value) {
        TokenKind.PLUS => {
            return left_val + right_val;
        },
        TokenKind.MINUS => {
            return left_val - right_val;
        },
        TokenKind.STAR => {
            return left_val * right_val;
        },
        TokenKind.SLASH => {
            if (right_val != 0) {
                return left_val / right_val;
            }
            return 0;
        },
        default => {
            return 0;
        },
    }
}

// ========== 함수 포인터 테스트 ==========
func double_it(x: u64) -> u64 {
    return x * 2;
}

func triple_it(x: u64) -> u64 {
    return x * 3;
}

func apply(f: func(u64) -> u64, val: u64) -> u64 {
    return f(val);
}

// ========== 배열/슬라이스 테스트 ==========
func sum_array(arr: [5]u64) -> u64 {
    var total: u64 = 0;
    
    // for 루프
    for (var i: u64 = 0; i < 5; i = i + 1) {
        total = total + arr[i];
    }
    
    return total;
}

func sum_slice(s: []u8) -> u64 {
    var total: u64 = 0;
    
    // foreach로 슬라이스 순회
    foreach (var b in s) {
        total = total + cast(u64, b);
    }
    
    return total;
}

// ========== 중첩 블록 + 섀도잉 테스트 ==========
func test_shadowing() -> u64 {
    var x: u64 = 1;
    
    {
        var x: u64 = 2;  // 섀도잉
        {
            var x: u64 = 3;  // 더 깊은 섀도잉
            x = x + 1;
            // x == 4
        }
        x = x + 10;
        // x == 12
    }
    
    x = x + 100;
    return x;  // 101
}

// ========== defer 테스트 ==========
func test_defer() -> u64 {
    var result: u64 = 0;
    
    {
        result = result + 1;
        defer result = result * 2;
        defer result = result + 10;
        result = result + 5;
        // result = 6, defer: +10 -> 16, *2 -> 32
    }
    
    return result;  // 32
}

// ========== 메인: 모든 기능 통합 테스트 ==========
func main() -> u64 {
    var total: u64 = 0;
    
    // 1. Lexer 테스트: "3 + 4 * 2"
    {
        var input: []u8 = "3 + 4 * 2";
        var lex: Lexer;
        lex.input = input;
        lex.pos = 0;
        
        var tok_count: u64 = 0;
        while (tok_count < 5) {
            var t = lex.next_token(&lex);
            if (t.kind == TokenKind.EOF) {
                break;
            }
            tok_count = tok_count + 1;
        }
        
        total = total + tok_count;  // 5개 토큰
    }
    
    // 2. Parser + Eval 테스트: 3 + 4 * 2 = 11
    {
        arena_offset = 0;
        
        var p: Parser;
        p.pos = 0;
        p.count = 5;
        
        // 토큰 배열 초기화
        p.tokens[0].kind = TokenKind.NUMBER;
        p.tokens[0].value = 3;
        p.tokens[1].kind = TokenKind.PLUS;
        p.tokens[2].kind = TokenKind.NUMBER;
        p.tokens[2].value = 4;
        p.tokens[3].kind = TokenKind.STAR;
        p.tokens[4].kind = TokenKind.NUMBER;
        p.tokens[4].value = 2;
        
        var ast = parse_expr(&p);
        var result = eval(ast);
        total = total + result;  // + 11
    }
    
    // 3. 함수 포인터 테스트
    {
        var v1 = apply(double_it, 5);   // 10
        var v2 = apply(triple_it, 4);   // 12
        total = total + v1 + v2;  // + 22
    }
    
    // 4. 배열 테스트
    {
        var arr: [5]u64;
        arr[0] = 1;
        arr[1] = 2;
        arr[2] = 3;
        arr[3] = 4;
        arr[4] = 5;
        
        var s = sum_array(arr);
        total = total + s;  // + 15
    }
    
    // 5. 슬라이스 테스트 (ASCII 값)
    {
        var str: []u8 = "ABC";  // 65, 66, 67
        var s = sum_slice(str);
        total = total + s;  // + 198
    }
    
    // 6. 섀도잉 테스트
    {
        var v = test_shadowing();
        total = total + v;  // + 101
    }
    
    // 7. defer 테스트
    {
        var v = test_defer();
        total = total + v;  // + 32
    }
    
    // 최종 합계: 5 + 11 + 22 + 15 + 198 + 101 + 32 = 384
    return total;
}
