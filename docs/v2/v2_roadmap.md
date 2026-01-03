# v2 Roadmap

이 문서는 v1(현재 구현) 위에서 **v2로 확장**하기 위한 작업 로드맵입니다.

원칙:
- v2는 “기능 추가”보다 **셀프호스팅에 필요한 언어/런타임 기반**을 먼저 확보합니다.
- 각 단계는 가능하면 **스모크 테스트(Px)** 로 검증합니다.
- v1에서 이미 안정화된 항목(예: 재귀/ptr/addr)은 **회귀 테스트**로 계속 유지합니다.

중요:
- v2는 기본적으로 **v1 위에 쌓는 버전**입니다.
  - 즉, v1에서 이미 구현된 기능(렉서/표현식/조건/문장/함수호출/asm/ptr 등)을 v2에서 “다시 구현”하는 게 목표가 아닙니다.
  - 내부 구조를 갈아엎는 리팩터링을 하더라도, 사용자 관점의 동작은 **회귀 테스트로 계속 보장**합니다.
- v2에서 “새로 해야 하는 일”은 보통 아래 두 종류입니다.
  1) v1에 없던 새 문법/의미 추가 (예: `var`, 블록 스코프, struct)
  2) v1에 있던 기능을 더 일반화/정교화 (예: 고정 1024 프레임 → 가변 프레임)

---

## **ABI (v2 기준으로 재정리)**

### **스택 프레임(가변 크기) + 16바이트 정렬**

- [ ] 함수별 `locals_frame_size` 계산
  - 로컬 슬롯/배열/임시 spill 슬롯까지 포함
  - 16바이트 정렬: `aligned = (size + 15) & ~15`
- [ ] Prologue: `push rbp; mov rbp, rsp; sub rsp, aligned`
- [ ] Epilogue: `mov rsp, rbp; pop rbp; ret`
- [ ] call-site 정렬 규칙 정리/고정(필요하면 call 전 임시 정렬)

### **인자 전달(>6개 확장 옵션)**

- [ ] 0~5: rdi,rsi,rdx,rcx,r8,r9
- [ ] 6개 초과 인자: 스택으로 전달(최소 구현: caller가 push, callee가 [rbp+..]로 접근)
- [ ] v1 호환: 6개 이하는 기존처럼 레지스터로 처리

### **레지스터 정책(명문화)**

- [ ] caller-saved / callee-saved 규칙을 문서로 확정
- [ ] 코드젠에서 “helper call이 레지스터를 clobber 할 수 있음”을 기본 전제로 작성

---

## **P0: 회귀(Regression) 필수 스모크**

v2 작업 중에도 반드시 깨지면 안 되는 최소 기능.

- [ ] P11: 재귀 fib (스택 프레임/지역 격리)
  - 입력: `fib(10)`
  - 기대: exit 55
- [ ] P12: addr/ptr64 swap (포인터/메모리)
  - 기대: exit 20

권장(추가 회귀):
- [ ] v1 기존 스모크(P0~P10)를 v2에서도 유지(최소 1회 전체 실행)
  - syscall/IO/lex/expr/cond/stmt/e2e/hex-char-asm 등

---

## **P0.5: 컴파일러용 자료구조(지금 당장 v1로 구현)**

v2에서 스코프/심볼테이블/타입정보 등을 구현하려면 “map / interner / arena” 류의 자료구조가 필요합니다.
이 섹션은 **언어 기능(v2 문법)** 이 아니라, 컴파일러 구현을 돕기 위한 **런타임/코어 유틸**을 먼저 확보하는 단계입니다.

- [ ] `HashMap` (키: Slice/문자열, 값: u64 또는 ptr)
  - 목표: `put/get/has` 최소 API
  - 구현 : 엔트리 배열(Vec 기반)
  - 용도: symbol table, struct field map, import module cache

- [ ] `StringInterner` (중복 문자열을 1회만 저장)
  - Depends on: HashMap
  - 목표: `intern(ptr,len) -> id` / `id -> (ptr,len)`
  - 용도: 토큰 텍스트/식별자 비교 비용 절감, 심볼테이블 키 안정화

- [ ] `Arena` bump allocator (노드/타입/AST용)
  - 목표: 다수의 작은 할당을 빠르게 처리, 컴파일 단위 종료 시 한 번에 해제(또는 누수 허용)
  - 용도: AST 노드, 타입 노드, import 그래프 노드

- [ ] `StringBuilder` / `Buf` (동적 바이트 버퍼)
  - Depends on: Vec
  - 목표: 라벨 mangling(`M_foo_bar__baz`) 같은 문자열 합성, 에러 메시지 구성

---

## **P1: 선언/스코프(진짜 로컬) 도입**

목표: “변수는 선언되어야만 사용 가능” + 블록 스코프(그림자 변수) 기반을 만든다.

- [ ] `var x;` 로컬 선언
- [ ] `var x = expr;` 선언+초기화
- [ ] 블록 `{ ... }` 를 독립 stmt로 허용
- [ ] 블록 스코프
  - [ ] symbol table에 scope push/pop
  - [ ] 같은 이름 shadowing 허용 여부 결정(권장: 허용)
- [ ] 미선언 변수 사용 시 컴파일 에러

추가 제약(중요): **전역 초기화(Global Init) 정책**
- [ ] 전역 변수(모듈 스코프 `global var` 등)를 도입한다면, 초기화는 **컴파일 타임 상수**로만 허용
  - 허용 예: 정수/문자/문자열 리터럴, `const`/`enum` 값, 간단한 상수식(정책 범위 내)
  - 금지 예: `map_new()` 같은 **함수 호출로 전역을 초기화**
- [ ] 복잡한 초기화(Heap 할당/함수 호출 필요)는 `main` 초입 또는 별도의 `init()` 함수에서 수행하도록 유도/권장
  - 이유: 코드젠이 “전역은 정적 데이터, 함수 호출은 런타임”이라는 경계를 명확히 가져야 함

스모크:
- [ ] P13: 블록 스코프 + shadowing

---

## **P1.5: 상수(const) + enum (컴파일 타임 값)**

목표: “이름 있는 정수 상수”를 언어 레벨로 도입해서, 스위치/에러코드/토큰/필드 오프셋/enum 등에서 재사용한다.

- [ ] `const` 선언
  - 최소 문법(MVP): `const NAME = expr;`
  - 위치: top-level 우선(모듈 스코프). 필요하면 함수 내부 const는 차후.
  - `expr`는 컴파일 타임으로 평가 가능한 부분집합부터 시작(정수 리터럴 + 산술/비트 연산 등)

- [ ] `enum` 선언
  - 최소 문법(MVP):
    - `enum Name { A, B, C }` (0부터 자동 증가)
    - `enum Name { A=1, B=2 }` (명시값 지원)
  - 심볼 접근: `Name.A` 처럼 네임스페이스를 강제(전역 오염/충돌 방지)
  - 표현식에서 값은 정수 상수로 취급

스모크:
- [ ] P19: `const` + `enum` + `Name.A` 사용

---

## **P1.6: 타입 힌트/캐스팅(초기 타입 시스템의 발판)**

목표: “아직은 대부분 u64이지만”, 포인터/바이트/구조체 같은 값의 의도를 소스에 표현할 수 있게 한다.

- [ ] 로컬/인자 타입 힌트(선언 기반)
  - 예시: `var x: u64 = 1;`, `func f(p: ptr) { ... }`
  - 힌트는 초기엔 코드젠에 큰 영향이 없어도 됨(검증/에러메시지 개선부터)

### 선언 문법: C 스타일이 필요한가?

사용자가 원하는 형태가 `int a = read_file(...);` 같은 **선언+초기화** 패턴이라면, v2에서 아래 둘 중 하나(또는 둘 다)를 선택해야 한다.

- 옵션 A(권장/MVP): `var a: i64 = expr;` 또는 `var a: u64 = expr;`
  - 장점: 파서가 단순하고, v1과 달리 “선언이 필요한 언어”로 바꾸는 전환점이 명확하다.

또한 `int`라는 이름을 넣을지(= `i64`의 alias로 취급)도 정책으로 결정해야 한다.

### (추가) `read_file()` 같은 API의 반환 타입 표현

현재 v1 런타임은 `read_file(path)`가 `(rax=ptr, rdx=len)`처럼 “2개 레지스터 반환” 형태다.
v2에서는 소스 레벨에서 이걸 어떻게 표현할지 정해야 한다.

- 옵션 A(권장): `read_file(path) -> Slice`
  - `Slice { ptr; len; }`를 코어 빌트인 타입(또는 표준 라이브러리 struct)로 취급
  - 사용 예: `var src: Slice = read_file(path);`

- [ ] 명시 캐스팅
  - 옵션 B: `cast(u8, expr)`
  - 최소 목표: 크기 변경(u8/u64)과 부호/0-확장 정책을 명문화

스모크:
- [ ] P20: 타입 힌트 + 캐스팅으로 값이 기대대로 나오는지
  -선언+초기화에 함수 호출을 포함: `var s: Slice = read_file("...");`

---

## **P1.7: switch-case**

목표: 다중 분기(특히 enum/토큰 분기)를 if-else 체인보다 읽기 좋게.

- [ ] 최소 문법(MVP):
  - `switch (expr) { case INT: stmt* break; ... default: stmt* }`
  - `case`는 정수/enum 상수만 허용(초기)
  - fallthrough는 초기엔 금지(명시 `fallthrough;` 도입은 선택)

- [ ] 코드젠
  - MVP: if-else 체인으로 lowering
  - 이후 최적화: 연속 case면 jump table

스모크:
- [ ] P21: switch-case로 분기 후 기대 exit code

---

## **P1.8: for / foreach (루프 문법 확장)**

목표: v1의 `while`은 유지하면서, 자주 쓰는 루프 패턴을 더 간결하게 쓸 수 있게 한다.

- [ ] `for` (C-style)
  - 최소 문법(MVP): `for (init; cond; post) stmt`
    - `init`/`post`는 (선택) 대입문/함수호출문/빈 문장 허용
    - `cond`가 비어 있으면 `true`로 취급(무한 루프)
  - lowering: `init; while (cond) { stmt; post; }`

- [ ] `foreach` (컨테이너 순회)
  - 최소 문법(MVP): `foreach (x in expr) stmt`
  - 초기 대상:
    - `Slice` (권장: `ptr/len` 기반)
    - 로컬 배열 `var a[N]` (가능하면)
  - 현재(v2 MVP): `Slice*`를 **byte 단위로 순회**하는 형태로 시작하고, 요소 폭/타입 기반 순회는 v3에서 보완
  - lowering(권장): 인덱스 기반 `while`로 변환
    - `var i = 0; while (i < len) { var x = expr[i]; ...; i=i+1; }`

스모크:
- [ ] P22: `for`로 합계 계산 / `foreach`로 동일 결과 확인

---

## **P1.9: asm 블록 문법 개선(raw multiline)**

목표: v1의 현재 형태

```b
asm {
  "xor rax, rax\n";
}
```

를 v2에서는 아래처럼 **문자열/세미콜론 없이** 읽기 좋은 형태로 쓸 수 있게 한다.

```b
asm {
  xor rax, rax
  mov rax, 5
}
```

- [ ] 파싱: `asm { ... }` 내부를 “raw 텍스트 블록”으로 취급
  - 최소 MVP: 줄 단위로 읽어서 `\n`을 자동으로 붙여 emitter로 전달
  - `{`/`}` 중첩은 금지(내부에서 `}`를 만나면 블록 종료로 간주)
  - 빈 줄/공백 보존 정책 확정(권장: 라인 트림 없이 그대로 + 끝에 `\n`)

스모크:
- [ ] P24: raw asm 블록 2~3줄 emit 후 실행 결과 검증

---

## **P2: 배열 로컬 + 인덱싱(기초)**

목표: 문자열/구조체 이전에 “연속 메모리”를 언어 수준에서 다룬다.

- [ ] `var a[16];` 로컬 배열 선언
- [ ] `a[i]` 인덱싱(최소: u64 기준)
  - [ ] load: `a[i]` -> 값
  - [ ] store: `a[i] = expr;`
- [ ] 인덱스 범위 체크는 MVP에서 생략 가능(문서로 명시)

스모크:
- [ ] P14: 배열에 값 채우고 합산

---

## **P3: 문자열 리터럴을 값으로 사용**

목표: 컴파일러 자체(셀프호스팅)에서 에러 메시지/키워드/파일명 등을 다루기 쉽게.

- [ ] 문자열 리터럴 `"..."` 을 표현식 값으로 허용
  - [ ] `.rodata`에 바이트 배열로 emit
  - [ ] 표현식 결과는 “C-string ptr” 또는 “(ptr,len) slice” 중 하나를 선택
- [ ] 최소 escape 지원 정책 확정(현재 렉서 정책과 일치시키기)

스모크:
- [ ] P15: `sys_write(1, "OK\n", 3)` 형태(또는 slice 기반)

---

## **P4: struct/필드/포인터 멤버 접근**

목표: Vec/Slice 같은 코어 자료구조를 언어 레벨로 표현.

- [ ] `struct Name { field1; field2; ... }`
- [ ] 재귀 구조체(Recursive Struct) 명세 확정
  - [ ] **불완전 타입(incomplete type)에 대한 포인터는 허용**: `next: *Node` 같은 패턴은 OK
  - [ ] 값으로 포함하는 재귀는 금지: `next: Node`는 크기 계산 불가이므로 에러
  - [ ] 전방 선언(Forward Declaration) 문법을 도입할지 결정
    - 옵션 B(암시적): `struct Node { ... *Node ... }`에서 포인터에 한해 자기 자신 타입 참조를 허용
  - 목표: AST/LinkedList 같은 핵심 자료구조를 언어로 표현 가능해야 함
- [ ] `offsetof(Name, field)` 또는 컴파일 타임 상수 오프셋 제공
- [ ] `x.field` (.)
- [ ] `p->field` (->)
- [ ] `sizeof(Name)` 또는 고정 크기 상수 제공

스모크:
- [ ] P16: struct 인스턴스 만들고 필드 읽기/쓰기

---

## **P5: ptr/addr 문법 정리**

v1은 `addr[x]`, `ptr64[p]` 기반. v2에서 선택지:

- [ ] 확장안: C 스타일 단항 연산자
  - [ ] `&x` (address-of)
  - [ ] `*p` (deref load/store, lvalue 지원)

스모크:
- [ ] P17: `&`/`*` 도입 시 교차 검증

---

## **P6: 함수/호출 확장(>6 args) + 호출 규약 고정**

- [ ] 6개 초과 인자 지원
- [ ] 재귀 + 다인자 조합 스모크

---

## **P7: 모듈/다중 파일**

- [ ] **Python 스타일 `import`** (컴파일 타임 모듈 로딩)
  - 목표: “텍스트 include”가 아니라, **모듈 이름 → 파일/패키지**로 해석하고 의존성 그래프를 만든다.
  - 최소 문법(MVP):
    - `import foo.bar;` (점으로 구분된 모듈 경로)
  - 해석/검색 규칙(권장):
    - `foo.bar`는 아래 순서로 resolve
      1) `<module_root>/foo/bar.b`
      2) `<module_root>/foo/bar/__init__.b` (패키지)
    - `module_root`는 (a) 엔트리 파일 디렉토리, (b) `-I`/`--module-root` 옵션 경로들 순으로 검색
  - 실행/캐시 규칙(컴파일 타임):
    - 같은 resolved path는 **한 번만 로드/파싱**(Python의 module cache처럼 dedupe)
    - 순환 import는 에러(사이클 경로를 함께 출력)
  - 이름 충돌 방지(모던 import의 핵심):
    - 모듈은 자체 네임스페이스를 가진다.
    - 다른 모듈의 심볼 접근은 `foo.bar.baz(...)` 같은 **qualified name**(dot)로만 허용(= 암시적 전역 merge 금지)
    - 코드젠은 내부적으로 라벨을 `M_foo_bar__baz` 같이 **모듈 prefix**로 mangling

추가 명세(중요): **점(.) 문법 충돌(모듈 경로 vs 필드 접근) 해결**
- [ ] `a.b`는 파서 단계에서 단일 의미로 확정하지 않고, AST에 “dotted path(식별자 경로)” 형태로 보존 가능
- [ ] 이후 Semantic Check 단계에서 심볼 테이블을 보고 해석을 확정
  - `a`가 모듈(네임스페이스)이면: `a.b`는 모듈/qualified 심볼 접근
  - `a`가 값(변수/표현식)이라면: `a.b`는 필드 접근
- [ ] 모듈 접근은 `import`로 로드된 모듈만 유효(미존재 모듈은 에러)
- [ ] 필드 접근은 struct 타입/필드 정의를 기반으로 검증(미존재 필드면 에러)

추가 명세(중요): **타입 정보의 수출(Export) / import 시 레이아웃 확보**

현재 스펙이 “심볼(함수 라벨)”에만 집중하면, 아래 같은 케이스에서 코드젠이 멈춘다.

- `mod_a.b`: `struct Point { x; y; }` 정의
- `mod_b.b`: `import mod_a; var p: mod_a.Point;` 그리고 `p.x = 1;` 같은 필드 접근

왜냐하면 `mod_b`는 `Point`의 `sizeof/align/offsetof(x/y)`를 알아야 `.field`/`->field`를 emit할 수 있기 때문이다.

따라서 v2의 import는 “함수 라벨 링크”가 아니라, 최소한 아래 타입 정보를 함께 가져와야 한다.

- [ ] 모듈 export 대상 정의
  - export 되는 것: `struct/enum/const/func`(정책 범위 내)
  - import 하는 쪽은 `mod_a.Point`처럼 **qualified type name**으로 접근

- [ ] 타입/레이아웃 정보 인터페이스
  - 최소 요구: `struct`의 field 목록, field order, `offsetof`, `sizeof`, `align`
  - 초기 단순화: 모든 필드는 기본 `u64`로 시작(또는 명시 타입만 허용)
  - 레이아웃 규칙(명문화): 선언 순서 유지 + 정렬 규칙(예: 8바이트 정렬부터)

- [ ] 구현 방식 선택(둘 중 하나)
  - 옵션 : import 시 해당 모듈을 파싱/세맨틱까지 수행하고, 타입 테이블을 공유(캐시)

- [ ] 불완전 타입(incomplete type) 정책(모듈 경계 포함)
  - 포인터로만 쓰는 경우(`*T`)는 레이아웃이 없어도 허용 가능
  - by-value(`T`)는 레이아웃이 반드시 필요(= import로 타입 정의가 로드되어야 함)

- [ ] 드라이버: import 그래프 구축 → 토폴로지 순서로 파싱/코드젠
- [ ] 중복 모듈/중복 심볼 에러 정책
  - 같은 모듈을 여러 번 import: OK(캐시로 1회 처리)
  - 같은 모듈 내 중복 정의: 에러
  - 서로 다른 모듈의 같은 이름: OK(qualified로 접근)

스모크:
- [ ] P18: 파일 2개로 나눠 컴파일 성공
- [ ] P23: 모듈 A의 struct를 모듈 B에서 by-value로 선언하고 필드 read/write

---

## **P8: 셀프호스팅 단계**

셀프호스팅을 “가능하게” 만들기 위한 우선순위 높은 누락 요소들.

### **P8.x (필수): Top-level `var` (전역 변수)**

- [ ] 전역 변수 선언 지원
  - 목표: 컴파일러 구현에서 `StringInterner`, `ErrorCount`, 모듈 캐시 같은 전역 상태를 함수 인자로 들고 다니지 않게
  - 최소 정책(권장): 전역 초기화는 **컴파일 타임 상수만 허용**
    - 허용 예: `var g_version: u64 = 1;`
    - 허용 예: `var g_err: u64;` (0 초기화)
    - 금지 예(초기): `var g = heap_alloc(16);` 같은 “함수 호출로 초기화”

- [ ] 문법(제안/MVP) 
  - [ ] `.bss` 스타일: `var g_name: u64;`
  - [ ] `.data` 스타일: `var g_name: u64 = CONST_EXPR;`
  - [ ] 타입 힌트는 로컬 `var`과 동일하게 재사용

### **P8.x (필수): Non-qword 구조체 필드 접근(Load/Store)**

- [ ] `struct` 필드가 `u8/u16/u32/u64`일 때 올바른 크기로 접근
  - load: `movzx`/`mov` 등을 사용해 올바른 확장 규칙을 적용
  - store: `mov byte/word/dword/qword [...]`로 저장
- [ ] `.field` / `->field` 모두 적용
- [ ] `offsetof/sizeof`도 필드 크기에 맞게 동작해야 함

### **P8.x (강력 권장): Aggregate 초기화(구조체/배열 리터럴)**

- [x] by-value struct 로컬 초기화 허용(선언 전용 brace-init)
  - 예: `var t: Token = { 1, 10, "abc" };`
  - 구현 범위(MVP): `= expr`는 여전히 금지, `= { ... }`만 허용(= store 시퀀스로 desugar)
  - 스모크: P27
- [ ] 배열 초기화(선택)
  - 예: `var a[4] = {1,2,3,4};` 또는 최소 기능으로는 struct만 먼저
- [ ] 리터럴의 의미는 “필드/원소 순서대로 대입”으로 시작(명시 필드명 초기화는 이후)

### **P8.x (권장): Typed Pointer Arithmetic 명세/구현**

- [x] `var p: *T; p = p + 1;`의 의미를 확정
  - 채택: 옵션 B(단순) — 항상 바이트 단위 이동(typed scaling 없음)
  - 권장 스타일: `p = p + sizeof(T);` 처럼 명시적으로 작성

### **P8.x (편의): `sizeof(Type)`를 상수식에서 사용**

- [ ] `const N = sizeof(Node) * 10;` 같은 패턴을 허용
  - 상수식 평가기(const-expr)에 `sizeof/offsetof`를 포함시키는 방향

### **P8.x (편의): 문자열/슬라이스 인덱싱의 폭 명확화**

- [ ] `"str"[i]` / `slice[i]`가 `u8`을 load 해서 `u64`로 0-확장하는지(또는 다른 규칙) 명문화
  - v2 MVP는 이미 `foreach`가 바이트 단위 순회를 전제로 하므로, 인덱싱도 일관성을 맞추는 편이 단순

- [ ] v2 컴파일러를 v1로 빌드
- [ ] v2 컴파일러로 v2 컴파일러를 다시 빌드(self-host)
- [ ] 결과 비교(바이너리 동일성 또는 출력 asm 동일성 중 하나 선택)

---

## **비고(선택 과제)**

- [ ] 에러 리포팅 강화(토큰 위치, 스택 트레이스 흉내)
- [ ] 최적화(상수 폴딩, dead code 등) — 셀프호스팅 이후
- [ ] 안전성(배열 bounds check 등) — 언어 철학 결정 후
