# B Language v4 Development Plan

v4_roadmap.md의 실행 계획. 기능을 의존성과 우선순위에 따라 버전별로 구분.

**원칙**:
- 각 버전은 **독립적으로 동작하는 컴파일러**를 유지
- 의존성 체인 내에서는 순서 엄수
- 블랙홀 위험 기능은 후순위 배치
- 각 버전마다 명확한 DoD

---

## Critical Path Analysis

### Path 1: 문법 완성 (Core Language)
```
match → enum with data → union → Result<T,E> → 표준 라이브러리
```
**우선순위**: [CRITICAL] (v4.0 필수)

### Path 2: 메모리 관리 (Memory Lifecycle)
```
new → delete → constructor → destructor → defer 개선
```
**우선순위**: [CRITICAL] (v4.0 필수)

### Path 3: 제네릭 개선 (Generics)
```
타입 추론 → Value generics → comptime 블록 → has_method/impls
```
**우선순위**: [HIGH] (v4.1)

### Path 4: CTFE (Compile-Time Execution)
```
AST Interpreter → Types as Values → Reflection → 조건부 컴파일
```
**우선순위**: [MEDIUM] (v4.3+, Optional)
**위험도**: [HIGH] (컴파일러 재설계 필요)

### Path 5: 다형성 (Inheritance & Traits)
```
struct 상속 → trait 정의 → impl → VTable 생성 → 다형성
```
**우선순위**: [MEDIUM] (v4.2, Optional)
**위험도**: [MEDIUM] (복잡도 높음)

### Path 6: 최적화 (Optimization)
```
SSA IR 전환 → Dominance Tree → 최적화 패스들
```
**우선순위**: [LOW] (v4.4+, Optional)
**위험도**: [MEDIUM] (SSA 전환 복잡)

---

## Version Roadmap

### v3.x Self-Hosting (선행 필수)
**기간**: 2026 Q1-Q2 (3-6개월)
**목표**: v3 문법으로 작성된 v3 컴파일러 완성
**상태**: [IN PROGRESS]

**전략**: 점진적 전환 (라이브러리 먼저, 컴파일러 나중에)

#### Phase 3.5: std 라이브러리 v3 전환 (중간 세이브포인트)
**기간**: 2026 Q1 (6-8주)
**목표**: std만 v3로 재작성, v2 컴파일러로 검증
**이유**: 컴파일러와 라이브러리를 동시에 바꾸면 버그 원인 파악 어려움

- [ ] **v3 std 라이브러리 작성**
  - [ ] Vec<T> v3 재작성 (동적 배열)
  - [ ] HashMap<K,V> v3 재작성
  - [ ] String v3 재작성 (기본 구현)
  - [ ] mem v3 재작성 (malloc/free/memcpy)
  - [ ] io v3 재작성 (파일 I/O)
  - [ ] str v3 재작성 (문자열 유틸리티)

- [ ] **v2 컴파일러로 v3 std 검증**
  - [ ] v2 컴파일러가 v3 std를 컴파일 가능한지 확인
  - [ ] std 단위 테스트 작성 및 통과
  - [ ] Golden test 중 std 의존 테스트 통과 확인

**v3.5 DoD**:
- [ ] v3 문법으로 작성된 std 라이브러리 완성
- [ ] v2 컴파일러로 v3 std 컴파일 성공
- [ ] std 단위 테스트 모두 통과
- [ ] 기존 v2 컴파일러가 v3 std를 사용하여 정상 동작

**블로커**: 없음 (즉시 시작 가능)

---

#### Phase 3.9: 컴파일러 v3 전환 (Full Self-Hosting)
**기간**: 2026 Q2 (8-10주)
**목표**: 컴파일러 자체를 v3로 재작성
**의존성**: v3.5 완료

**작업 항목**:
- [ ] Lexer v3 재작성
- [ ] Parser v3 재작성
- [ ] Type checker v3 재작성
- [ ] IR lowering v3 재작성
- [ ] Codegen v3 재작성
- [ ] Golden test 39개 통과
- [ ] 3세대 안정성 (v3→v3→v3 바이너리 동일)

**DoD**:
- [ ] v3 컴파일러가 자기 자신을 컴파일
- [ ] 모든 golden test 통과
- [ ] 3세대 체크 성공 (바이너리 해시 동일)

**블로커**: v3.5 미완료

---

### v4.0 Foundation (Core Language)
**기간**: 2026 Q3-Q4 (6-9개월)
**목표**: 문법 완성, v3 제약사항 해제
**상태**: [PLANNED]

**의존성**: v3 Self-Hosting 완료 필수

#### Phase 4.0.1: 제어 흐름 (2-3개월)

- [ ] **match 표현식** (v3의 switch 대체)
  - [ ] 파서: match 키워드, 패턴 매칭 문법
  - [ ] 타입 체크: 완전성 검사 (모든 케이스 커버)
  - [ ] Codegen: 점프 테이블 최적화
  - DoD: 정수/enum 매칭, 표현식으로 사용 가능
  - 참조: v4_roadmap.md 섹션 0.0

- [ ] **enum with data** (Tagged Union)
  - [ ] 파서: enum variant { data } 문법
  - [ ] 타입 체크: variant 검증
  - [ ] Codegen: discriminator + payload 레이아웃
  - DoD: Option<T>, Result<T,E> 구현 가능
  - 참조: v4_roadmap.md 섹션 0.0

- [ ] **union** (Raw Union, Type Punning)
  - [ ] 파서: union 키워드
  - [ ] Codegen: 필드 오버랩 (Offset 0)
  - DoD: 비트 캐스팅, 하드웨어 레지스터 매핑
  - 참조: v4_roadmap.md 섹션 0.0

#### Phase 4.0.2: 메모리 관리 (2-3개월)

- [ ] **new/delete 키워드**
  - [ ] 파서: new <Type>, delete ptr
  - [ ] Codegen: new → malloc + memset, delete → free
  - DoD: 모든 타입 힙 할당 가능
  - 참조: v4_roadmap.md 섹션 0.0

- [ ] **constructor/destructor**
  - [ ] 파서: constructor/destructor 키워드
  - [ ] Auto-Self: var self 자동 생성
  - [ ] Auto-Return: return self 자동 삽입
  - [ ] new T(...) → malloc + constructor 호출
  - [ ] delete ptr → destructor + free 호출
  - DoD: 객체 생명주기 관리, defer delete 패턴
  - 참조: v4_roadmap.md 섹션 0.0

#### Phase 4.0.3: 표준 타입 (1-2개월)

- [ ] **Result<T, E>**
  - [ ] enum 기반 구현
  - [ ] unwrap, unwrap_or, expect 메서드
  - DoD: 에러 처리 표준화
  - 참조: v4_roadmap.md 섹션 0.20

- [ ] **Option<T>**
  - [ ] enum 기반 구현
  - [ ] unwrap, is_some, is_none
  - DoD: Nullable 대체

- [ ] **String 타입**
  - [ ] Vec<u8> 래퍼
  - [ ] UTF-8 보장
  - [ ] String.new(), String.from() (명시적 할당)
  - [ ] s.free() (명시적 해제)
  - DoD: 문자열 표준 타입
  - 참조: v4_roadmap.md 섹션 2.1

#### Phase 4.0.4: 기타 제약 해제 (1-2개월)

- [ ] Struct 리터럴 expression
  - [ ] Named: Point{x: 1, y: 2}
  - [ ] Positional: Point{1, 2}
  - 참조: v4_roadmap.md 섹션 0.1

- [ ] 파라미터 7개 이상 지원 (스택 전달)
- [ ] defer break/continue 지원
  - 참조: v4_roadmap.md 섹션 0.8

**v4.0 DoD**:
- [ ] match로 모든 제어 흐름 처리
- [ ] enum/union으로 고급 타입 구현
- [ ] new/delete로 힙 메모리 관리
- [ ] constructor/destructor로 객체 생명주기 관리
- [ ] Result<T,E>로 에러 처리
- [ ] String 타입 사용 가능
- [ ] v3의 모든 제약사항 해제
- [ ] Golden test 추가 + 통과

**블로커**: v3 Self-Hosting 미완료

---

### v4.1 Generics & Comptime
**기간**: 2027 Q1-Q2 (6-9개월)
**목표**: 제네릭 개선, 기본 comptime 지원
**상태**: [PLANNED]

**의존성**: v4.0 완료

#### Phase 4.1.1: 제네릭 개선 (3-4개월)

- [ ] **타입 추론**
  - [ ] 함수 호출 시 타입 파라미터 추론
  - [ ] id(10) → id<u64>(10) 자동 변환
  - DoD: 명시적 <T> 생략 가능
  - 참조: v4_roadmap.md 섹션 0.18

- [ ] **Value generics**
  - [ ] <const N: u64> 파라미터
  - [ ] [N]T 배열 크기에 사용
  - DoD: 컴파일타임 상수 배열
  - 참조: v4_roadmap.md 섹션 0.17

#### Phase 4.1.2: 기본 Comptime (3-4개월)

- [ ] **comptime 블록**
  - [ ] comptime { ... } 문법
  - [ ] 컴파일타임 상수 평가
  - DoD: 간단한 상수 계산
  - 참조: v4_roadmap.md 섹션 1.1

- [ ] **has_method, impls 내장 함수**
  - [ ] has_method(T, "method_name")
  - [ ] impls(T, Trait)
  - [ ] comptime_assert 결합
  - DoD: Duck Typing 검증
  - 참조: v4_roadmap.md 섹션 0.20

- [ ] **assert_eq, assert_ok**
  - [ ] 테스트 전용 assertion
  - 참조: v4_roadmap.md 섹션 0.0

#### Phase 4.1.3: Explicit SIMD (2-3개월)

**철학**: 자동 벡터화(Optimization)는 v4.4+로 미루되, **명시적 SIMD(Intrinsic Wrapping)**는 v4.1에 포함.

**이유**:
- "해커의 언어" 정체성: 초기 버전부터 저수준 제어 제공
- 구현 난이도: 인트린식 매핑은 자동 벡터화보다 훨씬 쉬움
- 실용성: 성능 크리티컬한 코드(게임, 그래픽)에서 즉시 사용 가능

- [ ] **Vector 타입**
  - [ ] f32x4, f32x8 (SSE/AVX)
  - [ ] i32x4, i32x8
  - [ ] u8x16, u8x32
  - DoD: 벡터 타입 선언 및 로드/스토어
  - 참조: v4_roadmap.md 섹션 4.1

- [ ] **Intrinsics 래핑**
  - [ ] _mm_add_ps → vadd_f32x4
  - [ ] _mm_mul_ps → vmul_f32x4
  - [ ] _mm_load_ps / _mm_store_ps
  - DoD: 기본 산술 연산 (add, sub, mul, div)
  - 참조: v4_roadmap.md 섹션 4.1

- [ ] **std.simd 모듈**
  - [ ] 크로스 플랫폼 추상화 (SSE/AVX/NEON)
  - [ ] 벡터 리터럴: f32x4{1.0, 2.0, 3.0, 4.0}
  - [ ] 기본 연산자 오버로딩 (+, -, *, /)
  - DoD: 간단한 SIMD 코드 작성 가능

**v4.1 DoD**:
- [ ] 제네릭 타입 추론 작동
- [ ] Value generics로 고정 크기 배열
- [ ] comptime_assert로 타입 제약 검증
- [ ] 기본 comptime 계산 지원
- [ ] **Explicit SIMD 타입 및 인트린식 지원**
- [ ] **std.simd 기본 연산 가능**

**블로커**: v4.0 미완료

---

### v4.2 Inheritance & Traits (Optional)
**기간**: 2027 Q3-Q4 / 2028 Q1 (12-15개월)
**목표**: 다형성 지원
**상태**: [PLANNED]
**위험도**: [MEDIUM] (복잡도 높음)

**의존성**: v4.1 완료

**[주의]**: 이 기능은 선택적입니다. B 언어의 철학("해커 친화적 저수준 제어")과 충돌 가능성이 있으므로, **실제 필요성을 재검토** 후 진행하세요.

#### Phase 4.2.1: 구조체 상속 (3-4개월)

- [ ] **struct 상속**
  - [ ] struct Child : Parent 문법
  - [ ] 메모리 레이아웃: Parent 필드가 Offset 0
  - [ ] 다중 상속 지원
  - DoD: 부모 필드 접근, 캐스팅
  - 참조: v4_roadmap.md 섹션 0.0

#### Phase 4.2.2: Trait 시스템 (6-8개월)

- [ ] **trait 정의**
  - [ ] trait 키워드
  - [ ] 메서드 시그니처 선언
  - 참조: v4_roadmap.md 섹션 0.0

- [ ] **impl trait for Type**
  - [ ] 구현 강제
  - [ ] VTable 자동 생성
  - 참조: v4_roadmap.md 섹션 0.0

- [ ] **VPtr 메모리 레이아웃**
  - [ ] $vptr 필드 추가 (컴파일러 관리)
  - [ ] 리터럴 초기화 시 자동 설정
  - [ ] Tail Embedding (데이터 뒤에 배치)
  - 참조: v4_roadmap.md 섹션 0.0

- [ ] **다형성**
  - [ ] Trait 포인터로 vtable lookup
  - [ ] 캐스팅 시 주소 보정
  - DoD: 다형성 컬렉션, 의존성 주입
  - 참조: v4_roadmap.md 섹션 0.0

**v4.2 DoD**:
- [ ] struct 상속 작동
- [ ] trait 구현 및 VTable 생성
- [ ] 다형성 호출 가능
- [ ] 성능 측정 (vtable 오버헤드 < 5%)

**블로커**: v4.1 미완료

**재검토 포인트**: 
- 실제로 다형성이 필요한 use case가 있는가?
- Zig 스타일 comptime duck typing으로 충분하지 않은가?
- VTable 오버헤드가 "명시적 제어" 철학과 맞는가?

---

### v4.3 True CTFE (Optional)
**기간**: 2028 Q2-Q4 (9-12개월)
**목표**: Zig 스타일 컴파일타임 실행
**상태**: [PLANNED]
**위험도**: [HIGH] (블랙홀 위험, 컴파일러 재설계)

**의존성**: v4.1 완료, 컴파일러 아키텍처 재설계 필요

**[경고]**: 이 기능은 **블랙홀 위험이 매우 높습니다**. LLVM도 수년이 걸렸고, Zig도 10년 개발 중입니다. 실제 필요성을 신중히 검토하세요.

#### Phase 4.3.1: CTFE 엔진 (4-6개월)

- [ ] **AST Interpreter**
  - [ ] eval(Node, Env) → Value 구현
  - [ ] 산술/논리/비트 연산 지원
  - [ ] 변수 바인딩, 제어 흐름
  - 참조: v4_roadmap.md 섹션 1.2

- [ ] **Types as Values**
  - [ ] type 타입 추가
  - [ ] var T: type = u64 문법
  - [ ] @sizeof, @typeof 내장 함수
  - 참조: v4_roadmap.md 섹션 1.2

#### Phase 4.3.2: 고급 CTFE (3-4개월)

- [ ] **조건부 컴파일**
  - [ ] comptime if
  - [ ] Dead Code Elimination
  - 참조: v4_roadmap.md 섹션 1.2

- [ ] **Reflection**
  - [ ] @type_info(T)
  - [ ] @field(obj, name)
  - [ ] comptime for
  - 참조: v4_roadmap.md 섹션 1.2

#### Phase 4.3.3: 제네릭 재정의 (2-3개월)

- [ ] **제네릭을 함수로 재정의**
  - [ ] func Vec(T: type) -> type
  - [ ] Vec<u64> → Vec(u64) 변환
  - [ ] Memoization (캐싱)
  - 참조: v4_roadmap.md 섹션 1.2

**v4.3 DoD**:
- [ ] comptime 블록에서 임의의 코드 실행
- [ ] 타입을 값으로 조작
- [ ] Reflection 기반 메타프로그래밍
- [ ] 조건부 컴파일 작동
- [ ] 컴파일 속도 측정 (< 2배 느림)

**블로커**: v4.1 미완료, 컴파일러 재설계 미완료

**재검토 포인트**:
- 정말 Zig 수준의 CTFE가 필요한가?
- v4.1의 기본 comptime으로 충분하지 않은가?
- 개발 비용 vs 실용성 비교
- 대안: Rust 스타일 매크로 시스템 검토

---

### v4.4 Optimization (Optional)
**기간**: 2029+ (12-18개월)
**목표**: 성능 개선
**상태**: [PLANNED]
**위험도**: [MEDIUM] (SSA 전환 복잡)

**의존성**: v4.0 완료 (SSA는 기존 IR 위에 구축 가능)

**주의**: 최적화는 **가장 마지막**에 합니다. 언어 기능이 안정된 후에만 시작.

#### Phase 4.4.1: SSA IR 전환 (6-8개월)

- [ ] **SSA 변환**
  - [ ] SSAValue, Phi Node 정의
  - [ ] Dominance Tree 계산
  - [ ] SSA Construction
  - 참조: v4_roadmap.md 섹션 5

- [ ] **SSA Destruction**
  - [ ] 레지스터 할당 준비
  - [ ] Phi Node 제거

#### Phase 4.4.2: 최적화 패스 (6-8개월)

- [ ] **Local Optimization**
  - [ ] Constant Folding
  - [ ] Dead Code Elimination
  - [ ] Copy Propagation
  - 참조: v4_roadmap.md 섹션 6

- [ ] **Global Optimization**
  - [ ] Common Subexpression Elimination
  - [ ] Global Value Numbering
  - [ ] Sparse Conditional Constant Propagation
  - 참조: v4_roadmap.md 섹션 6

- [ ] **Loop Optimization**
  - [ ] Loop Invariant Code Motion
  - [ ] Strength Reduction
  - [ ] Loop Unrolling

**v4.4 DoD**:
- [ ] SSA IR 완성
- [ ] 최적화 패스 작동
- [ ] 성능 벤치마크 (최소 30% 향상)
- [ ] Golden test 통과 (최적화 전후 동일)

**블로커**: v4.0 미완료

---

### v4.5+ Future Features (Long-term)
**기간**: 2029+
**상태**: [IDEATION]

다음 기능들은 **아직 확정되지 않았으며**, 실제 필요성이 검증된 후에만 진행합니다:

- [ ] async/await (비동기 I/O)
  - 참조: v4_roadmap.md 섹션 3
  - 위험도: [HIGH] (런타임 복잡도)
  
- [ ] SIMD 자동 벡터화 (Automatic Vectorization)
  - **주의**: Explicit SIMD는 v4.1에서 구현됨
  - 이 항목은 컴파일러가 루프를 자동으로 벡터화하는 기능
  - 참조: v4_roadmap.md 섹션 4.2
  - 위험도: [HIGH] (복잡한 분석 필요)
  
- [ ] GPU 컴퓨트
  - 참조: v4_roadmap.md 섹션 4
  - 위험도: [HIGH] (전용 IR 필요)
  
- [ ] 인라인 어셈블리 개선
  - 참조: v4_roadmap.md 섹션 0.0
  
- [ ] 표준 라이브러리 확장
  - 참조: v4_roadmap.md 섹션 2

---

## 현실적 타임라인 요약

```
2026 Q1   : v3.5 std 라이브러리       [6-8주] [IN PROGRESS]
2026 Q2   : v3.9 컴파일러 Self-Host   [8-10주] [PLANNED]
2026 Q3-Q4: v4.0 Foundation           [6-9개월] [PLANNED]
2027 Q1-Q2: v4.1 Generics & SIMD      [6-9개월] [PLANNED]
2027 Q3-Q4: v4.2 Traits (Optional)    [12-15개월] [PLANNED]
2028 Q2-Q4: v4.3 True CTFE (Optional) [9-12개월] [IDEATION]
2029+:      v4.4 Optimization         [12-18개월] [IDEATION]
```

**총 예상 기간**: 3-4년 (v3 Self-Hosting부터 v4.3까지)

---

## 위험 관리

### 블랙홀 위험 기능
- [HIGH] **True CTFE** (v4.3): 컴파일러 재설계 필요, Zig도 10년 개발 중
- [HIGH] **async/await**: 런타임 복잡도 폭증, 스케줄러 필요
- [HIGH] **GPU Compute**: 전용 IR, 드라이버 통합 필요

### 중간 위험 기능
- [MEDIUM] **Trait 시스템** (v4.2): 복잡도 높음, VTable 오버헤드
- [MEDIUM] **SSA 최적화** (v4.4): 구현 복잡, 디버깅 어려움
- [MEDIUM] **SIMD 자동 벡터화** (v4.5+): 루프 분석 복잡, 플랫폼 의존성

### 안전한 기능
- [LOW] **v4.0 Core**: 문법 확장, 기존 패턴 반복
- [LOW] **v4.1 Generics**: 기존 제네릭 개선
- [LOW] **v4.1 Explicit SIMD**: 인트린식 래핑만, 구현 단순
- [LOW] **표준 라이브러리**: 독립적 개발 가능

---

## 현재 우선순위

### Phase 0.5 (즉시 시작): v3.5 std 라이브러리
- **목표**: std만 v3로 재작성, v2 컴파일러로 검증
- **기간**: 6-8주
- **블로커**: 없음
- **전략**: 라이브러리 먼저, 컴파일러 나중에 (디버깅 용이)

### Phase 0.9 (2026 Q2): v3.9 Self-Hosting
- **목표**: 컴파일러를 v3로 재작성
- **기간**: 8-10주
- **블로커**: v3.5 완료

### Phase 1 (2026 하반기): v4.0 Core
- **목표**: match, enum, union, new/delete, constructor/destructor
- **기간**: 6-9개월
- **블로커**: v3 Self-Hosting 완료

### Phase 2 (2027 상반기): v4.1 Generics & SIMD
- **목표**: 타입 추론, Value generics, 기본 comptime, **Explicit SIMD**
- **기간**: 6-9개월
- **블로커**: v4.0 완료
- **신규**: SIMD를 v4.5에서 v4.1로 앞당김 (해커 정체성)

### Phase 3+ (2027 하반기~): Optional Features
- **v4.2 Traits**: 필요성 재검토 후 진행
- **v4.3 CTFE**: 위험도 높음, 신중히 접근
- **v4.4 Optimization**: 언어 안정 후 진행

---

## 진행 규칙

### 버전 릴리스 조건
각 버전은 다음을 만족해야 릴리스:
- [ ] 모든 DoD 항목 완료
- [ ] Golden test 통과
- [ ] Self-compilation 성공
- [ ] 문서 업데이트
- [ ] 1주일 안정성 테스트

### 실패 시 대응
- **블랙홀 징후 발견 시**: 즉시 중단, 스코프 축소
- **3개월 이상 진전 없음**: 해당 기능 v4.x+1로 연기
- **복잡도 폭증**: 기능 재설계 또는 포기

### 문서 동기화
- 각 기능 구현 시 v4_roadmap.md 업데이트
- 버전 릴리스 시 v4_todo.md 체크박스 업데이트
- devlog 작성 (매 주요 구현마다)

---

## 참조 문서

- **v4_roadmap.md**: 전체 기능 명세 (3622줄)
- **v3 문서**: v3 기능 참조
- **common.instructions.md**: 개발 워크플로우
- **devlog-YYYY-MM-DD.md**: 개발 일지

---

## 다음 액션

1. [ ] v3 Self-Hosting 시작
   - std 라이브러리부터 재작성
   - 주간 진행 상황 체크

2. [ ] v4.0 상세 설계
   - match 문법 확정
   - enum layout 설계
   - constructor 의미론 확정

3. [ ] 위험 기능 재검토
   - Trait 정말 필요한가?
   - True CTFE vs 기본 comptime
   - 대안 기술 조사

**현재 포커스**: **v3 Self-Hosting**
