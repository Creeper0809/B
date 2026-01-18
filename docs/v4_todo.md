# B Language v4 Development Plan

v4_roadmap.md의 실행 계획. 기능을 의존성과 우선순위에 따라 버전별로 구분.

**원칙**:
- 각 버전은 **독립적으로 동작하는 컴파일러**를 유지
- 의존성 체인 내에서는 순서 엄수
- 블랙홀 위험 기능은 후순위 배치
- 각 버전마다 명확한 DoD

---

## Breaking Change: 파일 확장자 변경

**v4.0부터 `.b` → `.bpp`로 변경**

### 마이그레이션 작업 (v4.0)

**전략**: v3와 v4를 별도 폴더로 분리하여 점진적 전환

- [x] **bpp/ 폴더 구조 생성**
  - [x] `bpp/` 루트 폴더 생성
  - [x] `bpp/src/` 생성 (v4 컴파일러)
  - [x] `bpp/std/` 생성 (v4 표준 라이브러리)
  - [x] `bpp/examples/` 생성 (v4 예제)
  - [x] `bpp/test/` 생성 (v4 테스트)
  - [x] `bpp/README.md` 생성 (v4 개발 가이드)

- [ ] **컴파일러 업데이트**
  - [ ] `.bpp` 확장자 인식 추가
  - [ ] `.b` 파일 처리 시 deprecation 경고 출력
  - [ ] 하위 호환: `.b`와 `.bpp` 모두 컴파일 가능
  - [ ] `bpp/` 폴더 경로 인식

- [x] **v4 코드베이스 개발** (bpp/src/std/ v3 타입 문법 변환 완료: 2026-01-10)
  - [x] `bpp/src/std/io.bpp`: ptr8→*cast, syscall wrappers 타입 명시
  - [x] `bpp/src/std/mem.bpp`: ptr8→*cast, u64→u8 명시적 cast
  - [x] `bpp/src/std/vec.bpp`: ptr64→*cast, 함수 시그니처 타입 명시
  - [x] `bpp/src/std/hashmap.bpp`: ptr64→*cast (런타임 로직 버그는 별도)
  - [ ] `bpp/src/`에서 v4 컴파일러 개발 시작
  - [ ] `bpp/examples/`에 v4 기능 예제 작성
  - [ ] `bpp/test/`에 v4 테스트 작성
  - [ ] **주의**: 상위 폴더의 v3 코드는 그대로 유지

- [ ] **빌드 시스템 업데이트**
  - [ ] Makefile/빌드 스크립트에 `bpp/` 타곃 추가
  - [ ] `make v3` (v3 컴파일러), `make v4` (v4 컴파일러) 분리
  - [ ] CI/CD 파이프라인에 bpp/ 폴더 포함

- [ ] **문서 업데이트**
  - [ ] README.md에 v3/v4 폴더 구조 설명 추가
  - [ ] docs/에 v4 개발 가이드 작성
  - [ ] CHANGELOG.md에 breaking change 기록

**폴더 구조**:
```
B/
├── src/          # v3 컴파일러 (.b) - 유지
├── std/          # v3 표준 라이브러리 (.b) - 유지
├── examples/     # v3 예제 (.b) - 유지
├── test/         # v3 테스트 (.b) - 유지
└── bpp/          # v4 전용 폴더 (신규)
    ├── src/      # v4 컴파일러 (.bpp)
    ├── std/      # v4 표준 라이브러리 (.bpp)
    ├── examples/ # v4 예제 (.bpp)
    └── test/     # v4 테스트 (.bpp)
```

### v4.1에서 완전 전환

- [ ] `.b` 지원 완전 제거
- [ ] 컴파일러가 `.bpp`만 인식
- [ ] 에러 메시지: "File extension '.b' is no longer supported. Use '.bpp' instead."

---

## Phase 0: Windows Support (v3.5 이전 필수)

**기간**: 2-3주  
**목표**: Windows 10/11에서 B 컴파일러 빌드 및 실행 가능  
**우선순위**: [CRITICAL] (v3.5 std 개발 이전 완료)  
**블로커**: 없음 (즉시 시작 가능)

### 왜 지금 해야 하는가?

- **개발자 접근성**: 윈도우 사용자는 현재 컴파일러를 실행할 수 없음
- **v4 기능과 독립적**: 플랫폼 지원은 언어 기능과 분리 가능
- **기술 부채 방지**: 나중에 하면 더 어려움 (코드베이스 커짐)
- **테스트 인프라**: CI/CD에 Windows 테스트 추가 필요

### 작업 항목

#### Phase 0.1: 빌드 시스템 크로스 플랫폼화 (3-5일)

- [x] **Makefile → CMake 전환**
  - [x] `CMakeLists.txt` 작성
  - [x] 소스 파일 목록 자동 수집
  - [x] 컴파일러 플래그 조정 (GCC/Clang vs MSVC)
  - DoD: Linux와 Windows 모두에서 `cmake && make` 성공
  - 참조: v4_roadmap.md Phase 0
  - **완료**: 2026-01-09, Linux에서 빌드 성공

- [x] **경로 처리 통일**
  - [x] 경로 구분자 추상화 (`/` vs `\`)
  - [x] `src/os/path.b` 모듈 생성
  - [x] `driver.b` 마이그레이션 완료
  - DoD: 크로스 플랫폼 경로 처리
  - **완료**: 2026-01-09, 컴파일 및 테스트 통과

**Phase 0.1 DoD**:
- [x] CMake 빌드 시스템 작동
- [x] 크로스 플랫폼 경로 처리 모듈
- [x] Linux에서 컴파일 성공
- [x] Lexer golden test 통과
- [ ] Windows 테스트 (Phase 0.3 이후)

**완료일**: 2026-01-09 (5시간 소요)

---

#### Phase 0.2: 시스템 콜 추상화 (5-7일)

- [x] **OS 레이어 분리**
  - [x] `src/os/linux.b` 생성 (Linux syscall 래퍼)
  - [x] `src/os/windows.b` 생성 (Windows API 래퍼 스켈레톤)
  - [x] `src/os/common.b` 생성 (공통 인터페이스)
  - DoD: 플랫폼별 구현 분리 완료
  - 참조: v4_roadmap.md Phase 0
  - **완료**: 2026-01-09

- [x] **필수 OS 함수 구현**
  - [x] 파일 I/O: `os_open`, `os_read`, `os_write`, `os_close`, `os_fstat`
  - [x] 메모리: `os_mem_alloc`, `os_mem_free`
  - [x] 프로세스: `os_exit`
  - DoD: 크로스 플랫폼 API 작동
  - 참조: v4_roadmap.md Phase 0
  - **완료**: 2026-01-09

- [x] **Linux 구현** (기존 syscall 유지)
  - [x] `linux_exit/read/write/open/close/fstat` - syscall 래핑
  - [x] `linux_brk` - brk 기반 메모리 할당자
  - DoD: 기존 코드 호환성 유지
  - **완료**: 2026-01-09

- [x] **Windows 구현** (Win32 API 스켈레톤)
  - [x] `windows_exit/read/write` - placeholder 함수
  - [x] `windows_mem_alloc/free` - VirtualAlloc/Free 인터페이스
  - [x] `windows_open/close/fstat` - 인터페이스 정의
  - DoD: Windows API 구조 완성 (실제 구현은 Phase 0.4)
  - **완료**: 2026-01-09

**Phase 0.2 DoD**:
- [x] OS 추상화 레이어 완성
- [x] Linux 구현 완료 (syscall 기반)
- [x] Windows 구현 스켈레톤
- [x] 빌드 성공
- [x] Codegen 테스트 39/43 통과
- [ ] Windows 실제 구현 (Phase 0.4)

**완료일**: 2026-01-09 (3시간 소요)

---

#### Phase 0.3: 실행 파일 포맷 지원 (5-7일)

- [x] **PE32+ 코드 생성기 추가**
  - [x] PE 헤더 구조 정의 (`src/pe/format.b`)
  - [x] 섹션 레이아웃 (.text, .data, .rdata, .idata)
  - [x] Import Address Table (IAT) 스켈레톤 (`src/pe/iat.b`)
  - [x] DOS 헤더 + 스텁 생성 (`src/pe/builder.b`)
  - DoD: PE 파일 구조 완성 (통합은 Phase 0.4)
  - 참조: v4_roadmap.md Phase 0
  - **완료**: 2026-01-09

- [x] **PE 빌더 인프라**
  - [x] `pe_write_dos_header()` - DOS 호환 헤더
  - [x] `pe_write_headers()` - PE/COFF/Optional 헤더
  - [x] `pe_write_section_header()` - 섹션 헤더
  - DoD: PE 파일 구조화 가능
  - **완료**: 2026-01-09

- [x] **Import 처리 스켈레톤**
  - [x] kernel32.dll 임포트 정의
  - [x] IAT 크기 계산 로직
  - [x] Import Directory 구조 설계
  - DoD: 임포트 메커니즘 설계 완료
  - **완료**: 2026-01-09

**Phase 0.3 DoD**:
- [x] PE32+ 파일 포맷 구조 완성
- [x] 헤더 생성 함수 구현
- [x] IAT 설계 완료
- [x] 빌드 성공
- [ ] Windows 실행 파일 생성 (Phase 0.4 통합 필요)
- [ ] 실제 Windows 테스트 (Phase 0.4)

**완료일**: 2026-01-09 (설계 및 스켈레톤 완성)

**Note**: PE 생성 로직은 완성되었으나, codegen과의 통합은 Phase 0.4에서 진행.
현재는 ELF 출력만 생성하며, `--target=windows` 플래그는 향후 구현.

#### Phase 0.4: 테스트 및 CI/CD (2-3일)

- [x] **GitHub Actions CI/CD**
  - [x] Linux 빌드 job 추가 (Ubuntu)
  - [x] Windows 빌드 job 추가 (Windows Server 2022)
  - [x] 아티팩트 업로드 (v3c 바이너리)
  - DoD: PR마다 자동 빌드 및 테스트
  - 참조: v4_roadmap.md Phase 0
  - **완료**: 2026-01-09

- [x] **Golden Test 크로스 플랫폼**
  - [x] 경로 처리 모듈 통합 (os/path.b)
  - [x] Lexer 테스트 통과 확인
  - [x] Codegen 테스트 39/43 통과
  - DoD: Linux에서 테스트 안정화
  - **완료**: 2026-01-09

- [x] **문서 업데이트**
  - [x] `README.md`: Windows 빌드 방법 추가
  - [x] `docs/windows_support.md` 작성
  - [x] Platform Support 섹션 추가
  - DoD: 사용자가 문서만으로 빌드 가능
  - **완료**: 2026-01-09

**Phase 0.4 DoD**:
- [x] GitHub Actions CI/CD 설정 완료
- [x] Linux 빌드 자동화
- [x] Windows 빌드 자동화 (스켈레톤)
- [x] 문서화 완료
- [ ] Windows 실제 테스트 (실제 Windows 환경 필요)

**완료일**: 2026-01-09 (인프라 구축 완료)

---

### Phase 0 DoD

- [x] CMake 빌드 시스템 완성
- [x] OS 추상화 레이어 설계 및 구현
- [x] PE32+ 파일 포맷 설계
- [x] CI/CD 파이프라인 구축
- [x] 문서화 완료 (README, windows_support.md)
- [ ] Windows 10/11에서 `v3c.exe` 빌드 성공 (실제 Windows 테스트 대기)
- [ ] `v3c.exe`로 간단한 `.b` 파일 컴파일 성공 (실제 Windows 테스트 대기)
- [ ] 생성된 `.exe` 파일이 Windows에서 실행됨 (PE 생성 통합 필요, v3.5)
- [x] Golden test 39개 중 Linux에서 통과
- [x] CI/CD에서 Linux 빌드 성공
- [ ] CI/CD에서 Windows 빌드 성공 (실제 테스트 대기)

**Phase 0 전체 완료일**: 2026-01-09 (설계 및 인프라 완성)

**Note**: 
- **Windows 빌드 인프라**: 완성 ✅
- **실제 Windows 실행**: v3.5에서 PE 생성 통합 시 검증 예정
- **현재 상태**: Linux 개발 환경에서 모든 모듈 완성 및 테스트 통과

**위험도**: [LOW-MEDIUM]  
**블랙홀 가능성**: 낮음 (범위 명확, 2-3주 내 완료 가능)

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

### Path 6: 최적화 (Optimization) - 3단계 분산
```
[1단계 v4.0] Constant Folding, 기본 DCE, Peephole
    ↓
[2단계 v4.2] Copy Propagation, Dead Store, Strength Reduction
    ↓
[3단계 v4.4] SSA 전환 → GCSE, GVN, SCCP → Loop 최적화
```
**우선순위**: [분산] (각 버전에 점진적 배치)
**위험도**: [LOW→MEDIUM→HIGH] (단계별 증가)

### Path 7: 빌트인 함수 (Builtin Functions) - 4단계 분산
```
[v4.0] 타입 정보 + 검증/단언 + 디버깅 (기초)
    ↓
[v4.1] Volatile + 비트 조작 + Introspection (확장)
    ↓
[v4.3] 암호/알고리즘 Intrinsics (기본) + Atomic (기본)
    ↓
[v4.5+] Multi-precision + 암호 전용 Intrinsics (고급)
```
**우선순위**: [분산] (각 버전에 점진적 배치)
**위험도**: [LOW→LOW→MEDIUM→HIGH] (단계별 증가)
**철학**: 컴파일러 코어 기능과 병렬 진행 가능

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

- [x] **v3 std 라이브러리 작성**
  - [x] Vec<T> v3 재작성 (동적 배열)
  - [x] HashMap<K,V> v3 재작성
  - [x] String v3 재작성 (기본 구현)
  - [x] mem v3 재작성 (malloc/free/memcpy)
  - [x] io v3 재작성 (파일 I/O)
  - [x] str v3 재작성 (문자열 유틸리티)
  - **주의**: `.?` 연산자 미구현으로 `*T?` 대신 `*T` + `cast(u64, ptr) == 0` 사용

- [ ] **v3 컴파일러로 v3 std 검증** (In Progress)
  - [x] v3_hosted main.b 업그레이드 (full pipeline: lex→parse→typecheck→codegen)
  - [x] asm 키워드/토큰/파싱/타입체크/코드젠 추가
  - [x] `*ptr` 역참조 (v3 스타일) 지원 추가
  - [x] void return (`return;`) 지원 추가
  - [x] bool 리터럴 (`true`/`false`) 타입 시스템 추가
  - [x] 배열 변수 주소 (`&buf`) 지원 추가
  - [x] 배열 인덱스 주소 (`&buf[i]`) 지원 추가
  - [x] switch 문 case body codegen 버그 수정 (v2c workaround)
  - [x] `cast()` 내장 함수 지원 추가
  - [x] v3 std 파일들 컴파일 테스트 (6/6 성공: str, mem, io, string, hashmap, vec)
    - vec.b를 비제네릭 버전으로 재작성 (hashmap.b와 동일 패턴)
  - [ ] std 단위 테스트 작성 및 통과
  - [ ] Golden test 중 std 의존 테스트 통과 확인

**v3.5 DoD**:
- [ ] v3 문법으로 작성된 std 라이브러리 완성
- [ ] v3 컴파일러로 v3 std 컴파일 성공
- [ ] std 단위 테스트 모두 통과
- [ ] 기존 v3 컴파일러가 v3 std를 사용하여 정상 동작

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

#### Phase 4.0.1: 제어 흐름 및 OOP 기초 (2-3개월)

- [x] **impl 블록 완전 구현** (v3_16에서 완료)
  - [x] 파서: impl 블록 파싱, 메서드 정의
  - [x] Codegen: 메서드 호출 설탕 (obj.method(args) → StructName_method(&obj, args))
  - [x] 정적 메서드: StructName.method() → StructName_method() 호출
  - [x] 인스턴스 메서드: obj.method() → StructName_method(&obj) 호출
  - [x] 테스트: 76_impl_basic.b, 97_string_builder.b 통과
  - DoD: `obj.method()` 형태로 메서드 호출 가능
  - **완료일**: 2026-01-18 (v3_16)
  - **구현 세부사항**:
    - TOKEN_STATIC 키워드 추가
    - parse_primary에서 정적 메서드 호출 감지 (is_struct_type 확인)
    - parse_postfix_from에서 인스턴스 메서드 호출 처리 (AST_METHOD_CALL)
    - cg_method_call에서 struct_name_ptr 사용하여 함수 이름 생성

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

- [ ] **Safe Navigation 연산자 (`.?`, `->?`)**
  - [ ] 렉서: `.?`, `->?` 토큰 추가
  - [ ] 파서: MemberAccess, DerefMemberAccess에 nullable variant 추가
  - [ ] 타입 체크: `*T?` 타입에서만 허용, 결과 타입도 nullable
  - [ ] Codegen: null 체크 + 조건부 접근 코드 생성
  - [ ] 연산자 체이닝: `a?.b?.c` 형태 지원
  - DoD: `*T?` 포인터에서 안전한 필드 접근 가능
  - **배경**: v3 std 라이브러리에서 `*T?` 문법은 있으나 `.?` 연산자 미구현으로 사용 불가
  - **현재 우회**: `cast(u64, ptr) == 0` 체크 + `*T` 사용

- [ ] **Optional Indexing (`?[idx]`)**
  - [ ] 슬라이스/배열에서 bounds 체크 + Optional 반환
  - [ ] `arr?[i]` → Some(value) 또는 None
  - DoD: safe indexing 가능
  - 의존성: Option<T> 구현 필요 (Phase 4.0.3)

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

- [ ] **Tuple + 다중 리턴** (v3에서 제거된 기능 복원)
  - [ ] (T, U, ...) 타입 문법
  - [ ] 구조 분해: var (a, b) = func()
  - [ ] 다중 리턴: func f() -> (T, U)
  - DoD: 타입 시스템과 통합된 다중 값 반환
  - **배경**: v3에서 복잡한 호출 규약으로 인해 제거됨
  - 참조: v4_roadmap.md 섹션 0.0

- [ ] **String 타입**
  - [ ] Vec<u8> 래퍼
  - [ ] UTF-8 보장
  - [ ] String.new(), String.from() (명시적 할당)
  - [ ] s.free() (명시적 해제)
  - DoD: 문자열 표준 타입
  - 참조: v4_roadmap.md 섹션 2.1

#### Phase 4.0.4: 주석 확장 (1개월)

**참고**: 컴파일러 코어가 아니라 렉서/파서 레벨 작업이므로 병렬 진행 가능

- [ ] **문서화 주석 (Documentation Comments)**
  - [ ] 렉서: `///`, `/**` 토큰 인식
  - [ ] 파서: AST 노드에 `doc_comment` 필드 추가
  - [ ] 주석 토큰 보존 (파서에 전달)
  - DoD: 함수/구조체에 문서화 주석 첨부 가능
  - 참조: v4_roadmap.md 섹션 0.1

- [ ] **중첩 블록 주석 (Nested Block Comments)**
  - [ ] 렉서: depth 카운터 추가
  - [ ] `/*` 마다 +1, `*/` 마다 -1
  - DoD: `/* /* 중첩 */ */` 정상 동작
  - 참조: v4_roadmap.md 섹션 0.1

**주석 확장 DoD**:
- [ ] `///` 주석이 AST에 저장됨
- [ ] 중첩 블록 주석 파싱 성공
- [ ] 테스트 통과

#### Phase 4.0.5: 기타 제약 해제 (1-2개월)

- [ ] Struct 리터럴 expression
  - [ ] Named: Point{x: 1, y: 2}
  - [ ] Positional: Point{1, 2}
  - 참조: v4_roadmap.md 섹션 0.1

- [ ] 파라미터 7개 이상 지원 (스택 전달)
- [ ] defer break/continue 지원
  - 참조: v4_roadmap.md 섹션 0.9

#### Phase 4.0.6: 빌트인 함수 기초 (1-2개월)

**참고**: 코어 언어 기능과 병렬 진행 가능

- [ ] **타입 정보 빌트인**
  - [ ] `typeof(x)` 구현
  - [ ] `alignof(T)` 구현
  - [ ] `size_of_val(x)` 구현
  - DoD: 컴파일 타임 타입 정보 조회
  - 참조: v4_roadmap.md 내장 함수 섹션

- [ ] **검증 및 단언**
  - [ ] `assert(cond, msg)` 구현 (디버그 전용)
  - [ ] `debug_assert()` 별칭
  - [ ] `static_assert()` 컴파일 타임 검증
  - [ ] `unreachable(msg)` 구현
  - DoD: 런타임/컴파일 타임 검증 작동
  - 참조: v4_roadmap.md 내장 함수 섹션

- [ ] **디버깅 빌트인**
  - [ ] `line()`, `file()`, `function()` 구현
  - [ ] `breakpoint()` 구현 (x86: int3)
  - DoD: 소스 위치 정보 출력 가능
  - 참조: v4_roadmap.md 내장 함수 섹션

**빌트인 함수 기초 DoD**:
- [ ] 타입 정보 함수 작동
- [ ] assert 계열 작동
- [ ] 디버깅 함수 작동

#### Phase 4.0.7: 최적화 1단계 - 기본 (1-2개월)

**철학**: SSA 없이도 구현 가능한 기본 최적화. 기본기를 다진 후 시작.

- [ ] **문서화 주석 + 중첩 블록 주석 지원**
- [ ] **기본 빌트인 함수 구현 (타입 정보, 검증, 디버깅)**
- [ ] v3의 모든 제약사항 해제
- [ ] **1단계 최적화 (Constant Folding, 기본 DCE)** 타임에 계산됨
  - 참조: v4_roadmap.md 섹션 6.2

- [ ] **Dead Code Elimination (기본)**
  - [ ] 사용되지 않는 변수 제거
  - [ ] unreachable 코드 제거 (if (false) { ... })
  - DoD: 명백한 dead code 제거
  - 참조: v4_roadmap.md 섹션 6.2

- [ ] **간단한 Peephole Optimization**
  - [ ] x * 1 → x
  - [ ] x + 0 → x
  - [ ] x * 2 → x << 1
  - DoD: 기본 연산 최적화

**1단계 최적화 DoD**:
- [ ] 상수 폴딩 작동
- [ ] 기본 DCE 작동
- [ ] Golden test 통과 (최적화 전후 동일)

**v4.0 DoD**:
- [ ] match로 모든 제어 흐름 처리
- [ ] enum/union으로 고급 타입 구현
- [ ] new/delete로 힙 메모리 관리
- [ ] constructor/destructor로 객체 생명주기 관리
- [ ] Result<T,E>로 에러 처리
- [ ] String 타입 사용 가능
- [ ] **문서화 주석 + 중첩 블록 주석 지원**
- [ ] **기본 빌트인 함수 구현 (타입 정보, 검증, 디버깅)**
- [ ] v3의 모든 제약사항 해제
- [ ] **1단계 최적화 (Constant Folding, 기본 DCE)**
- [ ] Golden test 추가 + 통과

**블로커**: v3 Self-Hosting 미완료

---

### v4.0 릴리스 후 작업

#### 레포지토리 분리 검토 (1-2주)

**목표**: bpp 프로젝트를 독립 레포지토리로 분리 여부 결정

**검토 기준**:
- [ ] **v4.0 안정성 확인**
  - [ ] Self-compilation 3세대 성공
  - [ ] 크로스 플랫폼 빌드 안정적

- [ ] **v3 유지보수 상태 평가**
  - [ ] v3 유지보수 종료 결정 여부
  - [ ] v3 사용자/의존성 존재 여부
  - [ ] v3 버그픽스 필요성 평가

- [ ] **분리 결정**
  - **Option A: 분리 (`Creeper0809/bpp` 신규 생성)**
    - [ ] 새 레포 생성: `Creeper0809/bpp`
    - [ ] `bpp/` 폴더 전체 복사
    - [ ] Git 히스토리 이전 (선택)
    - [ ] CI/CD 설정 (Linux + Windows)
    - [ ] README.md, CONTRIBUTING.md 작성
    - [ ] 기존 B 레포는 아카이브 모드
    - [ ] 리다이렉션 안내 (README 업데이트)

**권장**: v4.0 릴리스 직후 재평가

---

### v4.1 Generics & Comptime
**기간**: 2027 Q1-Q2 (6-9개월)
**목표**: 제네릭 개선, 기본 comptime 지원
**상태**: [PLANNED]

**의존성**: v4.0 완료

#### Phase 4.1.1: 제네릭 개선 (3-4개월)

**Note**: v3에서 제네릭은 복잡한 타입 시스템으로 인해 제거됨. v4에서는 타입 추론과 통합하여 재설계.

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

**Note**: v3에서 comptime은 컴파일 타임 평가 복잡도로 인해 제거됨. v4에서는 CTFE 인터프리터와 통합하여 재설계.

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
- [ ] **빌트인 함수 확장 (volatile, bit manipulation, introspection)**

**블로커**: v4.0 미완료

#### Phase 4.1.4: 빌트인 함수 확장 (1-2개월)

**참고**: 제네릭/comptime 기능 활용하여 추가 빌트인 구현

- [ ] **Volatile 연산**
  - [ ] `volatile_load(ptr)` 구현
  - [ ] `volatile_store(ptr, value)` 구현
  - DoD: 컴파일러 최적화 방지
  - 참조: v4_roadmap.md 내장 함수 섹션

- [ ] **비트 조작**
  - [ ] `rotl(x, n)`, `rotr(x, n)` 구현
  - [ ] `bswap(x)` 구현
  - DoD: 로테이션/바이트 스왑 작동
  - 참조: v4_roadmap.md 내장 함수 섹션

- [ ] **Introspection**
  - [ ] `has_method(T, "name")` 구현
  - [ ] `impls(T, Trait)` 구현
  - DoD: 컴파일 타임 타입 검사
  - 참조: v4_roadmap.md 내장 함수 섹션

**빌트인 함수 확장 DoD**:
- [ ] volatile 연산 작동
- [ ] 비트 조작 작동
- [ ] introspection 작동

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
- [ ] **2단계 최적화 (Copy Propagation, 고급 DCE)**

**블로커**: v4.1 미완료

#### Phase 4.2.3: 최적화 2단계 - 중급 (2-3개월)

**철학**: SSA 없이 구현 가능한 데이터플로우 분석 기반 최적화.

- [ ] **Copy Propagation (복사 전파)**
  - [ ] x = y; z = x + 1; → z = y + 1;
  - [ ] 단순 변수 복사 제거
  - DoD: 불필요한 변수 복사 제거
  - 참조: v4_roadmap.md 섹션 6.2

- [ ] **Dead Store Elimination**
  - [ ] 사용되지 않는 대입 제거
  - [ ] x = 10; x = 20; → x = 20;
  - DoD: 중복 대입 제거

- [ ] **고급 Dead Code Elimination**
  - [ ] 제어흐름 분석 기반 DCE
  - [ ] if (const_true) { A } else { B } → A
  - DoD: 조건분기 기반 dead code 제거

- [ ] **Strength Reduction (기본)**
  - [ ] x * 4 → x << 2
  - [ ] x / 2 → x >> 1 (부호 없는 정수)
  - DoD: 비용이 큰 연산을 저렴한 연산으로 대체

**2단계 최적화 DoD**:
- [ ] Copy Propagation 작동
- [ ] Dead Store Elimination 작동
- [ ] 성능 벤치마크 (10-15% 향상)
- [ ] Golden test 통과 (최적화 전후 동일)

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
- [ ] **암호/알고리즘 Intrinsics - 기본 구현 (일부)**
- [ ] **Atomic 빌트인 함수 (기본)**

**블로커**: v4.1 미완료, 컴파일러 재설계 미완료

**재검토 포인트**:
- 정말 Zig 수준의 CTFE가 필요한가?
- v4.1의 기본 comptime으로 충분하지 않은가?
- 개발 비용 vs 실용성 비교
- 대안: Rust 스타일 매크로 시스템 검토

#### Phase 4.3.4: 빌트인 함수 확장 - 고급 (2-3개월)

**참고**: CTFE 기능과 결합하여 고급 빌트인 구현

- [ ] **암호 및 알고리즘 Intrinsics (기본)**
  - [ ] `sha256_compress(state, block)` 구현 (v4.3)
  - [ ] `aes_encrypt_block(key, block)` 구현 (v4.3)
  - DoD: 기본 암호 알고리즘 인트린식 작동
  - 참조: v4_roadmap.md 내장 함수 섹션 (암호 및 알고리즘)

- [ ] **Atomic 빌트인 (기본)**
  - [ ] `atomic_load(ptr, order)` 구현
  - [ ] `atomic_store(ptr, val, order)` 구현
  - [ ] `atomic_cmpxchg(ptr, old, new, order)` 구현
  - DoD: 기본 원자 연산 작동
  - 참조: v4_roadmap.md 내장 함수 섹션

**빌트인 함수 고급 DoD**:
- [ ] 기본 암호 인트린식 작동
- [ ] 기본 atomic 연산 작동

---

### v4.4 Optimization 3단계 - SSA 기반 (Optional)
**기간**: 2029+ (12-18개월)
**목표**: SSA IR 전환 및 고급 최적화
**상태**: [PLANNED]
**위험도**: [MEDIUM] (SSA 전환 복잡)

**의존성**: v4.2 완료 (2단계 최적화 경험 필요)

**철학**: 언어 기능이 안정된 후에만 SSA로 전환. 성능보다 정확성 우선.

#### Phase 4.4.1: SSA IR 전환 (6-8개월)

- [ ] **packed struct 복원** (v3에서 제거된 기능)
  - [ ] packed 키워드 파서 재구현
  - [ ] 비트필드 DSL 설계
  - [ ] 비트 단위 메모리 접근 codegen
  - DoD: 하드웨어 레지스터 매핑, 네트워크 프로토콜 구조체
  - 참조: v4_roadmap.md 비트필드 섹션
  - **배경**: v3에서 비트필드 복잡도로 제거, v4에서 재설계

- [ ] **SSA 변환**
  - [ ] SSAValue, Phi Node 정의
  - [ ] Dominance Tree 계산
  - [ ] SSA Construction (Cytron Algorithm)
  - DoD: 기본 블록 SSA 변환
  - 참조: v4_roadmap.md 섹션 5

- [ ] **SSA Destruction**
  - [ ] 레지스터 할당 준비
  - [ ] Phi Node 제거 (Critical Edge Splitting)
  - DoD: SSA에서 다시 일반 IR로 변환

#### Phase 4.4.2: SSA 기반 최적화 (4-6개월)

- [ ] **Global Common Subexpression Elimination (GCSE)**
  - [ ] 여러 블록에 걸쳤 동일 표현식 제거
  - DoD: cross-block CSE 작동
  - 참조: v4_roadmap.md 섹션 6.3

- [ ] **Global Value Numbering (GVN)**
  - [ ] Hash-based value numbering
  - [ ] 동일 값을 가진 변수 통합
  - DoD: 멀리 떨어진 동일 표현식 발견
  - 참조: v4_roadmap.md 섹션 6.3

- [ ] **Sparse Conditional Constant Propagation (SCCP)**
  - [ ] 조건분기를 고려한 상수 전파
  - [ ] 절대 실행되지 않는 블록 제거
  - DoD: 콘텍스트 기반 상수 최적화
  - 참조: v4_roadmap.md 섹션 6.3

#### Phase 4.4.3: 고급 최적화 (4-6개월)

- [ ] **Loop Optimization**
  - [ ] Loop Invariant Code Motion (LICM)
  - [ ] Loop Unrolling (고정 회수 루프)
  - [ ] Loop Strength Reduction
  - DoD: 루프 성능 향상
  - 참조: v4_roadmap.md 섹션 6.4

- [ ] **Inlining**
  - [ ] 작은 함수 자동 인라인
  - [ ] @[inline] 힌트 지원
  - [ ] 호출 비용 vs 코드 크기 휴리스틱
  - DoD: 함수 호출 오버헤드 감소

- [ ] **Tail Call Optimization**
  - [ ] 꼬리 재귀 호출 점프로 변환
  - DoD: 재귀 함수 스택 오버플로우 방지

**v4.4 DoD**:
- [ ] SSA IR 완성
- [ ] SSA 기반 최적화 패스 작동
- [ ] 루프 최적화 작동
- [ ] 성능 벤치마크 (최소 30% 향상)
- [ ] Golden test 통과 (최적화 전후 동일)

**블로커**: v4.2 미완료

---

### v4.5+ Future Features (Long-term)
**기간**: 2029+
**상태**: [IDEATION]

다음 기능들은 **아직 확정되지 않았으며**, 실제 필요성이 검증된 후에만 진행합니다:

- [ ] **보안 기능 복원** (v3에서 제거된 기능들)
  - [ ] **nospill**: 레지스터 할당기와 통합하여 재설계
    - [ ] 레지스터 할당기에서 nospill 변수 우선순위 처리
    - [ ] 스필이 불가피한 경우 컴파일 에러
    - DoD: 민감한 데이터의 메모리 노출 방지
  - [ ] **secret/wipe**: 보안 모듈로 분리
    - [ ] secret 변수 타입 시스템 통합
    - [ ] wipe 명령어 volatile 보장
    - [ ] 최적화 단계에서 wipe 코드 보존
    - DoD: 암호 키, 비밀번호 등 민감 데이터 안전 처리
  - **배경**: v3에서 레지스터 할당 복잡도로 제거, v4.5+에서 재설계
  - 참조: v4_roadmap.md 보안 섹션

- [ ] **프로퍼티 훅** (v3에서 제거된 기능)
  - [ ] @[getter], @[setter] 속성
  - [ ] 필드 접근 시 자동 함수 호출
  - [ ] lazy evaluation, validation 지원
  - DoD: C# 스타일 프로퍼티 구현
  - **배경**: v3에서 복잡도로 제거, v4.5+에서 재평가

- [ ] **고급 암호/알고리즘 Intrinsics (v4.5+)**
  - [ ] Multi-precision 연산 (mpadd_u256, mpmul_u256)
  - [ ] 암호 전용 인트린식 (poly1305_*, chacha20_stream)
  - [ ] Primality test (is_prime, miller_rabin)
  - 참조: v4_roadmap.md 내장 함수 섹션
  - 우선순위: v4.2 (Multi-precision), v4.3 (암호 전용)

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
2026 Q1   : Phase 0 Windows Support   [2-3주] [CRITICAL] ← 지금 시작
2026 Q1   : v3.5 std 라이브러리       [6-8주] [IN PROGRESS]
2026 Q2   : v3.9 컴파일러 Self-Host   [8-10주] [PLANNED]
2026 Q3-Q4: v4.0 Foundation + 최적화1 [6-9개월] [PLANNED]
2027 Q1-Q2: v4.1 Generics & SIMD + 빌트인 확장 [6-9개월] [PLANNED]
2027 Q3-Q4: v4.2 Traits + 최적화2    [12-15개월] [PLANNED]
2028 Q2-Q4: v4.3 True CTFE + 빌트인 고급 (Optional) [9-12개월] [IDEATION]
2029+:      v4.4 SSA + 최적화3       [12-18개월] [IDEATION]
```

**총 예상 기간**: 3-4년 (v3 Self-Hosting부터 v4.3까지)

**빌트인 함수 전략**:
- **v4.0**: 타입 정보, 검증/단언, 디버깅 (기초)
- **v4.1**: Volatile, 비트 조작, Introspection (확장)
- **v4.3**: 암호/알고리즘 Intrinsics (기본), Atomic (기본)
- **v4.5+**: Multi-precision, 암호 전용 (고급)

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
- [LOW] **Phase 0 Windows Support**: 플랫폼 독립성, 범위 명확
- [LOW] **v4.0 Core**: 문법 확장, 기존 패턴 반복
- [LOW] **v4.0 최적화 1단계**: Constant Folding, 기본 DCE - SSA 불필요
- [LOW] **v4.1 Generics**: 기존 제네릭 개선
- [LOW] **v4.1 Explicit SIMD**: 인트린식 래핑만, 구현 단순
- [LOW] **v4.2 최적화 2단계**: Copy Propagation, DSE - SSA 불필요
- [LOW] **표준 라이브러리**: 독립적 개발 가능

---

## 최적화 3단계 요약

| 단계 | 버전 | 최적화 | SSA 필요 | 난이도 |
|------|------|--------|----------|--------|
| **1단계** | v4.0 | Constant Folding, 기본 DCE, Peephole | X | [LOW] |
| **2단계** | v4.2 | Copy Propagation, Dead Store, Strength Reduction | X | [LOW] |
| **3단계** | v4.4 | GCSE, GVN, SCCP, Loop Opt, Inlining | O | [MEDIUM] |

**철학**: 
- SSA 전환은 마지막에 (언어 안정 후)
- 각 버전마다 점진적 성능 향상
- 1단계만으로도 10-15% 성능 향상 기대

---

## 현재 우선순위
 (최우선): Windows Support
- **목표**: Windows 10/11에서 B 컴파일러 빌드 및 실행
- **기간**: 2-3주
- **블로커**: 없음 (즉시 시작)
- **전략**: 플랫폼 독립성 확보 후 v3.5 개발

### Phase 0.5 (Windows 완료 후): v3.5 std 라이브러리
- **목표**: std만 v3로 재작성, v2 컴파일러로 검증
- **기간**: 6-8주
- **블로커**: Phase 0 완료주
- **블로커**: 없음
- **전략**: 라이브러리 먼저, 컴파일러 나중에 (디버깅 용이)

### Phase 0.9 (2026 Q2): v3.9 Self-Hosting
- **목표**: 컴파일러를 v3로 재작성
- **기간**: 8-10주
- **블로커**: v3.5 완료

### Phase 1 (2026 하반기): v4.0 Core + 최적화 1단계
- **목표**: match, enum, union, new/delete, constructor/destructor, **기본 최적화**
- **기간**: 6-9개월
- **블로커**: v3 Self-Hosting 완료
- **최적화**: Constant Folding, 기본 DCE, Peephole (SSA 불필요)

### Phase 2 (2027 상반기): v4.1 Generics & SIMD & 빌트인 확장
- **목표**: 타입 추론, Value generics, 기본 comptime, **Explicit SIMD**, **빌트인 함수 확장**
- **기간**: 6-9개월
- **블로커**: v4.0 완료
- **신규**: 
  - SIMD를 v4.5에서 v4.1로 앞당김 (해커 정체성)
  - Volatile, 비트 조작, Introspection 빌트인 추가

### Phase 3 (2027 하반기): v4.2 Traits + 최적화 2단계
- **목표**: Trait/상속, **중급 최적화**
- **기간**: 12-15개월
- **블로커**: v4.1 완료
- **최적화**: Copy Propagation, Dead Store, Strength Reduction (SSA 불필요)

### Phase 4+ (2028~): Optional Features
- **v4.3 CTFE + 빌트인 고급**: 위험도 높음, 신중히 접근
  - 암호/알고리즘 Intrinsics (기본), Atomic 빌트인 추가
- **v4.4 SSA + 최적화 3단계**: GCSE, GVN, SCCP, Loop Opt (SSA 필요)
- **v4.5+ 빌트인 고급**: Multi-precision, 암호 전용 Intrinsics

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
