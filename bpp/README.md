# B Language v4 (`.bpp`) Development

이 폴더는 **B Language v4** 개발을 위한 전용 공간입니다. v4부터는 파일 확장자가 `.b`에서 `.bpp`로 변경됩니다.

## 폴더 구조

```
bpp/
├── src/          # v4 컴파일러 소스 코드 (.bpp)
├── std/          # v4 표준 라이브러리 (.bpp)
├── examples/     # v4 기능 예제 (.bpp)
├── test/         # v4 테스트 코드 (.bpp)
└── README.md     # 이 파일
```

## v3 vs v4 분리 전략

- **상위 폴더** (`/src`, `/std`, `/examples`, `/test`): v3 코드 유지 (`.b` 확장자)
- **bpp/ 폴더**: v4 코드 개발 (`.bpp` 확장자)

이 방식으로 v3와 v4를 **병렬로 개발**하며, 점진적으로 전환할 수 있습니다.

## v4.0 주요 변경사항

### 새로운 문법
- `match` 표현식 (패턴 매칭)
- `enum` with data (대수적 데이터 타입)
- `union` (태그된 유니온)
- `new` / `delete` (힙 메모리 관리)
- `constructor` / `destructor` (객체 생명주기)
- `Result<T, E>` 타입 (에러 처리)
- `String` 타입 (기본 문자열)
- 문서화 주석 (`///`, `/* */`)
- 중첩 블록 주석 지원

### 제거된 제약사항
- v3의 모든 임시 제약사항 해제
- 더 유연한 타입 시스템
- 향상된 에러 처리

## 개발 가이드

### 1. 컴파일러 개발 (`bpp/src/`)
v4 컴파일러는 이 폴더에서 개발됩니다. 초기에는 v3 컴파일러를 기반으로 시작하되, 점진적으로 v4 문법을 지원합니다.

**핵심 모듈**:
- 렉서/파서: `.bpp` 확장자 인식, 새로운 키워드 지원
- AST: `match`, `enum`, `union` 노드 추가
- 타입 체커: `Result<T,E>`, `String` 타입 검증
- 코드 생성: 새로운 구문에 대한 IR 생성

### 2. 표준 라이브러리 (`bpp/std/`)
v4 표준 라이브러리는 v3 std를 기반으로 하되, v4 문법을 활용하여 재작성됩니다.

**주요 모듈**:
- `std.result`: `Result<T, E>` 타입 및 유틸리티
- `std.string`: `String` 타입 구현
- `std.mem`: 메모리 관리 (`new`, `delete` 래퍼)
- `std.vec`: `Vec<T>` 동적 배열
- `std.hash`: `HashMap<K, V>`

### 3. 예제 (`bpp/examples/`)
v4 기능을 보여주는 예제 코드를 작성합니다.

**추천 예제**:
- `01_match_basic.bpp`: `match` 표현식 기초
- `02_enum_data.bpp`: 데이터를 가진 `enum`
- `03_result_type.bpp`: `Result<T,E>` 에러 처리
- `04_new_delete.bpp`: 힙 메모리 관리
- `05_string_usage.bpp`: `String` 타입 사용법
- `06_union.bpp`: `union` 타입 예제

### 4. 테스트 (`bpp/test/`)
v4 기능에 대한 단위 테스트 및 통합 테스트를 작성합니다.

**테스트 전략**:
- Golden test: 입력 코드 → 예상 출력 비교
- 단위 테스트: 각 기능별 독립 테스트
- 에러 테스트: 잘못된 문법/타입 검증

## 빌드 방법

### v3 컴파일러로 v4 코드 빌드 (초기)
```bash
# v3 컴파일러가 아직 .bpp를 모를 때
make v3
./bin/v3c bpp/src/main.bpp -o bin/v4c
```

### v4 컴파일러로 self-compile (목표)
```bash
make v4
./bin/v4c bpp/src/main.bpp -o bin/v4c_new
```

## 마이그레이션 체크리스트

- [x] `bpp/` 폴더 구조 생성
- [x] `bpp/README.md` 작성
- [ ] `.bpp` 확장자 인식 (렉서)
- [ ] `match` 문법 구현
- [ ] `enum` with data 구현
- [ ] `union` 타입 구현
- [ ] `new` / `delete` 구현
- [ ] `constructor` / `destructor` 구현
- [ ] `Result<T,E>` 타입 구현
- [ ] `String` 타입 구현
- [ ] 문서화 주석 지원
- [ ] 중첩 블록 주석 지원
- [ ] Golden test 추가
- [ ] Self-compilation 성공

## 참고 문서

- [v4_roadmap.md](/docs/v4_roadmap.md): v4 전체 기능 스펙
- [v4_todo.md](/docs/v4_todo.md): v4 개발 실행 계획
- [dev.instructions.md](/.github/instructions/dev.instructions.md): 개발 가이드라인

## 개발 원칙

1. **Explicit Control**: 명시적 제어, 암묵적 동작 최소화
2. **No Magic**: 컴파일러 마법 금지, 모든 동작 투명하게
3. **Zero-overhead**: 추상화 비용 0, 사용하지 않으면 비용 없음
4. **Hacker-friendly**: 저수준 제어 가능, 시스템 프로그래밍 친화적

---

**시작일**: 2026-01-09  
**목표 완료일**: 2026 Q3-Q4 (v4.0)  
**상태**: [IN PROGRESS]
