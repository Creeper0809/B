## **ABI**

### **스택 프레임 & 정렬**

**함수 Prologue**

- [ ]  push rbp — 이전 스택 프레임 저장
- [ ]  mov rbp, rsp — 현재 스택 프레임 베이스 설정
- [ ]  sub rsp, ALIGNED_SIZE — 로컬 변수 공간 확보 (16바이트 단위 정렬)

**함수 Epilogue**

- [ ]  leave — 스택 포인터(rsp)를 rbp로 복구하고, 이전 rbp를 pop (지역변수 자동 정리)
- [ ]  ret — 스택의 Return Address를 꺼내 해당 위치로 점프

**스택 정렬 (SysV 변형/참고)**

- [ ]  16바이트 정렬 — 로컬 변수 총 크기를 16의 배수로 올림
- [ ]  SysV 규칙 — Call 직전 RSP%16==8 (미정렬), 진입 후(RIP Push후) RSP%16==0 (정렬됨)
- [ ]  MVP에서는 red zone 미사용

### **레지스터 정책**

- [ ]  **Scratch Registers:** rax, rcx, rdx, rsi, rdi, r8~r11 (함수 호출 후 값 보장 안 됨, 필요시 호출 전 push)
- [ ]  **Callee-saved:** rbx, r12~r15 (사용하려면 Prologue에서 저장 후 Epilogue에서 복구, MVP에선 사용 안 함 권장)

### **인자 전달**

- [ ]  순서: rdi, rsi, rdx, rcx, r8, r9
- [ ]  Arg Spill: 진입 즉시 [rbp-8]...에 저장

## **0단계: std.b — OS 래퍼 + 실패 경로**

- [ ]  sys_exit(code) — 프로세스 종료
- [ ]  sys_write(fd, buf, len) — 파일/터미널에 바이트 출력
- [ ]  sys_open(path, flags, mode) — 파일 열기(또는 생성) 및 fd 획득
    - path는 반드시 NUL-terminated C-String이어야 함
- [ ]  sys_read(fd, buf, len) — fd에서 바이트 읽기
    - **sys_open:** Flags = 0 (O_RDONLY). Mode = 0 (읽기라 무관).
    - **sys_fstat:** struct stat은 144바이트지만 우리에게 필요한 **파일 크기는 오프셋 48**에 위치. (Linux x86-64 기준)
    - **Read Loop:** 파일이 4096바이트보다 크면 OS가 끊어서 줄 수 있다. while (total < size) 루프가 필수
- [ ]  sys_close(fd) — 열린 fd 닫기
- [ ]  sys_fstat(fd, stbuf) — 파일 크기/종류 정보 획득(파일 전체 읽기에 유리)
- [ ]  sys_brk(addr) — 힙 경계 조절(bump allocator용)
- [ ]  panic(msg) — 에러 메시지 출력 후 sys_exit(1)로 즉시 종료
- [ ]  panic_at(line, msg) — 라인 번호 포함 에러 출력(디버깅 효율화)

---

## **1단계: std.b — 메모리/문자열/숫자 유틸**

- [ ]  heap_alloc(n) — free 없는 bump allocator로 메모리 확보
- [ ]  memcpy(dst, src, n) — 메모리 블록 복사
- [ ]  memset(dst, byte, n) — 메모리 블록을 특정 값으로 채움
- [ ]  strlen(s) — C 문자열 길이 산출
- [ ]  streq(a, b) — C 문자열 동일성 비교
- [ ]  itoa(x) -> (ptr,len) — 정수를 10진 문자열로 변환(라벨/디버그 출력용)
    - heap_alloc을 사용
- [ ]  atoi(s) -> 10진수/16진수(0x...) 문자열을 정수로 변환.
    - **입력:** Slice
    - **포맷:**
        - 10진수 (123)
        - 16진수 (0xFF, 0x 접두사 처리)
        - **부호 미지원:** 음수는 렉서/파서 레벨에서 단항 연산자  + 양수로 처리
    - **실패 시:** panic("Invalid number format") 호출.
- [ ]  **str_concat(s1, s2) -> Slice** label_gen용
- [ ]  **slice_to_cstr(s) -> ptr** — sys_open용

---

## **2단계: 공용 자료구조(부트스트랩 코어)**

### 2.1 Slice(문자열 슬라이스)

- [ ]  layout Slice { ptr; len; } — 원본 문자열 복사 없이 "부분 참조"
- [ ]  slice_eq(s1, s2) — 두 슬라이스 동일성 비교(len+memcmp)

### 2.2 Vec(push-only 동적 배열)

> Vec 원소 규약 — Vec는 u64 원소만 저장
> 
- [ ]  layout Vec { ptr; len; cap; } — 계속 늘어나는 리스트(토큰/심볼/라벨스택) 저장
- [ ]  vec_init(cap) — 초기 용량으로 Vec 생성
- [ ]  vec_push(vec*, item) — 끝에 추가, 용량 부족 시 2배 확장 후 이전
- [ ]  vec_get(vec*, i) — i번째 원소 반환
- [ ]  vec_len(vec*) — 현재 길이 반환

### 2.3 label_gen(라벨 생성기)

- [ ]  label_counter — 유니크 라벨 생성용 전역 카운터
- [ ]  label_next() -> Slice — L_1, L_2... 형태 라벨 문자열 생성

---

## **3단계: 파일 입력(소스 로딩)**

- [ ]  read_file(path) -> Slice — 파일 전체를 메모리에 읽어 (ptr,len) 반환

---

## **4단계: emitter.b — 출력 버퍼 + .asm 저장**

- [ ]  emit_init() — 1MB 출력 버퍼 사전 확보
- [ ]  emit_str(ptr, len) — 버퍼에 문자열 추가
- [ ]  emit_u64(x) — 숫자를 문자열로 변환하여 버퍼에 추가
- [ ]  emit_flush(fd) — 버퍼 내용을 fd에 write 후 버퍼 초기화
- [ ]  emit_to_file(path) — .asm 파일 열기 및 flush로 저장
    - **Flags:** O_CREAT | O_TRUNC | O_WRONLY
        - 소스 코드 최상단에 상수로 작성
    - **Mode:** 0644 (rw-r--r--)

---

## **5단계: token.b / lexer.b — 토큰화(+ asm 블록)**

### 5.1 토큰 정의

- [ ]  TOK_IDENT — 식별자 토큰
- [ ]  TOK_INT — 정수 리터럴(10진/16진) 토큰
- [ ]  TOK_STRING — 문자열 리터럴 토큰
- [ ]  TOK_CHAR — 문자 리터럴 토큰
- [ ]  연산자:
    - [ ]  산술: +, -, *, /, %
    - [ ]  비교: ==, !=, <, >, <=, >=
    - [ ]  비트: &, |, ^, ~, <<, >>
- [ ]  키워드 토큰들 — func/var/alias/if/else/while/break/continue/return 등 구분
- [ ]  TOK_ANDAND(&&), TOK_OROR(||) — 조건문 전용 단락평가 연산자 토큰
- [ ]  비교 연산 토큰들 — 표현
- [ ]  구분자 토큰들 — (){}[];,. 등 표현
- [ ]  TOK_ARROW(->) — 포인터 멤버 접근 토큰(나중에 struct에서 사용)

### 5.2 렉서 기능

- [ ]  line_num 추적 — 에러 위치 출력을 위한 줄 번호 계산
- [ ]  주석 처리 (//) — 줄바꿈(\n)이 나올 때까지 렉싱 스킵
- [ ]  문자열 escape 처리 — \\n \\t \\0 \\\\ \\\" 등을 실제 바이트로 변환
- [ ]  문자 escape 처리 — \\n \\t \\0 \\\\ \\' 등을 실제 바이트로 변환
- [ ]  asm { ... } raw 토큰 — 중괄호 내부를 해석 없이 문자열로 저장

규칙 :

- **Longest Match** (&&는 &보다 먼저 매칭, ->는 -보다 먼저)

---

## **6단계: symbol.b — 심볼 테이블(초기: Vec + 선형탐색)**

- [ ]  layout Symbol { kind; name:Slice; ... } — 이름과 종류/값 결합 저장
- [ ]  SYM_VAR — 지역변수 스택 오프셋 저장
- [ ]  SYM_ALIAS — 별칭 레지스터 ID 저장
- [ ]  SYM_CONST — 상수값(레이아웃 오프셋 등) 저장

---

## **7단계: parser.b — 선언/함수 뼈대**

- [ ]  parse_program() — top-level 순회하며 선언 처리
- [ ]  parse_var_decl() — var x; 파싱 및 스택 확보
- [ ]  parse_var_array_decl() — var buf[16]; 형태 배열 스택 공간 확보
- [ ]  parse_alias_decl() — alias rax : tmp; 형태 레지스터 별칭 등록
- [ ]  parse_func_decl() — 함수 시그니처/바디 파싱 및 코드 생성 시작
- [ ]  Scope Reset — 함수 파싱 종료 시 지역 심볼 테이블 초기화
    - 함수 시작 시 len_saved = symbol_vec.len 저장
    - 함수 끝날 때 symbol_vec.len = len_saved 로 복구

---

## **8단계: expr.b — 수식 파서**

> 복잡한 수식 (예 var a = 1 << (1 + 6) * 10)등을 처리할 수 있어야함 → 재귀 하강 파서 필요
> 

우선순위는 위에서 아래로

- [ ]  parse_bor () — | 비트 OR
- [ ]  parse_bxor () — ^비트 XOR
- [ ]  parse_band () — &비트 AND
- [ ]  parse_equality() — == != 우선순위 처리
- [ ]  parse_relational() — < > <= >= 우선순위 처리
- [ ]  parse_shift() ****— <<, >>
- [ ]  parse_additive() — + - 우선순위 처리
- [ ]  parse_term() — / * % 우선순위 처리
- [ ]  parse_unary() — ! - &(참조) ~ 단항 연산 처리
- [ ]  parse_factor() — 숫자/식별자/괄호/ptr8[]/ptr64[] 원자식 처리 + 함수 호출

---

## **9단계: 조건 파서 — 조건문 전용 &&/|| 단락평가**

- [ ]  parse_cond_emit_jfalse(target) — 조건 false 시 target으로 점프하는 코드 생성
- [ ]  cond_atom — expr <cmp> expr 또는 (cond) 최소 조건 단위 파싱
- [ ]  cond_not — !cond 처리하여 조건 반전(선택사항이나 유용)
- [ ]  cond_and (A && B) — A false 시 즉시 실패로 점프, true일 때만 B 평가
- [ ]  cond_or (A || B) — A true 시 B 스킵하고 성공 흐름 진행, false일 때만 B 평가(라벨 필요)
    - cond_or는 skip 라벨 1개 생성해서 A가 true면 B 평가를 스킵

---

## **10단계: stmt — if/while/break/continue/return**

- [ ]  stmt_if() — 조건 평가 및 then/else/else-if 흐름 생성
- [ ]  stmt_while() — 루프 start/end 라벨 생성 및 스택 관리(push/pop)
- [ ]  stmt_assign() — a = b 형태의 **단순 대입**
- [ ]  stmt_break(num) — 스택에서 num번째 상위 end 라벨 찾아 탈출 점프 (기본값 1)
- [ ]  stmt_continue() — 스택에서 num번째 상위 start 라벨 찾아 복귀 점프 (기본값 1)
- [ ]  stmt_return() — rax에 반환값 배치 및 함수 종료 흐름 생성
- [ ]  stmt_expr(): 대입 없이 식(함수 호출 등)만 있는 문장 처리 (ident 뒤에 (가 오면 호출로 처리).
    - parse_expr() 호출 후 결과값(rax) 무시 및 세미콜론 소비

---

## **11단계: 함수 인자/호출(ABI) + 드라이버/부트스트랩**

- [ ]  parse_func_args() — func add(a,b) 형태 인자 선언 파싱
- [ ]  emit_func_prologue_args() — rdi,rsi,... 인자를 로컬 변수 슬롯으로 저장하는 코드 생성
- [ ]  emit_call(name) — 인자를 ABI 레지스터에 배치 및 call 출력
- [ ]  main.b 파일 루프 — argv로 받은 여러 소스 순회하며 컴파일
- [ ]  Bootstrap — 기존 basm으로 basm2 컴파일
- [ ]  Self-host — basm2로 basm3 컴파일 및 결과 비교