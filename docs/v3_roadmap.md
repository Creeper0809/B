# v3 Roadmap (Draft)

이 문서는 v2로 v3 컴파일러를 작성하기 위해, v3에서 목표로 하는 **현대적인 문법/기능**과
그걸 가능하게 하는 **컴파일러 구조(AST → IR → 코드젠)** 전환 계획을 한 곳에 모아 둔 문서입니다.

원칙:
- v3 컴파일러는 **v2로 구현**한다(= v2가 컴파일할 수 있는 범위 안에서 점진적으로 만든다).
- v3는 v2의 MVP를 깨지지 않게 유지하면서, “현대적 언어에서 기대하는 표현력”을 단계적으로 확장한다.
- v3의 새 기능은 가능하면 “문법만 추가”가 아니라, **AST/타입/IR 단계까지 의미가 분명한 형태**로 설계한다.

문법 스타일(일관성 규칙, v3에서 강제 권장):
- 키워드 어순: `[가시성] [속성/계약] [카테고리] [이름]`
    - 가시성: `public`, `private`
    - 속성/계약: `secret`, `nospill`, `packed`, `final`, `@[...]`
    - 카테고리: `struct`, `enum`, `type`, `var`, `func`
    - 예: `public secret var key: [32]u8;`, `public packed struct Packet { ... }`
    - 정책(권장/MVP): 어순 위반은 컴파일 에러(문서/코드 스타일을 강제)

---

## 0) v3의 큰 목표(요약)

- [ ] **AST 기반 프론트엔드**: 토큰 → 파싱 → AST 생성(오류 복구 포함)
- [ ] **IR 기반 미들엔드**: AST → IR lowering, 간단한 최적화/검증 패스
- [ ] **타입 시스템 확장**: 기본 타입 + 사용자 정의 타입 + 제네릭 + (선택) trait/constraint
- [ ] **표준 라이브러리 기반**: String/Slice/Vec/HashMap 등(최소 API부터)

---

## 0.5) v2 기본 문법/동작 베이스라인(전부 끌고오기)

v3 컴파일러를 v2로 구현한다고 해서 “문법이 자동으로 생기지는” 않지만,
반대로 v2에서 이미 되는 기본 문법/동작은 v3가 **기본 베이스라인으로 상속**하는 것으로 한다.

- 원칙
    - [ ] 기본값: v2에서 허용되는 형태는 v3에서도 허용
    - [ ] 단, v3 로드맵의 다른 항목(예: 토큰화/타입 시스템/AST→IR 전환)이 **명시적으로 의미를 바꾸면 그쪽이 우선**
    - [ ] 이 섹션은 `docs/v2_syntax.md`의 “현재 구현 기준”을 v3로 가져온 체크리스트

- [ ] 렉시컬(토큰) 베이스
    - [ ] 주석: `//` 한 줄 주석
    - [ ] IDENT 규칙: `[_A-Za-z][_A-Za-z0-9]*`
    - [ ] 리터럴: INT(10/16진), STR("..."), CHAR('a' 등 → INT로 lowering)
    - [ ] 연산자/구분자
        - [ ] 단일: `(){}[];,. : + - * / % = < > & | ^ ~ !`
        - [ ] 다문자: `&& || == != <= >= << >> ->`

- [ ] Top-level 베이스
    - [ ] 선언 나열: `import`, `var`, `const`, `enum`, `struct`, `func`
    - [ ] import 동작: 드라이버 의존성 스캔은 “파일 선두 연속 import”만 대상으로 함(그 외 위치의 import는 문법 소비만 될 수 있음)
    - [ ] `const NAME = <const-expr>;` (전역 u64 정수 상수)
    - [ ] `enum Name { A, B = 10, C, } ;` (trailing comma 허용, 닫는 `}` 뒤 `;`는 옵션)
    - [ ] `struct Name { field; field: Type; field: *Type; } ;` (닫는 `}` 뒤 `;` 옵션)
    - [ ] 전역 `var` 초기값은 const-expr만 허용
    - [ ] 식별자 해석 fallback: 로컬/alias/const가 아니면 전역 슬롯으로 fallback(정책 유지)

- [ ] 함수/블록/스코프 베이스
    - [ ] 함수 형태: `func name(arg0, arg1, ...) { stmt* }` (인자 최대 6개)
    - [ ] 독립 블록 문장: `{ stmt* }` 지원 + 블록은 렉시컬 스코프를 가짐

- [ ] 문장(Statements) 베이스
    - [ ] `var` 로컬 선언
        - [ ] `var x;` / `var x = expr;`
        - [ ] 배열 선언 + 선언 시 초기화(init) 허용
            - [ ] v2 호환(u64 배열): `var arr[N];` / `var arr[N] = { expr0, expr1, ... };`
            - [ ] 타입드 배열: `var arr: [N]T;` / `var arr: [N]T = { expr0, expr1, ... };`
            - [ ] 초기화 규칙(MVP): 원소 개수는 N과 정확히 일치해야 함(부족/초과는 에러)
        - [ ] by-value struct 로컬: `var s: Pair = { expr0, expr1, ... };` (선언에서만 brace-init, trailing comma는 v2에선 미지원)
        - [ ] 레지스터 별칭: `alias <reg>: <name> [= expr];`
            - [ ] v3 MVP(권장): x86-64 GPR 전체를 별칭 대상으로 확장
                - [ ] 허용 reg: `rax rbx rcx rdx rsi rdi r8 r9 r10 r11 r12 r13 r14 r15`
                - [ ] `rsp`는 금지(스택 포인터 파손 위험)
                - [ ] `rbp`는 제한적으로 허용(확정): 디버그/프레임 포인터가 필요한 모드에서는 사용 예약이므로 컴파일 에러, 그 외에는 경고와 함께 허용
                - [ ] 초기 정책: 레지스터 별칭은 64-bit 이름만 허용(하위 레지스터 `eax/al` 등은 후순위)
            - [ ] (후순위) SIMD/FP 레지스터(`xmm0..xmm15`) 별칭 지원은 ABI/타입 규칙 확정 후 도입
    - [ ] 제어 흐름: `if/else`, `while`, `for`, `foreach`, `switch`, `break/continue`, `return`
        - [ ] `break n` / `continue n` 형태(기본 1단계)
        - [ ] `continue`는 `switch` 내부에서는 금지(정책 유지)
        - [ ] `switch`는 no-fallthrough(각 case는 암묵적으로 switch 끝으로 점프)
    - [ ] 대입문: `x = expr;` (v3에서는 1.2.1에서 복합 대입/증감을 추가)
    - [ ] 표현식 문장: `expr;`
    - [ ] 인라인 asm(v2 raw): `asm { ... }` (v3에서는 1.11에서 개선)

- [ ] 메모리/필드 store 베이스
    - [ ] `ptr8[addr] = expr;` / `ptr64[addr] = expr;`
    - [ ] `*addr = expr;` (v2에 이미 구현됨: 포인터를 통한 store)
    - [ ] `arr[idx] = expr;`
    - [ ] `base.field = expr;` / `base->field = expr;` (typed local 기반, 1/2/4/8B field 지원)

- [ ] 조건식(Conditions) 베이스
    - [ ] `||`, `&&`, `!`, 괄호, 비교(`== != < > <= >=`), truthy(`expr` 단독)
    - [ ] 중요: v2에서는 `&&`/`||`가 **조건식 전용**이었음 → v3는 1.2에서 expr로 승격 예정

- [ ] 표현식(Expressions) 베이스
    - [ ] 우선순위: unary(+ - ~ ! & *), `* / %`, `+ -`, `<< >>`, `< > <= >=`, `== !=`, `& ^ |`
    - [ ] factor: INT/STR/IDENT/(expr)
    - [ ] 호출: `IDENT(args...)` (최대 6)
    - [ ] load: `IDENT[expr]`, `ptr8[expr]`, `ptr64[expr]`, `IDENT.field`, `IDENT->field`, `*expr`
    - [ ] 주소/역참조: v2에 이미 구현됨
        - [ ] `&ident`는 ident만 허용(일반 lvalue 주소는 후순위)
        - [ ] `*expr`는 qword deref load
    - [ ] builtin: `cast(Type, expr)`, `sizeof([*]Type)`, `offsetof(Type, field)`

- [ ] v2의 핵심 제약(베이스라인으로 명시)
    - [ ] 포인터 산술은 typed scaling이 아니라 바이트 단위(= `p + 1`은 `sizeof(T)`가 아니라 +1 byte)
    - [ ] `Struct { ... }` 같은 struct 리터럴 expression은 v2에 없음(→ v3 1.3에서 추가)

---

## 0.6) 구현 순서(Phase) 재배치: “다이어트” 플랜

로드맵의 기능을 한 번에 모두 달성하려고 하면, v2 기반 부트스트랩 제약에서 병목이 크게 온다.
따라서 v3는 아래 Phase 순서로 “골격 → 타입 → 구조 → 킬러 기능 → 편의 기능” 순으로 진행한다.

- Phase 1 (골격)
    - [ ] 키워드 토큰화/AST 파서/오류 복구
    - [ ] AST → IR → x86-64 코드젠 파이프라인
    - [ ] 최소 타입: `u64` 중심으로 시작(타입 체크는 최소)

- Phase 2 (타입)
    - [ ] 정수 타입 분화(`u8`~`u64`, `i8`~`i64`) + `cast`
    - [ ] 포인터 `*T`, 슬라이스, 배열, 문자열(최소)
    - [ ] 산술/승격 규칙(엄격 타입 정책) 확정

- Phase 3 (구조)
    - [ ] `struct/enum`의 타입 체크/레이아웃
    - [ ] `foreach`의 폭/타입 인식 + 컨테이너 기본

- Phase 4 (보안/해커: 정체성)
    - [ ] `secret`, `wipe`, `nospill`, `@reg`(extern 전용)
    - [ ] `verify`/계약(가능하면 이 시점부터 홍보 가능)

- Phase 5 (편의/확장)
    - [ ] 제네릭(사용자 정의 포함)
    - [ ] (v4로 이동) `comptime`의 함수 호출/테이블 생성 등 고급 기능

---

## 1) 문법/표면 언어(Modern Surface Syntax)

### 1.1) 키워드/토큰 정리

v2는 일부 키워드를 IDENT 텍스트 비교로 처리합니다. v3에서는 파서 복잡도를 줄이기 위해 키워드를 토큰으로 승격합니다.

- [ ] 키워드 토큰화: `import`, `enum`, `struct`, `switch`, `for`, `foreach` 등
- [ ] 예약어 정책 명문화(식별자로 사용 가능한지/불가능한지)

### 1.1.1) 와일드카드/버리기 식별자: `_` (Discard Identifier)

필요 없는 값을 "의도적으로 무시"한다는 것을 문법으로 명시한다.
런타임 비용은 없고(단순 바인딩 규칙), 미사용 변수 경고/에러를 깔끔하게 처리할 수 있다.

- [ ] 규칙(MVP)
    - [ ] `_`는 "버리는 바인딩"으로 취급한다(심볼 테이블에 등록되지 않음)
    - [ ] `_`는 값을 읽을 수 없다(예: `x = _;`는 컴파일 에러)
    - [ ] 허용 위치(초기)
        - [ ] 다중 리턴 destructuring: `var a, _ = f();`, `a, _ = f();`
        - [ ] `foreach` 바인딩: `foreach (var _, val in arr) { ... }`

### 1.2) 타입 표기/선언 문법 개선

v2의 `var x: Type;` 스타일은 유지하되, “현대적” 선언 편의 문법을 추가합니다.

- [ ] 타입 추론 초기화(확정): `var x = expr;`에서 `: Type` 생략 허용
- [ ] 함수 시그니처에 반환 타입 표기 도입: `func f(x: T) -> U { ... }`
- [ ] `bool` 타입(조건/논리 연산이 표현식에서 자연스럽게 동작)
- [ ] `&&`/`||`를 expr로 승격(현대적 기대치: 조건식 전용이 아니라 표현식에서 사용)

### 1.2.1) 기본 문법(고급 언어 기본 세트): 불변 바인딩/복합 대입/증감

v2에는 `<< >>` 같은 shift 자체는 있지만, `final`/`++`/`--`/`+=` 같은 “기본 편의 문법”이 없습니다.
v3에서는 아래를 최소 세트로 추가하여, 코드가 더 짧고 관용적으로 작성되도록 합니다.

- [ ] 불변 바인딩: `final`
    - [ ] 문법(확정): `final var x: T = expr;` / `final var x = expr;`
    - [ ] 의미(MVP): 초기화 이후 재대입 금지(= binding immutability)
    - [ ] 제약(초기): `final`은 **변수 재대입만 금지**하고, 값의 “깊은 불변(deep immutable)”까지는 강제하지 않음
    - [ ] 오류: `final`에 대한 `x = ...;`는 컴파일 에러

- [ ] 복합 대입(Compound Assignment)
    - [ ] 문법: `x op= expr;`
    - [ ] 지원 op(MVP): `+=` `-=` `*=` `/=` `%=` `&=` `|=` `^=` `<<=` `>>=`
    - [ ] 의미: `x = x op expr`의 설탕(sugar)이며, `x`는 L-value여야 함
    - [ ] 타입 규칙: `x = x op expr`가 타입 체크를 통과해야 함

- [ ] 증감(Increment/Decrement)
    - [ ] 문법: `x++;` / `x--;`
    - [ ] MVP 정책: **문장(statement) 위치에서만 허용** (표현식 값으로는 취급하지 않음)
    - [ ] 허용 대상(MVP): 단순 식별자(IDENT)만(= 복잡한 LHS는 후순위)
    - [ ] lowering: `x += 1` / `x -= 1`로 lowering

### 1.2.2) 명명된 인자(Named Arguments) (Phase 5)

의도: bool 플래그가 많은 시스템 API 호출에서 실수를 줄이고, 호출 가독성을 높인다.
구현은 "검증 가능한 문법 설탕"으로만 제공하여 런타임 오버헤드는 0으로 유지한다.

- [ ] 문법(안)
    - [ ] `f(a: x, b: y)`
- [ ] MVP 정책(구현 가성비 우선)
    - [ ] 인자의 **순서는 반드시 파라미터 순서를 따른다**(재배열/스킵은 금지)
        - [ ] 예: `create_socket(tcp: true, blocking: false)`
    - [ ] 컴파일러는 이름이 실제 파라미터 이름과 일치하는지 검증한다(불일치 시 에러)
    - [ ] lowering: 이름을 제거하고 기존 positional call로 lowering(= 의미/ABI 동일)
    - [ ] 혼용 정책(확정): "전부 named" 또는 "전부 positional"만 허용(혼용 금지)

### 1.2.5) 암호학/보안 연산자/구문(확정)

암호학/보안 코드는 “성능”뿐 아니라 “부채널/키 잔존” 같은 실패 모드가 치명적이다.
v3에서는 핵심 패턴을 라이브러리 호출이 아니라 **언어의 연산자/구문**으로 승격한다.

- [ ] 비트 회전(Rotate) 연산자
    - [ ] `x <<< n` : left rotate (ROL)
    - [ ] `x >>> n` : right rotate (ROR)
    - [ ] 주의: Basm의 `>>>`는 Java의 unsigned shift가 아니라 **rotate** 의미로 고정
    - [ ] 적용 대상: 정수 타입(`u32/u64` 등)만 허용, 회전 폭은 타입 비트폭으로 mod 처리
    - [ ] 파서/우선순위: `<<`/`>>`와 동일한 레벨(shift)로 취급
    - [ ] lowering: `std.rotl/rotr` intrinsic 호출 또는 x86-64 `rol/ror`로 직접 코드젠

- [ ] 상수 시간 비교(Constant-Time Equality) 연산자: `===`, `!==`
    - [ ] 문법: `if (hash === expected) { ... }`
    - [ ] 동작: 값이 달라도 조기 종료 없이 끝까지 비교 후 결과 산출
    - [ ] 목적: 타이밍 공격(Timing Attack) 원천 차단
    - [ ] 제약(MVP): 적용 대상을 제한해서 의미/성능을 예측 가능하게(예: 고정폭 정수/고정 길이 배열)
    - [ ] lowering: `std.ct_eq` 같은 intrinsic로 내리거나, 비트 연산 기반 루프/asm로 구현

- [ ] 메모리 소각 구문: `wipe`
    - [ ] 문법(안):
        - [ ] `wipe variable;`
        - [ ] `wipe ptr, len;`
    - [ ] 동작: 즉시 메모리를 0(또는 정책에 따라 난수)로 덮어쓰기
    - [ ] 최적화 방지: `volatile`/전용 intrinsic로 lowering하여 DCE로 절대 제거되지 않게 보장
    - [ ] 목적: 키/비밀번호/중간값이 스택/힙에 잔존하는 것을 방지

### 1.2.6) 시스템 해킹/극한 최적화 문법(해커 팩)

기존 언어들이 라이브러리/매크로로 처리하던 low-level 패턴을 문법/연산자로 승격해
“기계 제어 + 투명성”을 언어의 개성으로 만든다.

- [ ] 강제 Tail Call: `return tail f(args...);`
    - [ ] 의미: `CALL`이 아니라 `JMP`로 전환하여 스택을 쌓지 않음(상태 머신/VM용)
    - [ ] 제약(MVP):
        - [ ] 타깃 함수 시그니처(인자/리턴)가 호환되는 경우에만 허용
        - [ ] `defer`와의 상호작용(확정): 현재 함수에 미실행 `defer`가 하나라도 있으면 `return tail ...;`은 컴파일 에러
    - [ ] IR/lowering: `musttail` 같은 플래그로 유지 → 백엔드에서 `jmp`로 내리기

- [ ] 정수 비트 슬라이싱: `x[hi:lo]`
    - [ ] 의미: 정수에서 특정 비트 구간을 추출(예: `instruction[31:26]`)
    - [ ] 적용 대상: 정수 타입만 허용
    - [ ] 제약(MVP): `hi`/`lo`는 컴파일 타임 상수(또는 최소한 범위 체크 가능해야 함)
    - [ ] lowering: `shift + mask`로 기본 구현, (후순위) x86 `bextr` 등으로 최적화

- [ ] Raw/Unsafe 메모리 연산자: `$`
    - [ ] 목표: “안전장치 해제”를 코드에서 한눈에 보이게 하는 강한 마커
    - [ ] 문법(확정: B안, Prefix / Target Prefix)
        - [ ] `$`는 "뒤에 오는 대상(target)을 raw/unsafe로 접근"하는 prefix 연산자
        - [ ] 포인터 deref/store/load: `$ptr`
            - [ ] 예: `$p = 10;` / `x = $p;`
        - [ ] 배열/슬라이스 인덱싱: `arr[$i]`
            - [ ] 의미: bounds check 없는 인덱싱
        - [ ] 필드 훅 우회(raw field): `obj.$field`
            - [ ] 예: `self.$hp = val;` / `tmp = self.$hp;`
    - [ ] 제약(MVP): 적용 범위/타입을 제한해서 의미를 명확히(예: 포인터/배열/슬라이스만)
        - [ ] 디버그 모드 정책(확정): 디버그에서도 의미/동작 변화 없이 완전 생략(트랩/검사 삽입 없음)
    - [ ] 안전 규칙(필수, MVP에서 명문화)
        - [ ] Rule 1: 배열/슬라이스 인덱싱은 기본적으로 Safe(= bounds check)
        - [ ] Rule 2: 포인터(`*T`) 기반 연산은 기본적으로 Unsafe(= 컴파일러가 안전을 보장하지 않음)
        - [ ] Rule 3: unsafe를 쓰려면 `$`로 “의도적 우회”를 코드에 남겨야 함(리뷰/감사 가능)

### 1.3) 구조체/열거형 리터럴(표현식)

v2에서는 “struct 리터럴 expression”이 없고, 선언 전용 brace-init만 있습니다.
v3에서는 값 생성/전달을 자연스럽게 하기 위해 리터럴을 목표로 합니다.

- [ ] 구조체 리터럴 expr:
    - [ ] named: `Pair{ a: 1, b: 2 }`
    - [ ] positional(확정): `Pair{ 1, 2 }`
- [ ] enum 값 생성 방식 정리(확정): `Color.Red`

### 1.3.5) 비트 필드 구조체: `packed struct` (Phase 3)

네트워크 패킷 헤더/CPU 제어 레지스터 같은 "비트 단위 필드"를 안전하고 명시적으로 다루기 위한 기능.
컴파일러가 `shift/and/or`로 lowering 하므로, 수동 비트연산과 동등한 비용(= zero overhead)로 동작한다.

- [ ] 문법(안)
    - [ ] `packed struct Name { field: u1; ... }`
- [ ] 비트폭 정수 타입(제한)
    - [ ] `uN`/`iN` (1 ≤ N ≤ 64)를 "비트폭 정수"로 예약
    - [ ] MVP: `packed struct` 필드에서만 `uN/iN` 허용(일반 타입으로의 확장은 후순위)
- [ ] 레이아웃/규칙(MVP)
    - [ ] 필드는 선언 순서대로 비트를 채운다(LSB→MSB, byte 0부터)
    - [ ] 전체 크기(byte) = `ceil(total_bits / 8)`
    - [ ] 포인터/슬라이스/일반 struct 필드 등 복합 타입은 MVP에서 금지(비트필드만 허용)
- [ ] 접근 lowering(필수)
    - [ ] read: load → shift+mask
    - [ ] write: read-modify-write(마스크로 해당 비트만 갱신)
    - [ ] 이 lowering은 최적화 대상으로 두되, 의미는 항상 유지되어야 함

### 1.4) 메서드/네임스페이스(읽기 좋은 API)

- [ ] 메서드 호출 설탕(sugar): `x.f(y)` ↔ `f(x, y)`
- [ ] `impl Type { ... }` 블록(메서드/연관 함수 묶기)
- [ ] visibility(접근제어자): `public` / `private` (미표기 = `private`) (모듈 경계에서 API 정리)

### 1.5) 자원 관리: `defer` (필수)

v2에서 가장 불편했던 점(리소스 누수/`malloc/free` 쌍 누락)을 언어 차원에서 줄이기 위한 기능.

- [ ] Go/Zig 스타일의 `defer <stmt>;`
- [ ] 스코프 종료 시 역순 실행 보장
    - [ ] `return`/`break`/`panic` 등 “조기 종료”에서도 실행
    - [ ] `defer` 스코프(확정): 블록 스코프(현재 블록 종료 시 실행)

### 1.6) FFI (Foreign Function Interface) 명시화 (필수)

v2의 암묵적 extern 호출을 정리하고, C ABI/플랫폼을 명시해서 libc/외부 라이브러리 연동을 쉽게 한다.

- [ ] extern 블록 문법(확정): `extern "C" { func ...; }`
    - [ ] 단일 선언 형태는 문법 설탕으로 취급 가능: `extern "C" func ...;` → `extern "C" { func ...; }`
- [ ] 호출 규약 지정(최소):
    - [ ] `extern "sysv"` (System V AMD64)
    - [ ] `extern "win64"` (Windows x64)
- [ ] extern 블록을 기본으로 사용(선언은 블록 내부에서만 허용)
- [ ] 심볼 이름 매핑 정책(기본은 그대로, 필요 시 `link_name` 같은 속성 추가)
- [ ] MVP 정책: 커스텀 레지스터 ABI(`@reg`)는 **`extern` 함수(FFI) 전용**으로만 허용

### 1.7) 조건부 컴파일(Conditional Compilation) (필수)

std/런타임을 OS별로 나누기 위해 컴파일 타임 분기 수단이 필요.

- [ ] 문법: `@[cfg(...)]` 어노테이션 기반으로 조건부 포함/제외
    - [ ] 예: `@[cfg(target_os="linux")]`
- [ ] 지원 대상 최소: `target_os` (`linux`/`windows`)
- [ ] 분기 범위(확정): 선언 + 문장(statement) 레벨
    - [ ] 선언: 함수/전역 `var/const`/`struct`/`enum`/`type` 등
    - [ ] 문장: 블록 내부의 개별 문장(그 결과 블록 레벨 분기도 자연스럽게 포함)

### 1.8) 일급 함수: 함수 포인터 & (선택) 클로저

제네릭만으로는 비교 함수/콜백 전달이 불편하므로 함수를 값으로 다룬다.

- [ ] 함수 포인터 타입
    - [ ] 타입 표기(확정): `func(i32, i32) -> bool`
    - [ ] 변수에 함수 주소 저장
    - [ ] 간접 호출(예: `call reg`) 코드젠
- [ ] 캡처 없는 익명 함수(선택)
    - [ ] `|x| x+1` 또는 `fn(x) { ... }` 등 문법(후에 확정)
- [ ] 클로저(캡처 있음) (후순위)
    - [ ] 캡처 레이아웃/수명 모델/호출 규약까지 포함한 설계 필요

### 1.9) 보안 프리미티브: `secret` (unique)

암호학/보안 코드에서 “키/시크릿 메모리”를 안전하게 다루기 위한 언어 차원의 지원.
핵심은 **dead store elimination(DSE)로 인해 zeroize가 제거되는 문제를 원천 차단**하는 것.

- [ ] 문법: `secret` 키워드(변수/타입 수식)
    - [ ] 예: `var key: secret [32]u8 = ...;`
- [ ] 의미(MVP): `secret` 변수는 스코프 종료 시 반드시 0으로 덮어쓰기(zeroize)
    - [ ] `return/break/panic` 등 조기 종료에도 실행
    - [ ] 최적화에 의해 제거되지 않도록 보장(volatile store 또는 전용 intrinsic로 lowering)
- [ ] 제약(초기): 스택 로컬부터 지원, 이후 힙/구조체 필드로 확장

### 1.9.5) 성능/보안 계약: `nospill` (레지스터 거주 보장)

극한 성능 루프(메모리 접근 최소화) 또는 보안상 “스택/메모리에 절대 남으면 안 되는 값”에 대해,
해당 변수가 **스필(spill)되어 메모리에 내려가면 컴파일 에러**를 내는 강한 계약 기능.

- [ ] 문법(안): `nospill var x: T = expr;`
    - [ ] 예:
        - [ ] `nospill var r1: u64 = 0;`
        - [ ] `nospill var r2: u64 = 1;`
- [ ] 의미(MVP)
    - [ ] `nospill` 변수는 레지스터에만 존재해야 함(스택 슬롯 할당 금지)
    - [ ] 레지스터 부족 등으로 spill이 필요해지면 **컴파일 에러**
- [ ] 구현 포인트
    - [ ] IR에서 “nospill 값”을 구분 가능하게 태깅(alloca 금지, spill 금지)
    - [ ] 레지스터 할당기(linear-scan 등)가 이 제약을 강제
    - [ ] 에러 메시지: 어떤 변수/어떤 구간에서 레지스터가 부족했는지 위치 정보 포함

### 1.10) 메타프로그래밍: `comptime` (Phase 5 / post-MVP) (unique)

`comptime`은 "컴파일 타임에 코드를 실행"하는 기능이므로, 컴파일러 내부에
상수 평가기(const-eval) 또는 제한 인터프리터/VM 같은 **내장 실행기**가 필요해진다.
이 항목은 v3 범위를 초과하는 리스크(실행기/VM 블랙홀)가 크므로 **v4 로드맵으로 이동**한다:
[docs/v4_roadmap.md](docs/v4_roadmap.md)

### 1.11) Inline ASM 문법 개선(alias 연결 + 레지스터 치환)

v2의 `asm { ... }`는 문자열을 그대로 내보내기 때문에, 레지스터를 바꾸면 asm 텍스트도 같이 고쳐야 한다.
v3에서는 “alias로 선언된 변수”만 inline asm에 연결하고, 텍스트에서 레지스터 이름을 자동 치환한다.

- [ ] 문법(안): `asm(alias_var1, alias_var2, ...) { ... }`
    - [ ] 인자로는 **alias 된 변수만 허용**(일반 로컬/전역은 금지)
    - [ ] 미지정 alias를 `{name}`로 참조하면 컴파일 에러
- [ ] 치환 규칙: 블록 내부 텍스트의 `{var_name}`을 해당 alias의 실제 레지스터 이름(`rax`, `rbx` 등)으로 치환
    - [ ] 예: `mov {tmp}, 0` (tmp가 `r10` alias면 `mov r10, 0` 출력)
- [ ] 목적: 레지스터 변경 시 asm 코드 수정 최소화 + 가독성 향상

### 1.12) 어노테이션 시스템(Attributes)

지저분한 키워드 추가 대신, `@[attribute]`로 컴파일러 지시어/계약/검증을 통일한다.

- [ ] 문법: `@[name(args...)]`를 함수/변수/루프 위에 부착
- [ ] 컴파일 제어(예): `@[inline]`, `@[no_mangle]`
- [ ] 형식 검증(Contract): `@[requires(expr)]`, `@[ensures(expr)]`, `@[invariant(expr)]`
- [ ] 조건부 컴파일/플랫폼 분기 같은 기능도 Attribute로 통일(자세한 문법은 1.7 참고)

#### 1.12.1) 프로퍼티 훅(Property Hooks): `@[setter]`, `@[getter]`

목표: 구조체(`struct`)는 "순수 데이터 레이아웃"을 유지하면서도,
필드 대입/읽기 시점에 검증(Validation)·로깅·지연 로딩 같은 로직을 **함수로 연결**해 구현한다.
(C#처럼 `get {}`/`set {}` 블록을 struct 안에 넣지 않는다.)

- [ ] 문법(안)
    - [ ] 필드에 부착:
        - [ ] `@[setter(set_func)] public hp: i32;`
        - [ ] (추가) 자동 setter 생성: `@[setter] public hp: i32;`
            - [ ] 의미: 별도 함수 이름을 주지 않으면, 컴파일러가 "기본 setter" 함수를 자동 생성하고 쓰기를 그 함수로 리다이렉트
            - [ ] 생성 함수 이름(고정, 충돌 방지): `<StructName>_set_<fieldName>`
                - [ ] 예: `struct Player { @[setter] hp: i32; }` → `Player_set_hp(self: *Player, val: i32) -> void`
                - [ ] 정책: 동일 모듈 내에 같은 이름의 사용자 정의 함수가 이미 있으면 컴파일 에러(이름 충돌)
                - [ ] 정책: 미래 확장을 위해 이 네이밍 패턴은 컴파일러 예약(reserved)으로 간주
            - [ ] 접근제어(권장/MVP)
                - [ ] 생성된 setter의 가시성은 필드의 가시성을 따른다(필드가 `public`이면 setter도 `public`, 아니면 `private`)
        - [ ] `@[getter(get_func)] public hp: i32;`
        - [ ] (추가) 자동 getter 생성: `@[getter] public hp: i32;`
            - [ ] 의미: 별도 함수 이름을 주지 않으면, 컴파일러가 "기본 getter" 함수를 자동 생성하고 읽기를 그 함수로 리다이렉트
            - [ ] 생성 함수 이름(고정, 충돌 방지): `<StructName>_get_<fieldName>`
                - [ ] 예: `struct Player { @[getter] hp: i32; }` → `Player_get_hp(self: *Player) -> i32`
                - [ ] 정책: 동일 모듈 내에 같은 이름의 사용자 정의 함수가 이미 있으면 컴파일 에러(이름 충돌)
                - [ ] 정책: 미래 확장을 위해 이 네이밍 패턴은 컴파일러 예약(reserved)으로 간주
            - [ ] 접근제어(권장/MVP)
                - [ ] 생성된 getter의 가시성은 필드의 가시성을 따른다(필드가 `public`이면 getter도 `public`, 아니면 `private`)
    - [ ] 훅은 "연결"만 의미하며, 로직은 별도 함수에 둔다

- [ ] lowering 규칙(필수)
    - [ ] 쓰기 리다이렉트:
        - [ ] `p.hp = v;` → `set_hp(&p, v);`
        - [ ] 시그니처(권장/MVP): `func set_hp(self: *Player, val: i32) -> void`
        - [ ] `@[setter]` 자동 생성이 켜진 경우:
            - [ ] `p.hp = v;` → `Player_set_hp(&p, v);` 형태로 lowering
            - [ ] 기본 구현(자동 생성 setter)은 raw write로 구현: `self.$hp = val;`
    - [ ] 읽기 리다이렉트(선택):
        - [ ] `x = p.hp;` → `x = get_hp(&p);`
        - [ ] 시그니처(권장/MVP): `func get_hp(self: *Player) -> i32`
        - [ ] `@[getter]` 자동 생성이 켜진 경우:
            - [ ] `x = p.hp;` → `x = Player_get_hp(&p);` 형태로 lowering
            - [ ] 기본 구현(자동 생성 getter)은 raw read로 구현: `return self.$hp;`

- [ ] 무한 재귀 방지(필수): Raw Access `$`로 실제 메모리 접근
    - [ ] setter/getter 내부에서 같은 필드에 일반 접근을 하면 훅이 다시 걸려 무한 재귀가 된다
    - [ ] 해결: 훅 내부에서는 **raw field access**를 사용해 "진짜 load/store"를 수행
        - [ ] raw write: `self.$hp = val;` (setter 훅을 우회하고 메모리에 직접 store)
        - [ ] raw read: `tmp = self.$hp;` (getter 훅을 우회하고 메모리에서 직접 load)
    - [ ] 규칙: `obj.$field` 형태의 raw field access는 오직 "훅 우회" 목적이며, 일반 코드에서의 남용은 `$`(unsafe) 규칙에 따른다

- [ ] 적용 범위/제약(MVP)
    - [ ] 대상: struct 필드에만 적용(로컬 변수/전역 변수 훅은 후순위)
    - [ ] 접근제어 연동: 다른 모듈에서 `m.T.f` 접근은 타입(`T`)도 `public`, 필드(`f`)도 `public`이어야 가능(5.1 참고)
    - [ ] 에러 정책: 훅 함수가 없거나 시그니처가 맞지 않으면 컴파일 에러(스팬 포함)

### 1.13) 파서 내장 유틸리티(MVP 전략): Hardcoded Intrinsics

제네릭/AST/IR이 완성되기 전에도 개발 편의성을 높이기 위해, 파서 단계에서만 처리하는 내장 유틸을 둔다.

- [ ] `print(expr)`
    - [ ] 인자 타입/형태를 보고 `print_u64`, `print_str` 등으로 자동 분기
    - [ ] 목적: 부트스트랩/디버깅 생산성
- [ ] `@embed("path")`
    - [ ] 파일을 읽어 `.rodata`의 바이트 배열로 삽입하고, `[]u8`(또는 동등 표현)로 노출
    - [ ] 목적: 쉘코드/테이블/테스트 데이터 삽입

- [ ] `@trng`
    - [ ] 하드웨어 난수(`RDRAND`/`RDSEED`)를 읽는 특수 시스템 변수(실패 시 정책: 재시도/에러/패닉)
    - [ ] 목적: 시드/엔트로피 소스 제공(암호학)

### 1.13.1) 암호/알고리즘 친화 Builtin Intrinsics (bit/limb ops)

표준 라이브러리가 완성되기 전에도, 암호/해킹/알고리즘 코드에서 빈도가 높은 원시 연산은
컴파일러가 "빌트인(intrinsic)"으로 인식해 최적의 기계 명령으로 lowering 한다.

- [ ] 바이트 스왑: `bswap(x)`
    - [ ] 기능: little-endian ↔ big-endian 변환
    - [ ] 타입: 정수(`u16/u32/u64` 우선, 필요 시 `i*`는 bitcast 취급)
    - [ ] 결과 타입: 입력과 동일
    - [ ] lowering(x86-64): `BSWAP` (폭에 맞게)

- [ ] 비트 카운트: `popcnt(x)`
    - [ ] 기능: 1인 비트의 개수(population count)
    - [ ] 결과 타입(MVP): `u64` (입력 폭과 무관하게 count를 반환)
    - [ ] lowering(x86-64): `POPCNT` (미지원 환경은 소프트웨어 폴백)

- [ ] 0 카운트: `ctz(x)`, `clz(x)`
    - [ ] 기능: trailing/leading zeros count
    - [ ] 결과 타입(MVP): `u64`
    - [ ] 0 입력 정책(필수): `x == 0`이면 결과는 "비트폭"(예: `u64`면 64)으로 정의(분기 없이 쓰기 쉬운 규칙)
    - [ ] lowering(x86-64): `TZCNT`/`LZCNT` (미지원 환경은 `BSF/BSR`+분기 또는 폴백)

- [ ] 큰 수(다중 워드) 연산용 carry/borrow: `addc(a, b, carry_in)`, `subb(a, b, borrow_in)`
    - [ ] 목적: RSA/ECC 같은 big-int limb 연산에서 캐리/빌림 처리를 분기 없이 빠르게 수행
    - [ ] MVP 타입(권장): `a: u64`, `b: u64`, `carry_in: u64(0 또는 1)`
    - [ ] 반환: `(sum, carry_out)` / `(diff, borrow_out)` (v3의 2-리턴 ABI와 결합)
        - [ ] `carry_out`/`borrow_out`도 `u64(0 또는 1)`
    - [ ] lowering(x86-64): `ADC` / `SBB`
    - [ ] 구현 메모: 이 연산은 플래그 의존이므로, IR에서 별도 opcode(`addc/subb`)로 유지하거나 lowering 순서를 고정해야 함

- [ ] (추천) wide multiply(상/하위 워드): `umul_wide(a, b)`, `smul_wide(a, b)`
    - [ ] 목적: big-int 곱셈, Barrett/Montgomery reduction, 해시/PRNG 등에서 “상위 워드(hi)”가 필요
    - [ ] 반환: `(lo, hi)`
        - [ ] `umul_wide(u64, u64) -> (u64, u64)`
        - [ ] `smul_wide(i64, i64) -> (i64, i64)` (정책: 2의 보수 기준으로 hi를 정의)
    - [ ] lowering(x86-64): `MUL`/`IMUL` (결과가 `rdx:rax`로 나옴)
    - [ ] 구현 메모: `addc/subb`와 달리 플래그에 덜 민감하지만, 2-리턴 ABI(`rax/rdx`)와 매우 자연스럽게 결합

- [ ] (추천) 상수시간 선택(constant-time select): `ct_select(mask, a, b)`
    - [ ] 목적: 분기 없는 선택(타이밍/브랜치 예측 기반 부채널 완화)
    - [ ] 의미(정의, 확정): `mask`는 임의의 비트마스크를 허용하며, `((a & mask) | (b & ~mask))`로 정의
    - [ ] 타입(MVP): 동일 폭 정수끼리만 허용(예: `u64`)
    - [ ] lowering: 기본 구현은 `and/or/not` 조합, (후순위) 아키텍처별 `cmov`/벡터화 최적화

- [ ] (옵션/후순위) carryless multiply(GF(2) 곱): `clmul(a, b)`
    - [ ] 목적: GHASH(AES-GCM), CRC/폴리노미얼 기반 알고리즘, 비트행렬/해시
    - [ ] 반환(안): `clmul(u64, u64) -> (u64, u64)` 또는 `u128` 동등 표현(없으면 2-리턴)
    - [ ] lowering(x86-64): `PCLMULQDQ` (지원 없는 환경은 소프트웨어 폴백)
    - [ ] 비고: SIMD 레지스터/타입 규칙이 얽히므로 MVP에는 넣지 말고 “필요 시 추가”로 유지

- [ ] (옵션/후순위) CRC32: `crc32(seed, x)`
    - [ ] 목적: 빠른 체크섬/해시(파일/패킷), 해킹/리버싱에서 자주 쓰는 원시 연산
    - [ ] 타입(안): `crc32(u32, u8|u16|u32|u64) -> u32`
    - [ ] lowering(x86-64): `CRC32` (SSE4.2), 미지원 환경은 소프트웨어 폴백

---

## 2) 타입 시스템(Types)

### 2.1) 기본 타입 확장

- [ ] 정수군 명시 확장(최소): `u8/u16/u32/u64`, `i8/i16/i32/i64`
- [ ] (MVP 제외) `usize/isize`(플랫폼 크기) 타입은 post-MVP에서만 도입 여부를 재검토

#### 2.1.1) 산술 연산 타입 정책(필수)

시스템 언어에서 암묵적 정수 승격은 버그의 원흉이므로, v3는 기본적으로 Rust/Go처럼 **엄격한 규칙**을 따른다.
다만 리터럴은 사용성을 위해 “문맥 기반 타입 추론”을 허용한다.

- [ ] 기본 규칙(MVP)
    - [ ] 이항 산술/비트 연산(`+ - * / % & | ^ << >>`)에서 양쪽 피연산자의 타입이 다르면 컴파일 에러
        - [ ] 예: `u8 + u32`는 에러(명시적 `cast(u32, a)` 필요)
    - [ ] 비교(`== != < > <= >=`)도 동일: 비교 가능한 동일 타입끼리만 허용(필요 시 cast)
    - [ ] shift에서 shift-count는 정수면 허용하되, 폭/부호 규칙을 정책으로 고정(예: `u64 << u8` 허용)

- [ ] 정수 리터럴 규칙(MVP)
    - [ ] 접미사 없는 정수 리터럴(`10`, `0xFF`)은 “아직 타입이 정해지지 않은 상수”로 취급
    - [ ] 문맥이 요구하는 타입이 있으면 그 타입으로 채택(예: `var x: u8 = 10;`)
    - [ ] 문맥이 없으면 기본 타입은 `u64`로 둠(v2와의 연속성)
    - [ ] 범위 초과 리터럴은 에러(오버플로우 묵인 금지)

- [ ] 캐스팅
    - [ ] 명시적 캐스팅은 `cast(Type, expr)`를 표준으로 유지(또는 v3 문법으로 대체하되 의미는 동일)
- [ ] 포인터 자료형: `*T` (v3에서 명시적으로 설계/구현)
    - [ ] 목표: 포인터를 “그냥 u64처럼 쓰는 값”이 아니라, 타입 체크/AST/IR에 포함되는 1급 타입으로 만든다.
    - [ ] 문법(MVP)
        - [ ] 타입: `*T` (기본: non-null)
        - [ ] Nullable 포인터: `*T?`
            - [ ] 의미: null을 가질 수 있는 포인터(= `Option[*T]`의 축약으로 취급 가능)
            - [ ] 목표: "이 포인터는 절대 null이 아니다"를 타입으로 표현(방어 코드 감소 + 버그 예방)
        - [ ] null 리터럴: `null`
            - [ ] `null`은 **`*T?`에만 대입 가능**(=`*T`에는 컴파일 에러)
            - [ ] v2 호환을 위해 정수 리터럴 `0`을 포인터에 대입하는 것은 **`*T?`에만 허용**(확정)
                - [ ] 권장: `0` 대신 `null`을 사용
    - [ ] 연산/의미(MVP)
        - [ ] 주소 연산자: `&expr`
            - [ ] MVP: `&ident`는 v2처럼 지원
            - [ ] 확장: `&base.field`, `&arr[idx]`, `&*p` 같은 일반 lvalue 주소 취득은 후순위(구현 난이도/부작용 순서)
        - [ ] 역참조: `*expr`
            - [ ] 타입 규칙: `expr: *T`이면 `*expr: T`
            - [ ] `expr: *T?`이면 **그대로는 deref 금지**(컴파일 에러)
                - [ ] MVP 우회(확정: B안)
                    - [ ] `cast(*T, p)`는 금지
                    - [ ] `unwrap_ptr(p)` 내장(또는 동등 기능)을 제공: `unwrap_ptr(p: *T?) -> *T`
                        - [ ] 동작: `p == null`이면 `panic` (또는 trap) / 아니면 non-null `*T`로 변환
                        - [ ] 목적: "널 가능"을 쓰는 곳에서만 비용/분기(또는 trap)가 발생하도록 강제
                - [ ] (post-MVP) 제한적 타입 좁히기(흐름 분석)로 `if (p != null)` 내부에서만 `p: *T`로 간주하는 기능은 후순위
            - [ ] store는 `*addr = value;` 형태로 지원(기본은 qword 폭에서 시작)
        - [ ] null 체크/비교: `p == null`, `p != null`
            - [ ] `*T?`에 대해 허용
            - [ ] `*T`에 대해서는 컴파일 에러(확정)
        - [ ] 변환 규칙(MVP)
            - [ ] `*T` → `*T?` 업캐스트는 허용(암묵적 가능)
            - [ ] `*T?` → `*T` 다운캐스트는 금지(명시적 null 처리 필요)
        - [ ] 포인터 산술(확정): 바이트 단위
            - [ ] `p + 1`은 +1 byte
            - [ ] typed scaling은 post-MVP에서 별도 연산/내장으로 도입
    - [ ] 레이아웃/코드젠(MVP)
        - [ ] 표현: 포인터는 64-bit 값으로 표현
        - [ ] IR: `ptr` 타입 또는 `*T` 타입을 IR에 유지(가능하면)하고, `load/store`에 타입 폭 정보를 제공
        - [ ] `null` lowering: 0 immediate
    - [ ] 관련 문법과의 접점
        - [ ] struct 포인터 필드 접근 `p->field`
        - [ ] `ptr8/ptr64[...]` 같은 raw 메모리 프리미티브와 공존/통합 정책 정리
        - [ ] 슬라이스/배열과의 관계(변환 규칙은 2.2에서 확정)

### 2.1.5) 타입 별칭(Type Alias) (필수)

복잡한 타입(특히 제네릭) 가독성을 위해 별칭을 제공.

- [ ] 문법: `type MyInt = u64;`
- [ ] 함수 타입 별칭: `type Callback = func(i32) -> void;`
- [ ] 별칭은 “새 타입”이 아니라 “동일 타입 이름”인지(= alias) 정책 명확화

### 2.1.6) `distinct` 타입(Strong Typed Alias) (Phase 2)

암호학/시스템 코드에서 "형태는 같은데 의미가 다른 값"(Key/Nonce/FD/Handle)을 섞어 쓰는 사고를 막기 위한 강한 별칭.
레이아웃/ABI는 기반 타입과 동일하며, 타입 체크만 강화하므로 런타임 비용은 0이다.

| 코드 | 의미 | 호환성 |
| --- | --- | --- |
| `type A = u64;` | 별칭(Alias) | `A`와 `u64`는 동일 타입으로 취급. 섞어 쓰기 가능 |
| `type B = distinct u64;` | 새 타입(New Type) | `B`와 `u64`는 남남. `cast` 없이 섞으면 에러 |

- [ ] 문법(안)
    - [ ] `type Key = distinct u64;`
    - [ ] `type Fd = distinct i32;`
- [ ] 의미(MVP)
    - [ ] `distinct`는 "새 타입"이며, 기반 타입과 **자동으로 섞이지 않는다**
        - [ ] `Key` ↔ `u64` 변환은 명시적 `cast`로만 허용
        - [ ] `Key` ↔ `Iv`(다른 distinct) 변환도 명시적 `cast`로만 허용
    - [ ] 리터럴은 문맥 기반 타입 추론을 따름
        - [ ] 예: `var k: Key = 123;` (리터럴이 `Key`로 채택)
        - [ ] 예: `var x: u64 = 123; var k: Key = x;` 는 에러(명시적 cast 필요)
    - [ ] 연산 규칙(권장/MVP)
        - [ ] 동일 `distinct` 타입끼리의 연산은 기반 타입의 연산 규칙을 그대로 적용(결과도 동일 distinct 타입)
        - [ ] 기반 타입과 섞인 연산은 금지(캐스팅을 통해서만 허용)
- [ ] 레이아웃/코드젠
    - [ ] `sizeof(distinct T) == sizeof(T)`
    - [ ] lowering/코드젠은 기반 타입과 동일(타입 태그만 다름)

### 2.2) 참조/슬라이스/배열/문자열

- [ ] 슬라이스 타입을 언어 레벨로 표준화(확정): `[]T`
    - MVP는 기존 레이아웃(`[ptr:u64][len:u64]`) 호환을 유지
    - [ ] 포인터/슬라이스 변환 규칙(필수)
        - [ ] 슬라이스 → 포인터: 암묵적 변환은 하지 않고, `slice.ptr`처럼 **명시적 필드/프로퍼티 접근**으로 꺼내 쓰는 스타일을 기본으로 함
        - [ ] 포인터 → 슬라이스: **명시적 변환만 허용**(예: 표준 라이브러리/빌트인으로 `slice_from_ptr_len(p, n)` 같은 형태를 제공)
        - [ ] 길이 정보 없는 `*T`를 슬라이스로 자동 포장하지 않음(모호성/버그 방지)
        - [ ] bounds check 우회는 `$`로만 허용(예: `arr[$i]`, 또는 슬라이스 인덱싱의 unsafe 변형)
- [ ] 고정 배열 타입 표기: `[N]T` (또는 v2 스타일의 `var a[N]`를 타입으로도 일반화)
- [ ] 배열 선언 시 초기화(확정): brace-init으로 원소를 나열해 초기화 가능
    - [ ] 예: `var a: [4]u8 = { 1, 2, 3, 4 };`
    - [ ] 예: `var m: [2][3]u8 = { {1,2,3}, {4,5,6} };`
    - [ ] 제약(MVP): 원소 개수는 각 차원의 크기와 정확히 일치해야 함
- [ ] 다차원 고정 배열(MVP 권장: 컴파일 타임 크기만)
    - [ ] 문법(안): `[N][M]T` 처럼 중첩 배열 타입을 허용(= "배열의 배열")
        - [ ] 예: `var a: [3][4]u8;`
    - [ ] 인덱싱: `a[i][j]` 지원(좌결합) + 각 차원별 bounds check는 기본 safe
    - [ ] 레이아웃: row-major(마지막 인덱스가 연속)로 고정
    - [ ] 메모리/포인터 규칙(초기)
        - [ ] `&a[i][j]` 같은 주소 취득은 lvalue 주소 규칙이 열리는 시점에 맞춰 지원(2.1의 `&expr` 정책과 연동)
        - [ ] 다차원 배열을 슬라이스로 자동 변환하지 않음(암묵적 decay 금지)
- [ ] 문자열 타입(엄격 권고: MVP는 “소유 문자열” 금지)
    - [ ] MVP의 `str`은 “언어 코어의 특수 소유 타입”이 아니라, **`[]u8`(또는 동등 표현)의 별칭/관용 표기**로 취급
        - [ ] 이유: 소유 `String`(힙, realloc, drop/defer, clone/이동 규칙)은 MVP에서 1인 개발 병목이 너무 큼
    - [ ] 문자열 리터럴("...")은 `.rodata`를 가리키는 `[]u8`로 lowering
        - [ ] 예: `"hello"` → `[]u8{ ptr=&.rodata("hello"), len=5 }`
    - [ ] C-string이 필요한 경우는 `*u8`(+ 명시적 `0` 종단 정책)로 다루고, 고수준 `String`은 std 라이브러리로 미룸
    - [ ] post-MVP에서만 `String`(소유) 도입 여부를 재검토

### 2.3) 대수적 데이터 타입(선택)

현대적 언어에서 자주 쓰는 “옵셔널/에러” 표현을 타입으로 넣습니다.

- [ ] `Option[T]` (또는 `T?`) 문법/표준 타입
- [ ] `Result[T, E]` + `try`/`?` 연산자(선택)
- [ ] `match` 패턴 매칭(선택)

### 2.4) 기계 제어: 커스텀 레지스터 ABI 표기(`@reg`) (unique)

특정 환경(커널/부트로더/쉘코드/특수 ABI)에서 “인자/리턴 레지스터를 직접 지정”할 수 있게 한다.

- [ ] 문법(안): 파라미터/리턴에 레지스터 어노테이션
    - [ ] 예: `func syscall_write(fd @ rdi: i32, buf @ rsi: *u8, len @ rdx: u64) -> @rax u64 { ... }`
    - [ ] 예: `func weird_call(val @ r10: u64) { ... }`
- [ ] 제약(MVP): `@reg`는 **`extern` 함수(FFI)에서만 허용** (일반 함수에서는 금지)
- [ ] 이유: 일반 함수까지 허용하면 호출마다 레지스터 셔플링/표준 ABI 파손 문제가 커짐
- [ ] ABI 상호작용: `extern`/FFI와 충돌 시 우선순위/에러 규칙 명확화
- [ ] 코드젠: prologue/epilogue 및 caller/callee-saved 규칙과의 관계를 문서화

---

## 3) 제네릭(Generics) (Phase 5 / post-MVP)

목표: v3는 장기적으로 컴파일러/표준 라이브러리 구현을 위해 제네릭이 필요합니다.
다만 제네릭은 monomorphization(코드 복제)와 IR/타입 체크를 강하게 얽히게 만들어, 부트스트랩 단계에서 가장 큰 병목이 된다.
따라서 MVP에서는 사용자 정의 제네릭을 제외하고, 필요한 컨테이너/유틸은 1.13의 hardcoded intrinsics로 우회한다.

권장 문법(안): Go 스타일에 가까운 타입 파라미터(대괄호).

```b
func id[T](x: T) -> T { return x; }
struct Vec[T] { ptr: *T; len: u64; cap: u64; }
```

- [ ] Phase 5에서 구현
    - [ ] 제네릭 함수: `func f[T, U](...) -> ...`
    - [ ] 제네릭 타입: `struct Vec[T] { ... }`
    - [ ] 인스턴스화 전략(확정): AST 단계 monomorphization
    - [ ] 타입 추론(호출 시 타입 인자 생략) 우선 지원
    - [ ] (선택) 제약/트레이트
        - [ ] `trait Eq { ... }`
        - [ ] `func f[T: Eq](x: T) -> bool`

---

## 4) 컨트롤 플로우/표준 루프/컨테이너

### 4.1) for/foreach 정교화

v2의 `foreach`는 구현 단순화를 위해 **`Slice*`의 byte 순회**만 지원합니다.
(v2에서 `Slice`는 메모리 상 `[ptr:u64][len:u64]` 레이아웃을 가정)

v3 목표:
- [ ] `foreach`가 요소 폭/타입을 알 수 있을 때(예: `u64` 배열/슬라이스) 요소 단위로 순회
- [ ] `foreach` 대상 확장: 로컬 배열 `var a[N]` / (향후) 타입드 컨테이너
- [ ] 루프 변수 선언 문법 확정: `foreach (var x in expr) { ... }` 또는 `foreach (x in expr) { ... }`
- [ ] iterator 프로토콜(선택): `for (x in iter(expr)) { ... }` 같은 형태로 일반화

### 4.2) switch/match

- [ ] `switch`는 유지하되, enum/상수에 대한 표준 사용 패턴 문서화
- [ ] (선택) `match` 도입 시 `switch`와 역할 분담 정리

---

## 5) 모듈/패키지/빌드(현대적 개발 흐름)

### 5.1) 모듈 시스템(확정): File-based Modules (1 파일 = 1 모듈)

목표: "현대적인 시스템 언어"의 기본값으로, 파일 단위 네임스페이스 격리 + 명시적 공개를 제공한다.
이 설계는 코드 정리 효과 대비 구현 난이도가 낮고, std 작성에도 직접 필요하다.

- [ ] 대원칙(필수)
    - [ ] 1 파일 = 1 모듈(네임스페이스)
        - [ ] `math.b` 파일은 자동으로 `math` 모듈이 된다(기본 모듈명 = 파일 basename, 확장자 제외)
    - [ ] 기본은 `private`(비공개), 외부 공개는 `public`으로만 한다(= Secure by Default)
    - [ ] `import`는 **Top-level only**: 파일 맨 위의 연속 구간에서만 허용(그 외 위치의 `import`는 컴파일 에러)

- [ ] import 문법(필수)
    - [ ] 경로 기반 import: `import "path/to/file.b";`
        - [ ] 기본 별칭(alias) = 파일 basename(예: `std/math.b` → `math`)
    - [ ] 별칭 import: `import "path/to/file.b" as m;`
    - [ ] 접근 규칙(필수): 모듈 외부 심볼은 **반드시** `alias.symbol` 형태로만 접근(글로벌 자동 공개 금지)
        - [ ] 예: `m.add(10, 20)` / `m.PI` / `m.Vec2`



- [ ] 접근 제어 정책(Access Control Policy) (확정)
    - [ ] 키워드: `public`(공개), `private`(비공개)
    - [ ] Default(미표기 시): **`private`과 동일하게 처리(Strictly Module-Private)**
        - [ ] 아무것도 안 적으면 해당 파일(모듈) 밖에서는 절대 보이지 않음
        - [ ] 이유: 보안 사고 방지를 위한 Secure by Default(최소 권한) 원칙
    - [ ] 적용 대상(Top-level): `func`, `const`, `struct`, `enum`, `type`(별칭)
        - [ ] 예: `public func add(...) { ... }`
        - [ ] 예: `public const PI = 314159;`
        - [ ] 예: `public struct Vec2 { ... }`
        - [ ] 예: `private func helper(...) { ... }` (명시적으로 숨기고 싶을 때)
    - [ ] Top-level에서의 의미(MVP)
        - [ ] `public`: 다른 모듈에서 `alias.symbol`로 접근 가능(export)
        - [ ] `private`/미표기: 해당 파일(모듈) 내부에서만 접근 가능

    - [ ] 구조체 필드 접근제어(확정: B안)
        - [ ] 필드도 `public/private`를 가질 수 있다(미표기 시 `private`)
        - [ ] 다른 모듈에서 `m.Vec2.x` 접근은, `Vec2`가 `public`이어야 하고, 필드 `x`도 `public`이어야 함
        - [ ] 이유: 데이터 캡슐화/진짜 API 경계 유지(스파게티 방지)
    - [ ] 확장 계획(예약): 패키지 단위 공유가 필요해지면 "미표기=private" 기본값의 의미를 바꾸지 않고, 별도의 `internal` 키워드를 도입한다
        - [ ] 다른 모듈에서 접근 시 "private symbol" 에러(스팬/모듈 경로 포함)
    - [ ] 구조체 필드 접근제어는 v3에서 지원(= 후순위로 미루지 않음)
        - [ ] 정책(확정): 필드도 `public`이어야 외부 접근 가능(B안)

- [ ] 구현 포인트(필수)
    - [ ] 모듈 단위로 AST 생성 및 심볼 테이블을 격리
        - [ ] 모듈은 `exports`(public) / `internals`(private) 2개 테이블을 가진다
    - [ ] 모듈 캐시: 동일 경로는 1회만 로드/파싱(중복 import 방지)
    - [ ] 순환 import는 MVP에서 **에러로 금지**(DAG만 허용)

### 5.2) 빌드 단위(패키지)와 캐시(증분 컴파일) (후순위)

- [ ] 빌드 단위(패키지) 개념 도입
- [ ] 캐시(증분 컴파일) 고려

---

## 6) 컴파일러 구조 전환: AST → IR

v2는 구현 단순화를 위해 “파싱하면서 즉시 코드젠(emit)”에 가깝습니다.
v3 컴파일러는 구조적으로 아래 단계를 갖는 것을 목표로 합니다.

### 6.1) 프론트엔드(AST)

- [ ] lexer: 토큰 스트림(키워드/리터럴/스팬)
- [ ] parser: AST 생성
    - [ ] 표현식/문장/타입 노드 분리
    - [ ] 에러 복구(최소: `;`/`}` 싱크)
- [ ] AST pretty-printer(디버깅/테스트용)

### 6.2) 의미 분석(바인딩/타입)

- [ ] 심볼 테이블 + 스코프 해결
- [ ] 심볼 테이블 구현을 **해시맵(HashMap) 기반**으로 전환
    - [ ] 목표: `put/get/has`가 평균 O(1)로 동작
    - [ ] 스코프 처리: scope push/pop + shadowing 지원(동일 이름 재정의)
    - [ ] 구현(확정): 스코프별 HashMap 스택(scope push/pop)
- [ ] 타입 체크(최소 규칙부터)
- [ ] 제네릭 인스턴스화(타입 추론/치환) (Phase 5)

### 6.3) IR 설계(최소부터)

초기 목표는 “코드젠이 쉬운 3-address/CFG 기반 IR”로 시작하고, 필요하면 SSA로 진화합니다.

- [ ] IR 기본 구조: Function / BasicBlock / Instruction
- [ ] 값 모델: virtual register(또는 SSA value) + 명시적 타입
- [ ] 메모리 모델: `alloca`/`load`/`store` 또는 “주소 + 폭” 중심의 명령
    - [ ] `wipe`/`secret` zeroize 같은 보안 목적 쓰기가 IR 최적화(DCE)로 제거되지 않도록,
        **일반 store와 별개의 opcode를 반드시 둔다**: `secure_store`(또는 `volatile_store`)
        - [ ] 규칙: `secure_store`는 관측 가능한 side-effect로 취급하며, DCE/미사용 제거 대상이 아님
        - [ ] lowering: `wipe`는 `secure_store` 루프로 lowering(폭/길이는 타입/len에서 결정)
- [ ] control flow: `br`, `cbr`, `ret`, `switch`(또는 lowering)

### 6.3.5) IR 단계의 “필수 최적화”(제네릭 성능/정리)

제네릭 monomorphization 후에는 `sizeof(T)` 기반 상수/분기 등 “컴파일 타임으로 결정 가능한 것”이 많아진다.
IR에서 정리하지 않으면 코드가 급격히 비효율적이 된다.

- [ ] Constant Folding (상수 접기)
    - [ ] `1 + 2` → `3`
    - [ ] `if (true) { ... }` → 분기/블록 제거
- [ ] Dead Code Elimination (DCE)
    - [ ] 도달 불가능 코드 제거
    - [ ] 상수 분기 처리 후 남은 잔여 코드 청소
    - [ ] 보안/부작용 보존: `secure_store`/`volatile_store`는 절대 제거/병합/생략하지 않음(`wipe`, `secret` zeroize의 기반)

### 6.4) 백엔드(x86-64)

- [ ] IR → x86-64 lowering
- [ ] 레지스터 할당(최소: linear-scan)
- [ ] 스택 슬롯/스필(spill) 정책
- [ ] 호출 규약/ABI를 IR 레벨에서 명확히 표현(호출 전/후 보존 레지스터)
- [ ] `nospill` 제약 지원: spill이 필요하면 컴파일 에러

### 6.4.5) 다중 리턴(Multiple Return Values) (MVP: 2개까지만)

Go/System V 스타일로 “자주 쓰는 2-리턴 패턴(`val, ok` / `res, err`)”을 빠르게 지원한다.
ABI/성능/구현 난이도 관점에서, v3의 MVP는 **리턴값 2개까지만 레지스터로 반환**한다.

- [ ] 문법(함수 선언): `-> T`에 더해 튜플 반환 타입 지원
    - [ ] `func div_mod(a: u64, b: u64) -> (u64, u64) { ... }`
    - [ ] AST에 `return_types: [Type]` 형태로 저장
- [ ] 문법(return): `return a, b;` 형태 지원
    - [ ] 1개 리턴: 기존 `return expr;` 유지
    - [ ] 2개 리턴: `return expr0, expr1;`
- [ ] ABI 규칙(MVP)
    - [ ] 1번째 리턴 → `rax`
    - [ ] 2번째 리턴 → `rdx`
    - [ ] 3개 이상 리턴은 MVP에서 에러(또는 명시적 out-pointer 패턴으로 유도)
- [ ] 호출/바인딩(예: destructuring assign)
    - [ ] **선언+초기화**: `var q, r = div_mod(10, 3);` 지원
    - [ ] 버리기 바인딩: `var q, _ = div_mod(10, 3);` 지원(1.1.1 `_` 규칙)
    - [ ] **기존 변수 대입**: `q, r = div_mod(10, 3);` 지원
    - [ ] 버리기 대입: `q, _ = div_mod(10, 3);` 지원
    - [ ] 제약(MVP): 좌측항(L-value)은 **단순 식별자(IDENT)만 허용**
        - [ ] 허용: `a, b = f();`
        - [ ] 금지: `arr[i], *p = f();` / `p->x, q = f();` 등(주소 계산/부작용 순서 이슈)
    - [ ] 코드젠: call 후 `rax/rdx`를 각각 대상 슬롯에 저장
- [ ] IR 설계와의 접점
    - [ ] IR 표현(확정): `ret v0, v1` 형태로 multi-return을 직접 표현(= `ret value_list`)
    - [ ] lowering 단계에서 `rax/rdx` 매핑이 일관되게 적용되도록 테스트

추가(후순위): 3개 이상 리턴은 “구조체 설탕(anonymous tuple struct) + hidden out pointer”로 확장 가능.

---

## 6.5) 디버깅 지원(삶의 질)

v2는 디버깅 시 어셈블리 라벨만 보고 추측해야 했다. v3는 최소한의 “위치 정보”를 끝까지 들고 간다.

- [ ] Location Info(Source Map) 전파
    - [ ] AST → IR → ASM 단계까지 파일/줄/컬럼(또는 span) 유지
    - [ ] 런타임 패닉 시 스택 트레이스 출력에 사용
    - [ ] (고급/후순위) asm에 `.loc` 넣어서 gdb 연동
- [ ] Panic 메커니즘
    - [ ] `panic("msg")` 내장 함수(또는 std 제공)
    - [ ] stderr 출력 + 종료(스택 정리 정책은 MVP에선 단순 종료도 허용)

---

## 7) 내장(Embedded) 컴파일러를 위한 준비(v3)

목표: 컴파일러를 단순 CLI 도구가 아니라, 다른 프로그램(IDE/빌드툴/테스트 러너) 안에
**라이브러리로 내장**할 수 있는 형태로 만들기 위한 선행 준비.

※ 테스트/검증 전략 및 formal/퍼징/새니타이저 로드맵은 v4로 이동: [docs/v4_roadmap.md](docs/v4_roadmap.md)
※ `comptime` 기능 자체는 v4로 이동했지만, **v3는 “컴파일러 내장 실행기(인터프리터/VM/const-eval)”를 만들 준비를 하는 단계**로 본다.
    - [ ] 목표: v4에서 `comptime`을 붙일 때, 실행기/샌드박스/진단 인프라가 이미 준비되어 있어 블랙홀이 되지 않게 한다.
    - [ ] 참고: v4의 `comptime` 범위/제약은 [docs/v4_roadmap.md](docs/v4_roadmap.md)

- [ ] 컴파일러 API 설계(라이브러리 친화)
    - [ ] 입력: 파일 경로뿐 아니라 “메모리 상 소스 문자열/가상 파일 시스템”도 받을 수 있어야 함
    - [ ] 출력: 디스크 출력뿐 아니라 “메모리 상 오브젝트/asm 문자열/IR 덤프”를 반환 가능해야 함
    - [ ] 진단: (1) 구조화된 diagnostics 목록(스팬/코드/메시지) (2) 렌더링된 텍스트 출력 둘 다 지원

- [ ] 상태/재진입성(Reentrancy)
    - [ ] 전역 mutable 상태를 최소화(가능하면 컴파일 컨텍스트 객체로 캡슐화)
    - [ ] 동일 프로세스에서 여러 번 컴파일 호출이 가능해야 함(테스트/툴링 전제)

- [ ] 결정성/재현성
    - [ ] 동일 입력은 동일 출력(바이너리/asm/IR)을 내는 것을 기본 목표로 함
    - [ ] 빌드 환경/플랫폼 차이로 변하는 값(타임스탬프 등)은 기본적으로 출력에 포함하지 않음

- [ ] 리소스/에러 처리
    - [ ] OOM/내부 에러/패닉의 정책을 고정(라이브러리 사용자를 죽이지 않도록 에러로 승격하는 방향 권장)
    - [ ] 큰 입력/악성 입력에서 무한 루프/폭주를 막는 가드(파서/IR 패스의 step limit 등) 고려

- [ ] 빌드/드라이버 분리
    - [ ] “프론트/미들/백엔드(컴파일러 core)”와 “CLI/파일 스캔(드라이버)”를 분리
    - [ ] 모듈/의존성 스캔은 외부(드라이버)에서 제공 가능하도록 인터페이스화

- [ ] (v4 `comptime` 대비) 컴파일러 내장 실행기 준비
    - [ ] const-eval 기반(상수식 평가) 인프라를 v3에서 먼저 안정화
        - [ ] `const/enum/sizeof/offsetof` 평가기의 인터페이스를 “독립 모듈”로 분리(나중에 확장 가능하게)
        - [ ] 평가 실패(overflow/OOB/0으로 나누기 등)를 “컴파일 에러 + 스팬”으로 승격하는 공통 경로 구축
    - [ ] 결정성/샌드박스 훅을 미리 심어둠
        - [ ] 실행 스텝 카운터/리밋(패서/평가기 공용) 기반 시설
        - [ ] 메모리 사용량 추적/상한(옵션이라도) 넣을 수 있는 지점 마련
    - [ ] 기능 제한을 표현할 타입/효과 정보
        - [ ] (권장) "컴파일 타임 실행에서 금지되는 연산"을 판별할 수 있게 AST/IR 노드에 태그/분류를 두는 방향 검토
        - [ ] FFI/`asm`/I/O 같은 노드를 실행기에서 즉시 차단할 수 있어야 함
    - [ ] 진단/스택 트레이스 품질
        - [ ] 내부 실행(평가/패스) 중 발생한 에러가 "어느 소스 위치"에서 났는지 안정적으로 추적
        - [ ] (후순위) 호출 스택 유사 정보(평가 컨텍스트 스택)를 diagnostics에 첨부 가능하게

이제 내가 선택해야할 부분은 없는거지?