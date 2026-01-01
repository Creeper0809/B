# TODO (roadmap 기반, 의존성 우선순위 + P별 스모크 테스트)

이 문서는 [docs/roadmap.md](docs/roadmap.md)의 항목을 **선행 의존성에 따라 재정렬**한 작업 목록입니다.
스모크 테스트는 **각 P(단계) 완료 조건**으로 포함합니다.

원본/작업 문서: [docs/todo.md](docs/todo.md)

---

(루트 todo는 docs/todo.md와 동일 내용을 유지합니다)

## P0 — 부트스트랩 기반 (없으면 다음 단계가 막힘)

- [x] ABI: 스택 프레임 & 16바이트 정렬 규칙 확정/구현
  - Depends on: 없음
  - 포함: prologue/epilogue, call 직전 정렬, red zone 미사용

- [x] ABI: 레지스터 정책(스크래치/칼리세이브) 운영 방식 확정
  - Depends on: ABI 스택 프레임
  - 참고: MVP에서는 callee-saved 사용 최소화(roadmap 원문)
  - v1 메모: docs/v1-abi.md에 결정사항 반영

- [x] std.b (0단계): OS 래퍼 + 실패 경로
  - Depends on: 없음
  - 포함: `sys_exit`, `sys_write`, `sys_open`, `sys_read`, `sys_close`, `sys_fstat`, `sys_brk`, `panic`, `panic_at`
  - [x] v1: `panic()`/`panic_at()` 구현 (src/v1/std/std0_sys.b)
  - [x] v1: `sys_exit/sys_write/sys_open/sys_read/sys_close/sys_fstat` 사용 가능 (Stage1 runtime builtins)
  - [x] v1: `sys_brk()` 구현 (src/v1/std/std0_sys.b)

- [x] P0 스모크 테스트: syscall 래퍼 최소 동작 확인
  - Depends on: ABI 스택 프레임 & 16바이트 정렬 규칙, std.b (0단계)
  - 제안: `sys_write(1, "OK\n", 3)` 출력 후 `sys_exit(0)`
  - v1: test/v1/run_smoke_p0.sh
  - v1(추가): panic 스모크 test/v1/run_smoke_p0_panic.sh
  - v1(추가): brk 스모크 test/v1/run_smoke_p0_brk.sh

## P1 — 메모리/문자열 유틸 + 코어 자료구조

- [x] std.b (1단계): 메모리/문자열/숫자 유틸
  - Depends on: std.b (0단계)
  - 포함: `heap_alloc`, `memcpy`, `memset`, `strlen`, `streq`, `itoa`, `atoi`, `str_concat`, `slice_to_cstr`
  - v1 구현 계획(현 Stage1 runtime 기준)
    - [x] `heap_alloc/memcpy/strlen/streq`는 Stage1 runtime builtins로 우선 사용
    - [x] `memset` (v1에서 직접 구현)
    - [x] `itoa` (v1: `itoa_u64_dec(x)` 구현, 반환: `rax=ptr`, `rdx=len`)
    - [x] `atoi` (v1: `atoi_u64(ptr,len)` + Slice/ panic 래퍼 완료)
    - [x] `str_concat` (v1: `str_concat(p1,n1,p2,n2)` 구현, 반환: `rax=ptr`, `rdx=len`)
    - [x] `slice_to_cstr` (v1: `slice_to_cstr(ptr,len)` 구현, 반환: `rax=ptr`)

- [x] 공용 자료구조 (2단계): Slice
  - Depends on: std.b (1단계) (최소 `memcpy/memset/strlen` 계열)
  - 포함: `layout Slice { ptr; len; }`, `slice_eq`
  - [x] v1: `layout Slice` 확정 (ptr/len)
  - [x] v1: `slice_eq` 구현 (v1: `slice_eq_parts(ptr,len,ptr,len)`)

- [x] 공용 자료구조 (2단계): Vec (push-only, u64 원소)
  - Depends on: std.b (1단계), Slice
  - 포함: `layout Vec { ptr; len; cap; }`, `vec_init`, `vec_push`, `vec_get`, `vec_len`
  - [x] v1: `layout Vec` 확정 (ptr/len/cap)
  - [x] v1: `vec_init(cap)` (v1: `vec_new(cap)` 구현)
  - [x] v1: `vec_push(vec*, item)` (cap 부족 시 2배 확장 + memcpy)
  - [x] v1: `vec_get/vec_len` 구현

- [x] 라벨 생성기 (2단계): label_gen
  - Depends on: std.b (1단계), Slice (그리고 보통 str_concat/itoa)
  - 포함: `label_counter`, `label_next() -> Slice`
  - [x] v1: `label_counter` 전역
  - [x] v1: `label_next()` (counter++ + itoa + 접두사 결합)

- [x] P1 스모크 테스트: heap/문자열/Vec 기본 기능 확인
  - Depends on: std.b (1단계), Slice/Vec/label_gen
  - 제안: `heap_alloc`으로 버퍼 확보 → `memset/memcpy` → `strlen/streq` 확인, Vec에 push 후 len/get 확인
  - 산출물: test/v1/run_smoke_p1.sh (std0+std1+core를 concat해서 실행)

## P2 — 입력/출력 파이프라인 (컴파일러 드라이버의 입출력)

- [x] 파일 입력 (3단계): `read_file(path) -> Slice`
  - Depends on: std.b (0단계), std.b (1단계), Slice

- [x] emitter.b (4단계): 출력 버퍼 + `.asm` 저장
  - Depends on: std.b (0단계), std.b (1단계), Slice
  - 포함: `emit_init`, `emit_str`, `emit_u64`, `emit_flush`, `emit_to_file`

- [x] P2 스모크 테스트: 파일 읽기/쓰기 왕복 확인
  - Depends on: `read_file`, emitter.b
  - 제안: README를 `read_file`로 읽어 길이 확인 → emitter로 임시 파일 저장 → 성공 로그 출력

## P3 — 렉서/토큰/심볼 (파서 이전 필수)

- [x] token.b / lexer.b (5단계): 토큰 정의
  - Depends on: Slice, Vec
  - 포함: ident/int/string/char, 연산자(+ - * / % 등), 비교/비트, 구분자, 키워드, `&&/||`, `->`

- [x] token.b / lexer.b (5단계): 렉서 기능
  - Depends on: `read_file`, token 정의, std.b 유틸(escape/atoi 등)
  - 포함: line_num 추적, `//` 주석, 문자열/문자 escape, `asm { ... }` raw 처리, longest-match

- [x] symbol.b (6단계): 심볼 테이블(초기 Vec+선형탐색)
  - Depends on: Slice, Vec
  - 포함: `layout Symbol`, `SYM_VAR`, `SYM_ALIAS`, `SYM_CONST`

- [x] P3 스모크 테스트: 렉서가 대표 입력을 토큰화
  - Depends on: token/lexer, symbol
  - 제안: 주석+정수/문자/문자열+`asm{}` 포함 샘플을 토큰화하고 토큰 종류/line_num을 출력

## P4 — 파서 뼈대 + 선언/스코프 (문장/식 이전 기반)

- [x] parser.b (7단계): 프로그램/선언/함수 뼈대
  - Depends on: lexer, symbol, emitter, ABI(스택 프레임)
  - 포함: `parse_program`, `parse_var_decl`, `parse_var_array_decl`, `parse_alias_decl`, `parse_func_decl`, 함수 종료 시 Scope Reset

- [x] P4 스모크 테스트: 최소 프로그램 파싱/에밋
  - Depends on: parser.b
  - 제안: `var g; func main(){ var x; }` 입력을 파싱해 `.asm` 생성 여부 확인

## P5 — 수식/조건/문장 (언어 기능 확장 코어)

- [x] expr.b (8단계): 수식 파서(재귀 하강, 우선순위)
  - Depends on: parser 뼈대(토큰 소비 구조), symbol(식별자), emitter(코드 생성 규칙)
  - 순서: bor → bxor → band → equality → relational → shift → additive → term → unary → factor

- [x] 조건 파서 (9단계): `&&/||` 단락평가
  - Depends on: expr.b, label_gen, emitter
  - [x] v1: `parse_cond_emit_jfalse`, cond_atom/not/and/or (short-circuit)
  - [x] 스모크: test/v1/run_smoke_p6.sh

- [x] stmt (10단계): if/while/break/continue/return + 대입/표현식 문장
  - Depends on: 조건 파서, expr.b, label_gen, emitter
  - [x] v1: `stmt_if`, `stmt_while`, `stmt_break`, `stmt_continue`, `stmt_return`, `stmt_expr`
  - [x] v1: `stmt_assign`
  - [x] 스모크: test/v1/run_smoke_p7.sh

- [x] P5 스모크 테스트: expr/조건/루프 코드젠 확인
  - Depends on: expr/cond/stmt
  - 제안: 샘플(연산 + if/while)을 컴파일해 라벨/점프/연산 emit이 나오는지 확인

## P6 — 함수 인자/호출 + 드라이버/자기호스팅

- [x] 함수 인자/호출(11단계): ABI 연동
  - Depends on: ABI(인자 레지스터/스필), parser.b(함수/스코프), expr/stmt(호출 인자 파싱에 필요할 수 있음)
  - 포함: `parse_func_args`, `emit_func_prologue_args`, `emit_call`

- [x] 드라이버/부트스트랩/셀프호스팅(11단계)
  - Depends on: `read_file`, lexer→parser→emitter end-to-end, `emit_to_file`
  - 포함: `main.b` argv 루프, Bootstrap(basm으로 basm2), Self-host(basm2로 basm3), 결과 비교

- [x] P6 스모크 테스트: end-to-end 컴파일/실행
  - Depends on: 함수 인자/호출, 드라이버
  - 제안: 예제 1개를 컴파일→NASM/ld 링크→실행해 기대 출력 확인
