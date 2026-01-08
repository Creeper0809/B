# v3 Syntax Reference

이 문서는 v3 컴파일러(hosted)에서 **현재 구현되어 동작하는** 모든 문법을 기술합니다.
v3_roadmap.md는 "목표", v3_syntax.md는 "현재 구현 상태"를 나타냅니다.

**컴파일러 특성**:
- **부트스트랩**: v2 컴파일러로 v3 컴파일러를 컴파일 (`src/v3_hosted/`)
- **아키텍처**: AST 기반 프론트엔드 + IR 미들엔드 + x86-64 백엔드
- **심볼 테이블**: 전역 심볼은 HashMap (O(1) lookup), 로컬 심볼은 Vec (블록 스코프)
- **타겟**: Linux x86-64 (System V ABI)

---

## 목차

1. [렉시컬 구조](#1-렉시컬-구조)
2. [타입 시스템](#2-타입-시스템)
3. [선언 (Declarations)](#3-선언-declarations)
4. [문장 (Statements)](#4-문장-statements)
5. [표현식 (Expressions)](#5-표현식-expressions)
6. [제어 흐름](#6-제어-흐름)
7. [함수](#7-함수)
8. [모듈 시스템](#8-모듈-시스템)
9. [제네릭](#9-제네릭)
10. [보안 기능](#10-보안-기능)
11. [Unsafe 연산](#11-unsafe-연산)
12. [내장 함수 (Builtins)](#12-내장-함수-builtins)
13. [인라인 어셈블리](#13-인라인-어셈블리)
14. [MVP 제약사항](#14-mvp-제약사항)

---

## 1. 렉시컬 구조

### 1.1 주석

```b
// 한 줄 주석만 지원
// 블록 주석(/* ... */)은 지원하지 않음
```

### 1.2 식별자

- 규칙: `[_A-Za-z][_A-Za-z0-9]*`
- 키워드는 식별자로 사용 불가
- `_` (언더스코어 단독)는 버리기 식별자로 특별 취급

### 1.3 키워드

```
import      const       var         func        return
struct      enum        if          else        while
for         foreach     switch      case        default
break       continue    alias       asm         cast
sizeof      offsetof    impl        defer       wipe
print       println     panic       null        secret
nospill     packed      public      private     extern
```

### 1.4 연산자 및 구분자

**단일 문자**:
```
( ) { } [ ] ; , . : + - * / % = < > & | ^ ~ !
```

**다중 문자**:
```
&& || == != <= >= << >> ->
```

### 1.5 리터럴

**정수 리터럴**:
```b
42          // 10진수
0x2A        // 16진수 (0x 접두사)
```

**문자 리터럴**:
```b
'a'         // ASCII 문자
'\n'        // 이스케이프: \n \r \t \\ \'
'\x41'      // 16진수 이스케이프 (0x41 = 'A')
```

문자 리터럴은 컴파일 시 정수(u64)로 변환됩니다.

**문자열 리터럴**:
```b
"hello"     // 문자열
"line1\nline2\n"  // 이스케이프 포함
```

문자열 리터럴은 `.rodata`에 저장되며 `[]u8` 슬라이스로 취급됩니다.

**특수 리터럴**:
```b
null        // nullable 포인터용 (*T? 타입만)
```

---

## 2. 타입 시스템

### 2.1 기본 타입

**정수 타입**:
```b
u8, u16, u32, u64     // 부호 없는 정수 (8, 16, 32, 64비트)
i8, i16, i32, i64     // 부호 있는 정수 (8, 16, 32, 64비트)
```

**불린 타입**:
```b
bool                  // 논리 타입 (내부적으로 u8)
```

**비트 크기 정수** (packed struct용):
```b
u1, u2, u3, ..., u63  // 1~63비트 부호 없는 정수
i1, i2, i3, ..., i63  // 1~63비트 부호 있는 정수
```

### 2.2 포인터 타입

```b
*T          // non-null 포인터 (null 불가)
*T?         // nullable 포인터 (null 가능)
```

**정책**:
- `*T`에는 `null` 또는 `0` 대입 불가 (컴파일 에러)
- `*T?`에만 `null` 대입 가능
- `*T?`에 정수 `0` 대입 가능하지만 `null` 사용 권장
- `*T` ← `*T?` 변환 불가, `unwrap_ptr(p)` builtin 사용 필요
- null 비교: `*T?`만 `== null` / `!= null` 허용

**포인터 산술**:
```b
// 포인터 산술은 바이트 단위!
var p: *u64 = ...;
p = p + 8;         // *u64를 다음 요소로 (8바이트 증가)
// sizeof(u64) * n 형태로 명시적 계산 필요
```

### 2.3 슬라이스 타입

```b
[]T         // 슬라이스 (포인터 + 길이)
```

**레이아웃**:
```b
struct {
    ptr: *T;      // 데이터 포인터 (offset 0)
    len: u64;     // 길이 (offset 8)
}  // 총 16바이트
```

**타입 별칭**:
```b
str         // []u8의 별칭 (문자열용)
```

**인덱싱**:
```b
var s: []u8 = "hello";
var c = s[0];       // safe: bounds check 수행
var c = s[$0];      // unsafe: bounds check 생략 ($로 명시)
```

### 2.4 배열 타입

```b
[N]T        // 고정 크기 배열 (N은 컴파일 타임 상수)
```

**다차원 배열**:
```b
[N][M]T     // N x M 배열 (배열의 배열)
a[i][j]     // 인덱싱
```

### 2.5 구조체 (struct)

```b
struct Name {
    field1: Type1;
    field2: Type2;
}
```

**packed struct** (비트필드):
```b
packed struct BitField {
    a: u3;      // 3비트
    b: u5;      // 5비트
    c: u6;      // 6비트
    d: u2;      // 2비트
}  // 총 16비트 (2바이트에 패킹)
```

- 일반 struct: 자동 패딩/정렬
- packed struct: 비트 단위 패킹, 패딩 없음

### 2.6 열거형 (enum)

```b
enum Color {
    Red,         // 0
    Green,       // 1
    Blue = 10,   // 10
    Yellow,      // 11
}
```

- 기본값: 0부터 시작, 이전 값 +1
- 명시적 값 지정 가능
- trailing comma 허용
- 내부 타입: `u64`

---

## 3. 선언 (Declarations)

### 3.1 import

```b
import "path/to/module";
```

**규칙**:
- 파일 맨 위 연속 구간에만 허용
- 1 파일 = 1 모듈
- 모듈명 = 파일 basename (확장자 제외)

### 3.2 전역 변수

```b
var name: Type;
var name: Type = const_expr;
```

- 초기값은 컴파일 타임 상수만 가능
- 기본 가시성: `private`
- `public var`로 외부 공개 가능

### 3.3 전역 상수

```b
const NAME = value;
```

- 타입: 항상 `u64`
- 값: 컴파일 타임 상수 표현식

### 3.4 함수

```b
func name(param1: Type1, param2: Type2) -> RetType {
    // body
}
```

**파라미터 생략** (v2 호환):
```b
func name(param1, param2) {  // 타입 없으면 u64로 추론
    // ...
}
```

**제약**:
- 최대 파라미터: 6개
- 리턴 타입 생략 시 `u64` (v2 호환)

### 3.5 struct 선언

```b
struct Name {
    field1: Type1;
    field2: Type2;
}
```

**접근 제어**:
```b
public struct Name {     // 타입 자체 공개
    public field1: Type; // 필드 공개
    private field2: Type; // 필드 비공개 (기본값)
}
```

외부 모듈에서 필드 접근하려면:
1. 타입이 `public`
2. 필드도 `public`

### 3.6 enum 선언

```b
enum Name {
    Variant1,
    Variant2 = value,
    Variant3,
}
```

### 3.7 impl 블록

```b
impl TypeName {
    func method1(self: TypeName, ...) -> RetType {
        // ...
    }
}
```

- 메서드 호출 설탕: `x.method(y)` ⇒ `method(x, y)`
- 첫 번째 파라미터가 `self: TypeName`이면 메서드로 인식

---

## 4. 문장 (Statements)

### 4.1 지역 변수 선언

```b
var x: Type;
var x: Type = expr;
```

**배열 선언**:
```b
var arr: [4]u8;
var arr: [4]u8 = {1, 2, 3, 4};  // 초기화
```

- 초기화 시 원소 개수는 정확히 일치해야 함
- 부족/초과는 컴파일 에러

**v2 호환 배열 문법** (구현됨):
```b
var arr[4];             // u64 배열 (항상 u64)
var arr[4] = {1,2,3,4}; // 초기화 가능
```

- `var arr[N]`은 자동으로 `var arr: [N]u64`로 변환
- `var arr[N]: Type` 형태는 불가 (에러)

**struct 초기화**:
```b
var s: S = {field1_val, field2_val, ...};
```

- 선언 시에만 brace-init 허용
- 필드 순서대로 값 나열

### 4.2 변수 섀도잉

```b
var x = 10;
{
    var x = 20;    // 새로운 x (외부 x 가림)
    // x == 20
}
// x == 10 (외부 x 복원)
```

- 블록 스코프마다 독립적인 변수 슬롯
- foreach 바인딩 변수도 섀도잉 가능

### 4.3 레지스터 별칭

```b
alias rax: name;
alias rax: name = expr;
```

**허용 레지스터**:
```
rax rbx rcx rdx rsi rdi r8 r9 r10 r11 r12 r13 r14 r15
```

**금지**:
- `rsp`: 스택 포인터 (항상 금지)
- `rbp`: 제한적 허용 (프레임 포인터 필요 시 금지)

### 4.4 대입문

```b
x = expr;
arr[idx] = expr;
base.field = expr;
base->field = expr;
*ptr = expr;
```

**복합 대입** (구현됨):
```b
x += expr;
x -= expr;
x *= expr;
x /= expr;
x %= expr;
x &= expr;
x |= expr;
x ^= expr;
x <<= expr;
x >>= expr;
```

**증감 연산자** (구현됨):
```b
x++;
x--;
++x;
--x;
```

### 4.5 표현식 문장

```b
func_call(args);
x++;
```

### 4.6 defer 문

```b
defer stmt;
```

**동작**:
- 현재 블록 종료 시 역순(LIFO)으로 실행
- `return`, 블록 끝에서 실행
- `break`/`continue` 시에도 실행

**예제**:
```b
{
    var fd = open("file");
    defer close(fd);    // 블록 끝에서 자동 호출
    // ... 작업 ...
}  // close(fd) 실행
```

### 4.7 wipe 문

```b
wipe var_name;
```

**용도**:
- `secret` 변수를 0으로 zeroize
- 최적화로 인한 제거 방지 (volatile)
- 민감한 데이터(키, 비밀번호) 정리

---

## 5. 표현식 (Expressions)

### 5.1 연산자 우선순위

(높음 → 낮음)

1. **Primary**: `()`, `[]`, `.`, `->`, 함수 호출
2. **Unary**: `+`, `-`, `~`, `!`, `&`, `*`, `cast`, `sizeof`, `offsetof`
3. **Multiplicative**: `*`, `/`, `%`
4. **Additive**: `+`, `-`
5. **Shift**: `<<`, `>>`
6. **Relational**: `<`, `>`, `<=`, `>=`
7. **Equality**: `==`, `!=`
8. **Bitwise AND**: `&`
9. **Bitwise XOR**: `^`
10. **Bitwise OR**: `|`
11. **Logical AND**: `&&`
12. **Logical OR**: `||`

### 5.2 산술 연산

```b
a + b
a - b
a * b
a / b
a % b
-a
+a
```

**타입 규칙**:
- 양쪽 피연산자 타입이 달라야 컴파일 에러
- 리터럴은 문맥에서 타입 추론
- 타입 변환은 `cast` 명시 필요

```b
var a: u8 = 10;
var b: u32 = 20;
var c = a + b;          // 에러: 타입 불일치
var c = cast(u32, a) + b;  // OK
```

### 5.3 비트 연산

```b
a & b       // AND
a | b       // OR
a ^ b       // XOR
~a          // NOT
a << n      // 왼쪽 시프트
a >> n      // 오른쪽 시프트
```

**shift 규칙**:
- shift count는 `u8` 권장
- 결과 타입은 왼쪽 피연산자 타입

### 5.4 비교 연산

```b
a == b
a != b
a < b
a > b
a <= b
a >= b
```

- 양쪽 타입 일치 필요
- 결과: `bool`

**포인터 null 비교**:
```b
var p: *u8? = null;
if (p == null) { ... }  // OK
if (p != null) { ... }  // OK

var q: *u8 = ...;
if (q == null) { ... }  // 에러: *T는 null 비교 불가
```

### 5.5 논리 연산

```b
a && b      // 논리 AND (short-circuit)
a || b      // 논리 OR (short-circuit)
!a          // 논리 NOT
```

### 5.6 인덱싱

```b
arr[idx]        // 배열/슬라이스 인덱싱 (safe, bounds check)
arr[$idx]       // unsafe 인덱싱 ($ 접두사, bounds check 생략)
```

**참고**: v2의 `ptr8[addr]`/`ptr64[addr]` 매직 식별자는 v3에서 미지원.
타입화된 포인터 역참조를 사용하세요:

```b
// v2 스타일 (v3 미지원)
// ptr8[addr] = val;

// v3 스타일
var p: *u8 = cast(*u8, addr);
*p = val;
val = *p;
```

### 5.7 필드 접근

```b
obj.field       // 구조체 필드 접근
ptr->field      // 포인터를 통한 필드 접근 (obj = *ptr; obj.field)
```

### 5.8 포인터 연산

```b
&var            // 주소 (현재: 변수만 허용, lvalue는 후순위)
*ptr            // 역참조 (load)
*ptr = val;     // 역참조 (store)
```

### 5.9 함수 호출

```b
func_name(arg1, arg2, ...)
```

- 최대 인자: 6개
- ABI: System V (rdi, rsi, rdx, rcx, r8, r9)

### 5.10 메서드 호출 설탕

```b
obj.method(args...)   // method(obj, args...)로 변환
```

---

## 6. 제어 흐름

### 6.1 if/else

```b
if (cond) {
    // ...
}

if (cond) {
    // ...
} else {
    // ...
}

if (cond1) {
    // ...
} else if (cond2) {
    // ...
} else {
    // ...
}
```

### 6.2 while

```b
while (cond) {
    // ...
}
```

### 6.3 for

```b
for (var i = 0; i < n; i = i + 1) {
    // ...
}
```

### 6.4 foreach

```b
foreach (var elem in container) {
    // elem: 요소 타입
}

foreach (var idx, var elem in container) {
    // idx: u64, elem: 요소 타입
}
```

**지원 컨테이너**:
- `[]T` (슬라이스)
- `[N]T` (배열)

**버리기 바인딩**:
```b
foreach (var _, var elem in arr) {  // 인덱스 무시
    // ...
}

foreach (var idx, var _ in arr) {   // 요소 무시
    // ...
}
```

### 6.5 switch

```b
switch (expr) {
    case value1:
        // ...
    case value2:
        // ...
    default:
        // ...
}
```

**특징**:
- **no-fallthrough**: 각 case는 암묵적으로 switch 끝으로 점프
- `break` 명시 가능 (조기 탈출)
- `default`는 선택적

**제약**:
- `continue`는 switch 내부에서 금지

### 6.6 break/continue

```b
break;
continue;

break n;        // n단계 루프 탈출
continue n;     // n단계 루프 다음 반복
```

- `n`은 컴파일 타임 상수
- 기본값: `n = 1`

### 6.7 return

```b
return;
return expr;
```

---

## 7. 함수

### 7.1 함수 정의

```b
func name(p1: T1, p2: T2) -> RetType {
    // body
}
```

**v2 호환 간소 문법**:
```b
func name(p1, p2) {  // 파라미터 타입 생략 시 u64
    // body
}
```

### 7.2 extern 함수

```b
extern "C" {
    func malloc(size: u64) -> *u8?;
    func free(ptr: *u8?);
}
```

**단일 선언 형태**:
```b
extern "C" func printf(fmt: *u8, ...) -> i32;
```

**레지스터 지정** (System V ABI 재정의):
```b
extern "C" @[reg("rax", "rdi")] func my_syscall(arg: u64) -> u64;
```

- `@[reg("ret_reg", "arg1_reg", ...)]` 순서

---

## 8. 모듈 시스템

### 8.1 가시성

**기본값**: `private` (모듈 내부만)

**공개**:
```b
public var global_var: u64;
public const CONSTANT = 42;
public func utility();
public struct Data { ... }
public enum Status { ... }
```

### 8.2 심볼 해석

**전역 심볼**:
- HashMap 기반 (O(1) lookup)
- 스코프: 전역, 외부 모듈(import)

**로컬 심볼**:
- Vec 기반 (역순 검색)
- 스코프: 함수, 블록 (렉시컬 스코프)

**해석 순서**:
1. 로컬 스코프 (안쪽 → 바깥쪽)
2. 함수 파라미터
3. 전역 스코프 (현재 모듈)
4. import된 외부 모듈

### 8.3 필드 접근 제어

```b
public struct S {
    public field1: u64;    // 외부 접근 가능
    private field2: u64;   // 모듈 내부만
}
```

외부에서 `field2` 접근 시 컴파일 에러.

---

## 9. 제네릭

### 9.1 제네릭 함수

```b
func identity<T>(x: T) -> T {
    return x;
}

var a: u32 = identity<u32>(42);

```

### 9.2 제네릭 구조체

```b
struct Pair<T, U> {
    first: T;
    second: U;
}

var p: Pair<u64, bool>;
```

### 9.3 Monomorphization

- AST 단계에서 타입별 인스턴스 생성
- 각 `<T=u64>` 조합마다 별도 함수/타입 생성
- 런타임 오버헤드 없음

### 9.4 제약 (MVP)

- **타입 인자 추론**: 미구현, 명시적 타입 인자 필수 (`f<T>(x)` 형태)
- Value generics (V4로 이동): `func foo<const N: u64>() { ... }`
- Trait bounds: 미구현
- Default type parameters: 미구현

---

## 10. 보안 기능

### 10.1 secret 변수

```b
secret var key: [32]u8;
```

**속성**:
- 레지스터 스필 금지 (`nospill` 자동 적용)
- `wipe` 문으로 zeroize 보장
- 컴파일러 최적화로 인한 제거 방지

### 10.2 wipe 문

```b
secret var password: [64]u8;
// ... 사용 ...
wipe password;  // 0으로 안전하게 지움
```

- IR: `SECURE_STORE` 명령어 (volatile)
- 최적화로 제거되지 않음

### 10.3 nospill 제약

```b
nospill var sensitive: u64;
```

- 해당 변수는 레지스터에만 유지
- 스택 스필 필요 시 컴파일 에러
- `secret` 변수는 자동으로 `nospill`

---

## 11. Unsafe 연산

### 11.1 $ 접두사

unsafe 연산을 명시적으로 표시:

```b
var arr: [10]u8;
var x = arr[$i];        // unsafe 인덱싱 (bounds check 생략)

struct S { field: u64; }
var s: S;
var z = s.$field;       // unsafe 필드 접근 (접근 제어 우회)
```

**정책**:
- `$` 표시가 없으면 safe (bounds check 수행)
- 디버그 모드에서도 동작 변화 없음 (트랩 삽입 안 함)

---

## 12. 내장 함수 (Builtins)

### 12.1 타입 연산

```b
sizeof(Type)             -> u64    // 타입 크기 (바이트)
sizeof(*Type)            -> u64    // 포인터 타입 크기 (항상 8)
offsetof(Type, field)    -> u64    // 필드 오프셋
```

### 12.2 타입 변환

```b
cast(TargetType, expr)   -> TargetType
```

- 정수 ↔ 정수 (크기 변환, 부호 변환)
- 포인터 ↔ 정수
- 포인터 타입 간 변환

### 12.3 포인터 연산

```b
unwrap_ptr(p: *T?) -> *T
```

- nullable 포인터를 non-null로 변환
- `p == null`이면 패닉 (런타임 검사)

### 12.4 슬라이스 생성

```b
slice_from_ptr_len(ptr: *T, len: u64) -> []T
```

### 12.5 출력

```b
print(args...)      // 개행 없이 출력
println(args...)    // 개행 포함 출력
```

**지원 타입**:
- `[]u8`, `str`: 문자열
- `u8`, `u16`, `u32`, `u64`: 10진수 출력

**예제**:
```b
print("x = ", 42, ", y = ", 100);   // "x = 42, y = 100"
println("Hello World");              // "Hello World\n"
```

### 12.6 패닉

```b
panic(msg: str)
```

- stderr에 메시지 출력
- `exit(1)`로 종료

---

## 13. 인라인 어셈블리

```b
asm {
    mov rax, 42
    add rax, 7
}
```

**제약**:
- raw 텍스트 그대로 출력
- 템플릿/치환 기능 없음 (v2 호환)
- 레지스터 충돌 책임은 사용자에게

---

## 14. MVP 제약사항

### 14.1 타입 시스템

**지원하지 않음**:
- `usize`/`isize`: u64/i64 사용
- 부동소수점: `f32`, `f64`
- 튜플 타입: `(T, U)` (V4로 이동)
- Union 타입
- 함수 포인터 타입 (원시 포인터로 대체 가능)

### 14.2 표현식

**지원하지 않음**:
- Struct 리터럴 표현식: `S { field: value }` (선언에서만 brace-init)
- 배열 리터럴 표현식: `[1, 2, 3]` (선언에서만 brace-init)
- 삼항 연산자: `cond ? a : b`

### 14.3 함수

**제약**:
- 최대 파라미터: 6개 (ABI 제약)
- 다중 리턴 (V4로 이동): `func f() -> (T, U)`
- 가변 인자: 컴파일러 매직(`print`)만 지원, 사용자 함수 불가
- 익명 함수/클로저: 미지원

### 14.4 제네릭

**제약**:
- Value generics (V4로 이동): `<const N: u64>`
- Trait bounds: 미지원
- Associated types: 미지원
- Default type parameters: 미지원

### 14.5 제어 흐름

**제약**:
- Labeled break/continue: 미지원 (`break n` 형태만)
- `goto`: 미지원
- `match` 표현식: 미지원 (switch는 문장만)

### 14.6 메모리 레이아웃

**포인터 산술**:
- 바이트 단위 증감 (typed scaling 없음)
- `p + 1` = 1바이트 증가 (sizeof(T) 아님)

**struct 정렬**:
- 일반 struct: 자동 패딩/정렬
- packed struct: 비트 단위 패킹

### 14.7 모듈 시스템

**제약**:
- 순환 import: 검출하지 않음 (무한 루프 가능)
- import 경로 해석: 상대 경로만, 패키지 관리 없음
- Re-export: 미지원 (`pub use` 없음)

### 14.8 컴파일러

**심볼 테이블**:
- 전역: HashMap (O(1))
- 로컬: Vec (O(n) 역순 검색, 소규모 함수에서는 무시 가능)

**에러 복구**:
- 최소 구현 (`;`/`}` 싱크)
- 에러 후에도 파싱 계속하지만 품질 제한적

**최적화**:
- Dead code elimination: 미구현
- Constant folding: 제한적 (const-expr만)
- Inlining: 미구현

### 14.9 V4로 이동된 기능

다음 기능은 v4_roadmap.md로 이동:

- **타입 추론**: `var x = expr;` (타입 생략)
- **Value generics**: `<const N: u64>`
- **comptime**: 컴파일 타임 실행
- **다중 리턴**: `func f() -> (T, U)`
- **Struct 리터럴 표현식**: `S { field: value }`
- **고급 trait 시스템**

---

## 15. 예제

### 15.1 Hello World

```b
func main() {
    println("Hello World");
    return 0;
}
```

### 15.2 구조체 + 메서드

```b
struct Point {
    x: u64;
    y: u64;
}

impl Point {
    func distance(self: Point) -> u64 {
        return self.x + self.y;  // 간소화된 거리
    }
}

func main() {
    var p: Point;
    p.x = 3;
    p.y = 4;
    return p.distance();  // 7
}
```

### 15.3 제네릭 함수

```b
func max<T>(a: T, b: T) -> T {
    if (a > b) {
        return a;
    }
    return b;
}

func main() {
    var x: u64 = max<u64>(10, 20);  // 명시적 타입 인자 필요
    return x;  // 20
}
```

### 15.4 foreach + 슬라이스

```b
func sum_bytes(s: str) -> u64 {
    var total: u64 = 0;
    foreach (var b in s) {
        total = total + cast(u64, b);
    }
    return total;
}

func main() {
    var s: str = "hello";
    return sum_bytes(s);
}
```

### 15.5 defer

```b
func process_file(path: str) {
    var fd = open(path);
    defer close(fd);
    
    // 파일 처리
    var data = read(fd);
    defer free(data);
    
    // ... 작업 ...
}  // free(data) 실행 → close(fd) 실행 (역순)
```

### 15.6 secret + wipe

```b
func authenticate(password: str) -> bool {
    secret var key: [32]u8;
    derive_key(password, &key);
    
    var result = verify_key(&key);
    
    wipe key;  // 메모리에서 안전하게 제거
    return result;
}
```

### 15.7 packed struct (비트필드)

```b
packed struct Header {
    version: u4;
    flags: u4;
    length: u8;
}

func main() {
    var h: Header;
    h.version = 1;
    h.flags = 0xF;
    h.length = 255;
    
    // 총 16비트 (2바이트)에 패킹됨
    return sizeof(Header);  // 2
}
```

---

## 16. 참고 문서

- **v3_roadmap.md**: 기능 로드맵 및 설계 결정
- **v3_todo.md**: 구현 진행 상황 및 테스트 결과
- **v4_roadmap.md**: V4로 이동된 고급 기능

---

## 17. 컴파일러 정보

**버전**: v3_hosted (2026-01-08 기준)

**테스트 현황**:
- Passing: 33 tests
- Failing: 4 tests (V4 이동 예정 기능)

**구현 위치**: `src/v3_hosted/`

**주요 모듈**:
- `token.b`: 토큰 정의
- `lexer.b`: 렉서
- `ast.b`: AST 노드 정의
- `parser.b`: 파서
- `typecheck.b`: 타입 체크
- `ir.b`: IR 정의
- `codegen.b`: 코드 생성 (x86-64)

**빌드**:
```bash
./bin/v2c src/v3_hosted/main.b --out bin/v3h
```

**사용**:
```bash
./bin/v3h input.b          # 파일 컴파일
./bin/v3h - < input.b      # stdin 컴파일
./bin/v3h --dump-ir input.b # IR 덤프
```

---

**끝**: 이 문서는 v3에서 **현재 구현되어 동작하는** 문법만을 기술합니다. 로드맵이나 미구현 기능은 v3_roadmap.md를 참조하세요.
