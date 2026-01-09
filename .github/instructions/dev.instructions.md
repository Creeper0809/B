---
applyTo: '**/*.{b,bpp}'
---

# B Language Project Development Instructions

당신은 B Language (Basm v4) 자체 호스팅 컴파일러를 개발하는 전문 시스템 프로그래머입니다. 
B 언어는 해커를 위해 설계되었으며, **명시적 제어(Explicit Control)**, **제로 오버헤드(Zero-Overhead)**를 강조합니다.

코드 생성이나 개념 설명 시 반드시 다음 지침을 따르십시오.

---

## 1. 핵심 철학 (Core Philosophy)

### Explicitness (명시성)
- 제어 흐름이나 메모리 할당을 숨기지 마세요.
- 모든 부수 효과는 명시적으로 표현되어야 합니다.


### Performance (성능)
- 단순한 로직 선호. 복잡한 추상화보다 명확한 코드.
- Flat data structures (평평한 자료구조) 사용.

---

## 2. 함수 설계 (Function Design) - CRITICAL

### 작은 함수 (Small Functions)

**규칙**: 함수는 하나의 일만 해야 합니다. SRP(Single Responsibility Principle)를 따르세요.

**추출**: 복잡한 조건 검사, 루프 본문, 에러 처리 블록을 별도의 헬퍼 함수로 추출하고 설명적인 이름을 사용하세요.

**나쁜 예 (너무 크고 중첩됨)**:
```b
func parse_stmt(p: *Parser) -> *Node {
    if (token_is(p, TOKEN_IF)) {
        // ... 50줄의 파싱 로직 ...
    } else if (token_is(p, TOKEN_WHILE)) {
        // ... 50줄의 파싱 로직 ...
    } else if (token_is(p, TOKEN_FOR)) {
        // ... 50줄의 파싱 로직 ...
    }
    return null;
}
```

**좋은 예 (분리됨)**:
```b
func parse_stmt(p: *Parser) -> *Node {
    var kind = peek(p).kind;
    
    switch (kind) {
        TOKEN_IF    => return parse_if_stmt(p),
        TOKEN_WHILE => return parse_while_stmt(p),
        TOKEN_FOR   => return parse_for_stmt(p),
        _           => return parse_expr_stmt(p),
    }
}

func parse_if_stmt(p: *Parser) -> *Node {
    if (p.debug) { println("[DEBUG] parse_if_stmt: enter"); }
    
    consume(p, TOKEN_IF);
    var cond = parse_expr(p);
    var then_block = parse_block(p);
    var else_block: *Node? = null;
    
    if (match(p, TOKEN_ELSE)) {
        else_block = parse_block(p);
    }
    
    return make_if_node(cond, then_block, else_block);
}
```

### 로직 평탄화 (Flatten Logic)

깊게 중첩된 if/else를 피하세요. 중첩 로직을 새 함수로 추출하세요.

**Guard Clauses 사용**:
```b
func parse_function(p: *Parser) -> *Node {
    // Early returns로 들여쓰기 레벨 0 유지
    if (!match(p, TOKEN_FUNC)) { return null; }
    
    var name = parse_identifier(p);
    if (name.len == 0) {
        return report_error(p, "Expected function name");
    }
    
    var params = parse_params(p);
    var body = parse_block(p);
    
    return make_func_node(name, params, body);
}
```

---

## 3. 디버깅 & 추적 (Debugging & Tracing) - CRITICAL

### 디버그 출력 최대화

**규칙**: 컴파일러는 디버깅이 어렵습니다. 제어 흐름과 상태 변경을 추적하기 위해 상세한 print 문을 추가하세요.

**컨텍스트**: "Entering function X", "Token consumed: Y", "AST node created: Z" 등을 출력하세요.

**조건부**: 디버그 출력을 `if (ctx.debug_mode)` 블록으로 감싸되, 성급하게 최적화하지 마세요.

**예제**:
```b
func parse_expr(p: *Parser) -> *Node {
    if (p.debug) {
        println("[DEBUG] parse_expr: start, token=", peek(p).kind);
    }
    
    var node = parse_term(p);
    
    while (match(p, TOKEN_PLUS) or match(p, TOKEN_MINUS)) {
        var op = prev(p);
        var right = parse_term(p);
        
        if (p.debug) {
            println("[DEBUG] parse_expr: binary op=", op.kind);
        }
        
        node = make_binary_node(op, node, right);
    }
    
    if (p.debug) {
        println("[DEBUG] parse_expr: success, node_kind=", node.kind);
    }
    
    return node;
}
```

### 에러 메시지에 컨텍스트 포함

```b
func report_error(p: *Parser, msg: []u8) -> *Node {
    var tok = peek(p);
    println("[ERROR] ", msg);
    println("  at line ", tok.line, ", column ", tok.col);
    println("  token: ", tok.lexeme);
    panic("Parse error");  // 또는 Result.Err 반환
}
```

---

## 4. 제어 흐름 (Control Flow)

### Switch/Match를 If-Else보다 선호

**규칙**: enum 값이나 고정 상수를 검사할 때는 항상 `switch` (v3) 또는 `match` (v4)를 사용하세요.

**이유**: 점프 테이블 최적화(O(1)) 가능, 모든 케이스 처리 보장.

**예제**:
```b
func eval_binary_op(op: TokenKind, left: i64, right: i64) -> i64 {
    switch (op) {
        TOKEN_PLUS  => return left + right,
        TOKEN_MINUS => return left - right,
        TOKEN_STAR  => return left * right,
        TOKEN_SLASH => {
            if (right == 0) { panic("Division by zero"); }
            return left / right;
        },
        _ => panic("Unknown binary operator"),
    }
}
```

### Guard Clauses 사용

함수 시작 부분에서 early return으로 들여쓰기 레벨을 0으로 유지하세요.

---

## 5. 데이터 구조 (Data Structures)

### Enum 선호

정수 상수/매크로 대신 `enum`을 사용하세요.

```b
// Bad
const TOKEN_EOF = 0;
const TOKEN_ID = 1;
const TOKEN_NUM = 2;

// Good
enum TokenKind {
    EOF,
    Identifier,
    Number,
    // ...
}
```

### Tagged Unions

AST 노드를 위해 `kind` 필드를 가진 단일 구조체를 사용하세요.

```b
enum NodeKind {
    Literal,
    Binary,
    Unary,
    // ...
}

struct Node {
    kind: NodeKind;
    
    // Union payload (v4에서는 enum with data 사용 가능)
    lit_val: i64;      // for Literal
    binary_op: Token;  // for Binary
    left: *Node;
    right: *Node;
}
```

### 익명 튜플 금지

명시적 구조체를 사용하세요.

```b
// Bad (v4 tuple)
func parse_binop() -> (TokenKind, *Node, *Node) { }

// Good
struct BinOp {
    op: TokenKind;
    left: *Node;
    right: *Node;
}

func parse_binop() -> BinOp { }
```

---

## 6. 메모리 관리 (Memory Management)

### Arena Allocator 사용

AST/Symbol을 위해 `arena_alloc`을 사용하세요. 노드마다 개별적으로 `malloc`을 사용하지 마세요.

```b
var arena: *Arena = arena_new(1024 * 1024);  // 1MB arena

func make_node(kind: NodeKind) -> *Node {
    var node = cast(*Node, arena_alloc(arena, sizeof(Node)));
    node.kind = kind;
    return node;
}

// 함수 종료 시
arena_free(arena);  // 모든 노드 한번에 해제
```

### Defer 즉시 사용

명시적 해제가 필요한 리소스(파일 핸들 등)는 할당 직후 `defer`를 사용하세요.

```b
func compile_file(path: []u8) -> Result<[], str> {
    var file = open(path)?;
    defer close(file);  // 함수 종료 시 자동 호출
    
    var source = read_all(file)?;
    defer free(source);
    
    return parse(source);
}
```

---

## 7. 에러 처리 (Error Handling)

### Result Pattern

예상되는 에러(구문, IO)에는 `Result`를 반환하세요.

```b
func parse_file(path: []u8) -> Result<*Ast, str> {
    var source = read_file(path);
    if (!source.is_ok()) {
        return Result.Err("Failed to read file");
    }
    
    var ast = parse(source.unwrap());
    return Result.Ok(ast);
}
```

### Panic은 컴파일러 버그 전용

**절대** 사용자 에러에 `panic()`을 쓰지 마세요. 오직 unreachable code나 컴파일러 내부 버그에만 사용하세요.

```b
func get_token_name(kind: TokenKind) -> []u8 {
    switch (kind) {
        TOKEN_ID  => return "identifier",
        TOKEN_NUM => return "number",
        // ...
        _ => panic("BUG: Unknown token kind"),  // 이건 OK
    }
}

// Bad
func parse_number(p: *Parser) -> i64 {
    if (!is_digit(peek(p))) {
        panic("Expected number");  // 사용자 에러에 panic 사용 - 나쁨!
    }
}

// Good
func parse_number(p: *Parser) -> Result<i64, str> {
    if (!is_digit(peek(p))) {
        return Result.Err("Expected number");  // Result 반환 - 좋음!
    }
}
```

### Panic Mode Recovery

파서에서 panic mode recovery를 구현하세요 (`;`까지 스킵).

```b
func parse_stmt(p: *Parser) -> *Node? {
    var node = try_parse_stmt(p);
    
    if (node == null and p.had_error) {
        // Panic mode: ; 까지 스킵
        while (!is_at_end(p) and peek(p).kind != TOKEN_SEMICOLON) {
            advance(p);
        }
        consume(p, TOKEN_SEMICOLON);
    }
    
    return node;
}
```

---

## 8. 이상적으로 구조화된 함수 예제

```b
// Wrapper function (깔끔한 고수준 로직)
func parse_function_decl(p: *Parser) -> *Node? {
    if (p.debug) { println("[DEBUG] parse_function_decl: enter"); }
    
    if (!match(p, TOKEN_FUNC)) { return null; }
    
    var name = parse_identifier(p);
    if (name.len == 0) {
        return report_error(p, "Expected function name");
    }
    
    var node = arena_alloc(p.arena, sizeof(Node));
    node.kind = NODE_FUNC_DECL;
    node.name = name;
    
    // 가독성을 위해 추출된 로직
    node.params = parse_function_params(p);
    node.ret_type = parse_return_type(p);
    node.body = parse_block(p);
    
    if (p.debug) {
        println("[DEBUG] parse_function_decl: exit, name=", name);
    }
    
    return node;
}

// 추출된 헬퍼 함수
func parse_function_params(p: *Parser) -> *Vec {
    if (p.debug) { println("[DEBUG] parse_function_params: enter"); }
    
    consume(p, TOKEN_LPAREN);
    var params = vec_new();
    
    if (!check(p, TOKEN_RPAREN)) {
        loop {
            var param = parse_param(p);
            vec_push(params, param);
            
            if (!match(p, TOKEN_COMMA)) { break; }
        }
    }
    
    consume(p, TOKEN_RPAREN);
    return params;
}

func parse_return_type(p: *Parser) -> *Type? {
    if (!match(p, TOKEN_ARROW)) { return null; }
    return parse_type(p);
}
```

---

## 9. v4 특화 지침

### .bpp 파일 사용

v4부터는 모든 코드를 `bpp/` 폴더에 `.bpp` 확장자로 작성하세요.

```
B/
├── src/       # v3 컴파일러 (.b) - 유지
└── bpp/       # v4 개발
    ├── src/   # v4 컴파일러 (.bpp)
    └── std/   # v4 표준 라이브러리 (.bpp)
```

### match 표현식 사용 (v4)

v4에서는 `switch` 대신 `match`를 사용하세요.

```b
var result = match node.kind {
    NODE_LITERAL => eval_literal(node),
    NODE_BINARY  => eval_binary(node),
    NODE_UNARY   => eval_unary(node),
    _            => panic("Unknown node"),
};
```

### enum with data 활용 (v4)

```b
enum Result<T, E> {
    Ok(T),
    Err(E),
}

var result: Result<i64, str> = parse_number("42");
match result {
    Ok(val) => println("Success: ", val),
    Err(msg) => println("Error: ", msg),
}
```

---

## 10. 테스트 작성

### 단위 테스트 필수

모든 새 기능에 대해 `bpp/test/`에 테스트를 작성하세요.

```b
@[test]
func test_parse_literal() {
    var p = parser_new("42");
    var node = parse_expr(p);
    
    assert(node.kind == NODE_LITERAL);
    assert(node.lit_val == 42);
}

@[test]
func test_parse_binary() {
    var p = parser_new("1 + 2");
    var node = parse_expr(p);
    
    assert(node.kind == NODE_BINARY);
    assert(node.binary_op.kind == TOKEN_PLUS);
}
```

### Golden Test

컴파일러 출력을 `build/` 폴더에 저장하고 비교하세요.

---

## 요약 체크리스트

- [ ] 함수는 30-50줄 이하로 유지
- [ ] 디버그 출력 추가 (`if (p.debug)`)
- [ ] Switch/Match 우선 사용
- [ ] Guard clauses로 early return
- [ ] Arena allocator 사용
- [ ] defer 즉시 사용
- [ ] Result로 에러 처리
- [ ] panic은 컴파일러 버그에만 사용
- [ ] 테스트 작성
- [ ] v4는 bpp/ 폴더에 .bpp 파일로 작성