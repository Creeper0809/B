## Phase 6: 기존 코드 마이그레이션 📝

### 6.1 v3.6 자체 소스 변환
```b
// Before (v3.6 현재)
func vec_len(v) {
    return ptr64[v + 8];
}

// After (업그레이드된 v3.6)
func vec_len(v: *i64) -> i64 {
    return *(v + 1);  // 자동으로 v + 8 계산
}
```

### 6.2 변환 작업
- [ ] 01_utils.b 변환
  - Vec, HashMap 함수들
  - 256개 `ptr64[]` → `*` 변환
  - 26개 `ptr8[]` → `*` 변환

- [ ] 02_lexer.b 변환
- [ ] 03_ast.b 변환
- [ ] 04_parser.b 변환
- [ ] 05_codegen.b 변환
- [ ] 06_main.b 변환

### 6.3 테스트
- [ ] 변환된 v3.7을 3.6으로컴파일
- [ ] 모듈 시스템 테스트
- [ ] 기존 테스트 케이스 모두 통과

---