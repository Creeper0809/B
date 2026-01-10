# v3.7 Migration Plan: ptr64[]/ptr8[] → *ptr

## 변환 패턴

### 1. 단순 읽기
```b
// Before
var x = ptr64[addr];
var y = ptr8[addr];

// After  
var x = *((*i64)addr);
var y = *((*u8)addr);
```

### 2. 단순 쓰기
```b
// Before
ptr64[addr] = value;
ptr8[addr] = value;

// After
*((*i64)addr) = value;
*((*u8)addr) = value;
```

### 3. 오프셋 읽기 (포인터 산술)
```b
// Before
var x = ptr64[addr + 8];
var y = ptr64[addr + 16];

// After (포인터 산술 활용)
var p: *i64 = (*i64)addr;
var x = *(p + 1);  // p + 1 = addr + 8
var y = *(p + 2);  // p + 2 = addr + 16
```

### 4. 오프셋 쓰기
```b
// Before
ptr64[v + 8] = len;
ptr64[v + 16] = cap;

// After
var p: *i64 = (*i64)v;
*(p + 1) = len;
*(p + 2) = cap;
```

### 5. Vec 구조체 (ptr64[v], ptr64[v+8], ptr64[v+16])
```b
// Before
func vec_new() {
    var v = heap_alloc(24);
    var buf = heap_alloc(0);
    ptr64[v] = buf;      // v[0] = buf
    ptr64[v + 8] = 0;    // v[1] = len
    ptr64[v + 16] = 0;   // v[2] = cap
    return v;
}

// After
func vec_new() {
    var v = heap_alloc(24);
    var buf = heap_alloc(0);
    var p: *i64 = (*i64)v;
    *p = buf;            // p[0] = buf
    *(p + 1) = 0;        // p[1] = len
    *(p + 2) = 0;        // p[2] = cap
    return v;
}
```

### 6. HashMap (더 복잡한 구조)
```b
// Before
func hashmap_get(hm, key_ptr, key_len) {
    var cap = ptr64[hm + 8];
    var buckets = ptr64[hm];
    // ...
}

// After
func hashmap_get(hm, key_ptr, key_len) {
    var p: *i64 = (*i64)hm;
    var cap = *(p + 1);
    var buckets = *p;
    // ...
}
```

## 변환 전략

### Phase 1: 간단한 패턴부터
1. `ptr64[0]` → `*((*i64)0)`
2. 단순 읽기/쓰기 변환

### Phase 2: 오프셋 패턴
1. 연속된 오프셋 접근 찾기
2. 포인터 변수로 추출
3. 포인터 산술로 변환

### Phase 3: 함수별 검증
1. 각 함수 변환 후 동작 확인
2. 테스트 케이스 실행

## 파일별 작업 순서

1. **01_utils.b** (가장 많이 사용, 256개)
   - Vec 함수들
   - HashMap 함수들
   - 문자열 함수들

2. **02_lexer.b**
   - 토큰 버퍼 조작

3. **03_ast.b**
   - AST 노드 조작

4. **04_parser.b**  
   - 심볼 테이블, 파싱 로직

5. **05_codegen.b**
   - 코드 생성, 어셈블리 emit

6. **06_main.b**
   - 메인 함수

## 검증 방법

각 파일 변환 후:
```bash
# v3_7 빌드
cat src/v3_7/parts/*.b > src/v3_7_combined.b
./bin/v3_6 src/v3_7_combined.b > build/v3_7_combined.b.asm
nasm -f elf64 -o build/v3_7.o build/v3_7_combined.b.asm
ld -o bin/v3_7 build/v3_7.o

# 테스트
./bin/v3_7 test/v3_6/minimal_test.b > /tmp/test.asm
```

## 주의사항

1. **타입 추가 필요**: 함수 파라미터와 지역 변수에 타입 어노테이션 추가
   ```b
   // Before
   func vec_len(v) {
       return ptr64[v + 8];
   }
   
   // After
   func vec_len(v: *i64) -> i64 {
       return *(v + 1);
   }
   ```

2. **포인터 변수 도입**: 반복되는 캐스트 피하기
   ```b
   // Bad
   *((*i64)v + 1) = x;
   *((*i64)v + 2) = y;
   
   // Good
   var p: *i64 = (*i64)v;
   *(p + 1) = x;
   *(p + 2) = y;
   ```

3. **u8 vs i64 구분**: ptr8[]는 (*u8), ptr64[]는 (*i64)

## 목표

- [ ] 363개 ptr64[] 모두 변환
- [ ] 29개 ptr8[] 모두 변환
- [ ] v3_7로 v3_7 자신 컴파일 성공
- [ ] 모든 테스트 통과
