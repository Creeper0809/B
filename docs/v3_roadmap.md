# v3 TODO (Implementation Tickets)

이 문서는 [docs/v3_roadmap.md](v3_roadmap.md)의 스펙/로드맵을 **구현 가능한 티켓 단위**로 쪼갠 체크리스트입니다.
목표는 “v2로 v3 컴파일러를 부트스트랩”할 때, 구현 순서와 DoD(완료 정의)가 흔들리지 않게 만드는 것입니다.

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

### 1.1 Lexer: 토큰화 + 스팬
- [ ] 키워드 토큰화(최소): `import enum struct func var const if else while for foreach switch break continue return`
- [ ] 연산자/구분자 토큰화(`&& || == != <= >= << >> ->` 포함)
- [ ] 정수/문자/문자열 리터럴 토큰 + 에러 리포팅
- [ ] 스팬(span) 유지: 파일/시작-끝 오프셋(또는 줄/컬럼)
- DoD
    - 키워드/연산자 경계 테스트(예: `a<<b`, `a < < b` 구분)
    - 최소 10개 입력에 대해 토큰 덤프(golden) 통과

### 1.2 Parser → AST: 최소 문장/표현식
- [ ] AST 노드 정의: Expr/Stmt/Type/Decl 분리
- [ ] Top-level: `import`, `const`, `var`, `enum`, `struct`, `func` 파싱
- [ ] 블록 스코프: `{ stmt* }` 파싱
- [ ] 표현식 파서(우선순위): unary, `* / %`, `+ -`, shift, 비교, 비트연산, 논리연산
- [ ] 에러 복구(최소): `;`/`}` 싱크
- DoD
    - 파싱 실패 시 “최소 1개 진단 + 계속 진행” 동작
    - 예제 파일 5개 이상에서 AST 생성 성공

### 1.3 드라이버: 파일 로딩 + import 스캔
- [ ] “파일 선두 연속 import만” 의존성 스캔 규칙 구현
- [ ] 1파일=1모듈: 모듈명 = basename
- [ ] import가 top-level 연속 구간을 벗어나면 컴파일 에러
- DoD
    - import 위치 위반에 대한 스팬 포함 에러
    - 간단한 2파일 프로젝트 컴파일(의존성 순서 고정)

### 1.4 최소 타입 체크(Phase 1용)
- [ ] `u64` 중심의 최소 타입 시스템(리터럴/산술 일부만)
- [ ] `cast(Type, expr)` AST 노드/타입 체크 뼈대
- DoD
    - `var x: u64 = 1 + 2;` 성공
    - 잘못된 타입 조합에 에러 1개 이상

### 1.5 IR: 최소 IR + x86-64 코드젠 파이프라인
- [ ] IR 데이터 구조: Function/BasicBlock/Instr
- [ ] 최소 lowering: 산술, 로컬 변수, if/while, return
- [ ] x86-64 backend: 최소 코드젠 + 실행 가능한 바이너리 출력(또는 asm)
- DoD
    - `examples/v1` 수준의 “hello/산술/루프”가 빌드/실행 가능
    - IR 덤프 옵션(디버깅용) 제공

---

## Phase 2 — 타입(정수/포인터/슬라이스/배열)

### 2.1 정수 타입 분화 + 엄격 산술 규칙
- [ ] 타입: `u8/u16/u32/u64`, `i8/i16/i32/i64`, `bool`
- [ ] 산술/비트 연산: 양쪽 타입 다르면 에러(리터럴은 문맥 기반)
- [ ] 비교 연산도 동일 타입만
- [ ] shift-count 규칙 고정(`u64 << u8` 허용 등)
- DoD
    - `u8 + u32` 에러, `cast(u32, a) + b` 성공
    - 범위 초과 리터럴 에러

### 2.2 포인터 타입 `*T` / `*T?` + null/0 정책
- [ ] 타입 표기 파싱/AST/타입체크: `*T`, `*T?`
- [ ] `null` 리터럴: `*T?`에만 대입
- [ ] 정수 `0` 대입: `*T?`에만 허용(권장 진단: `null` 사용)
- [ ] deref: `*(*T)`만 허용, `*(*T?)`는 에러
- [ ] builtin: `unwrap_ptr(p: *T?) -> *T` 추가
- [ ] null 비교: `*T?`만 허용, `*T`는 에러
- [ ] 포인터 산술: 바이트 단위
- DoD
    - `var p: *u8? = null;` OK
    - `var p: *u8 = null;` 에러
    - `if (p == null)`은 `*T?`에서만 OK

### 2.3 슬라이스 `[]T`
- [ ] 타입 표기: `[]T` 파싱/AST/타입체크
- [ ] 레이아웃: `[ptr:u64][len:u64]`(호환)
- [ ] 인덱싱 safe 기본 + unsafe 변형은 `$`로만(`a[$i]`)
- [ ] 포인터/슬라이스 변환: 암묵 없음, 명시적 `slice_from_ptr_len(p, n)` (builtin 또는 std)
- DoD
    - `[]u8`로 문자열 리터럴 lowering 동작
    - bounds-check 기본 동작 + `$` 사용 시 체크 생략

### 2.4 배열 타입 `[N]T` + 선언 init
- [ ] 타입 표기: `[N]T` 파싱/AST/타입체크
- [ ] 다차원: `[N][M]T` (= 배열의 배열), 인덱싱 `a[i][j]`
- [ ] 선언 시 초기화 brace-init
    - `var a: [4]u8 = {1,2,3,4};`
    - 원소 개수는 정확히 일치(부족/초과 에러)
- [ ] v2 스타일 `var a[N] = {...};` 지원 여부
    - 최소 목표: 문서에 있는 v2 호환(u64 배열) 형태 지원
- DoD
    - `[2][3]u8 = { {1,2,3}, {4,5,6} }` 성공
    - 개수 불일치 에러(스팬 포함)

### 2.5 문자열(코어는 비소유)
- [ ] 문자열 리터럴을 `.rodata`의 바이트 + `[]u8`로 lowering
- [ ] (선택) `str` 별칭/관용 표기 도입 여부는 post-MVP로 미룸
- DoD
    - `print("hi")` 같은 테스트에서 `[]u8`로 취급

---

## Phase 3 — 구조(구조체/열거형/foreach/packed)

### 3.1 struct/enum 타입 체크 + 레이아웃
- [ ] struct 필드 타입/오프셋/정렬 계산
- [ ] enum 값: `Color.Red` 형태 파싱/타입체크
- [ ] field 접근: `base.field`, `p->field`
- DoD
    - `offsetof(Type, field)`이 올바른 상수로 계산
    - struct 값 전달/리턴/대입이 동작

### 3.2 모듈 접근제어(기본 private)
- [ ] 심볼 공개 규칙: `public`만 외부 노출
- [ ] 필드 접근: 타입도 public + 필드도 public이어야 외부 접근 가능
- [ ] import 이름공간 해석
- DoD
    - 다른 파일에서 private 심볼 접근 시 에러
    - 최소 2모듈 예제로 검증

### 3.3 `foreach` 폭/타입 인식
- [ ] `foreach (var x in expr)` 문법 고정(필요 시 문서의 선택지 중 하나로 확정)
- [ ] `[]T`/`[N]T`에 대해 요소 단위 순회(폭/타입 기반)
- [ ] `_` discard 바인딩 지원: `foreach (var _, v in arr)`
- DoD
    - `foreach`가 u8/u64 배열에서 올바른 stride로 동작

### 3.4 `packed struct` 비트필드
- [ ] `uN/iN`(1..64) 파싱/검증(일반 타입 사용은 MVP 금지)
- [ ] read/write lowering(shift/mask, RMW)
- DoD
    - 간단한 패킷 헤더 encode/decode 예제 통과

### 3.5 프로퍼티 훅 `@[getter]`/`@[setter]`
- [ ] 어트리뷰트 파싱 + 필드에 부착
- [ ] lowering: `p.hp = v` → `set_hp(&p, v)` / `p.hp` → `get_hp(&p)`
- [ ] 자동 생성: `Player_set_hp`, `Player_get_hp` (이름 충돌 시 에러)
- [ ] raw access로 재귀 방지: `self.$hp`
- DoD
    - 훅 함수 시그니처 불일치 시 에러
    - 자동 생성이 raw read/write를 사용

---

## Phase 4 — 보안/해커(정체성)

### 4.1 `$` unsafe 연산(타입/제약)
- [ ] `$ptr` load/store를 허용하는 타입 규칙
- [ ] `arr[$i]` bounds-check 생략 규칙
- [ ] `obj.$field` 훅 우회 raw field access
- DoD
    - `$` 대상이 아닌 곳(예: 임의 expr)에 사용 시 에러

### 4.2 `wipe` + 최적화 방지 IR
- [ ] 문법: `wipe variable;`, `wipe ptr, len;`
- [ ] IR opcode: `secure_store`(또는 `volatile_store`) 도입
- [ ] DCE에서 `secure_store` 절대 제거 금지
- DoD
    - 최적화 패스 후에도 wipe가 남아있음(IR 덤프로 확인)

### 4.3 `secret` 변수
- [ ] `secret` 수식 파싱/타입체크
- [ ] 스코프 종료 시 zeroize 보장(조기 종료 포함)
- [ ] lowering: `secure_store` 사용
- DoD
    - 함수에 `return` 여러 개가 있어도 zeroize 삽입

### 4.4 `nospill`
- [ ] IR/RA에서 nospill 값 태깅
- [ ] spill 필요 시 컴파일 에러(+ 위치 정보)
- DoD
    - 인위적으로 레지스터 압박을 만들면 에러가 뜸

### 4.5 `@reg` (extern 전용)
- [ ] 파라미터/리턴 레지스터 어노테이션 파싱
- [ ] extern 함수에서만 허용(일반 함수는 에러)
- DoD
    - extern 호출에서 지정 레지스터를 그대로 사용

### 4.6 보안/암호 연산자 lowering
- [ ] rotate: `<<<`, `>>>` (ROL/ROR)
- [ ] constant-time eq: `===`, `!==`
- DoD
    - 최소 1개 벡터 테스트(고정 입력)로 결과 검증

---

## Phase 5 — 편의/확장

### 5.1 제네릭(사용자 정의) + AST monomorphization
- [ ] 문법: `func f[T](x: T) -> T`, `struct Vec[T] { ... }`
- [ ] 인스턴스화: AST 단계 monomorph
- [ ] 기본 타입 추론(호출 시 타입 인자 생략)
- DoD
    - `id(10)`이 `id[u64](10)`로 monomorph
    - 중복 인스턴스 캐시(동일 타입 인자) 동작

### 5.2 named args
- [ ] 호출 파싱: `f(a: x, b: y)`
- [ ] 검증: 파라미터명 일치, 순서 유지
- [ ] 혼용 금지: all-named 또는 all-positional
- DoD
    - `f(x, b: y)` 형태는 에러

### 5.3 IR 필수 최적화(정리)
- [ ] constant folding
- [ ] DCE (단, `secure_store`는 제거 금지)
- DoD
    - 간단한 입력에서 dead branch 제거 확인

### 5.4 multi-return(언어 표면 + IR + ABI)
- [ ] 함수 선언: `-> (T0, T1)`
- [ ] return 문장: `return a, b;`
- [ ] destructuring: `var q, r = f();`, `q, r = f();`, `_` discard
- [ ] IR: `ret v0, v1` (ret value_list)
- [ ] ABI: `rax/rdx` 매핑
- DoD
    - 2리턴 함수 호출/바인딩이 end-to-end로 동작

---

## 부록: 빠른 스모크 예제(권장)

- [ ] Phase 1: 산술/if/while/함수 호출/return
- [ ] Phase 2: 포인터 null/unwrap_ptr, `[]u8` 문자열 리터럴, 배열 init
- [ ] Phase 3: struct 레이아웃 + foreach + packed
- [ ] Phase 4: secret/wipe/nospill
- [ ] Phase 5: 제네릭 + named args + multi-return

todo 어때?
