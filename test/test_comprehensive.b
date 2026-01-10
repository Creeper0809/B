// 컴파일러 개발 필수 문법 종합 테스트

// ========== 1. enum 정의 ==========
enum TokenKind {
    EOF = 0,
    NUMBER = 1,
    PLUS = 2,
    MINUS = 3,
    STAR = 4,
}

enum NodeKind {
    LITERAL = 0,
    BINOP = 1,
}

// ========== 2. 구조체 정의 ==========
struct Token {
    kind: u64;
    value: u64;
}

struct Node {
    kind: u64;
    value: u64;
    left: *Node?;
    right: *Node?;
}

struct Parser {
    pos: u64;
    count: u64;
}

// ========== 3. impl 블록 (메서드) ==========
impl Parser {
    func advance(self: *Parser) {
        if (self.pos < self.count) {
            self.pos = self.pos + 1;
        }
    }
    
    func has_more(self: *Parser) -> bool {
        return self.pos < self.count;
    }
}

// ========== 4. 함수 포인터 ==========
func double_value(x: u64) -> u64 {
    return x * 2;
}

func triple_value(x: u64) -> u64 {
    return x * 3;
}

func apply_func(f: func(u64) -> u64, val: u64) -> u64 {
    return f(val);
}

// ========== 5. 포인터 연산 & 재귀 ==========
var node_arena: [100]u64;
var node_offset: u64;

func alloc_node() -> *Node {
    var ptr = cast(*Node, cast(u64, &node_arena) + node_offset);
    node_offset = node_offset + sizeof(Node);
    return ptr;
}

func make_literal(val: u64) -> *Node {
    var n = alloc_node();
    n.kind = NodeKind.LITERAL;
    n.value = val;
    n.left = null;
    n.right = null;
    return n;
}

func make_binop(op: u64, left: *Node, right: *Node) -> *Node {
    var n = alloc_node();
    n.kind = NodeKind.BINOP;
    n.value = op;
    n.left = left;
    n.right = right;
    return n;
}

// 재귀 평가
func eval_tree(node: *Node?) -> u64 {
    if (node == null) {
        return 0;
    }
    
    var n = unwrap_ptr(node);
    
    if (n.kind == NodeKind.LITERAL) {
        return n.value;
    }
    
    // BINOP
    var lhs = eval_tree(n.left);
    var rhs = eval_tree(n.right);
    
    switch (n.value) {
        case TokenKind.PLUS:
            return lhs + rhs;
        case TokenKind.MINUS:
            return lhs - rhs;
        case TokenKind.STAR:
            return lhs * rhs;
        default:
            return 0;
    }
}

// ========== 6. 제어 흐름 테스트 ==========
func test_control_flow() -> u64 {
    var sum: u64 = 0;
    
    // while 루프
    var i: u64 = 0;
    while (i < 5) {
        sum = sum + i;
        i = i + 1;
    }
    
    // for 루프
    for (var j: u64 = 0; j < 3; j = j + 1) {
        sum = sum + j * 2;
    }
    
    // switch
    var x: u64 = 2;
    switch (x) {
        case 0:
            sum = sum + 1;
        case 1:
            sum = sum + 2;
        case 2:
            sum = sum + 5;
        default:
            sum = sum + 0;
    }
    
    return sum;
}

// ========== 7. 슬라이스/foreach ==========
func sum_string_bytes(s: []u8) -> u64 {
    var total: u64 = 0;
    
    foreach (var b in s) {
        total = total + cast(u64, b);
    }
    
    return total;
}

// ========== 8. 중첩 블록 & 섀도잉 ==========
func test_shadowing() -> u64 {
    var x: u64 = 10;
    
    {
        var x: u64 = 20;
        x = x + 5;
        // x == 25
    }
    
    return x;  // 10
}

// ========== 9. defer ==========
func test_defer() -> u64 {
    var result: u64 = 1;
    
    {
        result = result + 5;
        defer result = result * 2;
        result = result + 3;
        // result = 9, defer: * 2 -> 18
    }
    
    return result;
}

// ========== 10. 복잡한 트리 빌드 & 평가 ==========
func build_complex_tree() -> *Node {
    // (3 + 4) * 2 = 14
    var left = make_binop(TokenKind.PLUS, 
                          make_literal(3), 
                          make_literal(4));
    var root = make_binop(TokenKind.STAR, 
                          left, 
                          make_literal(2));
    return root;
}

// ========== 메인: 모든 테스트 실행 ==========
func main() -> u64 {
    var total: u64 = 0;
    
    // 1. enum 사용
    total = total + TokenKind.STAR;  // + 4
    
    // 2. impl 메서드
    var p: Parser;
    p.pos = 0;
    p.count = 5;
    p.advance(&p);
    if (p.has_more(&p)) {
        total = total + 10;  // + 10
    }
    
    // 3. 함수 포인터
    var v1 = apply_func(double_value, 7);  // 14
    var v2 = apply_func(triple_value, 5);  // 15
    total = total + v1 + v2;  // + 29
    
    // 4. 제어 흐름
    var cf = test_control_flow();  // 10 + 6 + 5 = 21
    total = total + cf;
    
    // 5. 슬라이스/foreach
    var str: []u8 = "AB";  // 65 + 66 = 131
    var sb = sum_string_bytes(str);
    total = total + sb;
    
    // 6. 섀도잉
    var sh = test_shadowing();  // 10
    total = total + sh;
    
    // 7. defer
    var df = test_defer();  // 18
    total = total + df;
    
    // 8. 트리 빌드 & 평가
    node_offset = 0;
    var tree = build_complex_tree();
    var result = eval_tree(tree);  // 14
    total = total + result;
    
    // 최종: 4 + 10 + 29 + 21 + 131 + 10 + 18 + 14 = 237
    return total;
}
