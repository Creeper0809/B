# Versioned Library Policy

목표: 컴파일러의 역사를 아카이빙하기 위해, 공용 자료구조/런타임 유틸을 **버전별로 분리**한다.

## 원칙

- `src/library/vN/`은 **해당 버전에서 안정적으로 빌드 가능한 코드**만 포함한다.
- 상위 버전(v2/v3/...)에서 기능을 확장하더라도, v1용 코드는 그대로 남겨서 아카이빙한다.
- 공용 유틸(자료구조 등)을 추가할 때는:
  - 새 버전이 필요하면 `src/library/v2/`에 추가/복사해서 발전시킨다.
  - 기존 v1 코드는 깨지지 않도록 유지한다(또는 수정이 필요하면 v1을 고정하고 v2로 분기).

## 포함 경로(merged build 단위)

Stage1 제약 때문에 선언(`layout/const/var`)은 함수 정의보다 먼저 와야 한다.

권장 병합 순서 예시:

- `src/v1/prelude.b`
- `src/library/v1/prelude.b`
- `src/v1/std/*.b`
- `src/v1/core/*.b`
- `src/library/v1/core/*.b`
- `test/.../smoke/*.b`

## 현재 구현(2026-01-02)

- HashMap: `src/library/v1/core/hashmap.b` (smoke: `test/v1/run_smoke_p15.sh`)
- StringInterner: `src/library/v1/core/string_interner.b` (smoke: `test/v1/run_smoke_p16.sh`)
- Arena: `src/library/v1/core/arena.b` (smoke: `test/v1/run_smoke_p17.sh`)
- StringBuilder: `src/library/v1/core/string_builder.b` (smoke: `test/v1/run_smoke_p18.sh`)
