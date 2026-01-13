# v3.9 TODO

v3.9는 v3.8을 베이스로 하되, v3.8 안정판을 건드리지 않고 실험/확장을 진행하기 위한 작업 공간입니다.

## 표현식 컨텍스트 `++/--` (postfix/prefix)

- [ ] 목표: `i = j++;`, `x = ++j;`, `f(j++);` 같은 “표현식 자리”에서 `++/--`가 값을 반환하도록 의미론을 정의/구현
- [ ] postfix 의미: `j++`는 **현재 값 반환 후** `j = j + 1`
- [ ] prefix 의미: `++j`는 `j = j + 1` 후 **증가된 값 반환**
- [ ] 제약(초기): lvalue(ident / deref)만 허용
- [ ] 구현 아이디어(최소):
  - 코드젠에 임시 슬롯(스택) 또는 레지스터 스필을 사용해 “이전 값”을 보관
  - 또는 lowering 단계에서 `tmp = j; j = j + 1; tmp` 형태로 AST를 확장(표현식 시퀀스가 필요하면 새 노드가 필요할 수 있음)

## 테스트

- [ ] `B/v3_9/test/b`에 다음 케이스 추가
  - [ ] `i = j++;`에서 `i`는 증가 전 값
  - [ ] `i = ++j;`에서 `i`는 증가 후 값
  - [ ] `f(j++)` 인자 값 검증
  - [ ] `*(p++)` 같은 케이스는 v3.9 범위에서 제외(필요하면 별도 티켓)

## DoD

- [ ] 위 테스트 전부 PASS
- [ ] 기존 v3.9 데모 스위트 회귀 없음

---

## 선언+초기화 한 줄 통합 (보수적 리팩터링)

목표: v3.9 코드베이스에서 자주 보이는

```b
var x;
x = expr;
```

형태를 단계적으로

```b
var x = expr;
```

로 합친다.

### 리스크/주의

`var x = expr;`는 파서 레벨에서는 이미 지원하지만, **codegen 경로가 `var x; x = expr;`와 완전히 동일한 타입 전파를 보장해야** self-host 안정성이 나온다.

### 진행 현황

- [x] v3.9 소스를 v3.8 베이스로 재생성(백업 후 복사)하고, v3.9 전용 설정만 재적용
- [x] v3.9 codegen: `AST_VAR_DECL` 초기화 경로에서 포인터 타입(depth) 추론 결과를 `symtab_update_type`로 반영
- [x] v3.8 -> v3.9 2-stage self-host 확인 + 고정점(stage3에서 해시 동일) 확인
- [x] 회귀 테스트 추가: `B/v3_9/test/b/29_var_init_ptr_arith.b`
- [x] v3.9 codegen: `AST_VAR_DECL(init)`과 `AST_ASSIGN`를 동일한 내부 경로로 통합 (`cg_assign_core`)
- [x] v3.9 -> v3.9 3-stage self-host 고정점 재확인 (stageB.asm == stageC.asm)
- [x] 회귀 테스트 추가: `B/v3_9/test/b/30_var_init_call_ptr_deref.b`
- [x] 파일 단위 리팩터링 1차 완료: `B/v3_9/src/std/hashmap.b` 전체를 `var x = ...;` 형태로 전환
- [x] 파일 단위 리팩터링 2차 완료: `B/v3_9/src/std/io.b` 전체를 `var x = ...;` 형태로 전환
- [x] 파일 단위 리팩터링(std) 완료: `B/v3_9/src/std/{path,str,util,vec}.b`까지 `var x = ...;` 형태로 전환
- [x] std 전체 전환 이후에도 v3.9 테스트 PASS + v3.9->v3.9 3-stage 고정점 유지 재확인
- [x] `B/v3_9/src/lexer.b` 전체 var-init 통합 완료
- [x] `B/v3_9/src/parser.b` 전체 var-init 통합 완료
- [x] `B/v3_9/src/codegen.b` 부분 var-init 통합 (104/260 패턴 변환)
- [x] 3-stage self-host 수렴 확인 (stage2 == stage3)

### 다음 작업(보수적)

- [ ] `B/v3_9/src/codegen.b` 나머지 var-init 통합 계속
- [ ] `B/v3_9/src/main.b` var-init 통합
- [ ] 각 파일 변경 후: `bash B/v3_9/test/run_tests.sh` + v3.8->v3.9 self-host 스모크를 반복

### 메모(최근 이슈)

- self-host 중 `Expected token kind` 크래시가 났던 원인은, 컴파일러 소스에 논리 연산자 `and`를 써서(언어 문법은 `&&`/`||`) 파서가 해석하지 못했던 것. 해당 구문을 `&&`로 수정하여 해결.
