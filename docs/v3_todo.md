# v3 TODO (Implementation Tickets)

이 문서는 [docs/v3_roadmap.md](v3_roadmap.md)의 스펙/로드맵을 **구현 가능한 티켓 단위**로 쪼갠 체크리스트입니다.
목표는 “v2로 v3 컴파일러를 부트스트랩”할 때, 구현 순서와 DoD(완료 정의)가 흔들리지 않게 만드는 것입니다.

---

## 🚨 v3 단순화 계획 (2026-01-10)

**목표**: v3를 셀프호스팅 가능한 최소 기능 세트로 단순화  
**상세**: [v3_simplification.md](v3_simplification.md) 참조

### 삭제 예정 기능 (v4로 이동)

| 기능 | 상태 | 우선순위 |
|------|------|----------|
| 제네릭 `<T>` | ❌ 삭제됨 | Phase 1 |
| comptime | ❌ 삭제됨 | Phase 1 |
| nospill | ❌ 삭제됨 | Phase 2 |
| secret/wipe | ❌ 삭제됨 | Phase 2 |
| packed struct | ❌ 삭제됨 | Phase 2 |
| 프로퍼티 훅 | ❌ 삭제됨 | Phase 2 |
| 다중 리턴 | 🔴 삭제 예정 | Phase 3 |
| 부동소수점 | 🟡 보류 | TBD |

### 단순화 작업 체크리스트

- [ ] Phase 1: 제네릭/comptime 코드 제거 (lowering.b: 663→31줄)
- [ ] Phase 2: nospill/secret/wipe/packed/프로퍼티 훅 코드 제거
  - [ ] codegen.b: wipe 함수 제거, property hook 합성/호출 제거 (3481→3109줄)
  - [ ] typecheck.b: nospill 검사 비활성화 (에러 리포팅 제거)
  - [ ] parser.b: generic_registry 스텁화
- [ ] Phase 3: 추가 정리 (선택적)
- [ ] Phase 4: 제약 완화 (로컬 심볼 동적화)
- [ ] 최종: 셀프호스팅 빌드 성공

---

## 현재 테스트 현황 (2026-01-10)

**codegen_golden: 36 passing, 7 failing**

실패 테스트 (v4로 이동됨 - 예상된 실패):
- 14_packed_bitfield — v4로 이동 (packed struct 제거됨)
- 18_wipe_smoke — v4로 이동 (wipe 제거됨)
- 20_generics_struct_offsetof — v4로 이동 (제네릭 제거됨)
- 22_comptime_array_len_expr — v4로 이동 (comptime 제거됨)
- 24_multi_return — v4로 이동 (다중 리턴)
- 33_struct_literal — v4로 이동 (struct 리터럴 표현식)
- 35_extern_reg_call — v4로 이동 (extern)

**삭제된 테스트**:
- 15_property_hooks — 프로퍼티 훅 제거됨

최근 구현:
- [x] tagged 레이아웃 메타데이터 분리(tag_layout_ptr/len) 및 자동 마스킹 확장
- [x] packed struct 비트필드 읽기/쓰기 접근(일반 packed struct 포함)
- [x] tagged 레이아웃에서 addr 필드 제거(주소 암묵 처리) + 테스트 106 갱신
- [x] 테스트 106/107 갱신 및 통과 확인
- [x] 함수 시그니처 1차 수집 멀티패스 도입 + 전방 호출 테스트(108) 추가
- [x] main 진입 로직 헬퍼 분리 리팩토링
- [x] compiler 모듈로 전역/로더/구조체 레지스트리 분리
- [x] std.mem 모듈 추가 및 memset 테스트(109) 추가
- [x] std.util 해체 → std.diag/std.emit 분리
- [x] std.diag/std.emit 스텁화 + std.util 부트스트랩 유지
- [x] 모듈 네임스페이스 맹글링 + import as/from 선택적 import 구현
- [x] 전역/메서드/문자열 비교 경로 맹글링 반영 및 숫자 모듈 prefix 보정
- [x] std.str/std.char 프리루드 추가 + 110_import_alias 테스트 추가
- [x] v3_17 전환 및 SSA 스캐폴드 구조 추가 (Intrusive Instruction + Block 포인터 리스트)
- [x] SSA 스모크 테스트(111_ssa_smoke) 추가 및 v3_17 전체 테스트 PASS
- [x] SSABlock CFG(preds/succs) 확장 + phi_head 추가
- [x] SSA operand 비트 태깅 + ssa_add_edge API + 테스트(112_ssa_edges) 추가
- [x] SSA Phi 인자 리스트(SSAPhiArg) 추가 + 테스트(113_ssa_phi_args) 추가
- [x] SSAInstruction prev 포인터 태깅(Opcode 저장) 적용 + 크기 48B로 축소
- [x] Phi 전용 리스트 push front(SSA phi_head) 추가 + 테스트(114_ssa_phi_append) 추가
- [x] SSA CFG 빌더(If/While) 스캐폴드 추가 + 테스트(115_ssa_cfg_smoke) 추가
- [x] SSA 명령어 생성 단계(LOAD/STORE/BR/JMP/RET) 추가 + 테스트(116_ssa_inst_gen) 추가
- [x] SSA 비교 연산 opcode + while BR 보강 + 테스트(117_ssa_cmp_while) 추가
- [x] SSA 테스트 116 기대값 보정 (exit=0)
- [x] SSA mem2reg 스캐폴드(Immediate Dominator 계산) 추가 + 테스트(118_ssa_dom_basic) 추가
- [x] SSA Dominance Frontier 계산 추가 + 테스트(119_ssa_df_basic) 추가
- [x] SSA mem2reg Phi 삽입 + Rename 스택 구현 + 테스트(120_ssa_mem2reg_basic) 추가
- [x] SSA 단락 평가(AND/OR) 변환 + 테스트(121_ssa_short_circuit) 추가
- [x] -O1 플래그 파싱 + SSA O1 최적화 패스(상수 폴딩/NOP 제거) 추가 + 테스트(122_ssa_opt_o1_fold) 추가
- [x] SSA 파괴(Phi 제거 → COPY 삽입) 추가 + 테스트(123_ssa_destroy_basic) 추가
- [x] SSA 파괴 임계 엣지 분리 + 테스트(124_ssa_destroy_critical) 추가
- [x] SSA 그래프 컬러링 레지스터 할당 스캐폴드 + 테스트(125_ssa_regalloc_basic) 추가
- [x] 그래프 컬러링 결과 → 물리 레지스터 매핑 + 테스트(126_ssa_regalloc_map) 추가
- [x] 레지스터 매핑 SSA 적용(ops/phi 치환) + 테스트(127_ssa_regalloc_apply) 추가
- [x] 물리 레지스터 lowering(복사/로드/스토어 정리) + 테스트(128_ssa_lower_phys_basic) 추가
- [x] SSA → x86 코드젠(지원 함수 제한) + 테스트(129_ssa_codegen_basic) 추가
- [x] SSA 파라미터 로딩(SSA_OP_PARAM) + 코드젠/빌더 확장 + 테스트(130_ssa_codegen_param_basic) 추가
- ✅ **부동소수점 타입 (Phase 6.6)**: f32/f64 타입, SSE2 코드 생성, 비교 연산 bool 반환
  - 테스트 50 (float_basic): 기본 f64 변수 선언 및 출력
  - 테스트 51 (float_comparison): 부동소수점 비교 연산자 (==, !=, <, >, <=, >=) bool 반환 검증
- ✅ `char` 키워드 추가 (u8 별칭) + 타입 파서/렉서 확장
- ✅ u8/char 로컬 변수 로드/스토어 폭 보정 및 회귀 테스트(101_array_char) 추가
- ✅ `[]T`/`[N]T` 최소 지원 (로컬 선언/인덱싱) + 슬라이스 테스트(102_slice_basic)
- ✅ `[]T` 파라미터/리턴/구조체 필드 지원 + 배열 필드 지원 (103_slice_struct_fields)
- ✅ `[N]T` 파라미터/리턴 디케이(포인터) + 테스트 104_array_param_return
- ✅ `*tagged T` 파서/타입 플래그 + 자동 마스킹(Phase 1/2) + 테스트 105_tagged_ptr_basic
- ✅ `packed struct` 파싱 + `*tagged(Layout) T` 문법 + 테스트 106_tagged_layout_packed_struct
- ✅ `packed struct` 비트필드(uN) 파싱 + size 계산
- ✅ tagged 레이아웃 비트필드 접근/대입 lowering (상위 비트 자동 매핑)
- ✅ `print(args...)` 매직 함수: 인자 타입별 자동 분해 출력
- ✅ 테스트 34 (impl_method): `impl Type {}` 블록 + 메서드 호출 설탕
- ✅ 테스트 35, 36 (defer): `defer` 문 기본 구현 (블록 스코프, return 시 실행)
- ✅ 테스트 37 (shadowing): **변수 섀도잉** 완전 지원
- ✅ 테스트 38 (panic): `panic("msg")` 내장 함수 (stderr 출력 + exit(1))
- ✅ 전역 심볼 테이블 HashMap 전환 (O(1) lookup)

### v3_11 구조체 스위트 현황 (2026-01-13, 로컬)

- [x] `.` 멤버 접근: 34_struct_member
- [x] `->` 포인터 멤버 접근: 35_struct_arrow
- [x] 중첩 멤버 접근: 36_struct_nested
- [x] 다중 구조체 타입 선택: 37_struct_multiple
- [x] 다중 변수/루프/스트레스: 39~42
- [x] **함수 인자/호출 경계: 38_struct_function (Exit 42)**
- [x] **struct literal: 43~49 (모두 Exit 42)**
- [x] struct copy: 50~53, 55~58
- [x] linkedlist 계열: 59~67

**최신 테스트 결과 (2026-01-13)**: 69/69 PASS

### v3_13 리팩토링 메모 (2026-01-14)

- [x] `ast_literal()` 1건을 struct 기반으로 변경(레이아웃 유지) + 회귀 테스트 추가: 99_ast_literal_smoke
- [x] 개발일지(2026-01-14)에 `static`/`impl`/`enum` 설명 보강(Addendum)

### v3_15 타입 정보(TypeInfo) 리팩토링 메모 (2026-01-17)

- [x] `TypeInfo`를 40 bytes(5x u64)로 확장하고 `struct_def` 포함
- [x] `symtab`/`typeinfo`/`codegen`에서 TypeInfo 생성·저장을 40 bytes 구조체로 통일(16/24 bytes 트리플 제거)
- [x] `u64` 역순 탐색 루프(`while (i >= 0)`)를 `i64` 인덱스로 수정(언더플로우/무한 루프 방지)
- [x] 회귀 테스트 추가: `B/v3_15/test/b/92_typeinfo_member_chain.b` + 전체 테스트 PASS
- [x] switch 문자열 비교 개선: `str_eq` + `str_len` 기반 비교로 포인터 비교 버그 제거, `emitln` 적용으로 고정 문자열 길이 계산 오류 방지
- [x] 회귀 테스트 추가: `B/v3_15/test/b/77_switch_string.b` + 전체 테스트 PASS
- [x] StringBuilder 구현을 impl 기반으로 전환 (`StringBuilder.init/new/append_*`), 래퍼 API 유지 + 테스트 `97_string_builder` 갱신
- [x] `sb_append` 래퍼 추가로 간단한 append 호출 지원
- [x] 타입 파서 완화: type 위치의 식별자를 struct 타입으로 허용해 import된 struct(`StringBuilder`) 사용 가능

---

## 부트스트랩 핫픽스 (v3.6 컴파일러)

- [x] `else if` 문법 지원 (v3_7 소스 컴파일 중 파서 desync/크래시 해결)
- [x] **v3.6 셀프호스팅 완료** (2026-01-11)
  - [x] `idiv` → `div` (unsigned division) 변경으로 ASLR 환경 지원
  - [x] `emit` 함수 중복 제거 (io.b와 01_utils.b)
  - [x] v2c용 빌드와 selfhost용 빌드 분리
  - [x] Triple bootstrap 검증 완료 (selfhost == selfhost2 == selfhost3)

## v3.8 모듈화 (2026-01-14)

- [x] **v3.8 모듈 기반 컴파일러 생성** 
  - [x] `io.b` - 시스템 콜 및 메모리 할당 (102줄)
  - [x] `types.b` - 토큰/AST 상수 정의 (107줄)
  - [x] `vec.b` - 동적 배열 구현 (66줄)
  - [x] `util.b` - 문자열, 경로, 유틸리티 함수 (202줄)
  - [x] `hashmap.b` - 해시맵 구현 (230줄)
  - [x] `lexer.b` - 렉서 (287줄)
  - [x] `ast.b` - AST 노드 생성자 (261줄)
  - [x] `parser.b` - 파서 (730줄)
  - [x] `codegen.b` - x86-64 코드 생성기 (1050줄)
  - [x] `main.b` - 진입점 및 모듈 로딩 (190줄)
  - 총 10개 모듈, 약 3225줄 (원본 v3_7_ptr.b 4188줄에서 구조화)

- [x] v3.8 std 모듈 정리
    - [x] `std/str.b` 분리: `std/util.b`에서 문자열 유틸 구현 제거
    - [x] 하위 호환: `std/util.b`가 `import std.str;` 하도록 해서 기존 코드가 깨지지 않게 유지
    - [x] `std/path.b` 분리: `path_*`, `module_to_path`를 util에서 이동
    - [x] `std/char.b` 분리: `is_alpha/is_digit/is_alnum/is_whitespace`를 util에서 이동

- [x] v3.8 표현식/제어흐름 확장
    - [x] 비트 연산: `&`, `|`, `^`
    - [x] 쉬프트: `<<`, `>>`
    - [x] `continue;` 문
    - [x] 논리 단락평가: `&&`, `||` (조건식에서 RHS 평가 억제)
    - [x] 불리언 리터럴 키워드: `true`, `false`
    - [x] 문서([docs/v3_roadmap.md](v3_roadmap.md))에 맞춘 우선순위 정렬(`+ -` > `<< >>` > 비교/동등 > `& ^ |`)

- [x] v3.8 안정성 보강(최소)
    - [x] 파서 에러 진단: expected kind 실패 시 `line:col` + `lexeme` 출력
    - [x] 단락평가 회귀: RHS가 실행되면 크래시 나는 케이스 추가(26_short_circuit_no_eval)
    - [x] 큰 정수 리터럴 오버플로우: i64 범위 초과 시 위치/리터럴 포함 에러

- [x] repo 루트 `/test` 유닛 테스트 추가
    - [x] 러너: [test/run_v3_8.sh](../test/run_v3_8.sh)
    - [x] 케이스: bitwise/shift/continue + 우선순위 회귀 테스트

- [ ] 기존 v3.8 데모 테스트 스위트 정리
    - [x] [B/v3_8/test/run_tests.sh](../B/v3_8/test/run_tests.sh) 경로(`src/v3_8/test`)를 현재 구조로 갱신
    - [ ] [B/v3_8/test/*.b](../B/v3_8/test) import를 `std/*` 구조에 맞게 정리

- [x] v3.8 표현식/제어흐름 확장(추가)
        - [x] 증감 연산(문장 sugar): `x++; x--; ++x; --x;` (+ `for(...;...;i++)`)

---

## v3.9 티켓 (2026-01-11)

- [ ] v3.9 작업 목록: [docs/v3_9_todo.md](v3_9_todo.md)
- [ ] `++/--` 표현식 컨텍스트 지원(값 반환): `i = j++`, `x = ++j`, `f(j++)`
- [x] 선언+초기화 통합 리팩터링 기반 작업(보수적): var-init 타입 전파 수정 + self-host 검증 + 회귀 테스트 추가
- [ ] 선언+초기화 통합 리팩터링(본작업): 파일 단위로 `var x; x = expr;` → `var x = expr;` 전환 지속 (std/hashmap.b 완료, parser.b 진행 중)

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

- [ ] 키워드 토큰화(최소): `import enum struct func var const if else while for foreach switch break continue return`
- [ ] 연산자/구분자 토큰화(`&& || == != <= >= << >> ->` 포함)
- [ ] 정수/문자/문자열 리터럴 토큰 + 에러 리포팅
		- 현재: INT(10/16진), STRING("..."), CHAR('a', '\\n', '\\xNN' 등) 구현됨
- [ ] 스팬(span) 유지: 시작 오프셋 + 줄/컬럼
		- 현재: Token에 `start_off`(byte offset) + `line` + `col` 유지
- DoD
	- 키워드/연산자 경계 테스트(예: `a<<b`, `a < < b` 구분)
	- 최소 10개 입력에 대해 토큰 덤프(golden) 통과 (`test/v3_hosted/run_lexer_golden.sh`)

### 1.2 Parser → AST: 최소 문장/표현식
- [ ] AST 노드 정의(최소): Decl/Stmt/Expr/Type + Program
- [ ] Top-level: `import`, `const`, `var`, `enum`, `struct`, `func` decl 파싱
- [ ] 블록 스코프: `{ stmt* }` 파싱
- [ ] 표현식 파서(Phase 1.x): unary + binary(산술은 동일 우선순위, left-assoc), shift/비교/비트/논리
- [ ] 에러 복구(최소): `;`/`}` 싱크
- DoD
    - 파싱 실패 시 “최소 1개 진단 + 계속 진행” 동작
	- 예제 파일 5개 이상에서 AST 생성 성공 (`test/v3_hosted/run_parse_golden.sh`)

### 1.3 드라이버: 파일 로딩 + import 스캔
- [ ] “파일 선두 연속 import만” 의존성 스캔 규칙 구현
- [ ] 1파일=1모듈: 모듈명 = basename
- [ ] import가 top-level 연속 구간을 벗어나면 컴파일 에러
- DoD
    - import 위치 위반에 대한 스팬 포함 에러
    - 간단한 2파일 프로젝트 컴파일(의존성 순서 고정)

NOTE
	- golden runner 추가: `test/v3_hosted/run_import_scan_golden.sh`
	- 현재 P2 드라이버는 “scan-only”(의존성 순서 출력)로 유지
	- (참고) 과거에 파서와 함께 import 시 v2c segfault 이슈가 있었으나, 현재는 해결됨

### 1.4 최소 타입 체크(Phase 1용)
- [ ] `u64` 중심의 최소 타입 시스템(리터럴/산술 일부만)
- [ ] `cast(Type, expr)` AST 노드/타입 체크 뼈대
- DoD
    - `var x: u64 = 1 + 2;` 성공
    - 잘못된 타입 조합에 에러 1개 이상

NOTE
	- golden runner 추가: `test/v3_hosted/run_typecheck_golden.sh`

### 1.5 IR: 최소 IR + x86-64 코드젠 파이프라인
- [ ] IR 데이터 구조: Function/BasicBlock/Instr
- [ ] 최소 lowering: 산술, 로컬 변수, if/while, return
- [ ] x86-64 backend: 최소 코드젠 + asm 출력 + 링크/실행
- DoD
	- “hello/산술/루프”가 빌드/실행 가능 (`test/v3_hosted/run_codegen_golden.sh`)
	- IR 덤프 옵션(디버깅용) 제공 (`examples/v3_hosted/p4_codegen_smoke.b --dump-ir`)

NOTE
	- golden runner: `test/v3_hosted/run_codegen_golden.sh`

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
- [x] v3_16: 로컬 변수 선언/인덱싱(기본, bounds-check 없음)
- [x] v3_16: 파라미터/리턴/구조체 필드에서 `[]T` 지원
- [ ] 레이아웃: `[ptr:u64][len:u64]`(호환)
- [ ] 인덱싱 safe 기본 + unsafe 변형은 `$`로만(`a[$i]`)
- [ ] 포인터/슬라이스 변환: 암묵 없음, 명시적 `slice_from_ptr_len(p, n)` (builtin 또는 std)
- DoD
    - `[]u8`로 문자열 리터럴 lowering 동작
    - bounds-check 기본 동작 + `$` 사용 시 체크 생략

### 2.4 배열 타입 `[N]T` + 선언 init
- [ ] 타입 표기: `[N]T` 파싱/AST/타입체크
- [x] v3_16: 로컬 스택 배열 선언/인덱싱(단일 차원)
- [ ] 파라미터/리턴에서 `[N]T` 지원
- [x] v3_16: 구조체 필드에서 `[N]T` 지원
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
- [ ] struct 필드 타입/오프셋/정렬 계산 (offsetof로 검증)
- [ ] enum 값: `Color.Red` 형태 파싱/타입체크
- [ ] field 접근: `base.field`, `p->field`
- DoD
    - `offsetof(Type, field)`이 올바른 상수로 계산
	- struct 값 전달/리턴/대입이 동작 (현재: local-by-value 대입/초기화는 동작, 호출/리턴은 미구현)

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
	- `@[getter]` / `@[setter]`: 훅 함수 자동 생성
	- `@[getter(func)]` / `@[setter(func)]`: 지정 함수 호출

- [ ] lowering
	- 자동 생성: `p.hp = v` → `Player_set_hp(&p, v)` / `p.hp` → `Player_get_hp(&p)`
	- 지정 함수: `p.hp = v` → `func(&p, v)` / `p.hp` → `func(&p)`

- [ ] 자동 생성 이름(Struct 이름 prefix): `StructName_set_field`, `StructName_get_field`
	- 예: `struct Player { hp: u64 }` → `Player_set_hp`, `Player_get_hp`
	- 이름 충돌 시 에러

- [ ] raw access로 재귀 방지: `self.$hp` / `self->$hp`
- DoD
	- 훅 함수 시그니처 불일치 시 에러
	- `@[getter(func)]`/`@[setter(func)]`가 codegen golden에서 커버됨
	- raw access가 훅 우회를 보장(재귀 방지)

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
    - 인위적으로 레지스터 압박을 만들면 에러가 뜸

### 4.5 `@reg` (extern 전용)
- [ ] 파라미터/리턴 레지스터 어노테이션 파싱
- [ ] extern 함수에서만 허용(일반 함수는 에러)
    - extern 호출에서 지정 레지스터를 그대로 사용

### 4.6 보안/암호 연산자 lowering
- [ ] rotate: `<<<`, `>>>` (ROL/ROR)
- [ ] constant-time eq: `===`, `!==`
- DoD
    - 최소 1개 벡터 테스트(고정 입력)로 결과 검증

---

## Phase 5 — 편의/확장

### 5.1 제네릭(사용자 정의) + AST monomorphization
- [ ] 문법: `func f[T](x: T) -> T`, `struct Vec[T] { ... }` (파싱 구현됨)
- [ ] 인스턴스화: AST 단계 monomorph (기본 동작)
- DoD
    - [ ] 명시적 타입 인자: `id[u64](10)` 동작
    - [ ] 중복 인스턴스 캐시(동일 타입 인자) 동작

(타입 추론은 V4로 이동 - 사유: 복잡도, 테스트 19 실패 중)
(value generics는 V4로 이동 - 사유: comptime 의존성, 테스트 20/21/22 실패 중)
(named args는 V4로 이동 - 사유: parser 미구현, 테스트 23 실패 중)
(multi-return은 V4로 이동 - 사유: codegen 복잡도, 테스트 24 실패 중)
(constant folding/DCE는 V4로 이동 - 최적화는 MVP 범위 밖)
---

## Phase 6 — 추가 문법/표면 언어(Modern Surface Syntax)

### 6.1 복합 대입/증감 (Phase 1.2.1)
- [ ] 복합 대입: `+=`, `-=`, `*=`, `/=`, `%=`, `&=`, `|=`, `^=`, `<<=`, `>>=`
- [ ] 증감(문장 위치만): `x++;`, `x--;`
- DoD
    - [ ] `x += 1;`이 `x = x + 1;`로 lowering 확인

(불변 바인딩 `final`은 V4로 이동 - 사유: 타입 시스템 확장 필요)

### 6.2 enum 리터럴
- [ ] enum: `Color.Red` (구현됨)

(struct 리터럴은 V4로 이동 - 사유: typecheck 복잡도)

### 6.3 메서드/네임스페이스 (Phase 1.4)
- [ ] 메서드 호출 설탕: `x.f(y)` ↔ `f(x, y)` (typecheck에서 변환)
- [ ] `impl Type { ... }` 블록 (parser에서 `TypeName_method`로 rename)
- DoD
    - `x.add(y)`가 `add(x, y)` 호출로 lowering

### 6.4 자원 관리: `defer` (Phase 1.5)
- [ ] `defer <stmt>;` 파싱/AST
- [ ] 블록 스코프 종료 시 역순 실행
- [ ] return 시 실행 보장
- DoD
    - [ ] `defer free(p);`가 블록 종료 시 실행됨 (테스트 35, 36 통과)

(break/continue 시 defer 실행은 V4로 이동 - 사유: 제어 흐름 복잡도)

### 6.5 `print(args...)` 매직 함수

컴파일러가 `print(...)`를 인자 타입별로 자동 분해하는 편의 기능.

- [ ] 파싱: `print(expr, expr, ...)` → PRINT 문장
- [ ] 타입 체크: 각 인자의 타입 검증
- [ ] 코드젠: 인자 타입별로 `PRINT_U64`, `PRINT_SLICE` IR 자동 호출
- [ ] 지원 타입: `u64`, `[]u8` (문자열)
- DoD
    - [ ] `print("x = ", 42, "\n");` 형태로 여러 인자 출력 동작
    - [ ] 문자열은 PRINT_SLICE, 정수는 PRINT_U64로 lowering

(함수 포인터는 V4로 이동 - 사유: 타입 시스템 확장 필요)
(강제 Tail Call은 V4로 이동 - 사유: MVP 범위 밖)
(정수 비트 슬라이싱은 V4로 이동 - 사유: 암호/저수준 기능, MVP 범위 밖)
(Inline ASM 개선은 V4로 이동 - 사유: 고급 기능, MVP 범위 밖)
(어노테이션 시스템은 V4로 이동 - 사유: 메타프로그래밍, MVP 범위 밖)
(암호/알고리즘 Builtin Intrinsics는 V4로 이동 - 사유: 저수준 최적화, MVP 범위 밖)

### 6.6 타입 별칭 + distinct (Phase 2.1.5/2.1.6)
- [ ] `type Alias = T;` 별칭
- [ ] `type NewType = distinct T;` 강한 별칭
- [ ] distinct 타입 간 자동 변환 금지(명시적 cast만)
- DoD
    - `Key`와 `u64`를 섞어 쓰면 에러

---

## Phase 7 — 컴파일러 구조/품질

### 7.1 심볼 테이블 최적화 (Phase 6.2)

**전역 심볼: HashMap 전환 (완료)**
- [ ] 전역 심볼 테이블 HashMap 전환 (structs, enums, type_aliases, funcs)
- [ ] `put/get` 평균 O(1) (mod_id:name 복합 키)
- [ ] lookup 함수들에 HashMap 우선 조회 + fallback
- DoD
    - [ ] 전역 심볼 조회 O(1) 달성
    - 큰 모듈에서 심볼 조회 성능 개선 완료

**로컬 스코프: Vec 기반 역순 검색 + Shadowing (완료)**
- [ ] 역순 검색: `cg_local_find`를 역순 검색으로 변경 (뒤에서부터 찾음)
- [ ] collect 단계: 모든 VAR를 수집하고 AST(st+88)에 local 포인터 저장
- [ ] lower 전 truncate: params만 남기고 body vars 제거
- [ ] lower의 VAR: st+88에서 local 가져와서 활성 목록에 추가
- [ ] lower의 BLOCK: 진입 시 len 저장, 종료 시 truncate로 복원
- [ ] shadowing 지원: 같은 이름의 중첩 변수가 별도 슬롯 할당
- 자료구조: Vec 유지 (HashMap 전환 불필요 - 로컬 변수는 ~50개 미만)
- DoD
    - [ ] 중첩 블록에서 서로 다른 이름의 변수가 올바르게 동작 (테스트 37)
    - [ ] `{ var x = 1; { var x = 2; } }` shadowing 완전 지원 ✅


### 7.2 에러 리포팅 기초 (Phase 6.5)

**MVP 범위 (지금 해야 할 것):**
- [ ] AST에 위치 정보(`Span`) 저장: 파서가 토큰의 줄 번호를 AST 노드에 박아둨
- [ ] 컴파일 에러 출력: 타입 체크 실패 시 `"Error at line 10: ..."` 출력
- [ ] `panic("msg")` 내장 함수: stderr 출력 + 즉시 종료 (`exit(1)`) ✅
- DoD
    - [ ] 컴파일 에러에 줄 번호 포함
    - [ ] `panic` 호출 시 메시지 출력되고 종료 (테스트 38)

(런타임 스택 트레이스, ASM 위치 전파는 V4로 이동 - 사유: DWARF 등 복잡도)
### 7.2.5 부동소수점 타입 (Phase 6.6, v4 필수)

**v4 로드맵 구현에 필수**: v4의 GPU 벡터 연산, 조건부 컴파일 예제 등이 부동소수점을 사용하므로 v3에서 구현 필요.

- [ ] 타입 시스템 확장
    - [ ] `f32`, `f64` 타입 추가 (ast.b, typecheck.b)
    - [ ] 부동소수점 리터럴 파싱 (lexer.b): `3.14`, `1.0e-5` 형태
- [ ] 타입 체크
    - [ ] 산술/비교 연산 타입 규칙 (정수와 혼용 금지, 명시적 cast 필요)
    - [ ] 비교 연산 결과 타입: bool (정수 비교와 일관성 유지)
    - [ ] `cast(f32, int)`, `cast(i32, float)` 지원 (추후 구현)
- [ ] 코드젠
    - [ ] SSE2 명령어 생성 (`movss`, `addss`, `mulss`, `divss`, `cvtsi2ss`, `cvttss2si`)
    - [ ] XMM 레지스터 관리 (xmm0~xmm1 최소)
    - [ ] 비교 연산 (`comiss`, `comisd`) 결과를 bool로 스택에 푸시
- DoD
    - [ ] `var x: f32 = 3.14; var y = x + 1.5;` 컴파일/실행 성공
    - [ ] 테스트 케이스: 부동소수점 산술, 비교 연산 (50_float_basic, 51_float_comparison)

NOTE:
- 부동소수점 리터럴 파싱은 MVP 버전 (간소화된 비트 패킹, IEEE 754 완전 준수 아님)
- cast 연산은 추후 구현 예정

### 7.2.7 함수 포인터 타입 (Phase 6.7, v4 필수)

**v4 로드맵 구현에 필수**: v4의 콜백 패턴, 고차 함수, 리플렉션에서 타입 안전한 함수 포인터 필요.

- [ ] 타입 시스템 확장
    - [ ] `func(T, U) -> R` 타입 표기 파싱/AST
    - [ ] 함수 포인터 타입 정보 (파라미터 타입, 리턴 타입)
- [ ] 타입 체크
    - [ ] 함수 이름 → 포인터 변환 (주소 연산)
    - [ ] 함수 포인터 호출 시 시그니처 검증
    - [ ] 함수 포인터 대입 시 시그니처 일치 검사
- [ ] 코드젠
    - [ ] 함수 주소를 레지스터/메모리에 저장 (lea rax, [rel func_name])
    - [ ] 간접 호출 (`call rax` 형태)
- DoD
    - [ ] `var f: func(i64, i64) -> i64 = add;` 선언 동작
    - [ ] `var result = f(10, 20);` 간접 호출 동작
    - [ ] 테스트 케이스: 55_func_ptr (함수 포인터 호출, 재할당)
### 7.3 컴파일러 API 설계 (Phase 7)
- [ ] 메모리 상 소스 문자열 입력
- [ ] 메모리 상 asm/IR 덤프 출력
- [ ] 구조화된 diagnostics
- [ ] 상태 캡슐화(재진입성)
- DoD
    - 동일 프로세스에서 여러 번 컴파일 가능



---

## 부록: 빠른 스모크 예제(권장)

- [ ] Phase 1: 산술/if/while/함수 호출/return
- [ ] Phase 2: 포인터 null/unwrap_ptr, `[]u8` 문자열 리터럴, 배열 init
- [ ] Phase 3: struct 레이아웃 + foreach + packed
- [ ] Phase 4: secret/wipe/nospill
- [ ] Phase 5: 제네릭 타입 (value generics는 V4로 이동)
- [ ] Phase 6: 복합대입/증감, defer (struct 리터럴은 V4로 이동)
- [ ] Phase 7: panic 완료, 스택 트레이스는 V4로 이동

---

## v3_hosted 기능 확장 (2026-01-10)

**목표**: v3c_full이 bpp/*.bpp 파일을 컴파일할 수 있도록 기능 추가

### 완료된 작업

- [ ] import STRING: `import "path/to/file";` 문자열 경로 지원
- [ ] alias: `alias rax: name;` 레지스터 별칭
- [ ] asm 블록: `asm { ... }` 인라인 어셈블리
- [ ] DROP IR: alias 레지스터 보존용 스택 버리기

### 남은 작업

- [ ] bpp/*.bpp v3 문법 재작성
- [ ] v3c_full 셀프호스팅 테스트
