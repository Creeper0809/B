# v2 Syntax (현재 구현 기준)

이 문서는 **현재 v2 컴파일 파이프라인(드라이버 + 렉서/파서/코드젠)** 이 실제로 받아들이는 문법을 정리합니다.

- 입력 언어: v2
- 엔트리포인트: 드라이버가 `_start`를 만들고 `main()`을 호출합니다.
- 주의: 이 문서는 `docs/v2_roadmap.md`의 “계획”이 아니라, **현 구현이 허용하는 형태**만 적습니다.

---

## 1) 렉시컬(토큰) 규칙

### 공백/줄
- 공백/탭/CR/LF는 토큰 사이에서 무시됩니다.
- 줄 번호는 `\n`을 만날 때 증가합니다.

### 주석
- 한 줄 주석: `//` 부터 줄 끝까지 무시됩니다.

### 식별자(IDENT)
- 형태: `[_A-Za-z][_A-Za-z0-9]*`

### 키워드(토큰으로 인식되는 것)
다음은 렉서에서 **전용 토큰**으로 분류됩니다.

- `func`, `var`, `const`, `alias`
- `if`, `else`, `while`, `break`, `continue`, `return`

> 반대로 `import`, `enum`, `struct`, `switch`, `for`, `foreach`는 **전용 토큰이 아니라 IDENT로 들어온 뒤**, 파서가 텍스트 비교로 “키워드처럼” 처리합니다.

### 정수(INT)
- 10진수: `[0-9]+`
- 16진수: `0x[0-9A-Fa-f]+` (또는 `0X...`)

### 문자열(STR)
- 큰따옴표: `"..."`
- 문자열 리터럴은 v2에서 **표현식으로 지원**합니다.
  - 코드젠은 `.rodata`에 라벨을 만들고, 해당 라벨의 주소를 값으로 사용합니다.

### 문자 리터럴
- 작은따옴표: `'...'`
- 문자 리터럴은 렉서 단계에서 **정수(INT) 토큰으로 변환**됩니다.
- 지원 형태(단일 문자/단일 이스케이프):
  - `'a'`
  - `"\\n"`, `"\\t"`, `"\\r"`, `"\\0"`, `"\\\\"`, `"\\'"`

### 연산자/구분자
- 단일 문자: `(` `)` `{` `}` `[` `]` `;` `,` `.` `:` `+` `-` `*` `/` `%` `=` `<` `>` `&` `|` `^` `~` `!`
- 다문자 연산자: `&&` `||` `==` `!=` `<=` `>=` `<<` `>>` `->`

---

## 2) 프로그램 구조(Top-level)

대략 형태:

```b
import foo.bar;

const N = 10;

enum Color { Red, Green = 10, Blue };

struct Pair {
  a: u64;
  b: u64;
};

func main() {
  return 0;
}
```

v2의 top-level은 아래 선언들의 나열을 허용합니다.

- `import` (IDENT 기반 키워드)
- `var`
- `const`
- `enum` (IDENT 기반 키워드)
- `struct` (IDENT 기반 키워드)
- `func`

### 2.1) import

형태:

```b
import a.b.c;
```

- 문법적으로는 top-level에서만 소비됩니다.
- **실제 모듈 로딩/재귀 컴파일은 드라이버가 담당**합니다.
- 드라이버는 파일의 **선두에 연속으로 등장하는 import만 스캔**해서 의존 모듈을 DFS로 컴파일합니다.
  - 즉, 함수/블록 내부에 `import ...;`를 써도 “문법 토큰 소비”는 될 수 있으나, 드라이버 의존성 스캔에는 포함되지 않습니다.

모듈 경로 해석(요약):
- `import a.b.c;` → 상대 경로 `a/b/c`
- 탐색 순서:
  1) importing 파일이 있는 디렉터리
  2) `-I` / `--module-root`로 지정된 모듈 루트들
- 각 루트에서 아래를 순서대로 시도:
  1) `<root>/<rel>.b`
  2) `<root>/<rel>/__init__.b`

### 2.2) const

형태:

```b
const NAME = <const-expr>;
```

- 전역(컴파일 단위) 정수 상수(u64)입니다.
- 우변은 “상수식”으로 평가됩니다.

지원되는 상수식(요약):
- INT (문자 리터럴 포함)
- 다른 const 식별자
- 점 상수: `EnumName.Member` 형태
- 괄호
- unary `+` / `-`
- binary `+ - * / % & | ^ << >>`

### 2.3) enum

형태:

```b
enum Name {
  A,
  B = 10,
  C,
}
;
```

- 멤버는 0부터 자동 증가하며, `= const-expr`로 값을 지정할 수 있습니다.
- 멤버 구분자는 `,`이고, 끝에 `,`를 둘 수 있습니다.
- 닫는 `}` 뒤에 `;`는 옵션입니다.
- enum 멤버는 `Name.Member` 형태의 **점 상수**로 정의됩니다.

### 2.4) struct

형태:

```b
struct Name {
  field0;
  field1: u64;
  field2: *Other;
}
;
```

- 필드 형태: `IDENT [ ':' ['*'] IDENT ] ';'`
- 닫는 `}` 뒤에 `;`는 옵션입니다.
- 타입을 생략하면 기본적으로 8바이트 슬롯처럼 동작합니다(필드 메타데이터는 “없음”).

필드 크기 규칙(현재 구현):
- 기본 크기: 8바이트
- 포인터(`*T`)는 8바이트
- by-value(값으로 포함) 필드는 아래만 특별 취급합니다.
  - primitive: `u8/u16/u32/u64/i64`
  - 다른 `struct` 타입(완전 타입이어야 함)
- by-value 자기참조(`struct Node { next: Node; }`)는 금지
- 미정의 struct를 by-value로 쓰면 에러

### 2.5) var (global)

형태:

```b
var g;
var g = 123;

var p: *Pair;
var q: *Pair = 0;
```

정확한 문법(현재 구현):

```
'var' IDENT
  [ ':' ['*'] IDENT ]
  [ '=' const-expr ]
';'
```

특징/제약(중요):
- top-level `var`의 초기값은 일반 `expr`가 아니라 **상수식(const-expr)** 만 허용합니다.
  - const/enum(점 상수) 기반의 산술식까지는 가능
- 전역 배열 선언(`var arr[N];`)은 현재 구현에서 지원하지 않습니다.
- 타입 힌트(`: T`, `: *T`)는 파싱은 하지만, 전역 저장 공간의 레이아웃에는 아직 영향을 주지 않습니다(MVP).
- 전역 심볼명은 `v_<ident>` 형태입니다.
  - 초기값이 있으면 `.data`에 `dq <imm>`
  - 초기값이 없으면 `.bss`에 `resq 1`

참고(현 구현의 동작):
- 로컬/alias/const로 해석되지 않는 식별자는 전역 슬롯으로 fallback 됩니다.
  - 따라서 top-level `var`를 선언하지 않아도, 전역을 읽기/쓰기/&로 참조하면 `.bss resq 1` 형태로 자동 정의될 수 있습니다.

---

## 3) 함수

### 3.1) 함수 정의

형태:

```b
func name(arg0, arg1, ...) {
  stmt*
}
```

- 인자 최대 6개
- 함수 프레임 크기는 구현이 “스캔 패스”로 계산하여 16바이트 정렬로 잡습니다.

### 3.2) 호출

표현식에서:

```b
name(expr0, expr1, ...)
```

- 인자 최대 6개

---

## 4) 문장(Statements)

v2의 함수 본문 `{ ... }` 내부에서 아래 문장들을 지원합니다.

### 4.1) 블록

```b
{ stmt* }
```

- v2는 독립 블록을 문장으로 지원합니다.
- 블록은 **렉시컬 스코프**를 가지며, 블록 종료 시 내부 선언(`var`)은 스코프에서 제거됩니다.

### 4.2) var 선언

형태:

```b
var x;
var x = expr;

var arr[10];

var s: Pair;
var p: *Pair;
```

정확한 문법(현재 구현):

```
'var' IDENT
  ['[' INT ']']
  [ ':' ['*'] IDENT ]
  [ '=' expr ]
';'
```

제약(중요):
- 배열(`var arr[N]`)은 **초기화(`= expr`)가 금지**입니다.
- by-value struct 로컬(`var s: Pair`)은 **`= expr` 초기화가 금지**입니다.
  - 대신 선언에서만 **brace-init**을 지원합니다: `var s: Pair = { expr0, expr1, ... };`
  - 초기화 값은 **struct 선언 순서대로 필드에 대입**됩니다.
  - 값이 필드 수보다 많으면 에러입니다.
  - 값이 필드 수보다 적으면, 남은 필드는 0 초기값(이미 0-init됨)을 유지합니다.
  - trailing comma(`{1,2,}`)는 현재 구현에서 지원하지 않습니다.
- by-value struct 로컬은 기본적으로 0으로 초기화됩니다.

### 4.3) alias

형태:

```b
alias rdi: x;
alias r10: tmp = 123;
```

정확한 문법:

```
alias <reg> ':' <name> [ '=' expr ] ';'
reg := rdi|rsi|rdx|rcx|r8|r9|r10|r11
```

- 이후 `name`을 읽고/쓰면 해당 레지스터를 사용합니다.

### 4.4) if / else

형태:

```b
if (cond) {
  stmt*
} else if (cond) {
  stmt*
} else {
  stmt*
}
```

- 조건 문법은 “조건식(cond)”(아래 5장)을 사용합니다.

### 4.5) while

```b
while (cond) {
  stmt*
}
```

### 4.6) break / continue

형태:

```b
break;
break(2);

continue;
continue(2);
```

- 기본은 1단계.
- `(num)`은 바깥 루프까지 점프합니다.
- `continue`는 `switch` 내부에서는 금지입니다.

### 4.7) return

형태:

```b
return;
return expr;
```

### 4.8) switch (IDENT 기반 키워드)

형태:

```b
switch (expr) {
  case 0:
    stmt*
  case 1:
    stmt*
  default:
    stmt*
}
```

특징/제약:
- `case`의 값은 **상수(INT/const/enum 등)** 여야 합니다.
- **No-fallthrough**: 각 case 바디는 암묵적으로 switch 끝으로 점프합니다.
  - 즉, C처럼 아래 case로 떨어지는 동작은 없습니다.
- `break;`는 switch에서도 사용 가능하며, switch 끝으로 나갑니다.

### 4.9) for (IDENT 기반 키워드)

형태:

```b
for (init?; cond?; post?) {
  stmt*
}
```

정확한 규칙(현재 구현):
- `init`은 아래 중 하나(또는 비어있음)입니다.
  - `;` (empty)
  - `var` 선언
  - `IDENT = expr;` 형태의 대입문
  - `expr;` 형태의 표현식 문장
- `cond`는 조건식(cond)이 아니라, `parse_cond_emit_jfalse`로 처리되는 **cond 문법**입니다.
  - 비어있으면 항상 참으로 처리됩니다.
- `post`는 아래 중 하나(또는 비어있음)입니다.
  - `IDENT = expr` (세미콜론 없음)
  - `expr` (세미콜론 없음)

### 4.10) foreach (IDENT 기반 키워드)

형태:

```b
foreach (x in expr) {
  stmt*
}
```

현재 구현의 의미(요약):
- `expr`은 `Slice*`로 평가되어야 합니다.
- 바이트 단위로 순회하면서 현재 바이트(0~255)를 loop 변수 `x`에 대입합니다.

### 4.11) 대입문

```b
x = expr;
```

- `x`가 alias면 레지스터에 저장합니다.
- `x`가 const면 에러.
- `x`가 로컬로 존재하지 않으면 전역 슬롯(`v_<x>`)으로 fallback 해서 저장합니다.

### 4.12) 메모리 store

다음을 지원합니다.

```b
ptr8[addr] = expr;
ptr64[addr] = expr;

*addr = expr;

arr[idx] = expr;

base.field = expr;
base->field = expr;
```

핵심 제약:
- `base.field` / `base->field`는 **typed local** 기반만 허용합니다.
  - `.`는 “포인터가 아닌(struct by-value) typed local”
  - `->`는 “포인터 typed local”
- 필드 접근/저장은 현재 **1/2/4/8 바이트 필드(u8/u16/u32/u64/i64)** 를 지원합니다.
  - `u8/u16` load는 `movzx`로 0-확장
  - `u32` load는 `mov eax, dword [...]`로 0-확장

### 4.13) 표현식 문장

```b
expr;
```

### 4.14) 인라인 asm

```b
asm {
  ; NASM 코드가 그대로 들어감
}
```

- 렉서가 `asm { ... }` 전체를 raw 토큰 하나로 만들어 파서에 넘깁니다.
- `{`와 마지막 `}` 사이의 바이트를 그대로 출력에 삽입합니다.
- 마지막이 개행이 아니면 개행을 보장합니다.

---

## 5) 조건식(Conditions)

`if (...)`, `while (...)`, `for`의 cond 자리에 들어가는 문법입니다.

지원되는 개념:
- `||`, `&&` 단락 평가(short-circuit)
- `!` (논리 not)
- 괄호
- 비교 연산: `== != < > <= >=`
- 비교 없이 `expr`만 쓰면 truthy(0이면 false)

개략 문법:

```
cond := or
or   := and ('||' and)*
and  := not ('&&' not)*
not  := '!' not | atom
atom := '(' cond ')' | expr [ (==|!=|<|>|<=|>=) expr ]
```

중요:
- `&&`, `||`는 **표현식(expr) 문법에는 없고**, 오직 조건식(cond)에서만 지원합니다.

---

## 6) 표현식(Expressions)

v2 표현식은 “우선순위 기반 재귀 하강”으로 구현되어 있습니다.

우선순위(높음 → 낮음):
- factor
- unary: `+ - ~ ! & *`
- term: `* / %`
- additive: `+ -`
- shift: `<< >>`
- relational: `< > <= >=`
- equality: `== !=`
- bitwise: `& ^ |`

### 6.1) factor

지원:
- INT
- STR(문자열 리터럴)
- IDENT
- 괄호: `(expr)`

그리고 IDENT 기반으로 아래를 해석합니다.

- 호출: `IDENT '(' args? ')'` (최대 6 args)
- 배열/인덱싱 load: `IDENT '[' expr ']'`
- 점 접근:
  - `IDENT '.' IDENT`
    - 먼저 `Name.Member` 형태의 점 상수(enum/const 테이블)를 찾고
    - 없으면 struct field load로 처리(typed local + 1/2/4/8B field 지원)
- 포인터 필드 접근: `IDENT '->' IDENT` (typed local pointer + 1/2/4/8B field 지원)
- 포인터 load:
  - `ptr8[expr]` : byte load 후 0-확장
  - `ptr64[expr]`: qword load

### 6.2) unary

- `&ident`는 **식별자(ident)만** 지원합니다(일반 lvalue의 주소를 잡는 기능은 아님).
  - 로컬 슬롯이 있으면 로컬 주소
  - 없으면 전역 슬롯(`v_<ident>`) 주소로 fallback
- `*expr`는 qword deref load입니다.

### 6.3) builtin (IDENT로 파싱)

다음은 “식별자 + 괄호” 형태로 빌트인처럼 처리됩니다.

- `cast(Type, expr)`
  - Type: `u8/u16/u32/u64/i64` (현재 구현 기준)
- `sizeof([*]Type)`
  - primitive, struct, 포인터 지원
- `offsetof(Type, field)`
  - struct의 필드 오프셋

---

## 7) 현재 구현의 핵심 제약/주의사항

- `import/enum/struct/switch/for/foreach`는 **토큰 키워드가 아니라 IDENT 비교**로 처리됩니다.
- 드라이버 의존성 스캔은 “파일 선두 연속 import”만 대상으로 합니다.
- `switch`는 **no-fallthrough** 입니다.
- struct field access/store는 typed local 기반 + **1/2/4/8 바이트 필드(u8/u16/u32/u64/i64)** 를 지원합니다.
- `&&`/`||`는 조건식(cond)에서만 지원됩니다(표현식에는 없음).
- 포인터 산술은 **typed scaling을 하지 않습니다**.
  - 즉, `p + 1`은 `sizeof(T)`가 아니라 **항상 바이트 단위 +1** 입니다.
  - 권장 스타일: `p = p + sizeof(T);` 처럼 명시적으로 작성
- `var arr[N] = ...` (배열 초기화) 미지원
- `Struct { ... }` 같은 “struct 리터럴 expression”은 미지원(= return/by-value 인자/표현식 값 생성 안 함)
- top-level 전역 `var`의 초기값은 const-expr만 지원합니다.

---

## 8) 짧은 예제 모음

### 8.1) enum/const/switch

```b
enum E { A, B = 10, C };
const X = E.B + 1;

func main() {
  switch (X) {
    case 11:
      return 1;
    default:
      return 0;
  }
}
```

### 8.2) struct + field (sized fields)

```b
struct Pair { a: u64; b: u64; };

func main() {
  var p: Pair;
  p.a = 3;
  p.b = 4;
  return p.a + p.b;
}

### 8.3) struct brace-init (선언 전용)

```b
struct S { a: u64; b: u8; c: u16; };

func main() {
  var s: S = { 10, 2, 3 };
  return s.a + s.b + s.c;
}
```
```

### 8.3) for / break depth

```b
func main() {
  var i = 0;
  for (i = 0; i < 10; i = i + 1) {
    if (i == 7) { break; }
  }
  return i;
}
```

### 8.4) foreach (Slice*)

```b
func main() {
  var x;
  foreach (x in "hi") {
    // x는 'h', 'i'의 바이트 값으로 갱신됨
  }
  return 0;
}
```

---

## 9) (부록) `src/library/v1` 자료구조

여기서 설명하는 것들은 “v2 프론트엔드 문법(lexer/parser)” 자체가 아니라, 레포에 포함된 **B(Stage1) 코드로 구현된 자료구조/유틸 라이브러리**입니다.

- 위치: `src/library/v1/`
- 용도: v2 컴파일러/런타임 구현에서 재사용 가능한 HashMap/Arena/StringInterner/StringBuilder 제공

중요(빌드/병합 제약):
- `src/library/v1/prelude.b`에는 `layout` 선언만 있고, Stage1의 제약 때문에 **`layout/const/var` 선언은 병합된 빌드 유닛에서 모든 `func` 정의보다 앞**에 와야 합니다.
  - 즉, 이 라이브러리를 사용하는 merged `.b`를 만들 때는 `prelude.b`를 가장 앞쪽에 포함시키는 편이 안전합니다.

### 9.1) HashMap (open addressing)

레이아웃(선언은 `src/library/v1/prelude.b`):

- `HashMapEntry { key_ptr, key_len, value, hash, used }`
- `HashMap { entries, cap, len }`

키/값 모델:
- 키: `(key_ptr, key_len)`로 주어지는 **바이트 시퀀스**
- 값: `u64` 1개(`value` 필드)

주의(수명/ownership):
- `hashmap_put`은 키 바이트를 복사하지 않고 **`key_ptr/key_len`을 그대로 엔트리에 저장**합니다.
- 따라서 키로 넣은 메모리는 HashMap이 살아있는 동안 유효해야 합니다.

API (현재 구현 기준):
- `hashmap_new(cap) -> HashMap*`
  - `cap`은 내부에서 power-of-two로 반올림되며 최소 8입니다.
- `hashmap_put(map, key_ptr, key_len, value) -> rax`
  - 반환 `rax`: 새 엔트리 삽입이면 1, 기존 키 업데이트면 0
  - **자동 리사이즈 없음(MVP)**: load factor 관리가 필요하면 호출자가 `hashmap_rehash`를 직접 호출해야 합니다.
- `hashmap_get(map, key_ptr, key_len) -> rax=value, rdx=ok`
- `hashmap_has(map, key_ptr, key_len) -> rax=1/0`
- `hashmap_rehash(map, new_cap)`
  - `map->entries`/`map->cap`만 교체하고 `map->len`은 유지합니다.

구현 메모:
- 해시: FNV-1a 64-bit
- 충돌 처리: linear probing

### 9.2) Arena (bump allocator)

레이아웃(선언은 `src/library/v1/prelude.b`):
- `Arena { base, cap, off }`

API:
- `arena_new(cap_bytes) -> Arena*`
  - 내부에서 `heap_alloc(cap+15)` 후 16바이트 정렬된 base를 사용합니다.
- `arena_alloc(a, size_bytes, align_pow2) -> rax=ptr | 0`
  - 공간 부족이면 0을 반환합니다.
  - `align_pow2==0`은 1로 취급합니다.
- `arena_reset(a)`
  - `off=0`으로 되돌립니다(해제는 하지 않음).

### 9.3) StringInterner

레이아웃(선언은 `src/library/v1/prelude.b`):
- `StringInterner { map, items }`
  - `map`: `HashMap*` (bytes -> id)
  - `items`: `Vec*` (u64 items; 각 원소는 `Slice*` 포인터)

API:
- `string_interner_new(cap) -> StringInterner*`
- `string_interner_intern(si, ptr, len) -> rax=id`
  - 반환 `id`는 **1-based** 입니다.
  - 새 문자열이면 `heap_alloc(len+1)`로 복사하고 NUL-terminate 합니다.
  - 같은 바이트 시퀀스가 이미 있으면 기존 id를 반환합니다.
- `string_interner_get(si, id) -> rax=ptr, rdx=len`
  - `id`가 0이거나 범위를 벗어나면 `0/0`을 반환합니다.

### 9.4) StringBuilder (byte buffer)

레이아웃(선언은 `src/library/v1/prelude.b`):
- `StringBuilder { ptr, len, cap }`
  - `ptr`은 **항상 NUL-terminated** 상태를 유지합니다.

API:
- `sb_new(cap_bytes) -> StringBuilder*`
  - `cap`은 최소 8로 보정됩니다.
  - 내부 버퍼는 `heap_alloc(cap+1)`로 잡고 NUL을 유지합니다.
- `sb_clear(sb)`
- `sb_len(sb) -> rax`
- `sb_ptr(sb) -> rax` (NUL-terminated)
- `sb_append_bytes(sb, p, n)`
- `sb_append_cstr(sb, cstr)`
- `sb_append_u64_dec(sb, x)`

구현 메모:
- 내부적으로 필요 시 용량을 2배씩 키우며 새 버퍼를 `heap_alloc`하고 `memcpy`합니다(기존 버퍼 free 없음).

