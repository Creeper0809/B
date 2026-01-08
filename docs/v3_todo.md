# v3 TODO (Implementation Tickets)

이 문서는 [docs/v3_roadmap.md](v3_roadmap.md)의 스펙/로드맵을 **구현 가능한 티켓 단위**로 쪼갠 체크리스트입니다.
목표는 “v2로 v3 컴파일러를 부트스트랩”할 때, 구현 순서와 DoD(완료 정의)가 흔들리지 않게 만드는 것입니다.

---
## 현재 테스트 현황 (2026-01-08)

**codegen_golden: 31 passing, 4 failing**

실패 테스트:
- 20_generics_struct_offsetof — value generics + struct offsetof
- 22_comptime_array_len_expr — comptime 배열 길이
- 24_multi_return — 다중 반환 codegen
- 33_struct_literal — struct literal expression (V4로 이동)

최근 구현:
- ✅ 테스트 34 (impl_method): `impl Type {}` 블록 + 메서드 호출 설탕
- ✅ 테스트 35, 36 (defer): `defer` 문 기본 구현 (블록 스코프, return 시 실행)

---
## 전제(Freeze 요약)

v3 로드맵에서 이미 확정된 정책(문서에 반영된 내용)만 요약합니다.

- 모듈: 1 파일 = 1 모듈, `import`는 파일 맨 위 연속 구간만 허용, 기본 `private`, 명시 `public`만 공개
- unsafe 표기: `$` Prefix(B안) (`$ptr`, `arr[$i]`, `obj.$field`), 디버그에서도 동작 변화 없음(트랩/검사 삽입 없음)
- 포인터: `*T` 기본 non-null, `*T?` nullable, `null`은 `*T?`에만 대입, 정수 `0` 대입도 `*T?`에만 허용
- 포인터 비교: `*T?`만 `== null`/`!= null` 허용, `*T`에 대한 null 비교는 컴파일 에러
- 포인터 산술: 바이트 단위
- `defer`: 블록 스코프(현재 블록 종료 시 실행)
- FFI: `extern "C" { func ...; }` 블록 방식이 기본(단일 선언은 설탕)
- `@[cfg]`: 선언 + 문장(statement) 레벨
- 배열: 선언 시 brace-init 허용, 원소 개수는 고정 크기와 정확히 일치
- 제네릭: AST 단계 monomorphization
- 심볼테이블: 스코프별 HashMap 스택
- multi-return IR: `ret v0, v1` 형태로 직접 표현(= `ret value_list`), ABI는 `rax/rdx`
- `usize/isize`: MVP 제외(예시/문서/코어 타입에서 사용하지 않음)

---

## 티켓 포맷(권장)

각 항목은 다음을 포함합니다.

- **목표**: 무엇을 구현/완성하는지
- **DoD**: 무엇이 되면 “끝”인지(테스트/진단/예제)
- **의존성**: 선행되어야 하는 티켓

---

## Phase 1 — 골격(Front-end/IR 파이프라인 뼈대)

### 현재 상태(2026-01-05)

- hosted v3 P0(`src/v3_hosted` + `examples/v3_hosted/p0_token_dump.b`)에서
	`read_file → lex → token dump(stdout)` end-to-end 실행이 동작함.
- `src/v3_hosted/main.b`는 P0 CLI 드라이버로 동작함: `v3h <file>` 또는 `v3h -`(stdin).
- stdin 로딩은 v2 stdlib `io.read_stdin_cap`로 분리되어 드라이버 로직은 lexer/출력에 집중.
- Phase 1.1: Token span(`start_off` + `line` + `col`) 포함, lexer golden 10개 + 러너(`test/v3_hosted/run_lexer_golden.sh`) 통과.
- Phase 1.2: stmt/decl + 최소 에러 복구까지 포함한 파서 구현, parse golden + 러너(`test/v3_hosted/run_parse_golden.sh`) 통과.

### 1.1 Lexer: 토큰화 + 스팬

- [x] 키워드 토큰화(최소): `import enum struct func var const if else while for foreach switch break continue return`
- [x] 연산자/구분자 토큰화(`&& || == != <= >= << >> ->` 포함)
- [x] 정수/문자/문자열 리터럴 토큰 + 에러 리포팅
		- 현재: INT(10/16진), STRING("..."), CHAR('a', '\\n', '\\xNN' 등) 구현됨
- [x] 스팬(span) 유지: 시작 오프셋 + 줄/컬럼
		- 현재: Token에 `start_off`(byte offset) + `line` + `col` 유지
- DoD
	- 키워드/연산자 경계 테스트(예: `a<<b`, `a < < b` 구분)
	- 최소 10개 입력에 대해 토큰 덤프(golden) 통과 (`test/v3_hosted/run_lexer_golden.sh`)

### 1.2 Parser → AST: 최소 문장/표현식
- [x] AST 노드 정의(최소): Decl/Stmt/Expr/Type + Program
- [x] Top-level: `import`, `const`, `var`, `enum`, `struct`, `func` decl 파싱
- [x] 블록 스코프: `{ stmt* }` 파싱
- [x] 표현식 파서(Phase 1.x): unary + binary(산술은 동일 우선순위, left-assoc), shift/비교/비트/논리
- [x] 에러 복구(최소): `;`/`}` 싱크
- DoD
    - 파싱 실패 시 “최소 1개 진단 + 계속 진행” 동작
	- 예제 파일 5개 이상에서 AST 생성 성공 (`test/v3_hosted/run_parse_golden.sh`)

### 1.3 드라이버: 파일 로딩 + import 스캔
- [x] “파일 선두 연속 import만” 의존성 스캔 규칙 구현
- [x] 1파일=1모듈: 모듈명 = basename
- [x] import가 top-level 연속 구간을 벗어나면 컴파일 에러
- DoD
    - import 위치 위반에 대한 스팬 포함 에러
    - 간단한 2파일 프로젝트 컴파일(의존성 순서 고정)

NOTE
	- golden runner 추가: `test/v3_hosted/run_import_scan_golden.sh`
	- 현재 P2 드라이버는 “scan-only”(의존성 순서 출력)로 유지
	- (참고) 과거에 파서와 함께 import 시 v2c segfault 이슈가 있었으나, 현재는 해결됨

### 1.4 최소 타입 체크(Phase 1용)
- [x] `u64` 중심의 최소 타입 시스템(리터럴/산술 일부만)
- [x] `cast(Type, expr)` AST 노드/타입 체크 뼈대
- DoD
    - `var x: u64 = 1 + 2;` 성공
    - 잘못된 타입 조합에 에러 1개 이상

NOTE
	- golden runner 추가: `test/v3_hosted/run_typecheck_golden.sh`

### 1.5 IR: 최소 IR + x86-64 코드젠 파이프라인
- [x] IR 데이터 구조: Function/BasicBlock/Instr
- [x] 최소 lowering: 산술, 로컬 변수, if/while, return
- [x] x86-64 backend: 최소 코드젠 + asm 출력 + 링크/실행
- DoD
	- “hello/산술/루프”가 빌드/실행 가능 (`test/v3_hosted/run_codegen_golden.sh`)
	- IR 덤프 옵션(디버깅용) 제공 (`examples/v3_hosted/p4_codegen_smoke.b --dump-ir`)

NOTE
	- golden runner: `test/v3_hosted/run_codegen_golden.sh`

---

## Phase 2 — 타입(정수/포인터/슬라이스/배열)

### 2.1 정수 타입 분화 + 엄격 산술 규칙
- [x] 타입: `u8/u16/u32/u64`, `i8/i16/i32/i64`, `bool`
- [x] 산술/비트 연산: 양쪽 타입 다르면 에러(리터럴은 문맥 기반)
- [x] 비교 연산도 동일 타입만
- [x] shift-count 규칙 고정(`u64 << u8` 허용 등)
- DoD
    - `u8 + u32` 에러, `cast(u32, a) + b` 성공
    - 범위 초과 리터럴 에러

### 2.2 포인터 타입 `*T` / `*T?` + null/0 정책
- [x] 타입 표기 파싱/AST/타입체크: `*T`, `*T?`
- [x] `null` 리터럴: `*T?`에만 대입
- [x] 정수 `0` 대입: `*T?`에만 허용(권장 진단: `null` 사용)
- [x] deref: `*(*T)`만 허용, `*(*T?)`는 에러
- [x] builtin: `unwrap_ptr(p: *T?) -> *T` 추가
- [x] null 비교: `*T?`만 허용, `*T`는 에러
- [x] 포인터 산술: 바이트 단위
- DoD
    - `var p: *u8? = null;` OK
    - `var p: *u8 = null;` 에러
    - `if (p == null)`은 `*T?`에서만 OK

### 2.3 슬라이스 `[]T`
- [x] 타입 표기: `[]T` 파싱/AST/타입체크
- [x] 레이아웃: `[ptr:u64][len:u64]`(호환)
- [x] 인덱싱 safe 기본 + unsafe 변형은 `$`로만(`a[$i]`)
- [x] 포인터/슬라이스 변환: 암묵 없음, 명시적 `slice_from_ptr_len(p, n)` (builtin 또는 std)
- DoD
    - `[]u8`로 문자열 리터럴 lowering 동작
    - bounds-check 기본 동작 + `$` 사용 시 체크 생략

### 2.4 배열 타입 `[N]T` + 선언 init
- [x] 타입 표기: `[N]T` 파싱/AST/타입체크
- [x] 다차원: `[N][M]T` (= 배열의 배열), 인덱싱 `a[i][j]`
- [x] 선언 시 초기화 brace-init
    - `var a: [4]u8 = {1,2,3,4};`
    - 원소 개수는 정확히 일치(부족/초과 에러)
- [x] v2 스타일 `var a[N] = {...};` 지원 여부
    - 최소 목표: 문서에 있는 v2 호환(u64 배열) 형태 지원
- DoD
    - `[2][3]u8 = { {1,2,3}, {4,5,6} }` 성공
    - 개수 불일치 에러(스팬 포함)

### 2.5 문자열(코어는 비소유)
- [x] 문자열 리터럴을 `.rodata`의 바이트 + `[]u8`로 lowering
- [x] (선택) `str` 별칭/관용 표기 도입 여부는 post-MVP로 미룸
- DoD
    - `print("hi")` 같은 테스트에서 `[]u8`로 취급

---

## Phase 3 — 구조(구조체/열거형/foreach/packed)

### 3.1 struct/enum 타입 체크 + 레이아웃
- [x] struct 필드 타입/오프셋/정렬 계산 (offsetof로 검증)
- [x] enum 값: `Color.Red` 형태 파싱/타입체크
- [x] field 접근: `base.field`, `p->field`
- DoD
    - `offsetof(Type, field)`이 올바른 상수로 계산
	- struct 값 전달/리턴/대입이 동작 (현재: local-by-value 대입/초기화는 동작, 호출/리턴은 미구현)

### 3.2 모듈 접근제어(기본 private)
- [x] 심볼 공개 규칙: `public`만 외부 노출
- [x] 필드 접근: 타입도 public + 필드도 public이어야 외부 접근 가능
- [x] import 이름공간 해석
- DoD
    - 다른 파일에서 private 심볼 접근 시 에러
    - 최소 2모듈 예제로 검증

### 3.3 `foreach` 폭/타입 인식
- [x] `foreach (var x in expr)` 문법 고정(필요 시 문서의 선택지 중 하나로 확정)
- [x] `[]T`/`[N]T`에 대해 요소 단위 순회(폭/타입 기반)
- [x] `_` discard 바인딩 지원: `foreach (var _, v in arr)`
- DoD
    - `foreach`가 u8/u64 배열에서 올바른 stride로 동작

### 3.4 `packed struct` 비트필드
- [x] `uN/iN`(1..64) 파싱/검증(일반 타입 사용은 MVP 금지)
- [x] read/write lowering(shift/mask, RMW)
- DoD
    - 간단한 패킷 헤더 encode/decode 예제 통과

### 3.5 프로퍼티 훅 `@[getter]`/`@[setter]`

- [x] 어트리뷰트 파싱 + 필드에 부착
	- `@[getter]` / `@[setter]`: 훅 함수 자동 생성
	- `@[getter(func)]` / `@[setter(func)]`: 지정 함수 호출

- [x] lowering
	- 자동 생성: `p.hp = v` → `Player_set_hp(&p, v)` / `p.hp` → `Player_get_hp(&p)`
	- 지정 함수: `p.hp = v` → `func(&p, v)` / `p.hp` → `func(&p)`

- [x] 자동 생성 이름(Struct 이름 prefix): `StructName_set_field`, `StructName_get_field`
	- 예: `struct Player { hp: u64 }` → `Player_set_hp`, `Player_get_hp`
	- 이름 충돌 시 에러

- [x] raw access로 재귀 방지: `self.$hp` / `self->$hp`
- DoD
	- 훅 함수 시그니처 불일치 시 에러
	- `@[getter(func)]`/`@[setter(func)]`가 codegen golden에서 커버됨
	- raw access가 훅 우회를 보장(재귀 방지)

---

## Phase 4 — 보안/해커(정체성)

### 4.1 `$` unsafe 연산(타입/제약)
- [x] `$ptr` load/store를 허용하는 타입 규칙
- [x] `arr[$i]` bounds-check 생략 규칙
- [x] `obj.$field` 훅 우회 raw field access
- DoD
	- `$` 대상이 아닌 곳(예: 임의 expr)에 사용 시 에러

### 4.2 `wipe` + 최적화 방지 IR
- [x] 문법: `wipe variable;`, `wipe ptr, len;`
- [x] IR opcode: `secure_store`(또는 `volatile_store`) 도입
- [x] DCE에서 `secure_store` 절대 제거 금지
- DoD
    - 최적화 패스 후에도 wipe가 남아있음(IR 덤프로 확인)

### 4.3 `secret` 변수
- [x] `secret` 수식 파싱/타입체크
- [x] 스코프 종료 시 zeroize 보장(조기 종료 포함)
- [x] lowering: `secure_store` 사용
- DoD
    - 함수에 `return` 여러 개가 있어도 zeroize 삽입

### 4.4 `nospill`
- [x] IR/RA에서 nospill 값 태깅
- [x] spill 필요 시 컴파일 에러(+ 위치 정보)
    - 인위적으로 레지스터 압박을 만들면 에러가 뜸

### 4.5 `@reg` (extern 전용)
- [x] 파라미터/리턴 레지스터 어노테이션 파싱
- [x] extern 함수에서만 허용(일반 함수는 에러)
    - extern 호출에서 지정 레지스터를 그대로 사용

### 4.6 보안/암호 연산자 lowering
- [x] rotate: `<<<`, `>>>` (ROL/ROR)
- [x] constant-time eq: `===`, `!==`
- DoD
    - 최소 1개 벡터 테스트(고정 입력)로 결과 검증

---

## Phase 5 — 편의/확장

### 5.1 제네릭(사용자 정의) + AST monomorphization
- [x] 문법: `func f[T](x: T) -> T`, `struct Vec[T] { ... }` (파싱 구현됨)
- [x] 인스턴스화: AST 단계 monomorph (기본 동작)
- [x] 기본 타입 추론(호출 시 타입 인자 생략)
- [ ] value generics: `func f[N: u64]()` (부분 구현)
- DoD
    - [x] `id(10)`이 `id[u64](10)`로 monomorph
    - [ ] 중복 인스턴스 캐시(동일 타입 인자) 동작
    - [ ] value generics 완전 지원 (테스트 20, 21, 22 실패 중)

### 5.2 named args
- [x] 호출 파싱: `f(a: x, b: y)`
- [x] 검증: 파라미터명 일치, 순서 유지
- [x] 혼용 금지: all-named 또는 all-positional
- DoD
    - [x] `f(x, b: y)` 형태는 에러
- [ ] constant folding
- [ ] DCE (단, `secure_store`는 제거 금지)
- DoD
    - 간단한 입력에서 dead branch 제거 확인

### 5.4 multi-return(언어 표면 + IR + ABI)
- [x] 함수 선언: `-> (T0, T1)`
- [x] return 문장: `return a, b;`
- [x] destructuring: `var q, r = f();`, `q, r = f();`, `_` discard
- [x] IR: `ret v0, v1` (ret value_list)
- [x] ABI: `rax/rdx` 매핑
- [ ] codegen golden 테스트 통과 (테스트 24 실패 중)
    - 2리턴 함수 호출/바인딩이 end-to-end로 동작

---

---

## Phase 6 — 추가 문법/표면 언어(Modern Surface Syntax)

### 6.1 불변 바인딩/복합 대입/증감 (Phase 1.2.1)
- [ ] `final var x = expr;` (불변 바인딩)
- [x] 복합 대입: `+=`, `-=`, `*=`, `/=`, `%=`, `&=`, `|=`, `^=`, `<<=`, `>>=`
- [x] 증감(문장 위치만): `x++;`, `x--;`
- DoD
    - [x] `x += 1;`이 `x = x + 1;`로 lowering 확인
    - [ ] `final` 변수 재대입 시 에러

### 6.2 구조체/enum 리터럴 (Phase 1.3) → V4로 이동
- [ ] named: `Pair{ a: 1, b: 2 }`
- [ ] positional: `Pair{ 1, 2 }`
- [x] enum: `Color.Red` (구현됨)
- 사유: typecheck 복잡도(필드 매칭, 순서 재정렬 등)
- DoD
    - struct 리터럴로 값 생성/전달 동작

### 6.3 메서드/네임스페이스 (Phase 1.4)
- [x] 메서드 호출 설탕: `x.f(y)` ↔ `f(x, y)` (typecheck에서 변환)
- [x] `impl Type { ... }` 블록 (parser에서 `TypeName_method`로 rename)
- DoD
    - `x.add(y)`가 `add(x, y)` 호출로 lowering

### 6.4 자원 관리: `defer` (Phase 1.5)
- [x] `defer <stmt>;` 파싱/AST
- [x] 블록 스코프 종료 시 역순 실행
- [x] return 시 실행 보장
- [ ] break/continue 시 실행 (미구현)
- DoD
    - [x] `defer free(p);`가 블록 종료 시 실행됨 (테스트 35, 36 통과)

### 6.5 함수 포인터 타입 (Phase 1.8)
- [ ] 타입 표기: `func(T, U) -> R`
- [ ] 변수에 함수 주소 저장
- [ ] 간접 호출 코드젠
- DoD
    - 콜백 함수 전달 예제 동작

### 6.6 강제 Tail Call (Phase 1.2.6)
- [ ] `return tail f(args...);` 파싱/AST
- [ ] IR: `musttail` 플래그
- [ ] defer 충돌 검사(defer 있으면 에러)
- [ ] 코드젠: `jmp`로 변환
- DoD
    - tail call이 stack frame 안 쌓는지 확인

### 6.7 정수 비트 슬라이싱 (Phase 1.2.6)
- [ ] `x[hi:lo]` 파싱/AST
- [ ] 상수 범위 검증
- [ ] lowering: `shift + mask`
- DoD
    - `inst[31:26]` 같은 패턴 동작

### 6.8 Inline ASM 개선 (Phase 1.11)
- [ ] `asm(alias1, alias2) { ... }` 파싱
- [ ] `{name}` → 실제 레지스터 치환
- [ ] alias가 아닌 변수 사용 시 에러
- DoD
    - `mov {tmp}, 0` 같은 템플릿 동작

### 6.9 어노테이션 시스템 (Phase 1.12)
- [ ] `@[inline]`, `@[no_mangle]` 등 파싱
- [ ] (선택) 계약: `@[requires]`, `@[ensures]`, `@[invariant]`
- DoD
    - 기본 어노테이션이 파싱/검증됨

### 6.10 파서 내장 유틸 (Phase 1.13)
- [ ] `print(expr)` 타입별 자동 분기
- [ ] `@embed("path")` 파일 삽입
- [ ] `@trng` 하드웨어 난수
- DoD
    - `print(123)`와 `print("hi")`가 다르게 동작

### 6.11 암호/알고리즘 Builtin Intrinsics (Phase 1.13.1)
- [ ] `bswap(x)` - 바이트 스왑
- [ ] `popcnt(x)` - 비트 카운트
- [ ] `ctz(x)`, `clz(x)` - 0 카운트
- [ ] `addc(a, b, c)`, `subb(a, b, b)` - carry/borrow
- [ ] `umul_wide(a, b)`, `smul_wide(a, b)` - wide multiply
- [ ] `ct_select(mask, a, b)` - 상수시간 선택
- [ ] (후순위) `clmul`, `crc32`
- DoD
    - 각 intrinsic이 올바른 x86-64 명령으로 lowering

### 6.12 타입 별칭 + distinct (Phase 2.1.5/2.1.6)
- [x] `type Alias = T;` 별칭
- [x] `type NewType = distinct T;` 강한 별칭
- [x] distinct 타입 간 자동 변환 금지(명시적 cast만)
- DoD
    - `Key`와 `u64`를 섞어 쓰면 에러

---

## Phase 7 — 컴파일러 구조/품질

### 7.1 심볼 테이블 HashMap 전환 (Phase 6.2)
- [ ] 스코프별 HashMap 스택
- [ ] `put/get/has` 평균 O(1)
- [ ] shadowing 지원
- DoD
    - 큰 모듈에서 심볼 조회 성능 개선

### 7.2 다중 리턴 ABI 완전 지원 (Phase 6.4.5)
- [x] AST: `-> (T0, T1)`
- [x] return: `return a, b;`
- [x] destructuring: `var q, r = f();`, `q, r = f();`, `_` discard
- [x] IR: `ret v0, v1`
- [x] ABI: `rax/rdx` 매핑
- DoD
    - 2리턴 함수 end-to-end 동작

### 7.3 Location Info 전파 (Phase 6.5)
- [ ] AST → IR → ASM 단계까지 파일/줄/컬럼 유지
- [ ] 런타임 패닉 시 스택 트레이스 출력
- [ ] (후순위) `.loc` 지시어로 gdb 연동
- DoD
    - 패닉 메시지에 소스 위치 출력

### 7.4 Panic 메커니즘 (Phase 6.5)
- [ ] `panic("msg")` 내장 함수
- [ ] stderr 출력 + 종료
- [ ] (후순위) 스택 정리 정책
- DoD
    - `panic` 호출 시 메시지 출력되고 종료

### 7.5 컴파일러 API 설계 (Phase 7)
- [ ] 메모리 상 소스 문자열 입력
- [ ] 메모리 상 asm/IR 덤프 출력
- [ ] 구조화된 diagnostics
- [ ] 상태 캡슐화(재진입성)
- DoD
    - 동일 프로세스에서 여러 번 컴파일 가능

---

## Phase 8 — V4로 이동 예정 (Post-MVP)

### 8.1 `comptime` 메타프로그래밍
- [ ] 컴파일 타임 코드 실행
- [ ] 상수 평가기(const-eval) 또는 제한 인터프리터
- 사유: 실행기/VM 구현 블랙홀 리스크

### 8.2 구조체 리터럴 expression (Phase 1.3)
- [ ] named: `Pair{ a: 1, b: 2 }`
- [ ] positional: `Pair{ 1, 2 }`
- [ ] codegen: BRACE_INIT → 스택 초기화, sret 반환, VAR 초기화
- 사유: typecheck 복잡도(필드 매칭, 순서 재정렬 등)

### 8.3 조건부 컴파일 `@[cfg]` (Phase 1.7)
- [ ] 문법: `@[cfg(target_os="linux")]`
- [ ] 지원 대상: `target_os` (`linux`/`windows`)
- [ ] 분기 범위: 선언 + 문장(statement) 레벨

### 8.4 FFI extern 블록 (Phase 1.6)
- [ ] 문법: `extern "C" { func ...; }`
- [ ] 호출 규약: `extern "sysv"`, `extern "win64"`
- [ ] 심볼 이름 매핑

### 8.5 캡처 없는 익명 함수 (Phase 1.8)
- [ ] `|x| x+1` 또는 `fn(x) { ... }` 형태
- [ ] 클로저(캡처 있음)는 후순위

---

## 부록: 빠른 스모크 예제(권장)

- [x] Phase 1: 산술/if/while/함수 호출/return
- [x] Phase 2: 포인터 null/unwrap_ptr, `[]u8` 문자열 리터럴, 배열 init
- [x] Phase 3: struct 레이아웃 + foreach + packed
- [x] Phase 4: secret/wipe/nospill
- [ ] Phase 5: 제네릭 + named args + multi-return
- [ ] Phase 6: final/복합대입/증감, struct 리터럴, defer, 함수 포인터
- [ ] Phase 7: panic, 스택 트레이스