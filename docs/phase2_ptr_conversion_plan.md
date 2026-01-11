# Phase 2: ptr64[]/ptr8[] → * 변환 계획서

## 목표
v3.7의 모든 `ptr64[x]`와 `ptr8[x]` 구문을 `*x` 문법으로 변환

## 통계 (2026-01-11)

| 파일 | ptr64[] 사용 | ptr8[] 사용 | 합계 |
|------|-------------|------------|------|
| 01_utils.b | 66 | 19 | **85** |
| 02_lexer.b | 33 | 2 | **35** |
| 03_ast.b | 85 | 0 | **85** |
| 04_parser.b | 31 | 16 | **47** |
| 05_codegen.b | 158 | 0 | **158** |
| 06_main.b | 9 | 6 | **15** |
| **전체** | **382** | **43** | **425** |

## 변환 전략

### Phase 2.1: 패턴 분류 (분석)

#### 카테고리 A: 단순 읽기 (우선 변환)
```b
// 변환 가능: 단순 offset 읽기
return ptr64[v + 8];        → return *(v + 8);
x = ptr64[map];             → x = *map;
c = ptr8[s + i];            → c = *(s + i);
```

#### 카테고리 B: 단순 쓰기 (우선 변환)
```b
// 변환 가능: 단순 assignment
ptr64[v] = buf;             → *(v) = buf;
ptr64[v + 8] = 0;           → *(v + 8) = 0;
ptr8[buf] = c;              → *(buf) = c;
```

#### 카테고리 C: 고정 오프셋 (신중하게 변환)
```b
// 고정 오프셋: 구조체 필드 접근
ptr64[map + 8]              → *(map + 8)    // OK: 고정 offset
ptr64[node + 16]            → *(node + 16)  // OK: 고정 offset
ptr64[e + 32]               → *(e + 32)     // OK: 고정 offset
```

#### 카테고리 D: 동적 오프셋 (나중에/유지)
```b
// 동적 오프셋: pointer arithmetic 필요
ptr64[buf + i * 8]          → 유지 (v3.8에서 처리)
ptr64[new_buf + i * 8]      → 유지 (v3.8에서 처리)
ptr8[s + i]                 → 유지 (type-aware ptr arithmetic 필요)
```

#### 카테고리 E: 특수 케이스 (수동 검토)
```b
// self-referencing
ptr64[map + 16] = ptr64[map + 16] + 1;  → *(map + 16) = *(map + 16) + 1;

// inline 함수
func tok_kind(t: i64) -> i64 { return ptr64[t]; }
→ func tok_kind(t: i64) -> i64 { return *t; }
```

### Phase 2.2: 파일별 변환 우선순위

1. **02_lexer.b** (35 → 우선): 구조가 단순, 고정 오프셋 많음
2. **01_utils.b** (85): 문자열/벡터/해시맵 - 구조체 접근 많음
3. **04_parser.b** (47): 파서 상태 + AST 노드 접근
4. **03_ast.b** (85): AST 노드 생성 - 구조체 초기화
5. **05_codegen.b** (158): 가장 복잡, 타입 처리 많음
6. **06_main.b** (15 → 마지막): main + 프로그램 구조

### Phase 2.3: 변환 규칙

#### 기본 규칙
1. **읽기**: `ptr64[x]` → `*x` (괄호 필요시 `*(x)`)
2. **쓰기**: `ptr64[x] = y` → `*(x) = y`
3. **복합 표현식**: 괄호 사용 `ptr64[a + b]` → `*(a + b)`

#### 안전성 체크리스트
- [ ] 변환 후 컴파일 성공
- [ ] 어셈블리 출력 동일 (diff 확인)
- [ ] 테스트 프로그램 실행 성공
- [ ] 바이너리 크기 변화 없음 (83KB 유지)

### Phase 2.4: 주의사항

#### 변환하면 안 되는 패턴
```b
// 1. 동적 인덱싱
ptr64[buf + i * 8]          → 유지! (v3.8에서)

// 2. Loop 내부 복잡한 인덱싱
for (i = 0; i < len; i = i + 1) {
    ptr8[s1 + i]            → 유지! (type-aware arithmetic)
}

// 3. 주석/문서
// Check for ptr64[expr] or ptr8[expr] special syntax
→ 주석은 그대로 유지
```

#### 에러 방지
- 괄호 우선순위 주의: `*(x + 8)` vs `*x + 8`
- 연산자 우선순위: `*x + 1` = `(*x) + 1` ≠ `*(x + 1)`
- self-referencing 확인: `ptr64[x] = ptr64[x] + 1`

## Phase 2.5: 실행 계획

### Step 1: 02_lexer.b 변환 (가장 단순)
- [ ] 33개 ptr64[] 변환
- [ ] 2개 ptr8[] 변환
- [ ] 빌드 및 테스트
- [ ] diff 확인

### Step 2: 03_ast.b 변환 (구조체 초기화)
- [ ] 85개 ptr64[] 변환
- [ ] 빌드 및 테스트

### Step 3: 01_utils.b 변환 (데이터 구조)
- [ ] 66개 ptr64[] 변환
- [ ] 19개 ptr8[] 변환 (동적 인덱싱 제외)
- [ ] 빌드 및 테스트

### Step 4: 04_parser.b 변환
- [ ] 31개 ptr64[] 변환
- [ ] 16개 ptr8[] 변환
- [ ] 빌드 및 테스트

### Step 5: 06_main.b 변환
- [ ] 9개 ptr64[] 변환
- [ ] 6개 ptr8[] 변환
- [ ] 빌드 및 테스트

### Step 6: 05_codegen.b 변환 (가장 복잡)
- [ ] 158개 ptr64[] 변환
- [ ] 빌드 및 테스트
- [ ] 어셈블리 diff 확인

### Step 7: 최종 검증
- [ ] v3.7 전체 빌드
- [ ] Self-hosting: v3.7 → v3.7 → v3.7
- [ ] 모든 예제 컴파일
- [ ] 바이너리 크기 확인 (83KB)

## Phase 2.6: 검증 스크립트

```bash
# 변환 전 체크포인트
./bin/v3_6 build/v3_7_src.b > build/v3_7_before.asm
md5sum build/v3_7_before.asm > build/before.md5

# 변환 후 확인
./bin/v3_6 build/v3_7_src.b > build/v3_7_after.asm
diff build/v3_7_before.asm build/v3_7_after.asm || echo "Assembly changed!"

# 실행 테스트
echo "func test() { return 42; } func main() { return test(); }" | ./bin/v3_7 -
```

## 위험 요소

1. **대규모 변환**: 425개 패턴 → 실수 가능성 높음
2. **복잡한 표현식**: `ptr64[map + 16] = ptr64[map + 16] + 1`
3. **동적 인덱싱 혼재**: `ptr64[buf + i * 8]` vs `ptr64[buf]`
4. **파서 자체 변경 필요**: `ptr64[expr]` → `*expr` 문법 지원

## 결정 사항

- **Phase 2.0**: 파서에 `*` 연산자 추가 (unary prefix)
- **Phase 2.1-2.6**: 소스 변환 (파일별 점진적)
- **Phase 2.7**: 동적 인덱싱은 v3.8로 연기

## 다음 단계

현재 상태: Phase 2.1 분석 완료
다음: Phase 2.0 - 파서에 `*` 연산자 구현

---

**작성일**: 2026-01-11  
**상태**: 분석 완료, 실행 대기
