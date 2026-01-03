# TODO (v2_roadmap 기반, 의존성 우선순위)

이 문서는 [docs/v2_roadmap.md](docs/v2_roadmap.md)의 항목을 **선행 의존성에 따라 재정렬**한 작업 목록입니다.

표기:
- **Depends on:** 반드시 먼저 끝나야 하는 항목
- 체크박스는 “실제 구현 완료” 기준

---

## P0 — v2 스캐폴딩 + 회귀 기준선

- [x] v2 소스 트리 분리
  - Depends on: 없음
  - 포함: `src/v2/{core,driver,emit,lex,parse,std}` 디렉토리

- [x] v2 빌드/스모크 하네스 초안
  - Depends on: v2 소스 트리 분리
  - 목표: `src/v2/driver/main.b` 기반으로 드라이버를 빌드하고 입력 1개를 컴파일/실행까지 연결
  - 참고: 초기에는 v1의 `std/core/emit`를 재사용하고(v2 폴더는 driver/parse부터 교체) 점진적으로 분리

- [x] 회귀 스모크(필수)
  - Depends on: v2 빌드/스모크 하네스 초안
  - [x] P11: 재귀 fib(10)=55
  - [x] P12: addr/ptr64 swap -> a==20

- [ ] 회귀 스모크(권장)
  - Depends on: v2 빌드/스모크 하네스 초안
  - [ ] v1 기존 스모크(P0~P10)도 v2 개발 중 주기적으로 전체 실행

---

## P0.5 — 컴파일러용 자료구조(지금 당장 v1로 구현)

- [x] `HashMap` (Slice/문자열 키)
  - Depends on: 없음(기존 Vec/Slice 사용)
  - 목표: `new/put/get/has` 최소 API
  - 사용처: P2 스코프 심볼테이블, P5 struct 필드, P7 import 캐시
  - 구현: `src/library/v1/core/hashmap.b`
  - smoke: `test/v1/run_smoke_p15.sh`

- [x] `StringInterner`
  - Depends on: `HashMap`
  - 목표: `intern(ptr,len)->id`, `id->(ptr,len)`
  - 구현: `src/library/v1/core/string_interner.b`
  - smoke: `test/v1/run_smoke_p16.sh`

- [x] `Arena` bump allocator
  - Depends on: 없음
  - 목표: AST/타입 노드 등 잦은 할당을 단순화
  - 구현: `src/library/v1/core/arena.b`
  - smoke: `test/v1/run_smoke_p17.sh`

- [x] `StringBuilder` / 동적 버퍼
  - Depends on: Vec
  - 목표: label mangling/에러 메시지 등 문자열 합성
  - 구현: `src/library/v1/core/string_builder.b`
  - smoke: `test/v1/run_smoke_p18.sh`

---

## P1 — ABI 정교화(가변 프레임) + 호출 규약 고정

- [x] 가변 locals frame size 계산
  - Depends on: P0 회귀 기준선
  - 포함: 로컬 슬롯/배열/임시 spill 포함, 16바이트 정렬

- [x] call-site 정렬 정책 확정
  - Depends on: 가변 locals frame size 계산
  - 목표: helper call/함수 call 모두에서 안전한 정렬 보장

- [x] 6개 초과 인자 전달
  - Depends on: call-site 정렬 정책 확정
  - MVP: caller push + callee [rbp+..] 접근

- [x] 레지스터 정책 명문화(caller-saved/callee-saved) + 코드젠 반영
  - Depends on: P0 회귀 기준선
  - 목표:
    - helper call이 레지스터를 clobber 할 수 있음을 기본 전제로 고정
    - 문서/주요 코드젠 경로에서 규칙을 일관되게 사용

- [x] (>6 args) 스모크 추가
  - Depends on: 6개 초과 인자 전달
  - 목표: 7개 이상 인자 전달 + 재귀/로컬 프레임이 섞여도 정상 동작

---

## P2 — 선언/스코프(진짜 로컬) 도입

- [x] `var x;` 로컬 선언
  - Depends on: P0 회귀 기준선

- [x] `var x = expr;` 선언+초기화
  - Depends on: `var x;`

- [x] 독립 블록 문장 `{ stmt* }`
  - Depends on: P0 회귀 기준선

- [x] 블록 스코프 push/pop
  - Depends on: 독립 블록 문장

- [x] 미선언 변수 사용 시 에러
  - Depends on: `var` 도입 + 스코프

- [x] P13 스모크: 블록 스코프 + shadowing
  - Depends on: 블록 스코프 push/pop

- [ ] 전역 초기화(Global Init) 제약 명문화 + 에러 처리
  - Depends on: P2(var/스코프) 또는 P2.5(const/enum) 중 실제 설계에 맞춰 조정
  - 목표:
    - 전역 변수 초기화는 컴파일 타임 상수만 허용
    - 함수 호출/heap 할당 등 런타임 초기화는 `main`/`init()`에서 수행하도록 강제(또는 가이드)

---

## P2.5 — 상수/enum + 타입 힌트/캐스팅 + switch-case

- [x] top-level `const NAME = expr;`
  - Depends on: P2(var/스코프) 기반(심볼테이블)
  - MVP: const expr는 정수 리터럴 + 산술/비트 연산부터

- [x] `enum Name { ... }` (컴파일 타임 상수)
  - Depends on: top-level const
  - MVP:
    - auto-increment(0..)
    - explicit value(`A=3`) 지원
    - 참조는 `Name.A`(namespaced)만 허용

- [x] 타입 힌트(선언 기반)
  - Depends on: P2(var/스코프)
  - MVP 예시: `var x: u64 = 1;` / `func f(x: u64) {}`
  - 초기엔 “검증/에러메시지” 중심으로 시작 가능

- [ ] (정책) 선언 문법 결정: `var x: T = expr;`만 허용할지, `T x = expr;`도 허용할지
  - Depends on: P2(var/스코프)
  - 참고: C 스타일을 넣으면 타입명/식별자 분기가 필요(파서/세맨틱 복잡도 상승)

- [ ] (정책) `int` 타입 alias 지원 여부 결정
  - Depends on: 선언 문법 결정
  - 제안: `int` = `i64` (또는 아예 미지원하고 `i64/u64`만)

- [ ] (설계) `read_file()` 반환 타입 표현 결정
  - Depends on: 타입 힌트(선언 기반)
  - 옵션 A: `read_file(path) -> Slice` (권장)

- [x] 명시 캐스팅
  - Depends on: 타입 힌트
  - MVP: u8/u64, sign/zero-extend 정책 확정

- [x] switch-case
  - Depends on: P2(독립 블록 문장) + top-level const/enum
  - MVP: if-else lowering + fallthrough 금지

- [x] P19 스모크: const/enum
  - Depends on: `enum`

- [x] P20 스모크: 타입 힌트/캐스팅
  - Depends on: 명시 캐스팅
  - (권장 확장) 선언+초기화에 함수 호출 포함: `var s: Slice = read_file("...");`

- [x] P21 스모크: switch-case
  - Depends on: switch-case

---

## P2.6 — for / foreach (루프 문법 확장)

- [x] `for (init; cond; post) stmt` 도입
  - Depends on: P2(var/스코프) + P2(독립 블록 문장)
  - 구현:
    - 파서에서 전용 AST로 받거나, 곧바로 `while` AST로 lowering(선택)
    - `init/cond/post` 비어 있는 경우 정책 확정(예: cond 빈 경우 true)

- [x] `foreach (x in expr) stmt` 도입
  - Depends on: P3(배열 로컬 + 인덱싱) + P2(var/스코프)
  - MVP 대상: `Slice`(ptr/len) 우선, 그 다음 로컬 배열
  - lowering: 인덱스 기반 `while`로 변환
  - 현재(v2): `Slice*`를 **byte 단위로 순회**하는 MVP만 지원(요소 폭/타입 기반 foreach는 v3 로드맵으로 이관)

- [x] P22 스모크: `for`/`foreach` 기본 검증
  - Depends on: `for` + `foreach`

---

## P2.7 — asm 블록 문법 개선(raw multiline)

- [x] `asm { ... }` 내부를 raw 텍스트로 파싱
  - Depends on: P0 회귀 기준선
  - MVP:
    - 기존의 "...\n"; 나열 대신, 블록 내부 라인을 그대로 수집
    - emitter로 보낼 때 줄 끝에 `\n` 자동 부여(정책 확정)
    - 중첩 `{}`는 금지(내부 `}`에서 종료)

- [x] P24 스모크: raw asm 블록 실행 검증
  - Depends on: `asm` raw 텍스트 파싱

---

## P3 — 배열 로컬 + 인덱싱

- [x] `var a[16];` 선언
  - Depends on: P2(var/스코프)

- [x] `a[i]` load/store
  - Depends on: 배열 선언

- [x] P14 스모크: 배열 채우고 합산
  - Depends on: `a[i]` load/store

---

## P4 — 문자열 리터럴을 값으로 사용

- [x] `"..."`을 표현식 값으로 허용
  - Depends on: P0 회귀 기준선
  - 설계 결정: 결과 타입을 `C-string ptr`로 할지 `(ptr,len)`로 할지

- [x] `.rodata` emit
  - Depends on: 문자열 리터럴 값화

- [x] P15 스모크: 문자열 리터럴 주소/바이트 접근 검증(예: `ptr8["..."]`)
  - Depends on: `.rodata` emit

---

## P5 — struct + 필드 접근(. / ->)

- [x] `struct Name { ... }` 정의
  - Depends on: P2(var/스코프)

- [x] 재귀 구조체 정책 구현(불완전 타입 포인터)
  - Depends on: `struct` 파서/타입 테이블(기본)
  - 목표:
    - `next: *Node` 같은 incomplete-type pointer 허용
    - `next: Node` 같은 by-value recursion은 에러
    - (현재) 전방 선언 없이도 `*T`는 레이아웃 없이 허용

- [x] `sizeof/offsetof` 컴파일타임 값 제공
  - Depends on: struct 정의

- [x] `x.field` / `p->field`
  - Depends on: offsetof

- [x] Non-qword 필드 접근/저장(u8/u16/u32)
  - Depends on: `x.field` / `p->field`
  - 목표: load는 `movzx`/`mov eax`로 0-확장, store는 byte/word/dword 크기로 정확히 저장

- [x] P16 스모크: struct 필드 read/write
  - Depends on: `x.field` / `p->field`

- [x] P26 스모크: non-qword struct fields
  - Depends on: Non-qword 필드 접근/저장(u8/u16/u32)

---

## P6 — 포인터 문법 확장

- [x] `&x` address-of
  - Depends on: P2(var/스코프)

- [x] `*p` deref (lvalue 포함)
  - Depends on: `&x`

- [x] P17 스모크: `&/*` 교차 검증
  - Depends on: `*p`

---

## P7 — 모듈/다중 파일

- [ ] Python 스타일 `import` 정책 확정
  - Depends on: P0 회귀 기준선

- [ ] 모듈 경로/검색 규칙 구현(Driver)
  - Depends on: Python 스타일 `import` 정책 확정
  - 포함:
    - `import foo.bar;` 파싱(최소: top-level에서만)
    - resolve: `<root>/foo/bar.b` 또는 `<root>/foo/bar/__init__.b`
    - `-I/--module-root` 다중 경로 지원

- [ ] import 캐시 + 사이클 탐지
  - Depends on: 모듈 경로/검색 규칙 구현
  - 목표:
    - 동일 resolved path는 1회만 로드/파싱
    - 순환 import는 에러(사이클 경로 출력)

- [ ] qualified name(점) 지원
  - Depends on: P5(struct 필드 접근)와 별개로, “식별자 경로”로서의 `.` 처리
  - 목표: 다른 모듈 심볼은 `foo.bar.baz` 형태로만 참조

- [ ] 점(.) 해석 충돌 해결(모듈 vs 필드) — Semantic Check
  - Depends on: qualified name(점) 지원 + P5(struct 필드) 기본
  - 목표:
    - `a.b`를 파서에서 단정하지 않고, 심볼 테이블 기반으로 의미를 확정
    - `a`가 모듈이면 qualified name, 값이면 필드 접근으로 해석

- [ ] 모듈 prefix 라벨 mangling
  - Depends on: qualified name 지원
  - 목표: 코드젠 라벨이 모듈별로 분리되도록 `M_foo_bar__name` 같은 규칙 적용

- [ ] 드라이버: import 그래프를 토폴로지 순서로 컴파일
  - Depends on: import 캐시 + 사이클 탐지

- [ ] 중복 정의 에러 정책
  - Depends on: 모듈 prefix 라벨 mangling
  - 포함:
    - 같은 모듈 내 중복 정의: 에러
    - 서로 다른 모듈의 같은 이름: OK(qualified로 접근)

- [ ] 타입 정보 export/import(모듈 인터페이스) — struct layout 포함
  - Depends on: P5(struct + 필드 접근) + qualified name(점) 지원
  - 목표:
    - import한 모듈의 `struct/enum/const`를 타입 테이블에 반영
    - cross-module `sizeof/align/offsetof` 계산/조회 가능
  - 구현 선택:
    - 옵션 A(MVP): import 시 모듈을 파싱/세맨틱까지 수행하고 타입 테이블을 공유(캐시)
    - 옵션 B(확장): 인터페이스 파일 생성/로드(예: `.bmi`)
  - 정책:
    - `T` by-value는 레이아웃 필요(반드시 타입 정보 로드)
    - `*T`는 레이아웃 없어도 허용 가능(불완전 타입 포인터)

- [ ] P18 스모크: 파일 2개 컴파일
  - Depends on: 드라이버: import 그래프를 토폴로지 순서로 컴파일

- [ ] P23 스모크: 모듈 A struct를 모듈 B에서 사용(by-value)
  - Depends on: 타입 정보 export/import(모듈 인터페이스) — struct layout 포함

---

## P8 — 셀프호스팅

- [ ] v1로 v2 컴파일러 빌드
  - Depends on: P7(모듈/다중 파일) 최소 완성

- [ ] v2로 v2 재빌드(self-host)
  - Depends on: v1로 v2 빌드

- [ ] 결과 비교 정책 확정(바이너리 동일/출력 asm 동일 등)
  - Depends on: v2로 v2 재빌드
