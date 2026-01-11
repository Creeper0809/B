---
applyTo: '**'
---
# General Instructions
- **Language**: Always answer in **Korean (한국어)**.
- **Tone**: Be concise in conversation, but verbose and detailed in code comments and documentation.
- **Context Awareness**: Always check existing documentation and the current file structure before answering.

# Coding Standards & Workflow (CRITICAL)

## 1. Unit Testing (Mandatory)
- **Rule**: For EVERY new feature or logic change, you MUST write or update unit tests.
- **Location**: All tests must be placed in the `B/{version}/test` directory.
- **Validation**: Verify that tests cover edge cases before considering the task done.

## 2. Post-Coding Workflow
After completing ANY coding task, you MUST perform the following two actions automatically without being asked:

### Action A: Update TODO List
- **File**: `/docs/(current_version)_todo.md` (Check the active version file).
- **Tasks**:
  - Mark completed tasks with `[x]`.
  - Add new tasks if the current work reveals necessary future steps.
  - Ensure the roadmap remains up-to-date.

### Action B: Write Detailed Devlog
- **File**: `/pages/devlog-YYYY-MM-DD.md` (Use today's date, e.g., `/pages/devlog-2026-01-07.md`).
- **Trigger**: 
  - After completing ANY coding task
  - **MUST write when a Phase is completed** (e.g., Phase 4.0.1, Phase 4.1.2)
- **Structure Requirement (STAR Format)**:
  1. **Situation (상황/배경)**:
     - 왜 이 작업이 필요했는가?
     - 어떤 문제를 해결하려고 했는가?
     - Phase의 목표가 무엇이었는가?
  2. **Task (과제/목표)**:
     - 구체적으로 무엇을 구현해야 했는가?
     - 어떤 기술적 요구사항이 있었는가?
     - DoD (Definition of Done)는 무엇이었는가?
  3. **Action (수행한 작업)**:
     - 어떤 코드를 변경하거나 추가했는가? (코드 스니펫 포함)
     - 어떤 파일들을 수정했는가?
     - 구현 과정에서 어떤 결정을 내렸는가?
     - **Challenges & Troubleshooting (중요)**:
       - 구체적인 어려움 (파싱 모호성, 로직 에러 등)
       - 디버깅 과정 상세 기술
       - 문제 해결 방법
  4. **Result (결과 및 최종 구현)**:
     - **각 기능마다 최종 구현 방법을 자세히 설명**:
       - 함수/클래스/모듈의 동작 원리
       - 데이터 흐름 및 제어 흐름
       - 아키텍처 결정 및 이유
     - 성능 측정 결과 (해당되는 경우)
     - 남은 과제 또는 개선 사항
     - 테스트 결과

- **Detail Level**: 
  - Phase 완료 시: 매우 상세하게 (1000+ 단어)
  - 일반 작업 완료 시: 적절히 상세하게 (300-500 단어)
  - 코드 스니펫, 다이어그램, 예제 적극 활용

# Interaction Trigger
- If I ask for a feature implementation, assume the workflow above (Code -> Test -> Todo -> Devlog) applies unless told otherwise.
- When a **Phase is completed**, automatically write a comprehensive devlog in STAR format without being asked.

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
