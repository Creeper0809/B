# v3 단순화 계획 (v3 Simplification Plan)

## 목적

v3 컴파일러를 **셀프호스팅 가능한 최소 기능 세트**로 단순화합니다.
복잡한 기능들은 v4에서 다시 구현합니다.

## 원칙

1. **셀프호스팅 우선**: v3c가 자기 자신을 컴파일하는 데 필요한 기능만 유지
2. **단순함 선호**: 복잡한 기능보다 안정성 우선
3. **제약 완화**: 하드코딩된 제한(로컬 심볼 수 등) 제거/완화
4. **코드 크기 감소**: 불필요한 코드 제거로 유지보수성 향상

---

## 기능 분류

### ✅ 유지할 기능 (셀프호스팅 필수)

| 기능 | 설명 | 이유 |
|------|------|------|
| 기본 타입 | u8, u16, u32, u64, i64 | 필수 |
| 포인터 | `*T`, `*T?` | 메모리 접근 필수 |
| 슬라이스 | `[]T`, `str` | 문자열/배열 처리 |
| 배열 | `[N]T` | 고정 크기 버퍼 |
| struct | 일반 struct | 데이터 구조화 |
| enum | 기본 enum | 상수 정의 |
| 함수 | func, return | 필수 |
| 제어문 | if, else, while, for, foreach | 필수 |
| switch | no-fallthrough switch | 분기 처리 |
| break/continue | 루프 제어 | 필수 |
| import | 모듈 시스템 | 다중 파일 |
| const | 상수 정의 | 매직 넘버 제거 |
| var | 변수 선언 | 필수 |
| cast | 타입 변환 | 필수 |
| sizeof/offsetof | 타입 크기/오프셋 | 메모리 레이아웃 |
| 포인터 산술 | `+`, `-` on pointers | 필수 |
| print/println | 디버그 출력 | 디버깅 |
| defer | 리소스 정리 | 파일 핸들 등 |
| impl | 메서드 정의 | 편의성 |
| asm | 인라인 어셈블리 | 저수준 제어 (v2 호환) |
| alias | 레지스터 별칭 | v2 호환 |

### ❌ v4로 이동할 기능

| 기능 | 현재 코드 위치 | 이유 | v4 우선순위 |
|------|---------------|------|------------|
| **제네릭** | parser.b:133-200, lowering.b | 복잡한 타입 시스템 필요 | 높음 |
| **comptime** | lowering.b, ast.b:COMPTIME_EXPR | 컴파일 타임 평가 필요 | 높음 |
| **extern "C"** | parser.b, token.b | libc 연동, 당장 불필요 | 중간 |
| **nospill** | codegen.b:3212-3244 | 레지스터 할당 복잡화 | 낮음 |
| **secret/wipe** | codegen.b:1772-1876 | 보안 기능, 핵심 아님 | 낮음 |
| **packed struct** | parser.b:2627-2632 | 비트필드, 핵심 아님 | 중간 |
| **다중 리턴** | ast.b:TUPLE | 복잡한 호출 규약 | 중간 |
| **함수 포인터 타입** | ast.b:FUNC_PTR | 고급 기능 | 중간 |
| **부동소수점** | token.b:FLOAT, ast.b:FLOAT | SSE 레지스터 할당 | 낮음 |
| **distinct 타입** | token.b:KW_DISTINCT | 타입 시스템 확장 | 낮음 |
| **프로퍼티 훅** | parser.b, codegen.b | `@[getter]`/`@[setter]` 복잡성 | 낮음 |

### ⚠️ 완화할 제약

| 제약 | 현재 값 | 변경 | 이유 |
|------|--------|------|------|
| 로컬 심볼 수 | 하드코딩 | 동적 확장 | 큰 함수 지원 |
| 함수 파라미터 수 | 6개 | 유지 (ABI) | System V ABI |
| 스택 크기 | 하드코딩 | 동적 계산 | 큰 스택 프레임 |

---

## 삭제 작업 상세

### Phase 1: 제네릭 제거

**영향 파일**:
- `parser.b`: `parse_generic_params`, `parser_is_generic_param_list`
- `lowering.b`: `lw_register_generic_struct_typefn`, 관련 함수들
- `ast.b`: `AstTypeKind.GENERIC`
- `typecheck.b`: 제네릭 인스턴스화 로직

**작업**:
1. `parser.b`에서 `<T>` 파싱 코드 제거
2. `lowering.b`의 제네릭 관련 함수 제거
3. `AstTypeKind.GENERIC` 제거
4. 테스트에서 제네릭 사용 코드 제거/주석처리

### Phase 2: comptime 제거

**영향 파일**:
- `ast.b`: `AstTypeKind.COMPTIME_EXPR`
- `lowering.b`: comptime 관련 로직

**작업**:
1. `COMPTIME_EXPR` 제거
2. `lowering.b`의 comptime 로직 단순화

### Phase 3: nospill/secret/wipe 제거

**영향 파일**:
- `token.b`: `KW_NOSPILL`, `KW_SECRET`, `KW_WIPE`
- `lexer.b`: 키워드 인식
- `parser.b`: `parse_wipe_stmt`, secret/nospill 플래그
- `codegen.b`: nospill 레지스터 할당, secret 처리
- `ast.b`: `AstStmtKind.WIPE`

**작업**:
1. 키워드 제거
2. 파서에서 관련 문법 제거
3. codegen에서 nospill 레지스터 로직 제거
4. secret_locals 추적 제거

### Phase 4: packed struct 제거

**영향 파일**:
- `token.b`: `KW_PACKED`
- `parser.b`: packed struct 파싱
- `codegen.b`: 비트필드 접근 생성

**작업**:
1. `KW_PACKED` 키워드 제거
2. packed struct 문법 제거

### Phase 5: 제약 완화

**로컬 심볼 테이블 동적화**:
```b
// Before (하드코딩)
var locals[256];
var local_count = 0;

// After (동적)
var locals = vec_new(64);  // 필요시 자동 확장
```

---

## 예상 코드 감소

| 파일 | 현재 | 예상 | 감소율 |
|------|------|------|--------|
| codegen.b | 3481줄 | ~2800줄 | -20% |
| lowering.b | 662줄 | ~200줄 | -70% |
| parser.b | 2722줄 | ~2500줄 | -8% |
| typecheck.b | 5457줄 | ~5000줄 | -8% |
| **총계** | 13768줄 | ~12000줄 | -13% |

---

## 테스트 업데이트

### 제거할 테스트
- `test/14_packed_bitfield.b` → v4로 이동
- `test/15_property_hooks.b` → v4로 이동 (프로퍼티 훅)
- `test/18_wipe_smoke.b` → v4로 이동
- `test/20_generics_struct_offsetof.b` → v4로 이동
- `test/22_comptime_array_len_expr.b` → v4로 이동
- `test/24_multi_return.b` → v4로 이동
- `test/33_struct_literal.b` → v4로 이동 (표현식 형태)

### 유지할 테스트
나머지 37개+ 테스트 유지

---

## 마이그레이션 체크리스트

- [x] **Phase 1**: 제네릭/comptime 제거
  - [x] lowering.b → stub 함수만 유지 (663줄 → 31줄)
  - [x] parser.b → parse_generic_params stub
  - [x] ast.b → 주석 업데이트
  - [x] v3c_full 빌드 확인 (702KB → 665KB)

- [x] **Phase 2**: nospill/secret/wipe/packed/property hooks 제거
  - [x] token.b → 키워드 주석 처리
  - [x] lexer.b → 키워드 인식 제거
  - [x] parser.b → secret/nospill/wipe/packed 파싱 제거
  - [x] parser.b → @[getter]/@[setter] 프로퍼티 훅 제거
  - [x] v3c_full 빌드 확인 (665KB → 664KB)

- [ ] **Phase 3**: typecheck.b/codegen.b 정리 (선택적)
  - [ ] nospill 레지스터 할당 코드 제거
  - [ ] secret_locals 추적 코드 제거

- [ ] **Phase 4**: 제약 완화
  - [ ] 로컬 심볼 동적화
  - [ ] 스택 크기 동적화

- [ ] **최종 검증**
  - [x] 유지 테스트 통과 (37/43)
  - [ ] v3c_full 셀프호스팅 빌드
  - [ ] 생성된 바이너리 동작 확인

---

## v4 복원 계획

v3에서 제거된 기능들은 v4에서 **처음부터 다시 설계**하여 구현합니다.

| 기능 | v4 버전 | 설계 개선점 |
|------|---------|------------|
| 제네릭 | v4.2 | 타입 추론과 통합 |
| comptime | v4.3 | CTFE 인터프리터 |
| nospill | v4.5+ | 레지스터 할당기 통합 |
| secret/wipe | v4.5+ | 보안 모듈로 분리 |
| packed struct | v4.4 | 비트필드 DSL |
| 다중 리턴 | v4.2 | 튜플 타입과 통합 |
**프로퍼티 훅** | v4.5+

---

## 참고

- [v4_todo.md](./v4_todo.md) - v4 개발 계획
- [v4_roadmap.md](./v4_roadmap.md) - v4 기능 로드맵
