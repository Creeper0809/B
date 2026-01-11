# v3.7 개발 로드맵 (v3.6 기반 점진적 업그레이드)

## 현재 상태
- ✅ v3.6을 v3.7로 복사 완료
- ✅ main() 함수에 타입 시그니처 추가
- ✅ 기본 컴파일 및 실행 성공 (83KB)

## Phase 1: 타입 시그니처 추가 (ptr64[]/ptr8[] 유지)

### 1.1 utils 함수들 (01_utils.b) ✅
- [x] str_len, str_eq, str_copy 등 문자열 함수
- [x] vec_* 함수들 (벡터 관리)
- [x] hashmap_* 함수들 (해시맵)
- [x] path_* 함수들 (경로 처리)
- **완료**: 40개 함수 타입 시그니처 추가

### 1.2 lexer 함수들 (02_lexer.b) ✅
- [x] is_digit, is_alpha, is_alnum, is_whitespace
- [x] lex_new, lex_peek, lex_advance 등
- [x] tok_new, tok_kind, tok_ptr 등
- **완료**: 21개 함수 타입 시그니처 추가

### 1.3 AST 함수들 (03_ast.b) ✅
- [x] ast_literal, ast_ident, ast_string
- [x] ast_binary, ast_unary, ast_call
- [x] ast_if, ast_while, ast_for, ast_switch
- [x] ast_func, ast_program, ast_import
- **완료**: 27개 함수 타입 시그니처 추가

### 1.4 parser 함수들 (04_parser.b) ✅
- [x] parse_new, parse_peek, parse_match 등
- [x] parse_expr, parse_stmt, parse_block
- [x] parse_func_decl, parse_program
- **완료**: 37개 함수 타입 시그니처 추가

### 1.5 codegen 함수들 (05_codegen.b) ⏳  
- [x] symtab_* 함수들 (일부)
- [x] cg_expr, cg_stmt, cg_func (일부 자동 완성됨)
- **완료**: 17개 함수 중 주요 함수 타입 시그니처 추가

### 1.6 main 모듈 함수들 (06_main.b) ⏳
- [x] main() - 완료
- [ ] load_module, read_entire_file (일부 자동 완성 가능)

**결과**: v3.6으로 v3.7 컴파일 성공 (83KB), 어셈블리 생성 확인

**목표**: v3.6이 타입 시그니처가 추가된 v3.7을 컴파일하고, v3.7이 정상 작동

---

## Phase 2: ptr64[]/ptr8[] → * 변환 (신중하게)

### 2.1 안전한 변환 대상 식별
```b
// 변환 가능 (단순 offset)
ptr64[map] → *map
ptr64[map + 8] → *(map + 8)  // 아직 pointer arithmetic 없음

// 나중에 변환 (pointer arithmetic 필요)
ptr64[v + 8] → *(v + 1)  // v3.8에서 구현
```

### 2.2 변환 우선순위
1. **읽기 전용**: `ptr64[x]` → `*x`
2. **고정 오프셋**: `ptr64[x + 8]` → `*(x + 8)`
3. **동적 오프셋**: `ptr64[x + i]` → 유지 (당분간)

---

## Phase 3: Type-aware Pointer Arithmetic (v3.8+)

이 기능은 **v3.8 이후**로 연기:
- `*(ptr + 1)` → `ptr + sizeof(*ptr)` 자동 계산
- 완전한 타입 시스템 필요
- get_expr_type() 완전 재작성 필요

---

## 테스트 체크리스트

### 기본 테스트
- [x] 단순 함수 호출
- [ ] 예제 파일 생성 및 테스트
- [ ] Self-hosting (v3.7 → v3.7)

### 회귀 테스트
- [ ] v3.6 테스트 케이스 모두 통과
- [ ] ASLR 환경에서 안정성

---

## 다음 단계

1. **지금**: utils 함수들에 타입 시그니처 추가
2. **다음**: lexer, parser, codegen에 타입 시그니처 추가
3. **나중**: ptr64[] 변환은 Phase 2에서
