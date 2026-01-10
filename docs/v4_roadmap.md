# v4 Roadmap (Draft)

v4는 v3(MVP)에서 의도적으로 뒤로 미룬 “블랙홀 위험 기능”을 다룹니다.
목표는 기능을 더 넣는 것보다, **컴파일러/IR/표준 라이브러리 기반이 충분히 단단해진 뒤**
고급 기능을 안전하게 확장하는 것입니다.

원칙:
- v3에서 미룬 기능은 “그냥 나중에”가 아니라, v4에서 **명시적 범위/제약/실패 모드**를 먼저 고정한다.
- 컴파일러 내부 실행기/검증/퍼징은 쉽게 규모가 커지므로, 결정성/샌드박스/리소스 제한을 최우선으로 둔다.

---
## Breaking Change: 파일 확장자 변경

**v4부터 B 언어 파일 확장자가 `.b`에서 `.bpp`로 변경됩니다.**

### 이유

1. **언어 진화 표시**: v4는 v3 MVP와 달리 완전한 언어로 성장
2. **다른 언어와의 충돌 방지**: 
   - `.b` = Brainfuck, B (historic language), Boo 등 다수 언어 사용
   - `.bpp` = B++ (B Plus Plus), 고유한 확장자
3. **프로젝트 구분 명확화**:
   - v3 이전: `.b` (프로토타입)
   - v4 이후: `.bpp` (정식 버전)

### 마이그레이션

**폴더 구조**:
```
B/
├── src/          # v3 컴파일러 (.b 파일)
├── std/          # v3 표준 라이브러리 (.b 파일)
├── examples/     # v3 예제 (.b 파일)
├── test/         # v3 테스트 (.b 파일)
└── bpp/          # v4 전용 폴더 (v4부터 모든 개발은 여기서)
    ├── src/      # v4 컴파일러 (.bpp 파일)
    ├── std/      # v4 표준 라이브러리 (.bpp 파일)
    ├── examples/ # v4 예제 (.bpp 파일)
    └── test/     # v4 테스트 (.bpp 파일)
```

**이유**:
1. **v3와 v4 명확한 분리**: 기존 v3 코드 보존
2. **점진적 전환**: v4 개발을 별도로 진행하면서 v3 유지보수 가능
3. **테스트 분리**: v3 golden test와 v4 테스트 별도 관리
4. **클린 트리**: 프로젝트 구조 명확화

**v4.0 출시 시점**:
- [ ] `bpp/` 폴더 생성
- [ ] `bpp/src/`, `bpp/std/`, `bpp/examples/`, `bpp/test/` 생성
- [ ] v4 컴파일러를 `bpp/src/`에서 개발 시작
- [ ] v4 표준 라이브러리를 `bpp/std/`에서 개발
- [ ] 컴파일러가 `.b`와 `.bpp` 모두 인식 (하위 호환)
- [ ] 경고 메시지: "`.b` is deprecated, use `.bpp` instead"
- [ ] 빌드 시스템: `bpp/` 폴더 지원 추가

**v4.1 출시 시점**:
- [ ] `.b` 지원 완전 제거
- [ ] `.bpp`만 인식
- [ ] 상위 폴더 `.b` 파일들은 유지 (v3 아카이브)

**파일명 예시**:
```
이전: main.b, vec.b, test_parser.b
이후: main.bpp, vec.bpp, test_parser.bpp
```

---
## 0) v3 기능 현황 및 v4 확장

### v3에서 완료된 기능 (v4 Base)

v4는 v3의 모든 문법을 상속받습니다. 아래는 v3에서 이미 구현된 기능입니다:

- [x] **기본 타입**: u8/u16/u32/u64, i8/i16/i32/i64, bool, f32/f64
- [x] **포인터 타입**: `*T` (non-null), `*T?` (nullable)
- [x] **슬라이스**: `[]T` (포인터 + 길이)
- [x] **배열**: `[N]T` (고정 크기, 다차원 지원)
- [x] **구조체**: 일반/packed, 필드 접근 제어
- [x] **열거형**: `enum`, 명시적 값 지정
- [x] **함수 포인터**: `func(T, U) -> R` (v3.7, 테스트 55)
- [x] **제네릭**: `<T>` 타입 파라미터 (명시적)
- [x] **타입 별칭**: `type Alias = T`, `type NewType = distinct T`
- [ ] **impl 블록**: ⚠️ v3에서 파싱만 지원, 실제 메서드 호출은 v4에서 구현 필요
- [x] **제어 흐름**: if/else, while, for, foreach, switch (no-fallthrough)
- [x] **break/continue N**: 중첩 루프 제어
- [x] **복합 대입**: `+=`, `-=`, `*=`, `/=`, etc.
- [x] **증감 연산자**: `++`, `--`
- [x] **defer**: 블록 종료/return 시 실행
- [x] **보안 기능**: wipe, secret, nospill
- [x] **Unsafe**: `$` 접두사 (인덱싱, 필드 접근)
- [x] **프로퍼티 훅**: `@[getter]`, `@[setter]`
- [x] **내장 함수**: print/println, panic, sizeof, offsetof, cast
- [x] **인라인 어셈블리**: `asm { ... }` 블록
- [x] **모듈 시스템**: import, public/private
- [x] **변수 섀도잉**: 중첩 블록 스코프

### v3에서 이동된 항목 (Deferred from v3)

v3 MVP 구현 중 복잡도/블랙홀 리스크로 인해 v4로 미룬 항목들.

### 0.0) 언어 키워드/문법 추가 (Language Features)

v3에는 없지만 현대 프로그래밍 언어가 기본적으로 제공해야 하는 문법 요소들.
**원칙**: B의 명시성/저수준 철학 유지, Rust 소유권 시스템은 차용하지 않음.

#### 제어 흐름 키워드

- [ ] **`match`**: 패턴 매칭 표현식 (모든 타입 지원, `switch` 대체)
  ```b
  // enum variant 매칭 (주 용도)
  match file_result {
      Result.Ok(f) => process(f),
      Result.Err(e) => println("error: ", e),
  }
  
  // union 디스트럭처링
  match value {
      Value.i64(x) => println("int: ", x),
      Value.f64(f) => println("float: ", f),
      _ => println("other"),
  }
  
  // 원시 타입 매칭 (컴파일러가 자동으로 점프 테이블 최적화)
  match opcode {
      0x01 => add(),
      0x02 => sub(),
      0x03 => mul(),
      _ => error(),
  }
  ```
  
  **통합 전략** (`switch` 제거, `match`로 통합):
  
  컴파일러 입장에서 `switch`는 `match`의 **"특수한 경우(Special Case)"**입니다.
  
  **Lowering 단계 최적화**:
  - **복잡한 패턴 매칭 (enum/union)**: Tag 비교 + 분기 + 데이터 언패킹 생성
  - **단순 원시 타입 (int/char)**: **자동으로 `switch`와 동일한 기계어 생성**
    - Dense 케이스 (값들이 빽빽함): **점프 테이블(Jump Table)** 생성 → O(1)
    - Sparse 케이스 (값들이 듬성듬성): **이진 탐색(Binary Search)** 또는 if-else 체인 → O(log N)
  
  **명시적 최적화 제어** (해커용):
  ```b
  // 점프 테이블 강제 (불가능하면 컴파일 에러)
  @[jump_table]
  match byte_opcode {
      0x00 => handle_nop(),
      0x01 => handle_add(),
      0x02 => handle_sub(),
      0x03 => handle_mul(),
      _ => handle_unknown(),  // 나머지 케이스
  }
  ```
  
  **결론**: 
  - **문법은 `match` 하나로 통합** (키워드 단순화)
  - **성능은 `switch` 그대로 유지** (컴파일러가 스마트하게 최적화)
  - **명시성 필요 시 `@[jump_table]` 어노테이션** (해커의 의도 표현)

#### 타입 시스템 키워드

- [ ] **`union`**: Raw Union (C-style, 태그 없음)
  
  **철학**: `union`은 **"메모리 해석기(Memory Interpreter)"**입니다.
  같은 메모리를 서로 다른 타입으로 보는 **Type Punning** 도구로, 해커와 시스템 프로그래머에게 필수입니다.

##### 사용 사례 1: Float 비트 뜯어보기 (Type Punning)

```b
union FloatInt {
    f: f32,
    i: u32,
}

var u: FloatInt;
u.f = 3.141592;

// 메모리는 그대로, 해석만 u32로 (IEEE 754 비트 패턴 추출)
print(hex(u.i));  // 0x40490FDB

// 용도: Fast Inverse Square Root, NaN 익스플로잇, 부동소수점 디버깅
```

**장점**: 포인터 캐스팅 없이 Type Punning 가능, Strict Aliasing 문제 회피

##### 사용 사례 2: IP 주소 변환 (Endianness 변환 없이 쪼개기)

```b
union IpAddr {
    full: u32,
    bytes: [4]u8,
}

var ip: IpAddr;
ip.full = 0x0100007F;  // 127.0.0.1 (Little Endian)

// 시프트 연산(>> 24) 없이 바로 배열 접근
print(ip.bytes[3]);  // 127
print(ip.bytes[0]);  // 1
```

**장점**: CPU 연산 비용 0, 메모리 읽기 위치만 다름

##### 사용 사례 3: 레지스터/플래그 조작 (Hardware Access)

```b
packed struct Flags {
    enable: u1,
    mode: u3,
    interrupt: u1,
    reserved: u27,
}

union ControlReg {
    raw: u32,      // 한방에 쓰기/읽기
    bits: Flags,   // 비트별 쪼개기
}

var ctrl: ControlReg;
ctrl.raw = 0;          // 초기화 (한방에)
ctrl.bits.enable = 1;  // 비트 하나만 켜기
ctrl.bits.mode = 5;    // 모드 설정 (3비트)

// 하드웨어 레지스터에 쓰기 (u32 한방)
mmio_write(0x4000, ctrl.raw);
```

**용도**: 커널 드라이버, DMA 제어, 하드웨어 레지스터 매핑

##### 제약사항 및 안전성

**위험성**:
- **Undefined Behavior 유발 가능**: `u.f = 3.14; print(u.i);` (OK)
- **역방향은 쓰레기 값**: `u.i = 0x12345678; print(u.f);` (Invalid Float)
- **해커는 이 쓰레기 값을 의도적으로 이용** (익스플로잇, 역공학)

**규칙**:
- 마지막으로 쓴 필드와 다른 필드를 읽는 것은 프로그래머 책임
- 컴파일러는 경고하지 않음 (명시적 unsafe 블록 불필요)
- 모든 필드는 union의 Offset 0부터 시작 (겹침)

**메모리 레이아웃**:
```
union Example {
    a: u64,   // [0..7] 8바이트
    b: u32,   // [0..3] 4바이트 (앞 4바이트만 사용)
    c: [8]u8, // [0..7] 8바이트 (전체 오버랩)
}

sizeof(Example) = 8  // 가장 큰 필드 크기
```

##### vs. Rust/Zig의 Tagged Union

**차이점**:
- **B의 union**: 태그 없음, Type Punning 전용 (C와 동일)
- **Rust enum**: 태그 있음, 안전한 Sum Type
- **Zig union(enum)**: 선택적 태그, 안전성 선택 가능

**B 언어 철학**: 
> "해커 언어는 프로그래머를 보호하지 않는다. 대신 최대한의 제어권을 준다."

- [ ] **`enum` with data**: variant enum (Sum Type / Tagged Union)
  ```b
  enum Option<T> {
      Some(T),
      None,
  }
  
  enum Result<T, E> {
      Ok(T),
      Err(E),
  }
  ```
  
  **union과의 차이점**:
  - **`enum`**: 컴파일러가 내부적으로 **태그(discriminator)** 필드를 추가하여 현재 어떤 variant인지 추적합니다.
    - 안전함: `match`로 패턴 매칭 시 모든 케이스 검사 강제
    - 메모리 비용: 태그 필드 추가로 인한 오버헤드 (padding 포함)
  - **`union`**: 태그 없음. 순수하게 메모리만 겹침. (Type Punning 전용)
    - 위험함: 프로그래머가 현재 타입 추적 책임
    - 메모리 효율: 최소 크기 (태그 없음)
  
  **예시**:
  ```b
  // enum: 안전한 Tagged Union
  enum Value {
      Int(i64),    // 태그 0
      Float(f64),  // 태그 1
  }
  // 메모리: [tag: u8][padding: 7바이트][data: 8바이트] = 16바이트
  
  // union: 해커용 Raw Union
  union RawValue {
      i: i64,   // Offset 0
      f: f64,   // Offset 0 (겹침)
  }
  // 메모리: [data: 8바이트] = 8바이트
  ```

#### 메모리 할당 키워드

- [ ] **`new`**: 힙 메모리 할당 연산자 (Syntactic Sugar)
  
  **정의**: `new <Type>`는 **어떤 타입이든** 힙에 할당하는 범용 연산자입니다.
  
  > **문법:** `new <Type>`  
  > **동작:**  
  > 1. `sizeof(<Type>)` 계산  
  > 2. `malloc(size)` 호출  
  > 3. `memset(ptr, 0, size)` (보안을 위해 0 초기화)  
  > 4. `cast(*<Type>, ptr)` 반환  
  
  따라서 `new u64`, `new bool`, `new Circle`, `new [10]u8` **모두 가능**합니다.
  자바/C++의 복잡한 "객체 생성자"가 아니라, **단순 메모리 할당 매크로**일 뿐입니다.

##### 1. 기본 문법: 일관성(Consistency)

**스택 할당 (기존):**
```b
var c: Circle;  // 스택에 sizeof(Circle) 할당
c.radius = 10.0;
```

**힙 할당 (new 키워드):**
```b
var p = new Circle;  // 힙에 할당, 포인터 반환
p.radius = 20.0;
```

**핵심 원칙**: `new`는 **"구조체 전용 매직"이 아닙니다**. 
일관성과 직교성을 위해 모든 타입에 작동해야 합니다.

##### 2. 컴파일러 변환 (Lowering)

`new T`는 다음과 같이 변환됩니다:

```b
// 소스 코드:
var p = new Circle;

// 컴파일러 IR 변환:
var size = sizeof(Circle);       // 1. 사이즈 자동 계산
var raw_ptr = malloc(size);      // 2. 힙 할당
memset(raw_ptr, 0, size);        // 3. 0으로 초기화 (보안)
var p = cast(*Circle, raw_ptr);  // 4. 타입 캐스팅
```

**중요**: 
- `new`는 메모리를 **자동으로 0으로 초기화**합니다 (uninitialized 메모리 취약점 방지)
- **`new T`**: 할당만 (생성자 호출 안 함)
- **`new T(...)`**: 할당 + 생성자 호출 (Syntactic Sugar, 섹션 "생성자/소멸자" 참조)

##### 3. 초기화 방법

**방법 1: 구조체 리터럴** (권장)
```b
var p = new Circle;
*p = Circle {
    radius: 10.0,
    color: Color { r: 255, g: 0, b: 0 }
};
```

**방법 2: 필드별 대입**
```b
var p = new Circle;
p.radius = 10.0;
p.color.r = 255;
```

**방법 3: 팩토리 함수 패턴** (권장)
```b
func create_circle(radius: f64) -> *Circle {
    var p = new Circle;
    p.radius = radius;
    p.color = Color { r: 0, g: 0, b: 0 };
    return p;
}

var c = create_circle(5.0);
```

##### 4. 메모리 해제

`new`로 할당한 메모리는 **생성자 없으면** `free`, **생성자 있으면** `delete`로 해제합니다:

**생성자 없는 타입** (단순 메모리):
```b
var p = new u64;
// ... 사용 ...
free(p);  // malloc의 대칭
```

**생성자 있는 타입** (리소스 관리):
```b
var p = new Socket(8080);
// ... 사용 ...
delete p;  // destructor() + free()의 설탕
```

**권장 패턴** (defer 사용):
```b
var p = new Socket(8080);
defer delete p;  // 스코프 종료 시 자동 해제
```

**철학**: `new`는 `malloc`의 설탕이지만, 생성자가 있는 경우 대칭성을 위해 `delete`를 제공합니다.
`delete`는 명시적으로 작성해야 동작하며(C++처럼 자동 호출 없음), 내부적으로 `destructor() + free()`를 호출합니다.

##### 5. 모든 타입 지원 (Any Type)

**원시 타입 (Primitive Types)**:
```b
// 정수 할당
var p: *u64 = new u64;
*p = 123;
print(*p);  // 123
free(p);

// 부울 할당
var flag: *bool = new bool;
*flag = true;
free(flag);

// 실수 할당
var f: *f64 = new f64;
*f = 3.14;
free(f);
```

**왜 필요한가?** (해커/시스템 프로그래머 관점)
1. **공유 상태**: 여러 함수에서 하나의 정수 값을 포인터로 공유/수정
2. **Opaque Pointer**: C API에 `void* user_data`로 정수를 전달할 때
3. **수명 연장**: 스택 변수는 함수 종료 시 소멸하지만, 힙 변수는 `free` 전까지 생존

**배열 타입 (Array Types)**:
```b
// 고정 크기 배열 힙 할당
var buffer: *[1024]u8 = new [1024]u8;
(*buffer)[0] = 0xFF;
// 또는 문법 설탕:
buffer[0] = 0xFF;
free(buffer);

// 구조체 배열
var circles: *[100]Circle = new [100]Circle;
circles[0].radius = 10.0;
free(circles);
```

**동적 크기 배열** (후순위):
```b
var n: u64 = 100;
var arr = new [n]Circle;  // VLA 스타일, 구현 난이도 높음
```

**포인터의 포인터 (Double Pointer)**:
```b
// *u64 타입을 담을 공간을 힙에 할당 (Linked List 등)
var pp: **u64 = new *u64;
*pp = new u64;    // 안에 또 힙 할당 주소를 넣음
**pp = 999;

// 사용 후 해제
free(*pp);
free(pp);
```

**함수 포인터 (Function Pointer)**:
```b
type Handler = func(u64) -> void;

// 함수 포인터를 힙에 할당
var fp: *Handler = new Handler;
*fp = my_handler;
(*fp)(42);  // 간접 호출
free(fp);
```

##### 7. 제약사항 및 철학

**제약 (거의 없음)**:
- **`new T`**: 생성자 호출 안 함 (단순 할당+0 초기화)
- **`new T(...)`**: 생성자 호출함 (`T.constructor(...)`의 설탕)
- `new`는 항상 포인터 반환 (`*T`)
- 배열의 경우 `*[N]T` 반환 (슬라이스 아님)
- **타입 제약 없음**: 어떤 타입이든 `new` 가능 (직교성)

**메모리 배치 (Placement)**: 
Placement new 문법은 제공하지 않습니다. 대신 명시적 cast + 초기화 조합을 사용합니다.
```b
// 스택 버퍼에 객체 배치
var buffer: [1024]u8;
var p = cast(*Circle, &buffer);
memset(p, 0, sizeof(Circle));
p.radius = 10.0;

// 또는 구조체 리터럴로
*p = Circle { radius: 10.0 };
```

**철학**:
- **일관성 (Consistency)**: 모든 타입에 대해 동일한 규칙
- **직교성 (Orthogonality)**: `new`는 "구조체 전용 매직" 아님
- **명시적 제어**: 스택(`var x: T`) vs 힙(`var x = new T`) 구분 명확
- **Zero-Cost Abstraction**: `new`는 런타임 오버헤드 없음
- **보안 우선**: 자동 0 초기화로 정보 누출 방지
- **해커 친화적**: cast와 memset 조합으로 임의 메모리 제어 가능

##### 8. 대안 검토

**왜 `malloc` 직접 쓰지 않나?**
```b
// Before (verbose, error-prone):
var p = cast(*Circle, malloc(sizeof(Circle)));
memset(p, 0, sizeof(Circle));

// After (clean, safe):
var p = new Circle;

// 원시 타입의 경우 더 극적:
// Before:
var p = cast(*u64, malloc(sizeof(u64)));
memset(p, 0, sizeof(u64));

// After:
var p = new u64;
```

**생산성**: 3줄 → 1줄, 타입 중복 없음, 실수 방지

**철학 유지**: 내부적으로 여전히 `malloc`이므로 "마법" 없음

**해커 스타일**: 제약 없이 모든 타입에 뚫어놓는다. 이것이 진정한 저수준 제어다.

#### 생성자/소멸자 (Constructor/Destructor)

**철학**: "문법적 설탕(Syntactic Sugar)"은 제공하되, "보이지 않는 마법(Hidden Control Flow)"은 제거합니다.

##### 1. 생성자 (`constructor`)

**목적**: 객체 초기화의 보일러플레이트(변수 생성, 리턴)를 제거합니다.

- [ ] **정의 규칙**: `impl` 블록 내부에 `constructor` 키워드로 정의
- [ ] **Auto-Self**: 함수 진입 시 `self` 변수(Zero-initialized)가 자동 생성
- [ ] **Auto-Return**: 함수 종료 시 `self`가 자동 반환

**기본 생성자**:
```b
struct Socket {
    fd: i32;
    port: u16;
}

impl Socket {
    // 리턴 타입 생략 시 -> Self로 간주
    constructor(port: u16) {
        // [Compiler Magic 1] var self: Socket; (0으로 초기화)
        
        self.port = port;
        self.fd = sys_socket(AF_INET, SOCK_STREAM, 0);
        
        if (self.fd < 0) { panic("Socket failed"); }
        
        // [Compiler Magic 2] return self; (자동 삽입)
    }
}
```

**실패 가능한 생성자** (Result 반환):
```b
impl Socket {
    constructor(port: u16) -> Result<Self, str> {
        // [Compiler Magic 1] var self: Socket; (0으로 초기화)
        
        if (port < 1024) {
            return Result.Err("Privileged port");
        }
        
        self.port = port;
        self.fd = sys_socket(AF_INET, SOCK_STREAM, 0);
        
        if (self.fd < 0) {
            return Result.Err("Socket creation failed");
        }
        
        // [중요] Result 반환 시 자동 포장 없음. 명시적으로 작성해야 함.
        return Result.Ok(self);
    }
}
```

**철학**: 일반 생성자(`-> Self`)는 `return self;` 자동 삽입으로 편의성 제공.
실패 가능 생성자(`-> Result<Self, E>`)는 명시적 `return Result.Ok(self);` 강제로 투명성 확보.

##### 2. 소멸자 (`destructor`)

**목적**: 자원 해제 로직을 한곳에 모읍니다. **절대 자동으로 호출되지 않습니다.**

- [ ] **정의 규칙**: `impl` 블록 내부에 `destructor` 키워드로 정의 (인자 없음)
- [ ] **동작**: 내부적으로 `func drop(self: *Self)` 메서드로 변환
- [ ] **역할**: `free(self)` 직전에 수행해야 할 로직(파일 닫기, 연결 해제) 정의

```b
impl Socket {
    destructor {
        if (self.fd > 0) {
            sys_close(self.fd);
            println("Socket closed: ", self.port);
        }
        // [주의] 여기서 free(self)를 하지 않음. 내부 자원만 정리.
    }
}
```

##### 3. 라이프사이클 키워드 (`Type(...)`, `new`, `delete`, `defer`)

**생성**:

- [ ] **스택 할당**: `Type(...)`
  ```b
  // 컴파일러 변환: var s = Socket.constructor(8080);
  var s = Socket(8080);
  ```

- [ ] **힙 할당**: `new Type(...)`
  ```b
  // 컴파일러 변환:
  // 1. var ptr = malloc(sizeof(Socket));
  // 2. *ptr = Socket.constructor(8080);
  // 3. return ptr;
  var ptr = new Socket(8080);
  ```

**해제**:

- [ ] **`delete ptr`**: 명시적 소멸자 호출 + 메모리 해제 (Syntactic Sugar)
  ```b
  delete ptr;
  
  // 컴파일러 변환:
  // if (ptr != null) {
  //     ptr.destructor();
  //     free(ptr);
  // }
  ```
  
  **철학**: C++의 암묵적 `delete`와 달리, B의 `delete`는 명시적으로 작성했을 때만 동작하는 편의 문법입니다.
  `new`가 "할당 + 생성자"의 대칭으로, `delete`는 "소멸자 + 해제"의 편의를 제공합니다.

- [ ] **`defer delete ptr`**: 스코프 종료 시 호출 (가장 권장되는 패턴)
  ```b
  func handle() {
      var ptr = new Socket(8080);
      defer delete ptr;  // 함수 종료 시 destructor() + free() 실행 예약
      
      // ... 작업 ...
  }
  ```

##### 4. 컴파일러 내부 동작 (Lowering)

**소스 코드**:
```b
struct A { x: i32; }

impl A {
    constructor(v: i32) {
        self.x = v;
    }
    
    destructor {
        print("Bye");
    }
}

func main() {
    var p = new A(10);
    defer delete p;
}
```

**Lowered IR** (실제 실행 코드):
```b
struct A { x: i32; }

// [Constructor -> init 함수 변환]
func A_init(v: i32) -> A {
    var self: A;      // 자동 생성
    memset(&self, 0, sizeof(A));  // Zero 초기화
    self.x = v;       // 사용자 코드
    return self;      // 자동 리턴
}

// [Destructor -> drop 함수 변환]
func A_drop(self: *A) {
    print("Bye");
}

func main() {
    // [new A(10) 변환]
    var _temp_ptr = cast(*A, malloc(sizeof(A)));
    *_temp_ptr = A_init(10);
    var p = _temp_ptr;
    
    // [defer delete p 변환]
    // (함수 종료 지점으로 이동)
    A_drop(p);  // 소멸자 호출
    free(p);    // 메모리 해제
}
```

##### 5. 요약 (Cheatsheet)

| 기능 | 문법 (Sugar) | 컴파일러 변환 (Raw) | 비고 |
|------|-------------|-------------------|------|
| **생성자 정의** | `constructor(args) { ... }` | `static func init(args) -> Self` | `self` 자동 생성/반환 |
| **소멸자 정의** | `destructor { ... }` | `func drop(self: *Self)` | 자동 호출 안 됨 (명시적) |
| **스택 생성** | `var a = Class(10);` | `var a = Class_init(10);` | |
| **힙 생성** | `var p = new Class(10);` | `malloc` + `init` + placement | |
| **즉시 소멸** | `delete p;` | `p.drop(); free(p);` | |
| **자동 소멸** | `defer delete p;` | 스코프 끝에 `delete p` 삽입 | **가장 권장되는 패턴** |

##### 6. 제약사항 및 철학

**제약**:
- 생성자는 **선언만으로 자동 호출되지 않음**: 
  - `var x: T;` → 생성자 호출 안 함 (Zero-initialized만)
  - `var x = T(...);` → 생성자 명시적 호출 (문법적 설탕)
  - `var ptr = new T(...);` → malloc + 생성자 호출
- 소멸자는 **스코프 종료 시 자동 호출되지 않음**: 명시적 `delete` 또는 `defer delete`만 가능
- 복사 생성자 없음: `var a = b;`는 그냥 memcpy
- 대입 연산자 오버로딩 없음: `a = b;`는 그냥 memcpy

**철학**:
- **"편리함"과 "투명함"의 균형**: 
  - 편리함: 자동 `self` 생성/반환 (보일러플레이트 제거)
  - 투명함: 명시적 `delete`/`defer` (자동 호출 없음)
- **Zero-Cost Abstraction**: 생성자/소멸자가 없으면 순수 memcpy
- **명시적 제어**: 언제 리소스가 해제되는지 코드에 명확히 보임

**C++과의 차이**:
```cpp
// C++: 보이지 않는 마법
{
    MyClass obj(10);  // 생성자 자동 호출
    // ... 
}  // 소멸자 자동 호출 (코드에 안 보임)

// B: 명시적
{
    var obj = MyClass(10);  // 생성자 명시적 호출
    defer obj.drop();       // 소멸자 예약 (코드에 보임)
}
```

#### 상속 (Inheritance) - 다중 상속 + 인터페이스

v3에는 `impl` 블록만 있고 상속은 없습니다. v4에서 **명시적 다중 상속 + 인터페이스(trait)**를 지원합니다.

##### 1. 기본 다중 상속 (VPtr 없음)

- [ ] **다중 상속 선언**: `struct Child : Parent1, Parent2 { ... }`
  ```b
  struct Animal {
      hp: u64;
  }
  
  struct Flyer {
      altitude: u64;
  }
  
  struct Dragon : Animal, Flyer {
      fire_power: u64;
  }
  ```

- [ ] **메모리 레이아웃**: 부모들을 순서대로 적층
  ```
  Dragon 메모리:
  [0..7]    Animal (hp)
  [8..15]   Flyer (altitude)
  [16..23]  Dragon (fire_power)
  ```

- [ ] **명시적 부모 스코프 접근**: `obj.<ParentType>field`
  ```b
  struct Lion { roar: u32; }
  struct Tiger { roar: u32; }
  
  struct Liger : Lion, Tiger { }
  
  var x: Liger;
  // x.roar = 10;         // [Error] Ambiguous! Lion? Tiger?
  
  x.<Lion>roar = 10;      // OK: Offset 0 (Lion) 위치의 roar
  x.<Tiger>roar = 20;     // OK: Offset 4 (Tiger) 위치의 roar
  ```

##### 2. 인터페이스 (trait) - 다형성 지원

- [ ] **`trait`**: 인터페이스 정의 (계약만, 구현 없음)
  ```b
  trait Drawable {
      func draw(self: *Self);
      func bounds(self: *Self) -> Rect;
  }
  ```

- [ ] **trait 구현 구조체**: 구조체가 trait를 구현하면 구조체 정의에 VTable 포인터 필드가 포함됨
  ```b
  struct Circle : Drawable {
      radius: f64;
  }
  
  // 컴파일러가 확장:
  // struct Circle {
  //     $vptr: *DrawableVTable;  // Offset 0 (컴파일러 관리 필드)
  //     radius: f64;              // Offset 8
  // }
  ```

- [ ] **`impl trait for Type`**: trait 구현 강제
  ```b
  impl Drawable for Circle {
      func draw(self: *Self) {
          // self는 *Circle 타입으로 이미 캐스팅됨
          println("Circle r=", self.radius);
      }
      
      func bounds(self: *Self) -> Rect {
          return Rect { x: 0, y: 0, w: self.radius * 2, h: self.radius * 2 };
      }
  }
  
  // trait의 모든 메서드를 구현 안 하면 컴파일 에러:
  // [Error] Circle does not implement Drawable.bounds
  ```

##### 3. VTable 자동 생성 (컴파일러)

- [ ] **VTable 생성**: `impl trait for Type` 발견 시 자동 생성
  ```b
  // 컴파일러가 RODATA에 생성:
  const CIRCLE_DRAWABLE_VTABLE: DrawableVTable = {
      draw: __thunk_Circle_draw,
      bounds: __thunk_Circle_bounds,
  };
  
  // Thunk (Shim) 함수 자동 생성:
  func __thunk_Circle_draw(ptr: *void) {
      Circle_draw(cast(*Circle, ptr));
  }
  ```

##### 4. 초기화 규칙 (명시적 초기화만)

**중요**: 컴파일러는 **구조체 리터럴 초기화(`{ }`)** 시에만 `$vptr`을 설정합니다.

- [ ] **안전한 초기화** (권장):
  ```b
  var c = Circle { radius: 10.0 };
  // 리터럴 초기화 시 컴파일러가 설정:
  // c.$vptr = &CIRCLE_DRAWABLE_VTABLE;
  // c.radius = 10.0;
  
  c.draw();  // OK: vtable lookup
  ```

- [ ] **Unsafe 선언** (해커용):
  ```b
  var raw: Circle;  // vptr 초기화 안 됨 (쓰레기 값)
  // raw.draw();    // [위험!] Null Pointer Dereference
  
  // 수동 복구:
  raw = Circle { radius: 5.0 };  // 이때 vptr 세팅됨
  raw.draw();  // OK
  ```

- [ ] **memcpy/memset 주의**:
  ```b
  var c1 = Circle { radius: 10.0 };  // vptr 설정됨
  var c2: Circle;
  memcpy(&c2, &c1, sizeof(Circle));  // vptr 포함 복사 (OK)
  
  memset(&c1, 0, sizeof(Circle));    // vptr도 0으로 덮어씀 (위험!)
  // c1.draw();  // Null Pointer Dereference
  ```

##### 5. 다형성 사용

- [ ] **다형성 컬렉션**:
  ```b
  var shapes: []*Drawable = [
      cast(*Drawable, &circle),
      cast(*Drawable, &square),
      cast(*Drawable, &triangle),
  ];
  
  for (var i: u64 = 0; i < shapes.len; i++) {
      shapes[i].draw();  // 각자의 draw 호출 (vtable lookup)
  }
  ```

- [ ] **의존성 주입**:
  ```b
  func render(obj: *Drawable) {
      obj.draw();  // 런타임에 실제 타입 결정
  }
  
  render(cast(*Drawable, &circle));
  render(cast(*Drawable, &square));
  ```

##### 6. 다중 상속 + trait 혼합

- [ ] **구조체 상속 + trait 구현**:
  ```b
  struct Animal { hp: u64; }
  
  trait Drawable {
      func draw(self: *Self);
  }
  
  // Lion은 Animal 상속 + Drawable 구현
  struct Lion : Animal, Drawable {
      mane_size: u64;
  }
  
  // 메모리 레이아웃 (중요: 데이터 상속이 Offset 0 우선!):
  // [0..7]    hp (Animal)              <- Offset 0: 부모 데이터 (캐스팅 안전)
  // [8..15]   $vptr_Drawable           <- Offset 8: Trait VPtr은 뒤에
  // [16..23]  mane_size (Lion)
  ```

- [ ] **VPtr 배치 규칙**: 
  - 데이터 상속(`struct : ParentStruct`)이 **항상 Offset 0**
  - Trait VPtr(`struct : Trait`)은 모든 데이터 뒤에 배치
  - 이유: `Lion*` → `Animal*` 캐스팅 안전성 보장
  
- [ ] **Trait 캐스팅 시 주소 보정**:
  ```b
  var lion: Lion = Lion { mane_size: 10 };
  
  // Animal로 캐스팅 (주소 유지)
  var animal_ptr: *Animal = cast(*Animal, &lion);  // OK: Offset 0
  animal_ptr.hp = 100;
  
  // Drawable로 캐스팅 (주소 보정 필요)
  var drawable_ptr: *Drawable = cast(*Drawable, &lion.<Drawable>);  // Offset 8로 이동
  // 또는 컴파일러가 자동:
  drawable_ptr = cast(*Drawable, cast(*u8, &lion) + 8);
  drawable_ptr.draw();
  ```

##### 6.1) Trait 기본 구현 (Default Implementation)

- [ ] **기본 메서드 제공**:
  ```b
  trait Drawable {
      func draw(self: *Self);  // 구현 필수
      
      // 기본 구현 (오버라이딩 선택)
      func is_visible(self: *Self) -> bool {
          return true;
      }
  }
  
  impl Drawable for Circle {
      func draw(self: *Self) {
          println("Circle");
      }
      // is_visible는 구현 안 해도 OK (기본 구현 사용)
  }
  ```

- [ ] **VTable 생성 시**: 구현 안 한 메서드는 기본 함수 주소 사용
  ```b
  // 컴파일러가 생성:
  const CIRCLE_DRAWABLE_VTABLE: DrawableVTable = {
      draw: __thunk_Circle_draw,
      is_visible: __default_Drawable_is_visible,  // 기본 구현
  };
  ```

##### 6.2) Unsafe VPtr 접근 (VTable Hooking)

**해커 기능**: VTable을 런타임에 조작 가능

- [ ] **`$vptr` unsafe 접근**:
  ```b
  var c = Circle { radius: 10.0 };
  
  // 정상 호출
  c.draw();  // Circle 출력
  
  unsafe {
      // VTable Hooking (시스템 해킹 기법)
      var fake_vtable = cast(*DrawableVTable, malloc(sizeof(DrawableVTable)));
      memcpy(fake_vtable, c.$vptr_Drawable, sizeof(DrawableVTable));
      
      fake_vtable.draw = my_malicious_draw;  // 함수 포인터 교체
      
      c.$vptr_Drawable = fake_vtable;  // VTable 교체
  }
  
  c.draw();  // my_malicious_draw 호출! (Hook 성공)
  ```

- [ ] **안전성 규칙**:
  - `$vptr_*` 필드는 `unsafe` 블록 밖에서는 접근 불가
  - 컴파일 에러: `[Error] Cannot access $vptr_Drawable outside unsafe block`
  - VTable 교체 후 타입 안전성은 프로그래머 책임

- [ ] **사용 사례**:
  - 디버깅: 함수 호출 추적
  - 테스트: Mock 객체 생성
  - 보안: 익스플로잇 연구
  - 플러그인: 동적 함수 교체

##### 7. 컴파일러 내부 동작 (Lowering)

**VTable 생성**:
```b
// impl Drawable for Circle 발견
// → RODATA에 vtable 생성
static CIRCLE_DRAWABLE_VTABLE: DrawableVTable = {
    draw: __thunk_Circle_draw,
    bounds: __thunk_Circle_bounds,
};
```

**Thunk 생성** (타입 변환 래퍼):
```b
// Drawable.draw는 *void 받지만, Circle.draw는 *Circle 받음
func __thunk_Circle_draw(ptr: *void) {
    var self = cast(*Circle, ptr);
    Circle_draw(self);
}
```

**리터럴 주입**:
```b
// 소스: var c = Circle { radius: 10.0 };
// IR 변환:
var c: Circle;
c.$vptr = &CIRCLE_DRAWABLE_VTABLE;  // 자동 주입
c.radius = 10.0;
```

**메서드 호출**:
```b
// 소스: c.draw();
// IR 변환:
var vtable = c.$vptr;
var draw_fn = vtable.draw;
draw_fn(cast(*void, &c));
```

##### 8. 제약사항 및 철학

**제약**:
- 가상 상속 없음 (Diamond Inheritance 금지)
- 추상 클래스 없음 (trait로 대체)
- 생성자/소멸자 없음 (defer 사용)

**VPtr 배치 규칙 (Critical)**:
- 데이터 상속은 **항상 Offset 0** (캐스팅 안전성)
- Trait VPtr은 **데이터 뒤에 배치** (Tail Embedding)
- `$vptr_TraitName` 명명 규칙 (trait별로 분리)
- Unsafe 블록에서만 `$vptr` 직접 접근 가능 (VTable Hooking)

**조상 접근 규칙**:
- `obj.<AncestorType>field`: 부모, 조부모, 증조부모 등 모든 조상 접근 가능
- 컴파일러가 상속 체인을 따라 오프셋 계산 (컴파일 타임)
  ```b
  struct Animal { hp: u64; }
  struct Mammal : Animal { fur: u64; }
  struct Dog : Mammal { tail: u64; }
  
  var dog: Dog;
  dog.<Animal>hp = 100;   // OK: 조부모 (Offset 0)
  dog.<Mammal>fur = 50;   // OK: 부모 (Offset 8)
  dog.tail = 5;           // OK: 자식 (Offset 16)
  ```

**철학**:
- **명시적 초기화**: 리터럴 초기화(`{ }`)를 작성할 때만 vptr 설정
- **Zero-Cost 상속**: trait 없는 순수 구조체 상속은 vptr 오버헤드 없음
- **해커 친화적**: `var raw: Circle;` 선언만으로는 vptr 초기화 안 됨 (의도적)
- **타입 안전성**: trait 구현 누락 시 컴파일 에러

---
- [ ] **`comptime`**: 컴파일 타임 함수 (Zig 스타일)
  ```b
  comptime func factorial(n: u64) -> u64 {
      if (n <= 1) { return 1; }
      return n * factorial(n - 1);
  }
  
  const FACT_10: u64 = factorial(10);  // 컴파일 타임 계산
  ```

- [ ] **가변 인자**: 사용자 정의 가변 인자 함수
  ```b
  func printf(fmt: []u8, args: ...any) {
      // 현재는 print/println만 매직으로 지원
  }
  ```

#### 에러 처리 키워드
- [ ] **`?`**: 에러 전파 접미사 연산자 (Rust-style)
  ```b
  func read_config() -> Result<Config, str> {
      var file = open_file("config.txt")?;  // Err 시 즉시 리턴
      var data = file.read()?;
      return parse_config(data)?;
  }
  ```
  
  **참고**: `try` 전위 연산자는 도입하지 않습니다 (`try-catch` 블록과 혼동 방지).

- [ ] **`or`**: 기본값 제공 (null coalescing)
  ```b
  var value = get_option() or 42;  // None이면 42
  var ptr = find_item() or panic("not found");
  ```

#### 내장 함수/연산자

##### 타입 정보 (Type Information)

- [ ] **`typeof`**: 타입 얻기
  ```b
  var x: u64 = 10;
  type T = typeof(x);  // T = u64
  ```

- [ ] **`alignof`**: 정렬 크기
  ```b
  const ALIGN: u64 = alignof(MyStruct);
  ```

- [ ] **`size_of_val`**: 값의 실제 크기 (동적 크기 타입용)
  ```b
  var slice: []u8 = get_slice();
  var size = size_of_val(slice);  // 슬라이스가 가리키는 데이터 크기
  ```

##### 검증 및 단언 (Assertions)

- [ ] **`assert`**: 런타임 검증 (디버그 빌드 전용)
  ```b
  func divide(a: i32, b: i32) -> i32 {
      assert(b != 0, "Division by zero");  // 런타임 체크
      return a / b;
  }
  
  // 릴리스 빌드에서는 제거됨 (zero-cost)
  ```

- [ ] **`debug_assert`**: assert의 명시적 별칭 (더 명확한 의도 표현)
  ```b
  debug_assert(ptr != null, "Null pointer");
  ```

- [ ] **`static_assert`**: 컴파일 타임 검증 (comptime_assert 별칭)
  ```b
  static_assert(sizeof(Packet) == 64, "Packet must be 64 bytes");
  ```

- [ ] **`comptime_assert`**: 컴파일 타임 검증
  ```b
  func sort<T>(arr: []T) {
      comptime_assert(has_method(T, "cmp"), "T must have cmp method");
      // ...
  }
  
  // 컴파일 타임에 검사, 런타임 비용 없음
  ```

- [ ] **`unreachable`**: 도달 불가능 코드 표시 (최적화 힌트 + 런타임 검증)
  ```b
  match opcode {
      0x01 => handle_add(),
      0x02 => handle_sub(),
      _ => unreachable("Invalid opcode"),  // 디버그: panic, 릴리스: undefined behavior
  }
  ```

##### Comptime 메타프로그래밍 (Metaprogramming)

- [ ] **`has_method`**: 타입이 메서드를 가지는지 검사 (comptime 전용)
  ```b
  comptime {
      if (has_method(T, "to_string")) {
          // T는 to_string 메서드를 가짐
      }
  }
  ```

- [ ] **`impls`**: 타입이 trait을 구현하는지 검사 (comptime 전용)
  ```b
  comptime_assert(impls(T, Iterator), "T must implement Iterator");
  ```

- [ ] **`is_const`**: 변수가 컴파일 타임 상수인지 검사
  ```b
  comptime {
      if (is_const(N)) {
          // N은 컴파일 타임에 결정됨
      }
  }
  ```

- [ ] **`is_type`**: 값이 타입인지 검사 (comptime 전용)
  ```b
  comptime {
      if (is_type(T)) {
          // T는 타입
      }
  }
  ```

##### 테스트 헬퍼 (Testing Helpers)

**참고**: 테스트 관련 매크로는 `std.test` 모듈에서 제공됩니다. 여기서는 컴파일러가 특별히 알아야 하는 것만 포함합니다.

- [ ] **`@[test]`**: 테스트 함수 표시 (속성, 컴파일러가 인식)
  ```b
  @[test]
  func test_addition() {
      assert(2 + 2 == 4);
  }
  ```

**Stdlib로 이동**: `assert_eq`, `assert_ne`, `assert_ok`, `assert_err`는 `std.test` 모듈에서 제네릭 함수로 제공됩니다.

##### 메모리 및 포인터 (Memory & Pointers)

- [ ] **`volatile_read`**: volatile 메모리 읽기 (컴파일러 최적화 방지)
  ```b
  var status = volatile_read(device_register);
  // MMIO 레지스터 접근 시 필수
  ```

- [ ] **`volatile_write`**: volatile 메모리 쓰기
  ```b
  volatile_write(device_register, 0xFF);
  ```

- [ ] **`prefetch`**: 메모리 프리페치 힌트 (캐시 최적화)
  ```b
  prefetch(next_node);  // 다음 노드를 L1 캐시로 미리 로드
  // x86: prefetch 명령어
  ```

- [ ] **`fence`**: 메모리 펜스 (순서 보장)
  ```b
  fence_acquire();  // 읽기 펜스
  fence_release();  // 쓰기 펜스
  fence_seq_cst();  // 완전 순서 펜스
  ```

**참고**: `ptr_add`, `ptr_sub`, `addr_of` 등은 빌트인이 아니라 언어 연산자(`ptr + n`, `ptr - n`, `&var`)로 제공됩니다.

##### 비트 조작 (Bit Manipulation)

- [ ] **`rotl`**: 왼쪽 비트 로테이션
  ```b
  var result = rotl(value, 5);  // value를 5비트 왼쪽 회전
  ```

- [ ] **`rotr`**: 오른쪽 비트 로테이션
  ```b
  var result = rotr(value, 3);
  ```

- [ ] **`reverse_bits`**: 비트 순서 반전
  ```b
  var reversed = reverse_bits(0b10110001);  // 0b10001101
  ```

- [ ] **`parity`**: 패리티 비트 계산 (비트 1의 개수가 홀수인지)
  ```b
  var is_odd = parity(value);  // true if odd number of 1s
  ```

##### 디버깅 및 진단 (Debugging & Diagnostics)

- [ ] **`breakpoint`**: 디버거 중단점 삽입
  ```b
  if (suspicious_condition) {
      breakpoint();  // 디버거가 여기서 멈춤 (x86: int3)
  }
  ```

- [ ] **`line`**: 현재 줄 번호 (컴파일 타임)
  ```b
  const LINE: u32 = line();
  ```

- [ ] **`file`**: 현재 파일 이름 (컴파일 타임)
  ```b
  const FILE: []u8 = file();
  ```

- [ ] **`function`**: 현재 함수 이름 (컴파일 타임)
  ```b
  const FUNC: []u8 = function();
  ```

- [ ] **`print_trace`**: 스택 트레이스 출력 (디버그 빌드)
  ```b
  func handle_error() {
      print_trace();  // 현재 호출 스택 출력
  }
  ```

##### 원자적 연산 (Atomic Operations)

- [ ] **`atomic_load`**: 원자적 읽기
  ```b
  var value = atomic_load(&counter);
  ```

- [ ] **`atomic_store`**: 원자적 쓰기
  ```b
  atomic_store(&counter, 42);
  ```

- [ ] **`atomic_add`**: 원자적 덧셈 (fetch-and-add)
  ```b
  var old_val = atomic_add(&counter, 1);  // counter++, 이전 값 반환
  ```

- [ ] **`atomic_sub`**: 원자적 뺄셈
  ```b
  var old_val = atomic_sub(&counter, 1);  // counter--
  ```

- [ ] **`atomic_cmpxchg`**: Compare-and-Swap (CAS)
  ```b
  var success = atomic_cmpxchg(&ptr, expected, new_value);
  ```

- [ ] **`atomic_fence`**: 원자적 펜스
  ```b
  atomic_fence_acquire();
  atomic_fence_release();
  ```

##### 수학 및 부동소수점 (Math & Float)

**참고**: 일반적인 수학 함수(`abs`, `min`, `max`, `clamp`)는 `std.math` 모듈에서 제공됩니다. 여기는 CPU 명령어나 특수 처리가 필요한 것만 포함합니다.

- [ ] **`sqrt`**: 제곱근 (CPU 명령어)
  ```b
  var result = sqrt(16.0);  // 4.0
  // x86: sqrtsd 명령어 직접 사용
  ```

- [ ] **`is_nan`**: NaN 검사 (부동소수점 예외 처리)
  ```b
  if (is_nan(result)) { panic("Invalid float"); }
  // 순서 비교로는 검사 불가 (NaN != NaN)
  ```

- [ ] **`is_inf`**: 무한대 검사
  ```b
  if (is_inf(result)) { panic("Overflow"); }
  ```

**Stdlib로 이동**: 
- `abs`, `min`, `max`, `clamp` → `std.math` (제네릭 함수)
- `float_to_bits`, `bits_to_float` → `std.bit` (union 기반 Type Punning)

##### 시스템 및 플랫폼 (System & Platform)

- [ ] **`syscall`**: 직접 시스템 콜 (리눅스)
  ```b
  var result = syscall(SYS_write, fd, buffer, len);
  ```

- [ ] **`cpu_relax`**: CPU 힌트 (스핀락 최적화)
  ```b
  while (atomic_load(&lock) != 0) {
      cpu_relax();  // x86: pause 명령
  }
  ```

- [ ] **`likely`**: 분기 예측 힌트 (조건이 참일 가능성 높음)
  ```b
  if (likely(ptr != null)) {
      // 이 경로가 대부분 실행됨
  }
  ```

- [ ] **`unlikely`**: 분기 예측 힌트 (조건이 거짓일 가능성 높음)
  ```b
  if (unlikely(error)) {
      handle_error();
  }
  ```

- [ ] **`assume`**: 컴파일러에게 조건이 항상 참이라고 알림 (최적화 힌트)
  ```b
  assume(len > 0);  // 컴파일러가 len <= 0 케이스를 고려 안 함
  ```

##### 암호 및 알고리즘 Intrinsics (Cryptographic & Algorithm Intrinsics)

**바이트 순서 및 비트 연산 (Byte Order & Bit Operations)**:

- [ ] **`bswap16/32/64`**: 바이트 스왑 (엔디안 변환)
  ```b
  var be_value = bswap32(le_value);  // Little → Big Endian
  // x86: bswap 명령어
  ```

- [ ] **`popcnt`**: 비트 카운트 (1의 개수)
  ```b
  var count = popcnt(0b10110101);  // 5
  // x86: popcnt 명령어
  ```

- [ ] **`ctz`**: Trailing Zero Count (오른쪽부터 0의 개수)
  ```b
  var zeros = ctz(0b10110000);  // 4
  // x86: tzcnt 명령어
  // 용도: 비트 스캔, 2의 거듭제곱 검사
  ```

- [ ] **`clz`**: Leading Zero Count (왼쪽부터 0의 개수)
  ```b
  var zeros = clz(0b00001011);  // 4 (32비트 기준)
  // x86: lzcnt 명령어
  // 용도: 로그2 계산, 최상위 비트 찾기
  ```

**다중 정밀도 연산 (Multi-Precision Arithmetic)**:

- [ ] **`addc`**: Add with Carry (캐리 있는 덧셈)
  ```b
  var carry_out: u8;
  var result = addc(a, b, carry_in, &carry_out);
  // x86: adc 명령어
  // 용도: 큰 정수 연산 (256비트+ 정수 라이브러리)
  ```

- [ ] **`subb`**: Subtract with Borrow (보로우 있는 뺄셈)
  ```b
  var borrow_out: u8;
  var result = subb(a, b, borrow_in, &borrow_out);
  // x86: sbb 명령어
  ```

- [ ] **`umul_wide`**: Unsigned Wide Multiply (전체 결과 반환)
  ```b
  var hi: u64;
  var lo = umul_wide(a, b, &hi);  // a*b의 128비트 결과
  // x86: mul 명령어 (rdx:rax)
  // 용도: 오버플로우 검사, 큰 정수 곱셈
  ```

- [ ] **`smul_wide`**: Signed Wide Multiply
  ```b
  var hi: i64;
  var lo = smul_wide(a, b, &hi);
  // x86: imul 명령어
  ```

- [ ] **`udiv_wide`**: Wide Divide (128비트 / 64비트)
  ```b
  var quotient = udiv_wide(hi, lo, divisor, &remainder);
  // x86: div 명령어
  ```

**상수시간 연산 (Constant-Time Operations)**:

- [ ] **`ct_select`**: 상수시간 선택 (분기 없음)
  ```b
  var result = ct_select(condition, if_true, if_false);
  // x86: cmov 명령어
  // 조건이 0이면 if_false, 아니면 if_true
  // 실행 시간이 condition 값에 무관 (타이밍 공격 방지)
  ```

- [ ] **`ct_eq`**: 상수시간 비교 (같음)
  ```b
  var is_equal = ct_eq(a, b);  // 0 또는 1 반환
  // 분기 없이 비교, 실행 시간 일정
  ```

- [ ] **`ct_ne`**: 상수시간 비교 (다름)
  ```b
  var is_different = ct_ne(a, b);
  ```

- [ ] **`ct_lt`**: 상수시간 비교 (작음)
  ```b
  var is_less = ct_lt(a, b);
  ```

**암호학 특화 (Cryptographic Specialized)**:

- [ ] **`clmul`**: Carry-less Multiply (GF(2) 곱셈)
  ```b
  var result = clmul(a, b);
  // x86: pclmulqdq 명령어 (AES-NI)
  // 용도: AES-GCM, CRC, 해시 함수
  ```

- [ ] **`crc32`**: CRC32 계산 (하드웨어 가속)
  ```b
  var checksum = crc32(data, len);
  // x86: crc32 명령어 (SSE4.2)
  // 용도: 체크섬, 무결성 검증
  ```

- [ ] **`aes_enc`**: AES 암호화 라운드 (하드웨어 가속)
  ```b
  var ciphertext = aes_enc(plaintext, round_key);
  // x86: aesenc 명령어 (AES-NI)
  // 용도: AES 블록 암호 구현
  ```

- [ ] **`aes_dec`**: AES 복호화 라운드
  ```b
  var plaintext = aes_dec(ciphertext, round_key);
  // x86: aesdec 명령어
  ```

- [ ] **`sha256_round`**: SHA-256 압축 함수 (하드웨어 가속)
  ```b
  sha256_round(&state, block);
  // x86: sha256rnds2 명령어 (SHA Extensions)
  // 용도: SHA-256 해시 함수 구현
  ```

**난수 생성 (Random Number Generation)**:

- [ ] **`rdrand`**: 하드웨어 난수 생성기 (NIST SP 800-90)
  ```b
  var random: u64;
  var success = rdrand(&random);  // true if successful
  // x86: rdrand 명령어
  // 용도: 암호학적 난수, 키 생성
  ```

- [ ] **`rdseed`**: 하드웨어 시드 생성기 (진정한 난수)
  ```b
  var seed: u64;
  var success = rdseed(&seed);
  // x86: rdseed 명령어
  // rdrand보다 더 느리지만 더 강력한 엔트로피
  ```

**구현 우선순위**:
- **v4.1** (기본): `bswap`, `popcnt`, `ctz`, `clz`, `ct_select`, `ct_eq`, `addc`, `subb`
- **v4.2** (다중 정밀도): `umul_wide`, `smul_wide`, `udiv_wide`, `rdrand`, `rdseed`
- **v4.3** (암호학): `clmul`, `crc32`, `aes_enc`, `aes_dec`, `sha256_round`

#### 속성 (Attributes)

**참고**: 속성은 컴파일러가 직접 인식하고 처리해야 하므로 빌트인입니다.
- [ ] **`@[inline]`**: 함수 인라이닝 힌트
- [ ] **`@[no_inline]`**: 인라이닝 금지
- [ ] **`@[deprecated]`**: 폐기 예정 경고
  ```b
  @[deprecated("use new_func instead")]
  func old_func() { }
  ```

- [ ] **`@[must_use]`**: 반환값 사용 강제
  ```b
  @[must_use]
  func allocate() -> *u8 { }
  ```

- [ ] **`@[cold]`**: 드물게 실행되는 경로 (최적화 힌트)
  ```b
  @[cold]
  func handle_error() { }
  ```

- [ ] **`@[test]`**: 단위 테스트 표시
  ```b
  @[test]
  func test_addition() {
      assert(2 + 2 == 4);
  }
  ```

- [ ] **`@[export]`**: 심볼 내보내기 (no_mangle + public)
  ```b
  @[export]
  func my_api_function() { }
  ```

---

### 0.1) 주석 확장 (Comment Extensions)

v3는 기본적인 단일 라인 주석(`//`)과 블록 주석(`/* */`)만 지원합니다.
v4에서는 **문서화(Documentation)**, **IDE 지원**, **컴파일러 지시(Directives)** 등을 위한 주석 시스템을 확장합니다.

#### 현재 지원 (v3)

```b
// 단일 라인 주석
var x = 10;  // 코드 뒤 주석

/*
 * 블록 주석
 * 여러 줄에 걸쳐 작성 가능
 */
```

#### 확장 1: 문서화 주석 (Documentation Comments)

**구문**: `///` (단일 라인) 또는 `/** */` (블록)

**목적**: 
- 함수, 구조체, 모듈에 대한 공식 문서 생성
- IDE 툴팁/자동완성에 표시
- `bdoc` 도구로 HTML/Markdown 문서 추출

**예제**:
```b
/// Circle 구조체는 2D 원을 표현합니다.
/// 
/// # 필드
/// - `center`: 원의 중심점 좌표
/// - `radius`: 원의 반지름 (양수여야 함)
/// 
/// # 예제
/// ```b
/// var c = Circle{ center: Point{0, 0}, radius: 10.0 };
/// var area = c.area();  // 314.159...
/// ```
struct Circle {
    center: Point;
    radius: f64;
}

/// 원의 넓이를 계산합니다.
/// 
/// # 반환값
/// - 넓이 (π * r²)
/// 
/// # 패닉
/// - `radius`가 음수인 경우 패닉 발생
func (c: *Circle) area() -> f64 {
    if (c.radius < 0) { panic("Negative radius"); }
    return 3.141592653589793 * c.radius * c.radius;
}
```

**블록 문서화 주석**:
```b
/**
 * 파일을 엽니다.
 * 
 * @param path 파일 경로
 * @param mode 열기 모드 ("r", "w", "a")
 * @return 파일 핸들 또는 에러
 * 
 * @example
 * var file = open("/tmp/test.txt", "r");
 * match file {
 *     Result.Ok(f) => process(f),
 *     Result.Err(e) => println("Error: ", e),
 * }
 */
func open(path: []u8, mode: []u8) -> Result<*File, str> {
    // ...
}
```

**IDE 통합**:
- 함수 호출 시 자동으로 문서화 주석 표시
- `Ctrl+Space` 자동완성에 설명 표시
- Hover 시 전체 문서 표시

#### 확장 2: 내부 문서 주석 (Inner Doc Comments)

**구문**: `//!` (단일 라인) 또는 `/*! */` (블록)

**목적**: 
- 모듈/파일 전체를 설명
- 파일 최상단에 작성

**예제**:
```b
//! # vec 모듈
//! 
//! 동적 크기 배열(Vector) 구현을 제공합니다.
//! 
//! ## 특징
//! - 자동 크기 조절 (capacity doubling)
//! - Generic 타입 지원 (`Vec<T>`)
//! - 슬라이스 뷰 (`as_slice()`)
//! 
//! ## 사용 예제
//! ```b
//! var v: Vec<u64> = vec_new();
//! vec_push(&v, 10);
//! vec_push(&v, 20);
//! println(v.len);  // 2
//! ```

import mem;
import builtin;

struct Vec<T> {
    // ...
}
```

#### 확장 3: 중첩 블록 주석 (Nested Block Comments)

**v3 제약**: `/* /* 중첩 불가 */ */` 구문 에러

**v4 확장**: 중첩 블록 주석 지원

**목적**: 
- 큰 코드 블록을 주석 처리할 때 기존 블록 주석을 덮어쓸 수 있음

**예제**:
```b
/*
    var x = 10;
    
    /* 이 부분도 주석 처리됨
       var y = 20;
    */
    
    var z = 30;  // 전체가 주석 처리됨
*/
```

**구현**: 
- 렉서에서 주석 깊이(depth) 카운터 추가
- `/*`마다 +1, `*/`마다 -1
- depth가 0이 되면 주석 종료

**우선순위**: v4.0 (구현 비용 낮고 효용성 매우 높음)

#### 확장 4: TODO/FIXME/NOTE 태그 (Annotation Tags)

**구문**: `// TODO:`, `// FIXME:`, `// NOTE:`, `// HACK:`, `// XXX:`

**목적**: 
- 코드베이스 내 할 일 추적
- IDE/에디터가 자동으로 목록화

**예제**:
```b
// TODO: 에러 처리 개선 필요
func parse_file(path: []u8) -> *Ast {
    // ...
}

// FIXME: 메모리 릭 발생 (2026-01-09)
func allocate_buffer(size: u64) -> *u8 {
    // ...
}

// NOTE: 이 알고리즘은 O(n²)이지만 n < 100이므로 괜찮음
func sort_small_array(arr: []u32) {
    // ...
}

// HACK: 임시 우회책, v4.2에서 제거 예정
func workaround_compiler_bug() {
    // ...
}
```

**IDE 통합**:
- VS Code의 "Problems" 패널에 표시
- `Tasks: Run Task` → `Show TODO comments` 자동 생성

#### 구현 전략

**렉서(Lexer) 확장**:
1. `//`, `/*`, `///`, `/**`, `//!`, `/*!`, `//@` 인식
2. 문서화 주석은 토큰으로 유지 (파서에 전달)
3. 일반 주석은 버림

**파서(Parser) 통합**:
1. 문서화 주석을 AST 노드에 첨부
   - `struct Node { ..., doc_comment: []u8? }`
2. 함수/구조체/모듈 선언 직전의 `///` 주석 수집

**코드 생성(Codegen)**:
1. 문서화 주석은 기계어에 영향 없음
2. 디버그 정보에 포함 (DWARF)

**문서 생성기 (bdoc)**:
1. AST를 순회하며 `doc_comment` 필드 추출
2. Markdown 또는 HTML로 변환
3. Cross-reference 링크 생성

#### 설계 원칙 (Design Principles)

**주석 vs 속성의 명확한 구분**:

> **"주석은 설명, 속성은 제어"**

- **주석 (`///`, `//!`)**: 문서화 전용. 제거해도 프로그램 동작은 동일.
- **속성 (`@[...]`)**: 컴파일 결과에 영향. 제거하면 바이너리가 달라짐.

**잘못된 설계 (Anti-Pattern)**:
```b
// Bad: 주석으로 컴파일러 제어 (혼란스러움)
//! inline(always)
func foo() { }

//@ cfg(target_os="linux")
func bar() { }
```

**올바른 설계**:
```b
// Good: 속성으로 컴파일러 제어 (명시적)
@[inline]
func foo() { }

@[cfg(target_os="linux")]
func bar() { }
```

**철학**:
- B 언어는 "명시성(Explicitness)"을 최우선으로 합니다.
- 코드 동작에 영향을 주는 것은 **코드 문법(속성)**이어야 하며, **주석에 숨겨져서는 안 됩니다**.
- 주석은 오직 **사람을 위한 설명**과 **도구 연동(IDE, bdoc)**에만 사용됩니다.

#### 우선순위

- **v4.0** (Lexer/Parser 기반): 
  - [ ] `///`, `/**` 문서화 주석 기본 지원
  - [ ] 렉서/파서에서 주석 토큰 보존
  - [ ] AST 노드에 `doc_comment` 필드 추가
  - [ ] **중첩 블록 주석** (`/* /* */ */`) 지원 (depth 카운터)
  
- **v4.1** (표준 라이브러리 문서화):
  - [ ] `//!`, `/*!` 내부 문서 주석 (모듈/파일 설명)
  - [ ] TODO/FIXME/NOTE 태그 인식 (IDE 연동)
  - [ ] 표준 라이브러리 전체 문서 작성
  
- **v4.2** (속성 시스템 강화):
  - [ ] `@[inline]`, `@[no_inline]` 속성 구현
  - [ ] `@[cfg(...)]` 조건부 컴파일 속성 구현
  - [ ] `@[allow(...)]` 경고 억제 속성 구현
  - [ ] `@[deprecated(...)]` 폐기 경고 속성 구현
  
- **v4.3** (도구 생태계):
  - [ ] `bdoc` 문서 생성기 구현
  - [ ] HTML 템플릿 + 검색 기능
  - [ ] Language Server Protocol (LSP) 통합
  - [ ] IDE에서 Hover 시 문서 표시
  - [ ] IDE 통합 (Language Server Protocol)

---

### 0.2) 구조체 리터럴 expression

v3 테스트 33에서 실패. typecheck 복잡도(필드 매칭, 순서 재정렬, 타입 추론 등)가 크기 때문에 v4로 이동.

- [ ] named: `Pair{ a: 1, b: 2 }`
- [ ] positional: `Pair{ 1, 2 }`
- [ ] codegen: BRACE_INIT → 스택 초기화, sret 반환, VAR 초기화
- DoD
    - struct 리터럴로 값 생성/전달 동작
    - 필드 순서와 무관하게 named init 동작 (e.g., `{ b: 2, a: 1 }`)

### 0.3) 조건부 컴파일 `@[cfg]`

플랫폼별 분기가 필요하지만, v3 MVP 범위에서는 단일 타겟(Linux x86-64)만 지원.

- [ ] 문법: `@[cfg(target_os="linux")]`
- [ ] 지원 대상: `target_os` (`linux`/`windows`)
- [ ] 분기 범위: 선언 + 문장(statement) 레벨
- DoD
    - `@[cfg(target_os="linux")]` 붙은 함수가 Linux에서만 컴파일됨

### 0.4) FFI extern 블록

v3에서는 단순 `extern func` 선언만 지원. 블록 방식 + 호출 규약 지정은 v4.

- [ ] 문법: `extern "C" { func ...; }`
- [ ] 호출 규약: `extern "sysv"`, `extern "win64"`
- [ ] 심볼 이름 매핑 (e.g., `@[link_name="custom_name"]`)
- DoD
    - C 라이브러리 함수 호출 예제 동작

### 0.5) 익명 함수 / 클로저

**참고**: 함수 포인터 타입은 v3에서 이미 구현됨 (`func(T, U) -> R`, 테스트 55).

- [x] 함수 포인터 타입: `func(T, U) -> R` (v3 완료)
- [x] 변수에 함수 주소 저장 (v3 완료)
- [x] 간접 호출 코드젠 (v3 완료)
- [ ] (v4) 익명 함수: `|x| x+1` 또는 `fn(x) { ... }` 형태
- [ ] (v4) 클로저(캡처 있음)
- DoD
    - 익명 함수 리터럴 동작
    - 클로저 변수 캡처 동작

### 0.6) Named Arguments

v3 테스트 23에서 실패. parser 미구현(typecheck 준비는 완료)으로 인해 v4로 이동.

- [ ] 호출 파싱: `f(a: x, b: y)` 문법 지원
- [x] typecheck: 파라미터명 일치, 순서 매핑 로직 (이미 구현됨)
- [ ] 검증: 파라미터명 일치, 순서 유지
- [ ] 혼용 금지: all-named 또는 all-positional
- DoD
    - `f(a: 1, b: 2)` 호출이 `f(1, 2)`와 동일하게 동작
    - `f(x, b: y)` 혼용은 컴파일 에러

### 0.7) 다중 리턴 (Multi-Return)

v3 테스트 24에서 실패. codegen 복잡도(rax/rdx 매핑, destructuring 등)로 인해 v4로 이동.

- [x] 함수 선언: `-> (T0, T1)` (파싱 완료)
- [x] return 문장: `return a, b;` (파싱 완료)
- [ ] destructuring: `var q, r = f();`, `q, r = f();`, `_` discard
- [ ] IR: `ret v0, v1` (ret value_list)
- [ ] ABI: `rax/rdx` 매핑
- DoD
    - 2리턴 함수 호출/바인딩이 end-to-end로 동작

### 0.8) 최적화 패스 (Constant Folding / DCE)

v3 MVP에서는 최적화 없이 직접 코드젠. 최적화는 v4에서 IR 패스로 추가.

- [ ] Constant Folding: 상수 표현식을 컴파일 타임에 계산 (`1 + 2 → 3`)
- [ ] Dead Code Elimination (DCE): 사용되지 않는 변수/코드 제거
- [ ] 예외: `secure_store` (wipe) 등 보안 관련 IR은 절대 제거 금지
- DoD
    - 간단한 입력에서 dead branch 제거 확인
    - IR 덤프에서 상수 계산 결과 확인

### 0.9) `defer` break/continue 지원

v3에서는 defer의 블록 스코프/return 시 실행만 구현. break/continue 시 defer 실행은 제어 흐름 복잡도로 인해 v4로 이동.

- [x] defer 기본 구현 (블록 종료, return 시)
- [ ] break/continue 시 defer 실행
- [ ] 중첩 루프에서 break N/continue N 시 defer 스택 정리
- [ ] switch 내부 break 시 defer 정리
- DoD
    - `while { defer f(); if (c) break; }` 형태에서 break 시 f() 호출 확인
    - 중첩 루프 + break 2 시 올바른 defer 스택 정리

### 0.10) 정수 비트 슬라이싱 (Bit Slicing)

v3에서는 MVP 범위 밖. 암호/저수준 비트 조작이 필요한 경우 v4에서 추가.

- [ ] 문법: `x[hi:lo]` 파싱/AST
- [ ] 상수 범위 검증 (hi > lo, hi < bitwidth)
- [ ] lowering: `(x >> lo) & mask` 형태로 변환
- [ ] 타입 체크: 정수 타입에만 허용
- DoD
    - `inst[31:26]` 같은 RISC 명령어 디코딩 패턴 동작
    - `flags[7:4]` 비트 필드 추출 동작

### 0.11) 런타임 디버깅 인프라 (Location Info 고급)

v3에서는 컴파일 에러 위치만 지원. 런타임 위치 정보는 DWARF 등 복잡도로 인해 v4로 이동.

- [ ] IR → ASM 단계까지 파일/줄/컬럼 유지
- [ ] 런타임 패닉 시 스택 트레이스 출력
- [ ] `.loc` 지시어로 gdb 연동
- [ ] 스택 정리 정책 (panic 시 defer 실행 등)
- DoD
    - 패닉 메시지에 소스 위치 + 호출 스택 출력

### 0.12) 강제 Tail Call

v3에서는 MVP 범위 밖. 재귀 최적화가 필요한 경우 v4에서 추가.

- [ ] 문법: `return tail f(args...);` 파싱/AST
- [ ] IR: `musttail` 플래그
- [ ] defer 충돌 검사(defer 있으면 에러)
- [ ] 코드젠: `jmp`로 변환
- DoD
    - tail call이 stack frame 안 쌓는지 확인

### 0.13) Inline ASM 개선

v3에서는 기본 `asm { ... }` 블록만 지원. 레지스터 템플릿 치환은 v4에서 추가.

- [ ] 문법: `asm(alias1, alias2) { ... }` 파싱
- [ ] `{name}` → 실제 레지스터 치환
- [ ] alias가 아닌 변수 사용 시 에러
- DoD
    - `mov {tmp}, 0` 같은 템플릿 동작

### 0.14) 어노테이션 시스템

v3에서는 제한적 어노테이션만 지원. 전체 시스템은 v4에서 구축.

- [ ] `@[inline]`, `@[no_mangle]` 등 파싱
- [ ] (선택) 계약: `@[requires]`, `@[ensures]`, `@[invariant]`
- DoD
    - 기본 어노테이션이 파싱/검증됨

### 0.15) 파서 내장 유틸

v3에서는 MVP 범위 밖. 편의 기능은 v4에서 추가.

- [ ] `print(expr)` 타입별 자동 분기
- [ ] `@embed("path")` 파일 삽입
- [ ] `@trng` 하드웨어 난수
- DoD
    - `print(123)`와 `print("hi")`가 다르게 동작

### 0.16) 불변 바인딩 (`final`)

v3에서는 MVP 범위 밖. 타입 시스템 확장이 필요하여 v4로 이동.

- [ ] 문법: `final var x = expr;` 파싱/AST
- [ ] 타입 체크: final 변수 재대입 시 컴파일 에러
- [ ] 함수 파라미터에도 적용 가능: `func f(final x: u64)`
- [ ] (후순위) `final` 구조체 필드 (불변 필드)
- DoD
    - `final var x = 10; x = 20;` 컴파일 에러
    - 루프 변수에 `final` 사용 시 동작 검증

### 0.18) Value Generics (값 제네릭)

v3 테스트 20, 21, 22에서 실패. comptime 의존성과 타입 시스템 확장이 필요하여 v4로 이동.

**제네릭 문법 위계** (중요):
- **진실(Truth)**: `func f(comptime N: u64)` - 타입도 값이다 (Zig-style)
- **설탕(Sugar)**: `func f<N: u64>()` - 가독성을 위한 문법 설탕 (C++-style)
- 내부적으로 `<N>`는 `(comptime N)`으로 변환됨 (Phase 4.2 참조)

- [x] 문법: `func f<N: u64>()` (파싱 일부 구현됨)
- [ ] 타입 체크: 값 제네릭 파라미터 검증
- [ ] 인스턴스화: 상수 값으로 monomorphization
- [ ] `[N]T` 배열 타입에서 N을 제네릭 파라미터로 사용
- [ ] `struct Buffer<N: u64> { data: [N]u8; }` 패턴 지원
- [ ] comptime 표현식과 통합
- DoD
    - `func sum<N: u64>(arr: [N]u64) -> u64` 동작
    - `Buffer<1024>` 같은 인스턴스화 가능
    - 테스트 20, 21, 22 통과

### 0.19) 제네릭 타입 추론 (Generic Type Inference)

v3 테스트 19에서 실패. typecheck에 부분 구현되어 있으나 미완성. 호출 시 타입 인자 생략을 지원하기 위해 v4로 이동.

- [x] typecheck: 기본 infer 로직 (부분 구현됨, lines 3213, 3255, 3271)
- [ ] 단일 함수 호출 타입 추론: `id(10)` → `id<u64>(10)` 자동 추론
- [ ] 인자 타입으로부터 타입 파라미터 추론 알고리즘 완성
- [ ] 불일치/모호함 시 명확한 에러 메시지
- [ ] 중첩 제네릭 호출 타입 전파 (e.g., `map(arr, id)` 형태)
- DoD
    - `id(10)`이 `id<u64>(10)`로 추론되어 monomorph
    - 타입 불일치 시 "cannot infer type args" 에러
    - 테스트 19 통과

### 0.20) 구시대 문법 제거 (v4 Clean-up)

v2 매직 식별자 등 구시대적 문법은 v4에서 완전히 제거합니다.

- [x] `ptr8[addr]`, `ptr64[addr]` → v3에서 이미 제거됨 (타입 포인터 사용)
- [ ] v2 호환 배열 문법 제거 고려: `var arr[N]` → `var arr: [N]T`
- [ ] v2 호환 함수 파라미터 타입 생략 제거: `func f(a, b)` → `func f(a: T, b: U)`
- DoD
    - v4 코드는 모두 명시적 타입 표기
    - v2 호환성 완전 중단

**정책**: v4부터는 명시성(Explicitness) 우선. v2 간소 문법 지원 중단.

---

## 0.20) v3 MVP 제약사항 해제 (v4에서 구현)

v3는 MVP(Minimum Viable Product)로 많은 기능을 의도적으로 제한했습니다.
v4에서는 이러한 제약을 해제하고 완전한 기능을 구현합니다.

### 함수 시스템

**v3 제약**:
- 최대 파라미터: 6개 (System V ABI rdi, rsi, rdx, rcx, r8, r9)
- 다중 리턴 미지원
- 가변 인자: 컴파일러 매직(`print`)만 지원, 사용자 정의 불가
- 익명 함수/클로저: 미지원

**v4 해제**:
- [ ] 최대 파라미터 확장: 7개 이상 (스택 전달)
- [x] 다중 리턴: `func f() -> (T, U)` (0.6에서 구현)
- [ ] 사용자 정의 가변 인자: `func printf(fmt: str, args: ...any)`
- [ ] 익명 함수: `|x| x+1` (0.4에서 구현)
- [ ] 클로저 (캡처 있음): `|&x| x+1`

### 표현식

**v3 제약**:
- Struct 리터럴 표현식 미지원 (선언에서만 brace-init)
- 배열 리터럴 표현식 미지원
- 삼항 연산자 미지원

**v4 해제**:
- [x] Struct 리터럴: `Point{ x: 1, y: 2 }` (0.1에서 구현)
- [ ] 배열 리터럴: `[1, 2, 3, 4]` (타입 추론 필요)
- [ ] 삼항 연산자: `cond ? a : b`

### 제네릭 시스템

**v3 제약**:
- Value generics 미지원
- 타입 추론 미지원 (명시적 `<T>` 필수)
- Trait bounds 미지원
- Associated types 미지원
- Default type parameters 미지원

**v4 해제**:
- [x] Value generics: `<const N: u64>` (0.17에서 구현)
- [x] 타입 추론: `id(10)` → `id[u64](10)` (0.18에서 구현)
- [ ] Associated types: `type Item;` (trait 전용)
- [ ] Default type parameters: `<T = u64>`

**제외 (Rust 문법 거부)**: 
- ~~Trait bounds `<T: Comparable>`~~: **Rust/C++ Concept 스타일 제약은 지원하지 않음.**
  
  **대신 comptime_assert로 대체** (해커에게 더 많은 제어권):
  ```b
  // v4 B 언어 방식: 제약은 문법이 아니라 '코드'로 작성
  func sort<T>(arr: []T) {
      // 표준 라이브러리 함수 사용
      comptime_assert(impls(T, Comparable), "T must implement Comparable");
      
      // 또는 직접 메서드 존재 여부 검사
      comptime_assert(has_method(T, "cmp"), "T must have cmp method");
      
      // 정렬 로직
      for (var i: u64 = 0; i < arr.len; i++) {
          for (var j: u64 = i + 1; j < arr.len; j++) {
              if (arr[j].cmp(arr[i]) < 0) {
                  swap(&arr[i], &arr[j]);
              }
          }
      }
  }
  ```
  
  **장점**:
  - 파서가 단순함 (제약 문법 불필요)
  - 해커가 검사 로직을 직접 제어 가능
  - Zig 스타일 Duck Typing + 명시적 comptime 검증 유지
  - 컴파일 타임 에러 메시지 커스터마이징 가능

### 제어 흐름

**v3 제약**:
- `match` 키워드 미지원 (v3는 `switch`만 제공, fallthrough 없음)

**v4 해제**:
- [ ] **`match` 표현식**: `var x = match val { 1 => a, 2 => b };`
  - **중요**: v4에서 `switch` 키워드 삭제, `match`로 통합
  - 원시 타입 매칭 시 컴파일러가 자동으로 점프 테이블 최적화
  - v3의 `switch` 코드는 `match`로 마이그레이션 필요

### 타입 시스템

**v3 제약**:
- Union 타입 미지원
- **에러 처리**: panic만 가능, Result/Option 타입 미지원
- **패턴 매칭**: v3 `switch`는 정수만 가능 (패턴 매칭 없음)
- **다중 리턴**: 파싱만 구현, 레지스터 할당 미완성

**v4 해제**:
- [ ] Union 타입: `union Value { i: i64, f: f64 }`
- [ ] **Result 타입**: `Result<T, E>` 표준 타입
- [ ] **Option 타입**: `Option<T>` (nullable 대체)
- [ ] **`?` 연산자**: `var x = try_func()?;` (에러 전파)
- [ ] **패턴 매칭**: `match` 키워드로 enum/union/원시 타입 모두 통합
  - **성능 보장**: 원시 타입은 v3 `switch`와 동일한 점프 테이블 최적화
  - **명시성 제공**: `@[jump_table]` 어노테이션으로 최적화 강제 가능

### 에러 처리 (Error Handling)

**v3 현황**:
- `panic(msg)`: stderr 출력 후 `exit(1)` (복구 불가)
- nullable 포인터: `*T?` (null 체크 수동)
- 에러 복구 메커니즘 없음

**v4 추가**:
- [ ] **Result<T, E>** 표준 타입
  ```b
  enum Result<T, E> {
      Ok(T),
      Err(E),
  }
  
  func divide(a: i64, b: i64) -> Result<i64, str> {
      if (b == 0) {
          return Result.Err("division by zero");
      }
      return Result.Ok(a / b);
  }
  
  var result: Result<i64, str> = divide(10, 0);
  match result {
      Ok(val) => println("result: ", val),
      Err(msg) => println("error: ", msg),
  }
  ```

- [ ] **Option<T>** 표준 타입
  ```b
  enum Option<T> {
      Some(T),
      None,
  }
  
  func find_index(arr: []u8, target: u8) -> Option<u64> {
      for (var i: u64 = 0; i < arr.len; i++) {
          if (arr[i] == target) {
              return Option.Some(i);
          }
      }
      return Option.None;
  }
  ```

- [ ] **`?` 연산자** (에러 전파)
  ```b
  func read_config() -> Result<Config, str> {
      var file = open_file("config.toml")?;  // 에러 시 즉시 리턴
      var data = try file.read()?;
      var config = try parse_config(data)?;
      return Result.Ok(config);
  }
  ```

- [ ] **unwrap/expect** 메서드
  ```b
  var val: u64 = result.unwrap();         // panic on Err
  var val: u64 = result.expect("failed"); // panic with custom msg
  var val: u64 = result.unwrap_or(42);    // default value
  ```

### 인라인 어셈블리

**v3 제약**:
- raw 텍스트만 지원
- 템플릿/치환 기능 없음
- 레지스터 충돌 수동 관리

**v4 해제**:
- [x] 레지스터 템플릿: `asm(alias) { mov {tmp}, 0 }` (0.12에서 구현)
- [ ] 입출력 제약: `asm("add %1, %0" : "=r"(out) : "r"(in))`
- [ ] Clobber 자동 관리

### 레지스터 별칭 (alias)

**v3 제약**:
- 허용 레지스터: rax, rbx, rcx, rdx, rsi, rdi, r8~r15
- 금지: rsp (스택 포인터)
- 제한: rbp (프레임 포인터 필요 시)

**v4 해제**:
- [ ] 모든 범용 레지스터 지원 확장
- [ ] XMM 레지스터 별칭: `alias xmm0: vec;`
- [ ] YMM/ZMM 레지스터 (AVX2/AVX-512)
- [ ] 레지스터 압박 검출 개선

### 최적화

**v3 제약**:
- Dead code elimination 미구현
- Constant folding 제한적 (const-expr만)
- Inlining 미구현

**v4 해제**:
- [x] Constant folding: `1 + 2` → `3` (0.7에서 구현)
- [x] Dead code elimination (0.7에서 구현)
- [ ] 함수 인라이닝: `@[inline]`
- [ ] Loop unrolling
- [ ] 자동 벡터화 (SIMD)

### 모듈 시스템

**v3 제약**:
- 순환 import 검출 안 함
- import 경로: 상대 경로만
- Re-export 미지원

**v4 해제**:
- [ ] 순환 import 검출 및 에러
- [ ] 절대 경로 import: `import "@std/io"`
- [ ] 패키지 관리 연동
- [ ] Re-export: `pub use module::Type;`

### 에러 리포팅

**v3 제약**:
- 에러 복구 최소 (`;`/`}` 싱크)
- 스택 트레이스 미지원
- 컴파일 에러만 위치 정보

**v4 해제**:
- [ ] 에러 복구 개선 (다중 에러 리포팅)
- [x] 런타임 스택 트레이스 (0.10에서 구현)
- [ ] DWARF 디버그 정보 생성
- [ ] gdb/lldb 연동

### 개발 도구 (Tooling)

**v3 현황**:
- 컴파일러만 존재
- IDE 지원 없음
- 포맷터 없음
- 린터 없음
- 패키지 관리자 없음
- 빌드 시스템: 수동 스크립트만

**v4 추가**:
- [ ] **LSP (Language Server Protocol)** 서버
  - [ ] 자동 완성 (auto-completion)
  - [ ] 정의로 이동 (go to definition)
  - [ ] 참조 찾기 (find references)
  - [ ] 심볼 이름 변경 (rename)
  - [ ] 호버 정보 (hover documentation)
  - [ ] 에러 진단 (diagnostics)
  - [ ] 코드 액션 (quick fixes)

- [ ] **포맷터** (`bfmt`)
  ```bash
  bfmt --check src/      # 검사만
  bfmt src/              # 자동 포맷
  bfmt --config=.bfmt.toml src/  # 설정 파일
  ```

- [ ] **린터** (`blint`)
  ```bash
  blint src/
  # 경고: unused variable 'x'
  # 경고: unreachable code after return
  ```

- [ ] **패키지 관리자** (`bpkg`)
  ```toml
  # bpkg.toml
  [package]
  name = "myapp"
  version = "0.1.0"
  
  [dependencies]
  crypto = "1.2.3"
  http = { git = "https://github.com/user/http" }
  
  [dev-dependencies]
  test-utils = "0.1.0"
  ```

- [ ] **빌드 시스템** (build.b)
  ```b
  import std.build;
  
  func main() {
      var b = Build.new();
      
      var exe = b.add_executable("myapp");
      exe.add_source_files(&[
          "src/main.b",
          "src/lib.b",
      ]);
      exe.link_lib("crypto");
      exe.set_target("x86_64-linux");
      
      b.install_artifact(exe);
  }
  ```

- [ ] **문서 생성기** (`bdoc`)
  ```b
  /// 두 정수를 더합니다.
  ///
  /// # 예제
  /// ```b
  /// var result = add(2, 3);
  /// assert_eq(result, 5);
  /// ```
  func add(a: i64, b: i64) -> i64 {
      return a + b;
  }
  ```
  
  ```bash
  bdoc src/  # HTML 문서 생성
  ```

- [ ] **벤치마크 프레임워크**
  ```b
  import std.bench;
  
  @[bench]
  func bench_hashmap_insert() {
      var map = HashMap.new();
      for (var i: u64 = 0; i < 1000; i++) {
          map.insert(i, i * 2);
      }
  }
  ```

- [ ] **프로파일러** (`bprof`)
  ```bash
  v4c --profile main.b
  ./main
  bprof --flame main.prof  # flame graph 생성
  ```

- [ ] **REPL** (Read-Eval-Print Loop)
  ```bash
  $ brepl
  >>> var x = 10
  >>> x + 20
  30
  >>> func double(n: i64) -> i64 { return n * 2; }
  >>> double(21)
  42
  ```

### 비동기/동시성 (Async/Concurrency)

**v3 현황**:
- 동시성 지원 없음
- 단일 스레드만
- async/await 없음

**v4 고려 사항** (Phase 3~4, 신중한 설계 필요):
- [ ] **Thread** 지원
  ```b
  import std.thread;
  
  func worker(id: u64) {
      println("Thread ", id, " running");
  }
  
  var t1 = Thread.spawn(|| worker(1));
  var t2 = Thread.spawn(|| worker(2));
  t1.join();
  t2.join();
  ```

- [ ] **Channel** (메시지 패싱)
  ```b
  import std.sync;
  
  var ch: Channel<u64> = Channel.new();
  
  Thread.spawn(|| {
      ch.send(42);
  });
  
  var val = ch.recv();
  println(val);  // 42
  ```

- [ ] **Async/Await** (선택적)
  ```b
  import std.async;
  
  async func fetch_data(url: str) -> Result<str, str> {
      var response = await http_get(url)?;
      var body = await response.text()?;
      return Result.Ok(body);
  }
  
  func main() {
      var runtime = Runtime.new();
      runtime.block_on(fetch_data("https://example.com"));
  }
  ```

- [ ] **Mutex/RwLock** (동기화 프리미티브)
  ```b
  import std.sync;
  
  var counter: Mutex<u64> = Mutex.new(0);
  
  func increment() {
      var guard = counter.lock();
      *guard += 1;
  }  // guard 스코프 종료 시 자동 unlock
  ```

**참고**: 비동기/동시성은 복잡도가 매우 높아 v5로 미루는 것도 고려

### 표준 라이브러리

**v3 현황**:
- 최소한의 유틸리티만 존재 (Vec, HashMap, file I/O)
- Collections: Vec만 (Set, Map, Deque 등 미지원)
- Iterator 인터페이스 없음
- String 타입 없음 (`[]u8` 슬라이스만)
- 날짜/시간 API 없음
- 정규표현식 없음
- JSON/CSV 등 포맷 파서 없음

**v4 추가**:
- [ ] **Collections** (표준 자료구조)
  - [ ] `Vec<T>`: 동적 배열 (이미 존재하지만 개선)
  - [ ] `HashMap<K, V>`: 해시맵 (이미 존재하지만 개선)
  - [ ] `HashSet<T>`: 해시셋
  - [ ] `LinkedList<T>`: 연결 리스트
  - [ ] `Deque<T>`: 양방향 큐
  - [ ] `BTreeMap<K, V>`: B-트리 맵
  - [ ] `BTreeSet<T>`: B-트리 셋
  - [ ] `PriorityQueue<T>`: 우선순위 큐

- [ ] **Iterator** 인터페이스
  ```b
  trait Iterator<T> {
      func next(self: *Self) -> Option<T>;
  }
  
  // Chaining methods
  var sum = arr.iter()
      .filter(|x| x > 10)
      .map(|x| x * 2)
      .sum();
  ```

- [ ] **Range** 타입
  ```b
  for (var i in 0..10) {  // 0부터 9까지
      println(i);
  }
  
  for (var i in 0..=10) {  // 0부터 10까지 (inclusive)
      println(i);
  }
  ```

- [ ] **String** 타입 (UTF-8 보장된 Vec<u8> 래퍼)
  ```b
  // String은 내부적으로 Vec<u8>이며, UTF-8 인코딩을 보장합니다.
  // 힙 할당이 발생하며, free/defer로 명시적 해제 필요합니다.
  
  var s = String.new();  // 빈 문자열 (힙 할당)
  defer s.free();        // 명시적 해제
  
  s.push_str("Hello");   // 내부적으로 Vec.push_many 호출
  s.push_str(" World");
  println(s.len());       // 11 (바이트 단위)
  
  // 스택 문자열 리터럴은 []u8 슬라이스
  var literal: []u8 = "Static";  // 힙 할당 없음
  
  // 변환: []u8 -> String (복사 + 할당)
  var owned = String.from(literal);  // malloc 발생
  defer owned.free();
  
  // UTF-8 검증
  for (var ch in s.chars()) {  // char iterator (rune)
      println(ch);  // u32 (유니코드 코드포인트)
  }
  ```
  
  **철학**: 
  - `String` = 소유권 있는 가변 문자열 (힙)
  - `[]u8` = 빌린 불변 문자열 (스택/정적)
  - 모든 힙 할당은 명시적 (`new`, `from`)

- [ ] **날짜/시간** API
  ```b
  import std.time;
  
  var now = Time.now();
  var duration = Duration.from_secs(60);
  var later = now.add(duration);
  ```

- [ ] **파일 시스템** API
  ```b
  import std.fs;
  
  var path = Path.new("data/config.toml");
  var exists = path.exists();
  var contents = fs.read_to_string(path)?;
  ```

- [ ] **네트워크** API
  ```b
  import std.net;
  
  var listener = TcpListener.bind("127.0.0.1:8080")?;
  for (var stream in listener.incoming()) {
      handle_client(stream);
  }
  ```

- [ ] **JSON** 파서
  ```b
  import std.json;
  
  var json_str = "{\"name\": \"Alice\", \"age\": 30}";
  var value: JsonValue = json.parse(json_str)?;
  var name: str = value["name"].as_str()?;
  ```

- [ ] **정규표현식**
  ```b
  import std.regex;
  
  var re = Regex.new(r"^\d{3}-\d{4}$")?;
  var is_match = re.is_match("123-4567");
  ```

- [ ] **명령줄 인자 파서**
  ```b
  import std.args;
  
  var args = Args.parse(argc, argv);
  var verbose = args.flag("verbose");
  var output = args.option("output").unwrap_or("out.txt");
  ```

- [ ] **테스트 프레임워크**
  ```b
  import std.test;
  
  @[test]
  func test_addition() {
      assert_eq(2 + 2, 4);
  }
  
  @[test]
  func test_division() {
      var result = divide(10, 2);
      assert_ok(result);
      assert_eq(result.unwrap(), 5);
  }
  ```

---

## 2) 메타프로그래밍: `comptime`

v3에서는 const-eval 수준만 유지하고, 함수 호출/루프/테이블 생성 같은 고급 `comptime`은 v4에서 다룬다.
핵심 포인트: `comptime`은 컴파일러가 코드를 “실행”해야 하므로, 컴파일러 내부에
상수 평가기(const-eval) 또는 제한 인터프리터/VM 같은 **내장 실행기**가 사실상 필수다.
아래 체크리스트는 이 실행기가 블랙홀이 되지 않도록 경계를 고정하는 용도다.

- [ ] 문법(안): `const X = comptime f(...);`
- [ ] 예: `const CRC_TABLE = comptime gen_crc_table();`

### 1.1) 컴파일러 내장 실행기: “작은 인터프리터/제한 VM” 체크리스트

`comptime`을 함수 호출/루프까지 확장하려면 컴파일러 내부에 “실행기”가 필요해지기 쉽다.
이 실행기는 범위를 제한하지 않으면 기능/디버깅/보안/성능 면에서 블랙홀로 커질 수 있으므로,
아래 원칙을 **필수로 고정**한다.

- [ ] 결정성(Determinism)
	- [ ] I/O, 시스템콜, 시간, 스레드, 랜덤 등 비결정 요소는 comptime에서 금지(= 컴파일 에러)
	- [ ] 외부 입력이 필요한 패턴은 v3의 `@embed`/생성된 파일 포함으로 우회

- [ ] 샌드박스/리소스 제한(필수)
	- [ ] 실행 스텝 제한(예: instruction count) + 제한 초과 시 컴파일 에러
	- [ ] comptime 메모리 상한(예: N KiB/MiB) + 제한 초과 시 컴파일 에러
	- [ ] 재귀/루프 무한 실행 방지 정책(스텝 제한으로 일원화 권장)

- [ ] 허용/금지 기능(범위 최소화)
	- [ ] 허용(최소): 정수/비트 연산, 비교/분기, 지역 변수, 고정 크기 배열/슬라이스 기반 계산(단, bounds는 기본 safe)
	- [ ] 금지(기본): FFI/`extern` 호출, `asm`, OS 의존 기능, 힙 할당(초기)
	- [ ] 포인터/`*T` 관련 연산은 초기에는 comptime에서 금지하거나, “opaque 값 + 산술/역참조 금지”로 최소화
	- [ ] `$`(unsafe 우회)는 comptime에서 기본 금지(권장)

- [ ] 오류/진단
	- [ ] comptime 런타임 에러(0으로 나누기, OOB, overflow 등)는 “컴파일 에러”로 승격
	- [ ] 에러는 원인 스팬/호출 스택(가능하면)을 포함해서 보고

- [ ] 구현 형태(택1)
	- [ ] AST/IR const-eval 확장: 가능한 범위는 AST/IR 기반 평가기로 처리(권장)
	- [ ] 제한 바이트코드 VM: 필요한 경우에만 최소 명령 집합으로 VM을 추가

### 1.2) The Comptime Revolution: Zig 스타일 True CTFE

v3의 "단순 치환(Template)" 방식으로 제네릭의 급한 불을 끄고,
v4에서는 엔진을 갈아엎어 **Zig 스타일의 "True Comptime(CTFE - Compile Time Function Execution)"**을 구현한다.

**핵심 철학:**
1. **"타입(Type)도 값(Value)이다."** (`var t: type = u64;`)
2. **"제네릭은 타입을 리턴하는 함수일 뿐이다."** (`func Vec(T: type) -> type`)
3. **"컴파일러는 첫 번째 사용자다."** (컴파일 타임에 코드 실행)

#### Phase 4.0: CTFE 엔진 탑재

가장 먼저 컴파일러 내부(`lib_compiler`)에 **AST 인터프리터**를 심어야 한다.

- [ ] **AST Interpreter 구현**
	- [ ] 컴파일러 내부에 `eval(Node, Env) -> Value` 함수 구현
	- [ ] 산술 연산(`+`, `-`, `*`, `/`, `%`) 및 논리 연산 평가 가능
	- [ ] 비트 연산(`&`, `|`, `^`, `<<`, `>>`, `<<<`, `>>>`) 지원
	- [ ] 변수 바인딩: 컴파일 타임 변수 저장소(`Map<Name, Value>`) 구현
	- [ ] 제어 흐름: `if`/`else`, `while`, `for` 루프의 컴파일 타임 실행
	- [ ] 함수 호출: 컴파일 타임 함수 호출 스택 관리
	- [ ] **DoD:** `const X = 10 + 20;`을 파싱할 때, 런타임 코드가 아니라 컴파일 타임 상수 `30`으로 계산되어 박제됨

- [ ] **`comptime` 블록/키워드 지원**
	- [ ] `comptime { ... }`: 이 블록 안의 코드는 즉시 `eval()`로 보내고, 결과만 남김
	- [ ] `func(comptime x: i32)`: 인자가 상수가 아니면 컴파일 에러 발생
	- [ ] `comptime var x = expr;`: 컴파일 타임 변수 선언

#### Phase 4.1: "Types as Values" (타입의 1등 시민화)

지금까지 `u64`, `i32`는 키워드였지만, 이제는 **값**으로 취급한다.

- [ ] **`type` 타입 추가**
	- [ ] 컴파일러 내부 값(`Value` enum)에 `Type(TypeInfo)` 추가
	- [ ] 문법 허용: `var T: type = i32;`
	- [ ] 타입 변수 전달: `func print_type(T: type) { ... }`

- [ ] **타입 연산 (Type Operations)**
	- [ ] `@sizeof(T: type) -> u64` (컴파일 타임 내장 함수)
	- [ ] `@alignof(T: type) -> u64`
	- [ ] `@offsetof(T: type, field: string) -> u64`
	- [ ] `@typeof(expr) -> type` (표현식의 타입 추출)
	- [ ] `@type_name(T: type) -> []u8` (타입 이름 문자열 반환)

- [ ] **DoD:** 아래 코드가 컴파일 타임에 실행되어야 함
```b
comptime {
    var my_type: type = u64;
    if (@sizeof(my_type) == 8) {
        // 컴파일 타임 출력 (컴파일러 로그)
        @comptime_print("It's 64bit!");
    }
}
```

#### Phase 4.2: 제네릭의 재정의 (Generics as Functions)

v3의 "텍스트 치환 방식(`<T>`)"을 내부적으로 **"함수 실행 방식"**으로 전환한다.

- [ ] **구조체 생성 함수 (Type Constructors)**
	- [ ] 함수가 `type`을 반환할 수 있게 허용
	- [ ] 반환된 `struct` 정의를 익명 구조체로 등록

```b
// v4 스타일 제네릭 (내부 표현)
func Vec(comptime T: type) -> type {
    return struct {
        ptr: *T;
        len: u64;
        cap: u64;
    };
}
```

- [ ] **문법 설탕 (Syntactic Sugar) 유지**
	- [ ] 사용자는 여전히 `Vec<u64>`로 쓸 수 있음 (v3 호환성)
	- [ ] 파서가 `Vec<u64>`를 만나면 → 내부적으로 `Vec(u64)` 함수 호출로 변환(Lowering)
	- [ ] 양방향 지원:
		- [ ] `Vec<u64>` (C++ 스타일 문법 설탕)
		- [ ] `Vec(u64)` (Zig 스타일 직접 호출)

- [ ] **Memoization (캐싱)**
	- [ ] `Vec(u64)`를 두 번 호출하면, 인터프리터가 "어? 아까 입력값 `u64`로 돌린 결과 있네?" 하고 캐시된 구조체를 반환
	- [ ] 중복 정의 방지 + 컴파일 속도 향상

- [ ] **제네릭 함수 재정의**
```b
// 기존 v3 방식 (문법 설탕으로 유지)
func add<T>(a: T, b: T) -> T { return a + b; }

// v4 내부 변환 (comptime 파라미터)
func add(comptime T: type, a: T, b: T) -> T { 
    return a + b; 
}

// 호출
add<i32>(10, 20)  // 문법 설탕
add(i32, 10, 20)  // 직접 호출 (둘 다 지원)
```

#### Phase 4.3: 조건부 컴파일 (Conditional Compilation)

v4의 꽃이다. 제네릭 내부에서 `if`문을 써서 **구조체 모양을 바꾼다.**

- [ ] **Comptime Control Flow**
	- [ ] `eval()` 함수가 `if` 문을 만났을 때, 조건이 `true`인 분기만 AST에 남기고 `false` 분기는 **삭제(Dead Code Elimination)**
	- [ ] 컴파일 타임 루프 언롤링(Loop Unrolling)
	- [ ] 컴파일 타임 분기에 따른 타입 변경

- [ ] **검증 (Use Case)**
```b
func IntOrFloat(comptime T: type) -> type {
    comptime {
        if (T == i32 or T == i64) {
            return struct { i: T; };
        } else if (T == f32 or T == f64) {
            return struct { f: T; };
        } else {
            @compile_error("IntOrFloat requires integer or float type");
        }
    }
}

// 사용
var x: IntOrFloat<i32>;  // struct { i: i32; }
var y: IntOrFloat<f32>;  // struct { f: f32; }
var z: IntOrFloat<bool>; // 컴파일 에러!
```

- [ ] **플랫폼별 조건부 컴파일**
```b
func get_socket_type() -> type {
    comptime {
        if (@target_os() == "windows") {
            return struct { handle: u64; };
        } else {
            return struct { fd: i32; };
        }
    }
}
```

#### Phase 4.4: 리플렉션 (Reflection)

구조체의 필드 정보를 컴파일 타임에 순회할 수 있게 한다. (직렬화 라이브러리 자동화)

- [ ] **`@type_info(T)` 내장 함수**
	- [ ] 구조체 `T`를 넣으면 필드 리스트를 반환
	- [ ] 반환 값: 필드 배열 (`name: []u8`, `type: type`, `offset: u64`)
	- [ ] enum의 경우: variant 리스트 반환

- [ ] **Comptime Loop (Unrolling)**
	- [ ] `comptime for` 문이 컴파일 타임에 돌면서 코드를 복사-붙여넣기함

```b
// JSON 직렬화 자동 생성 예시
struct Player {
    name: []u8;
    hp: i32;
    level: u64;
}

func serialize(obj: anytype) -> []u8 {
    var result: []u8 = "{";
    
    comptime {
        var fields = @type_info(@typeof(obj)).fields;
        
        // 컴파일 타임 루프: 각 필드마다 코드 생성
        for (field, i in fields) {
            if (i > 0) {
                result = result.concat(", ");
            }
            
            // 필드 이름 출력
            result = result.concat("\"" ++ field.name ++ "\": ");
            
            // 필드 값 접근 ($연산자로 동적 필드 접근)
            result = result.concat(to_json(@field(obj, field.name)));
        }
    }
    
    result = result.concat("}");
    return result;
}
```

- [ ] **`@field(obj, name)` 내장 함수**
	- [ ] 컴파일 타임에 알려진 문자열로 필드 접근
	- [ ] 의미: `obj.name`과 동일하지만, `name`이 컴파일 타임 변수일 때 사용

#### Phase 4.5: 컴파일 타임 코드 생성 (Code Generation)

가장 강력한 기능: 컴파일 타임에 **함수를 만든다.**

- [ ] **`@embed_code()` 또는 mixin 메커니즘**
	- [ ] 컴파일 타임에 문자열로 코드를 생성하고, AST에 주입

```b
// 예시: 성능 크리티컬 벡터 연산 생성기
func generate_vec_ops(comptime size: u64) -> type {
    comptime {
        var code = "struct Vec" ++ @to_string(size) ++ " {\n";
        
        // 필드 생성
        for (i in 0..size) {
            code = code ++ "    x" ++ @to_string(i) ++ ": f32;\n";
        }
        
        // 덧셈 함수 생성
        code = code ++ "    func add(self: *Vec, other: Vec) -> Vec {\n";
        code = code ++ "        return Vec{\n";
        for (i in 0..size) {
            code = code ++ "            .x" ++ @to_string(i) 
                   ++ " = self.x" ++ @to_string(i) 
                   ++ " + other.x" ++ @to_string(i) ++ ",\n";
        }
        code = code ++ "        };\n    }\n}";
        
        return @embed_code(code);
    }
}

var v4: generate_vec_ops(4);  // Vec4 생성 (x0, x1, x2, x3)
```

#### v3 vs v4 비교 요약

| 기능 | Basm v3 (Template) | Basm v4 (Comptime) |
| --- | --- | --- |
| **제네릭 원리** | 텍스트 치환 (Find & Replace) | **함수 실행 (Function Call)** |
| **`Vec<T>`** | `T` 자리에 타입을 끼워 넣음 | `Vec` 함수가 `struct`를 리턴함 |
| **`if`문 사용** | 불가능 (혹은 `#ifdef` 전처리기) | **가능** (조건에 따라 필드 변경 가능) |
| **컴파일러 구조** | 파서 → 변환기 → 코드젠 | 파서 → **VM(실행)** → 코드젠 |
| **타입의 지위** | 키워드 (고정) | **1급 값** (`type` 타입) |
| **리플렉션** | 없음 | **완전 지원** (`@type_info`) |
| **유연성** | C++ 템플릿 수준 | Zig/Lisp 수준 (무한한 자유) |
| **마이그레이션** | - | `Vec<T>` 문법 설탕 유지 (호환성) |

#### 구현 우선순위

1. **Phase 4.0** (필수): AST Interpreter 기본 엔진
2. **Phase 4.1** (필수): `type` 타입 + 타입 연산
3. **Phase 4.2** (고우선): 제네릭 재구현 (v3 호환성 유지)
4. **Phase 4.3** (중우선): 조건부 컴파일
5. **Phase 4.4** (중우선): 리플렉션
6. **Phase 4.5** (저우선): 코드 생성 (실험적)

#### 보안/안정성 고려사항

- [ ] **무한 루프 방지**: 컴파일 타임 실행 step count 제한 (위의 1.1 참고)
- [ ] **메모리 제한**: 컴파일 타임 할당 상한 (위의 1.1 참고)
- [ ] **에러 전파**: 컴파일 타임 에러는 원본 소스 위치와 함께 보고
- [ ] **결정성**: I/O/시스템콜/시간/랜덤 금지 (위의 1.1 참고)

### 결론

이 로드맵은 **컴파일러의 두뇌를 교체하는 대수술**이다.
v3에서 언어의 **"뼈대(Parser, CodeGen, Memory)"**를 완성하고,
v4에서 **"지능(Interpreter)"**을 심는다.

---

## 3) 테스트/검증 전략(v4)

v3에서는 컴파일러/IR/코드젠의 골격을 우선 완성하고,
v4에서 테스트 체계를 “자동화/확장/보안 중심”으로 강화한다.

### 2.1) 형식 검증(Formal Verification)

"테스트로는 버그가 없음을 증명할 수 없다"는 철학을 목표 기능으로 삼는다.

- [ ] Verify 백엔드: `basm verify`
	- [ ] `@[requires]`, `@[ensures]`, `@[invariant]`가 붙은 코드를 SMT-LIB 2.0 수식으로 변환
	- [ ] Z3 등 외부 solver 연동
	- [ ] 주요 타깃: overflow, 분기 조건 위반, 계약 조건 위반
- [ ] 컴파일 모드 정책
	- [ ] `verify`: 증명만 수행(실행 파일 생성 X)
	- [ ] `debug`: 계약 조건을 런타임 `assert()`로 삽입
	- [ ] `release`: 계약 조건 제거(Zero Overhead)

### 2.2) 내장 Fuzzing 및 Sanitizer

- [ ] Fuzz 블록(안): `fuzz "name" (provider) { ... }`
	- [ ] 컴파일러가 하네스/입력 주입/무한 루프 제어를 자동 생성
- [ ] Runtime Sanitizers: `-fsanitize` 옵션
	- [ ] 오버플로우, OOB, 0으로 나누기 등을 런타임에서 포착

### 2.3) 기존 테스트 체계(유지/확장)

- [ ] 파서 스냅샷 테스트(AST pretty-print golden)
- [ ] IR 스냅샷 테스트(IR dump golden)
- [ ] e2e 스모크(Px): 작은 프로그램 컴파일→실행 exit code 검증
- [ ] 제네릭/컨테이너/foreach 폭 인식 등 핵심 기능별 스모크 추가

---
---

## 1) 실용적 구현 우선순위 (v4 Roadmap)

v4의 모든 기능이 동등하게 중요한 것은 아닙니다. 아래 우선순위를 따르세요.

### ⚪ Phase -1: 코드 리팩토링 (v3 Self-Hosted)

**v4 구현 전 필수 작업**: v3 컴파일러와 스탠다드 라이브러리를 v3 문법으로 리팩토링

#### 목표
v2 문법으로 작성된 v3 컴파일러와 스탠다드 라이브러리를 v3 문법으로 재작성하여 Self-Hosted 달성

#### 작업 내용

**1. v2 매직 식별자 제거**
```b
// Before (v2 문법)
var expr = cast(*Expr, malloc(32));
ptr64[expr + 0] = CALL;
ptr64[expr + 8] = cast(u64, callee);
ptr64[expr + 16] = cast(u64, args);

// After (v3 문법)
struct Expr {
    kind: ExprKind;
    callee: *Expr;
    args: *Vec;
}

var expr: *Expr = cast(*Expr, malloc(sizeof(Expr)));
expr->kind = CALL;
expr->callee = callee;
expr->args = args;
```

**2. 타입 명시 추가**
```b
// Before (v2 호환)
func parse_expr(p) {  // 타입 생략
    var tok = peek(p);
    // ...
}

// After (v3 명시적)
func parse_expr(p: *Parser) -> *Expr {
    var tok: *Token = peek(p);
    // ...
}
```

**3. 포인터 타입 개선**
```b
// Before (v2 스타일)
var nodes = vec_new(8);  // void* 타입
var node = cast(*AstNode, vec_get(nodes, i));

// After (v3 타입 안전)
var nodes: *Vec = vec_new(8);  // Vec<AstNode*>
var node: *AstNode = cast(*AstNode, vec_get(nodes, i));
```

**4. 구조체 활용**
```b
// Before (v2 tuple 흉내)
var result = vec_new(2);
vec_push(result, cast(*u8, success));
vec_push(result, cast(*u8, value));

// After (v3 struct)
struct ParseResult {
    success: bool;
    value: *Expr;
}

var result: ParseResult = ParseResult{
    success: true,
    value: expr,
};
```

**5. 함수 포인터 활용**
```b
// Before (v2 간접 호출 없음)
if (kind == ADD) {
    result = emit_add(ctx, left, right);
} else if (kind == SUB) {
    result = emit_sub(ctx, left, right);
}
// ... 20개 case

// After (v3 함수 포인터)
var emit_ops: [20]func(*CodegenCtx, *IR, *IR) -> *IR = {
    emit_add, emit_sub, emit_mul, ...
};

var emit_fn: func(*CodegenCtx, *IR, *IR) -> *IR = emit_ops[kind];
var result: *IR = emit_fn(ctx, left, right);
```

**6. HashMap 활용**
```b
// Before (v2 linear search)
func find_symbol(env, name_ptr, name_len) {
    for (var i = 0; i < vec_len(env); i = i + 1) {
        var sym = vec_get(env, i);
        if (str_eq(sym.name, name_ptr, name_len)) {
            return sym;
        }
    }
    return 0;  // null
}

// After (v3 HashMap, 이미 구현됨)
func find_symbol(env: *HashMap, name: []u8) -> *Symbol? {
    return hashmap_get(env, name);  // O(1)
}
```

**7. defer 활용 (메모리 안전)**
```b
// Before (v2 수동 해제)
func compile_file(path) {
    var source = read_file(path);
    var tokens = lex(source);
    var ast = parse(tokens);
    var ir = lower(ast);
    var asm = codegen(ir);
    
    free(source);
    vec_free(tokens);
    free(ast);
    free(ir);
    return asm;
}

// After (v3 defer)
func compile_file(path: []u8) -> []u8 {
    var source: []u8 = read_file(path);
    defer free_slice(source);
    
    var tokens: *Vec = lex(source);
    defer vec_free(tokens);
    
    var ast: *Ast = parse(tokens);
    defer ast_free(ast);
    
    var ir: *IR = lower(ast);
    defer ir_free(ir);
    
    return codegen(ir);  // defer 자동 실행
}
```

#### 리팩토링 단계별 계획

**Week 1-2: 스탠다드 라이브러리 재작성**
- [ ] `std/mem.b`: malloc, free, memcpy → v3 문법 변환
- [ ] `std/vec.b`: Vec 타입 개선 (제네릭 준비)
- [ ] `std/hashmap.b`: HashMap v3 문법으로 재작성
- [ ] `std/string.b`: 문자열 함수 (str_eq, str_len 등)
- [ ] `std/io.b`: 파일 I/O (read_file, write_file)
- [ ] `std/os.b`: 시스템 호출 래퍼

**Week 3-4: 기반 자료구조**
- [x] `src/v3_hosted/ast.b`: 구조체 정의 변환
- [x] `src/v3_hosted/token.b`: 토큰 구조체
- [ ] `src/v3_hosted/vec.b`: Vec 타입 개선

**Week 5-6: 파서/렉서**
- [ ] `src/v3_hosted/lexer.b`: v3 문법으로 재작성
- [ ] `src/v3_hosted/parser.b`: 타입 명시, 구조체 활용

**Week 7-8: 타입 체크**
- [ ] `src/v3_hosted/typecheck.b`: HashMap 활용, 함수 포인터

**Week 9-10: 코드 생성**
- [ ] `src/v3_hosted/ir.b`: IR 구조체 개선
- [ ] `src/v3_hosted/codegen.b`: defer, 에러 처리

**Week 11-12: 검증**
- [ ] Golden Test: v2 → v3 → v3 → v3 (3세대 체크)
- [ ] 성능 비교: v2 vs v3 컴파일 속도
- [ ] 크기 비교: 바이너리 크기
- [ ] 스탠다드 라이브러리 단위 테스트

#### DoD (Definition of Done)

- [ ] v3 문법으로 작성된 v3 컴파일러가 자기 자신을 컴파일
- [ ] 스탠다드 라이브러리 v3 재작성 완료
- [ ] 모든 golden test 통과 (39개)
- [ ] 3세대 안정성 확인 (v3 → v3 → v3 바이너리 동일)
- [ ] v2 매직 식별자 완전 제거
- [ ] 코드 품질: 타입 안전성, defer, HashMap
- [ ] 스탠다드 라이브러리 단위 테스트 작성

#### 예상 효과

- **코드 가독성**: 50% 향상 (타입 명시, 구조체)
- **유지보수성**: 70% 향상 (자료구조 명확)
- **버그 감소**: 30% 감소 (타입 안전성)
- **개발 속도**: 2배 향상 (v3 문법 활용)

---

### Phase 0: v3에서 미룬 쉬운 것들

**즉시 시작 가능 (문법/IR 확장)**:
- Named Arguments (parser만 추가, typecheck 완료)
- 구조체 리터럴 (typecheck 복잡하지만 실용적)
- 다중 리턴 (rax/rdx ABI 매핑)
- 조건부 컴파일 `@[cfg]` (AST 필터링)
- FFI extern 블록
- `defer` break/continue 지원
- 배열 리터럴: `[1, 2, 3, 4]`
- 삼항 연산자: `cond ? a : b`

**표준 라이브러리 기본 확장**:
- [ ] **String 타입** (UTF-8 보장 Vec<u8>): `String.new()`, `String.from()`, `push_str()`, `chars()`, 명시적 `free()` 필요
- [ ] **Range 타입**: `0..10`, `0..=10`
- [ ] **Option<T>**: `Some(T)`, `None` (nullable 포인터 대체)
- [ ] **Result<T, E>**: `Ok(T)`, `Err(E)` + `unwrap()`, `expect()`
- [ ] **HashSet<T>**: HashMap 기반 구현
- [ ] **기본 Collections**: LinkedList, Deque

**개발 도구 기초**:
- [ ] **포맷터** (`bfmt`): 기본 들여쓰기, 줄바꿈
- [ ] **테스트 프레임워크**: `@[test]`, `assert_eq()`, `assert_ok()`

### Phase 1: 점진적 기능 확장

**v3 self-hosted 후 (IR/타입 시스템 강화)**:
- 제네릭 타입 추론 (Hindley-Milner)
- Value generics (제한적 comptime)
- **SSA IR 구축** (Static Single Assignment)
  - Dominance tree 계산
  - Phi 노드 삽입
  - 변수 이름 변경 (Renaming)
  - SSA 파괴 (codegen 전)
- 최적화 패스 (SSA 기반)
  - Constant propagation
  - Dead code elimination (DCE)
  - Common subexpression elimination (CSE)
  - Copy propagation
- 불변 바인딩 `final`
- 런타임 디버깅 (스택 트레이스)

**에러 처리 완성**:
- [ ] **try 연산자** (`?`): 에러 전파
- [ ] **패턴 매칭**: enum/union 디스트럭처링
- [ ] **match 표현식**: `var x = match val { ... }`

**표준 라이브러리 확장**:
- [ ] **Iterator 인터페이스**: `iter()`, `filter()`, `map()`, `sum()`
- [ ] **BTreeMap/BTreeSet**: 정렬된 컬렉션
- [ ] **PriorityQueue**: 힙 기반 구현
- [ ] **날짜/시간 API**: `Time.now()`, `Duration`
- [ ] **파일 시스템 API**: `Path`, `fs::read_to_string()`

**개발 도구**:
- [ ] **린터** (`blint`): 미사용 변수, unreachable code 경고
- [ ] **문서 생성기** (`bdoc`): `///` 주석 → HTML

### Phase 2: 고급 기능

**신중한 설계 필요 (타입 시스템 고도화)**:
- 형식 검증 (SMT solver 통합)
- 비트 슬라이싱
- 암호 Builtin intrinsics
- Inline ASM 개선
- Associated types (trait 전용)
- Default type parameters
- Comptime 타입 검증 강화 (trait bounds 대체)

**표준 라이브러리 고급**:
- [ ] **네트워크 API**: `TcpListener`, `TcpStream`
- [ ] **JSON 파서**: `json::parse()`, `JsonValue`
- [ ] **정규표현식**: `Regex::new()`
- [ ] **명령줄 인자 파서**: `Args::parse()`

**개발 도구**:
- [ ] **LSP 서버**: 자동 완성, 정의로 이동, 참조 찾기
- [ ] **패키지 관리자** (`bpkg`): 의존성 관리
- [ ] **빌드 시스템**: `build.b` 스크립트
- [ ] **벤치마크 프레임워크**: `@[bench]`

### Phase 3: Comptime Revolution

**컴파일러 재설계 수준 (메타프로그래밍)**:
- AST Interpreter 구현
- `type` 타입 (Types as Values)
- 리플렉션 (`@type_info`)
- 조건부 컴파일 (Comptime Control Flow)
- 코드 생성 (`@embed_code`)

**동시성 (선택적)**:
- [ ] **Thread 지원**: `Thread::spawn()`
- [ ] **Channel**: 메시지 패싱
- [ ] **Mutex/RwLock**: 동기화 프리미티브
- [ ] **Async/Await** (선택적, v5 고려)

**개발 도구 고급**:
- [ ] **프로파일러** (`bprof`): flame graph 생성
- [ ] **REPL**: 인터랙티브 쉘

**경고**: 이 기능은 컴파일러 내부 구조를 근본부터 바꿉니다. v5로 미루는 것도 고려하세요.

---

## 4) CPU SIMD 자동 벡터화 (v4 우선순위)

**목표**: GPU까지 가지 않고 CPU 벡터 명령어(AVX2/AVX-512)만으로도 충분한 성능 향상을 얻습니다.

### 왜 SIMD가 먼저인가?

**장점**:
- **8~16배 속도 향상**: 단일 명령으로 8개(AVX2) 또는 16개(AVX-512) 데이터 처리
- **데이터 전송 병목 없음**: CPU 캐시 내에서 동작
- **구현 난이도 낮음**: IR → AVX2 패턴 매칭으로 가능
- **디버깅 용이**: CPU 디버거로 직접 추적 가능
- **이식성**: x86-64 서버/데스크톱 대부분 지원

**vs GPU**:
- GPU는 v4 전체 작업량의 2~3배 복잡도
- SPIR-V 코드젠, Vulkan 런타임, 메모리 전송 최적화 필요
- v4 목표(Self-Hosted 컴파일러)와 범위 불일치

### 자동 벡터화 예시

```b
// 소스 코드 (단순 루프)
for (var i: u64 = 0; i < n; i++) {
    c[i] = a[i] + b[i];
}

// 컴파일러가 생성하는 AVX2 코드:
// L_loop:
//   vmovups ymm0, [rdi + rax*4]      ; a[i..i+7] 로드 (8개)
//   vaddps ymm0, ymm0, [rsi + rax*4] ; b[i..i+7] 더하기 (8개)
//   vmovups [rdx + rax*4], ymm0      ; c[i..i+7] 저장 (8개)
//   add rax, 8                       ; i += 8
//   cmp rax, rcx
//   jl L_loop
```

### 구현 전략

- [ ] **Loop Analysis**: 벡터화 가능 루프 검출
  - 단순 증가 카운터 (`i++`)
  - 독립적 반복 (data dependency 없음)
  - 배열 접근 패턴 (`arr[i]`)

- [ ] **패턴 매칭**: IR에서 벡터화 가능 연산 식별
  - 덧셈/뺄셈: `vaddps`, `vsubps`
  - 곱셈/나눗셈: `vmulps`, `vdivps`
  - 비교 연산: `vcmpps`
  - 로드/스토어: `vmovups`, `vmovaps`

- [ ] **코드 생성**: AVX2 명령어로 변환
  - Alignment 체크 (16바이트 정렬 시 `vmovaps` 사용)
  - Remainder loop (n % 8 != 0 처리)
  - 레지스터 할당 (ymm0~ymm15)

### 제약사항

**벡터화 불가능한 경우**:
- Data dependency: `arr[i] = arr[i-1] + 1`
- 분기문 포함: `if (arr[i] > 0) { ... }`
- 함수 호출 포함: `arr[i] = compute(i);`
- 포인터 간접 참조: `arr[ptr[i]]`

이런 경우 일반 루프로 폴백합니다.

### SIMD 직접 제어 (Explicit SIMD)

**철학**: 자동 벡터화는 편리하지만, **해커는 성능을 운에 맡기지 않습니다.**

컴파일러의 자동 벡터화는 코드가 조금만 복잡해지면 쉽게 실패합니다.
분기문, 함수 호출, 복잡한 메모리 패턴 등이 있으면 벡터화를 포기합니다.
**Basm은 프로그래머가 명시적으로 SIMD를 제어할 수 있어야 합니다.**

#### Level 1: SIMD 자료형 (Vector Types)

메모리 정렬(Alignment)이 보장된 내장 벡터 타입을 제공합니다.

- [ ] **벡터 타입 정의**
  ```b
  // 128비트 벡터 (SSE)
  var a: f32x4 = f32x4 { 1.0, 2.0, 3.0, 4.0 };  // float 4개
  var b: i32x4 = i32x4 { 1, 2, 3, 4 };          // int 4개
  
  // 256비트 벡터 (AVX2)
  var c: f32x8 = f32x8 { 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0 };
  var d: u8x32;  // byte 32개
  
  // 512비트 벡터 (AVX-512, 후순위)
  var e: f32x16;
  ```

- [ ] **연산자 오버로딩**
  ```b
  var a: f32x4 = f32x4 { 1.0, 2.0, 3.0, 4.0 };
  var b: f32x4 = f32x4 { 5.0, 5.0, 5.0, 5.0 };
  
  var c = a + b;  // vaddps (4개 동시 덧셈)
  var d = a * b;  // vmulps (4개 동시 곱셈)
  var e = a < b;  // vcmpps (4개 동시 비교)
  ```

- [ ] **메모리 정렬 보장**
  ```b
  // 컴파일러가 자동으로 16바이트 정렬
  var aligned_array: [1024]f32x4;  // 16KB, 16바이트 정렬
  
  // 힙 할당도 정렬 보장
  var vec_ptr = new f32x4;  // malloc 대신 aligned_alloc 사용
  ```

#### Level 2: 인트린식 (Intrinsics)

C/C++의 `_mm256_*` 같은 인트린식을 Basm 스타일로 제공합니다.

- [ ] **플랫폼별 모듈**
  ```b
  import std.arch.x86.sse2;
  import std.arch.x86.avx2;
  import std.arch.x86.avx512;  // 후순위
  import std.arch.arm.neon;    // 후순위
  ```

- [ ] **기본 인트린식**
  ```b
  // 로드/스토어
  var vec = avx2.load_aligned(ptr);      // vmovaps (정렬된 로드)
  var vec = avx2.load_unaligned(ptr);    // vmovups (비정렬 로드)
  avx2.store_aligned(ptr, vec);          // vmovaps (정렬된 저장)
  
  // 브로드캐스트
  var all_five = avx2.set1_f32(5.0);     // vbroadcastss (모든 요소에 5.0)
  
  // 비교
  var mask = avx2.eq_f32(a, b);          // vcmpeqps (같음 비교)
  var mask = avx2.gt_f32(a, b);          // vcmpgtps (큼 비교)
  
  // 비트 연산
  var result = avx2.and_i32(a, b);       // vpand (비트 AND)
  var result = avx2.or_i32(a, b);        // vpor (비트 OR)
  ```

- [ ] **고급 인트린식**
  ```b
  // 셔플/치환
  var shuffled = avx2.shuffle_f32(vec, mask);  // vpshufb
  
  // 마스크 추출
  var bitmask = avx2.move_mask_i8(cmp);        // vpmovmskb
  
  // 암호화 (AES-NI)
  import std.arch.x86.aes;
  var encrypted = aes.enc(data, key);          // aesenc
  
  // 팝카운트
  var count = popcnt(bits);                    // popcnt
  ```

#### 실전 예시: 초고속 문자열 검색

```b
import std.arch.x86.avx2;

// 바이트 배열에서 개행 문자(0x0A) 위치 찾기
func find_newline_fast(buf: *u8, len: u64) -> i64 {
    var ptr = buf;
    
    // 개행 문자로 꽉 채운 벡터 생성
    var target = avx2.set1_i8(0x0A);
    
    // 32바이트 단위로 병렬 처리
    while (len >= 32) {
        // 메모리 로드 (vmovdqu)
        var chunk = avx2.load_unaligned(cast(*u8x32, ptr));
        
        // 비교 (vpcmpeqb) -> 일치하면 0xFF, 아니면 0x00
        var cmp = avx2.eq_i8(chunk, target);
        
        // 비트마스크 추출 (vpmovmskb) -> 32비트 정수
        var mask = avx2.move_mask_i8(cmp);
        
        if (mask != 0) {
            // 개행 발견! 첫 번째 1비트 위치 찾기
            return cast(i64, ptr - buf) + cast(i64, trailing_zeros(mask));
        }
        
        ptr += 32;
        len -= 32;
    }
    
    // 남은 자투리는 스칼라로 처리
    for (var i: u64 = 0; i < len; i++) {
        if (ptr[i] == 0x0A) {
            return cast(i64, ptr - buf) + cast(i64, i);
        }
    }
    
    return -1;  // 못 찾음
}
```

#### 분기문이 있는 경우: 마스킹 기법

자동 벡터화가 실패하는 분기문도 마스킹으로 해결 가능합니다.

```b
// Before: 자동 벡터화 실패
for (var i: u64 = 0; i < n; i++) {
    if (a[i] > 0) {  // 분기문 때문에 벡터화 포기
        b[i] = a[i] * 2;
    }
}

// After: 마스킹으로 강제 벡터화
import std.arch.x86.avx2;

var i: u64 = 0;
while (i + 8 <= n) {
    var vec_a = avx2.load(cast(*f32x8, &a[i]));
    var vec_b = avx2.load(cast(*f32x8, &b[i]));
    
    // 조건 마스크 생성 (a[i] > 0)
    var zero = avx2.set1_f32(0.0);
    var mask = avx2.gt_f32(vec_a, zero);
    
    // 조건부 곱셈 (마스크가 true인 곳만 적용)
    var doubled = avx2.mul_f32(vec_a, avx2.set1_f32(2.0));
    var result = avx2.blend_f32(vec_b, doubled, mask);  // 마스크에 따라 선택
    
    avx2.store(cast(*f32x8, &b[i]), result);
    i += 8;
}

// 남은 자투리 처리
while (i < n) {
    if (a[i] > 0) { b[i] = a[i] * 2; }
    i++;
}
```

#### 구현 우선순위

**1단계** (v4 필수):
- [ ] Vector Types (`f32x4`, `f32x8`, `i32x4`, `u8x32`)
- [ ] 기본 연산자 오버로딩 (`+`, `-`, `*`, `/`, `<`, `>`)
- [ ] 기본 인트린식 (load, store, set, add, mul)

**2단계** (v4 후반):
- [ ] 고급 인트린식 (shuffle, blend, mask, compare)
- [ ] 특수 명령어 (AES-NI, popcount, lzcnt)

**3단계** (v5):
- [ ] ARM NEON 지원
- [ ] AVX-512 지원 (512비트 벡터)
- [ ] Portable SIMD 추상화

#### 설계 원칙

1. **Raw Intrinsics First**: 기계어 1:1 매핑 우선
2. **No Magic**: 명시적으로 작성한 코드만 SIMD로 변환
3. **Fallback to Scalar**: 벡터 타입 미지원 CPU는 스칼라 루프로 폴백
4. **Alignment First**: 정렬된 메모리 접근을 기본으로

**결론**: 
- **자동 벡터화**: 간단한 루프는 컴파일러가 알아서 (편의성)
- **직접 제어**: 복잡한 로직은 프로그래머가 명시적으로 (성능 보장)
- 두 방법 모두 제공하여 "편의성"과 "제어권" 모두 확보

### 향후 확장 (v5+)

- [ ] GPU 지원은 **별도 프로젝트** 또는 v5 이후로 연기
- [ ] GPU 문서는 `docs/gpu_vision.md`로 분리
- [ ] v4는 CPU 최적화에만 집중

**결론**: v4는 CPU SIMD 자동 벡터화로 충분한 성능 향상 달성. GPU는 나중에.

---

## 5) SSA IR (Static Single Assignment)

SSA(정적 단일 대입)는 각 변수가 정확히 한 번만 대입되는 중간 표현(IR)입니다.
이는 최적화 패스를 단순화하고 강력하게 만드는 핵심 기술입니다.

### 5.1) SSA가 필요한 이유

**문제 (비SSA IR)**:
```b
// 원본 코드
var x = 10;
if (cond) {
    x = 20;
}
print(x);
```

**비SSA IR**:
```
x = 10
if cond goto L1
x = 20
L1:
print(x)  // x가 10인지 20인지 불명확!
```

**SSA IR**:
```
x_0 = 10
if cond goto L1
x_1 = 20
L1:
x_2 = phi(x_0, x_1)  // 합류 지점에서 phi 노드
print(x_2)           // 명확!
```

**장점**:
1. **Use-Def 체인 명확**: 각 사용이 어느 정의에서 왔는지 O(1)로 추적
2. **최적화 단순화**: Dead code elimination, constant propagation이 쉬워짐
3. **분석 정확도**: Data-flow analysis가 정확해짐

### 5.2) 구현 전략 (2단계)

#### Stage 1: SSA-lite (v4 초기, 1~2개월)

완전한 SSA가 아닌 간소화 버전으로 빠르게 구축:

```b
// SSA-lite: Phi 노드 없이 버전 넘버링만
struct SSAValue {
    var_id: u64;
    version: u64;  // x_0, x_1, x_2...
}

// 변수 재정의마다 버전 증가
var x_0 = 10;
if (cond) { var x_1 = 20; }
var x_2 = select(cond, x_1, x_0);  // phi 대신 select
print(x_2);
```

**장점**:
- 구현 간단 (Phi 노드 삽입 불필요)
- 기본 최적화 (CSE, DCE) 즉시 가능
- v3 문법만으로 충분

**단점**:
- 고급 최적화 제한적
- 메모리 사용량 증가 (select 명령어)

#### Stage 2: 완전한 SSA (v4 중후반, 3~6개월)

표준 SSA 알고리즘 구현:

- [ ] **Dominance Tree 계산**
  - [ ] Lengauer-Tarjan 알고리즘
  - [ ] 즉시 지배자(Immediate Dominator) 계산
  - [ ] Dominance Frontier 계산

- [ ] **Phi 노드 삽입**
  - [ ] 각 변수의 정의 지점 수집
  - [ ] Dominance Frontier에 Phi 노드 배치
  - [ ] 최소 Phi 노드 (Pruned SSA)

- [ ] **변수 이름 변경 (Renaming)**
  - [ ] 지배 트리 DFS 순회
  - [ ] 각 정의에 새 버전 할당
  - [ ] Phi 노드 피연산자 연결

- [ ] **SSA 파괴 (Out of SSA)**
  - [ ] Phi 노드를 복사 명령으로 변환
  - [ ] Critical edge 분할
  - [ ] 레지스터 할당 전 처리

### 5.3) SSA 자료구조

```b
// 기본 블록 (SSA 확장)
struct BasicBlock {
    id: u64;
    instructions: *Vec;
    predecessors: *Vec;
    successors: *Vec;
    phi_nodes: *Vec;       // Phi 노드 리스트
    idom: *BasicBlock?;    // 즉시 지배자
    dom_children: *Vec;    // 지배 트리 자식들
}

// SSA 값
struct SSAValue {
    id: u64;                // 고유 ID (x_0, x_1, ...)
    type: Type;
    def_instr: *Instruction?;  // 정의 명령어
    uses: *Vec;             // 사용 지점들 (Use-Def chain)
}

// Phi 노드
struct PhiNode {
    result: *SSAValue;
    incoming: *Vec;  // Vec<(BasicBlock*, SSAValue*)>
}

// 명령어 (SSA 형식)
struct Instruction {
    opcode: OpCode;
    operands: *Vec;         // Vec<SSAValue*>
    result: *SSAValue?;
    parent_block: *BasicBlock;
}
```

### 5.4) SSA 기반 최적화

SSA 형식이 있으면 다음 최적화가 효율적으로 가능:

#### Constant Propagation
```b
// SSA IR
x_0 = 10
y_0 = x_0 + 5  // x_0은 항상 10 → y_0 = 15로 변환
z_0 = y_0 * 2  // y_0은 항상 15 → z_0 = 30으로 변환
```

#### Dead Code Elimination
```b
// SSA IR
x_0 = 10
y_0 = x_0 + 5
z_0 = 20       // z_0을 사용하지 않음 → 제거!
return y_0
```

#### Common Subexpression Elimination
```b
// SSA IR
a_0 = x_0 + y_0
b_0 = x_0 + y_0  // 동일 표현식 → b_0 = a_0으로 교체
```

#### Copy Propagation
```b
// SSA IR
x_0 = 10
y_0 = x_0      // 단순 복사
z_0 = y_0 + 5  // y_0 = x_0 → z_0 = x_0 + 5로 변환
```

### 5.5) 구현 우선순위

**1단계** (즉시 시작):
- Dominance tree 계산
- SSA 변환 (간소화 버전)
- 기본 최적화 (constant folding, DCE)

**2단계** (SSA-lite 완성 후):
- Phi 노드 삽입 (완전 SSA)
- 고급 최적화 (CSE, copy propagation)
- SSA 파괴 (레지스터 할당 준비)

**3단계** (최적화 고도화):
- Global value numbering
- Loop invariant code motion
- Strength reduction

### 5.6) 참고 자료

**논문**:
- Cytron et al. (1991): "Efficiently Computing Static Single Assignment Form and the Control Dependence Graph"
- Braun et al. (2013): "Simple and Efficient Construction of Static Single Assignment Form"

**구현 예시**:
- LLVM SSA Construction
- Cranelift IR (Rust)
- QBE IR (Minimal SSA IR)

### 5.7) v3 vs v4 비교

| 항목 | v3 (현재) | v4 (SSA) |
|------|-----------|----------|
| **IR 형태** | Stack-based | SSA (Register-based) |
| **변수 추적** | 어려움 | Use-Def chain으로 O(1) |
| **최적화** | 제한적 | 강력 (DCE, CSE, CP 등) |
| **코드 품질** | 기본 | 고품질 |
| **구현 복잡도** | 낮음 | 중간~높음 |
| **컴파일 속도** | 빠름 | 중간 (분석 비용) |

### 5.8) 주의사항

**함정**:
1. **Critical Edge 처리**: Phi 노드 배치 시 critical edge 분할 필요
2. **메모리 관리**: SSA 노드가 많아져서 메모리 사용량 증가
3. **디버깅**: SSA IR 덤프가 필수 (사람이 읽기 어려움)
4. **SSA 파괴**: 레지스터 할당 전에 반드시 일반 형식으로 변환

**권장 사항**:
- SSA-lite부터 시작 (Phi 노드 없이)
- IR 덤프 도구 먼저 구축
- 단위 테스트로 각 최적화 검증
- LLVM/Cranelift 참고 (재발명 금지)

---

## 6) 컴파일러 최적화 기법 (Optimization Techniques)

컴파일러 최적화는 여러 단계에서 적용됩니다. 각 최적화는 독립적으로 구현 가능하며,
조합하면 상승 효과가 발생합니다.

### 6.1) Peephole 최적화 (지역 최적화)

**정의**: 작은 명령어 윈도우(보통 2~3개)를 보고 패턴 매칭으로 개선

#### 대수 단순화 (Algebraic Simplification)
```b
// Before
x = y + 0        // → x = y
x = y * 1        // → x = y
x = y * 0        // → x = 0
x = y - y        // → x = 0
x = y / 1        // → x = y
x = y % 1        // → x = 0
x = y | 0        // → x = y
x = y & 0        // → x = 0
x = y & 0xFFFFFFFF  // → x = y (64비트)
x = y ^ 0        // → x = y
x = y ^ y        // → x = 0
x = y << 0       // → x = y
x = y >> 0       // → x = y
```

#### 강도 감소 (Strength Reduction)
```b
// Before → After
x = y * 2        // → x = y << 1
x = y * 4        // → x = y << 2
x = y * 8        // → x = y << 3
x = y / 2        // → x = y >> 1 (부호 없는 경우)
x = y % 8        // → x = y & 7 (2의 거듭제곱)
```

#### 중복 로드/스토어 제거
```asm
; Before
mov rax, [rbp-8]
mov [rbp-8], rax  ; 중복! 제거

; Before
mov [rbp-8], rax
mov rbx, [rbp-8]  ; → mov rbx, rax
```

#### 불필요한 점프 제거
```asm
; Before
jmp L1
L1:              ; 바로 다음 → jmp 제거

; Before
cmp rax, rbx
je L1
jmp L2
L1: jmp L2      ; 둘 다 L2로 → 첫 je를 L2로
```

**구현 난이도**: ⭐⭐☆☆☆ (쉬움)
**효과**: 코드 크기 5~10% 감소

---

### 6.2) 기본 블록 최적화

#### Local Common Subexpression Elimination (Local CSE)
```b
// Before
a = x + y
b = x + y    // 중복 표현식
c = a * 2

// After
a = x + y
b = a        // 재사용
c = a * 2
```

#### Copy Propagation
```b
// Before
x = y
z = x + 1    // x는 y의 복사본

// After
x = y
z = y + 1    // x를 y로 교체
```

#### Constant Folding (상수 폴딩)
```b
// Before
x = 2 + 3
y = x * 4
z = y + 10

// After
x = 5
y = 20
z = 30
```

#### Dead Store Elimination
```b
// Before
x = 10       // 사용되지 않음
x = 20
print(x)

// After
x = 20       // 첫 대입 제거
print(x)
```

**구현 난이도**: ⭐⭐⭐☆☆ (중간)
**효과**: 코드 크기 10~20% 감소

---

### 6.3) 전역 최적화 (SSA 기반)

#### Global Common Subexpression Elimination (Global CSE)
```b
// Before
if (cond) {
    x = a + b
} else {
    y = a + b    // 동일 표현식
}

// After (SSA)
t = a + b
if (cond) {
    x = t
} else {
    y = t
}
```

#### Sparse Conditional Constant Propagation (SCCP)
```b
// Before
x = 10
if (x > 5) {    // 항상 true
    y = 20
} else {
    y = 30      // dead code
}

// After
x = 10
y = 20          // else 제거
```

#### Global Value Numbering (GVN)
```b
// Before
a = x + y
// ... 많은 코드 ...
b = x + y       // 같은 표현식 (멀리 떨어져 있음)

// After
a = x + y
// ...
b = a           // 재사용
```

#### Dead Code Elimination (DCE)
```b
// Before
x = 10
y = 20          // y를 사용하지 않음
z = x + 5
return z

// After
x = 10
z = x + 5       // y 제거
return z
```

**구현 난이도**: ⭐⭐⭐⭐☆ (어려움, SSA 필요)
**효과**: 코드 크기 20~40% 감소

---

### 6.4) 루프 최적화

#### Loop Invariant Code Motion (LICM)
```b
// Before
for (var i = 0; i < n; i++) {
    x = a * b        // 루프 불변식
    arr[i] = x + i
}

// After
x = a * b            // 루프 밖으로 이동
for (var i = 0; i < n; i++) {
    arr[i] = x + i
}
```

#### Loop Unrolling (루프 언롤링)
```b
// Before
for (var i = 0; i < 4; i++) {
    arr[i] = i * 2
}

// After (완전 언롤링)
arr[0] = 0
arr[1] = 2
arr[2] = 4
arr[3] = 6
```

#### Loop Fusion (루프 융합)
```b
// Before
for (var i = 0; i < n; i++) {
    a[i] = b[i] + 1
}
for (var i = 0; i < n; i++) {
    c[i] = a[i] * 2
}

// After
for (var i = 0; i < n; i++) {
    a[i] = b[i] + 1
    c[i] = a[i] * 2
}
```

#### Loop Inversion (루프 반전)
```b
// Before (do-while이 더 효율적)
while (cond) {
    body
}

// After
if (cond) {
    do {
        body
    } while (cond)
}
```

#### Strength Reduction in Loops
```b
// Before
for (var i = 0; i < n; i++) {
    arr[i] = i * 5    // 매번 곱셈
}

// After
var t = 0
for (var i = 0; i < n; i++) {
    arr[i] = t
    t = t + 5         // 덧셈으로 변환
}
```

**구현 난이도**: ⭐⭐⭐⭐⭐ (매우 어려움)
**효과**: 루프 집약적 코드 50~300% 속도 향상

---

### 6.5) 인라이닝 (Inlining)

#### 함수 인라이닝
```b
// Before
func add(a: u64, b: u64) -> u64 {
    return a + b
}

func main() {
    var x = add(10, 20)    // 함수 호출 오버헤드
}

// After
func main() {
    var x = 10 + 20        // 인라인 + 상수 폴딩
}
```

**휴리스틱**:
- 작은 함수 (< 10 줄): 항상 인라인
- 한 번만 호출: 항상 인라인
- 핫 패스 (프로파일링): 크기 상관없이 인라인
- 재귀 함수: 인라인 금지

**구현 난이도**: ⭐⭐⭐⭐☆ (어려움)
**효과**: 함수 호출 오버헤드 제거 (10~50% 속도 향상)

---

### 6.6) 프로시저 간 최적화 (IPA)

#### 상수 전파 (IPA Constant Propagation)
```b
// Before
func compute(x: u64) -> u64 {
    return x * 2
}

func main() {
    return compute(10)     // 상수 인자
}

// After (인라인 + 상수 폴딩)
func main() {
    return 20
}
```

#### Dead Argument Elimination
```b
// Before
func compute(x: u64, y: u64) -> u64 {
    return x * 2           // y 미사용
}

// After
func compute(x: u64) -> u64 {
    return x * 2
}
```

**구현 난이도**: ⭐⭐⭐⭐⭐ (매우 어려움, 전역 분석 필요)
**효과**: 큰 프로그램에서 10~30% 속도 향상

---

### 6.7) 백엔드 최적화 (Code Generation)

#### 레지스터 할당 (Register Allocation)
- **Linear Scan**: 빠르지만 준최적
- **Graph Coloring**: 느리지만 최적
- **Greedy**: 중간 (권장)

#### 명령어 선택 (Instruction Selection)
```asm
; Before (naive)
mov rax, 1
add rax, 2

; After (peephole)
mov rax, 3        ; 상수 폴딩
```

#### 명령어 스케줄링 (Instruction Scheduling)
```asm
; Before (파이프라인 스톨)
mov rax, [rbp-8]
add rax, 1        ; rax 의존성 → 스톨

; After (재정렬)
mov rbx, [rbp-16]
mov rax, [rbp-8]
add rbx, 2
add rax, 1        ; 병렬 실행 가능
```

#### 자동 벡터화 (Auto-vectorization)
```b
// Before
for (var i = 0; i < n; i++) {
    c[i] = a[i] + b[i]
}

// After (AVX2)
// vmovups ymm0, [a+i]    ; 8개 로드
// vaddps ymm0, [b+i]     ; 8개 동시 덧셈
// vmovups [c+i], ymm0    ; 8개 저장
```

**구현 난이도**: ⭐⭐⭐⭐⭐ (매우 어려움)
**효과**: 8~16배 속도 향상 (SIMD)

---

### 6.8) 최적화 우선순위 (v4 구현 순서)

#### Phase 1: 기본 최적화
1. **Constant Folding** (상수 폴딩)
2. **Dead Code Elimination** (DCE)
3. **Copy Propagation**
4. **Algebraic Simplification** (대수 단순화)
5. **Peephole 최적화**

**구현**: IR 패스로 구현, 테스트 쉬움

#### Phase 2: SSA 기반 최적화
1. **Global CSE** (전역 공통 부분식 제거)
2. **SCCP** (조건부 상수 전파)
3. **GVN** (전역 값 넘버링)
4. **Strength Reduction** (강도 감소)

**구현**: SSA IR 구축 후 가능

#### Phase 3: 루프 최적화
1. **LICM** (루프 불변식 이동)
2. **Loop Unrolling** (루프 언롤링)
3. **Loop Fusion** (루프 융합)

**구현**: 루프 분석 인프라 필요

#### Phase 4: 고급 최적화
1. **함수 인라이닝**
2. **프로시저 간 최적화 (IPA)**
3. **자동 벡터화 (SIMD)**
4. **명령어 스케줄링**

**구현**: 전역 분석, 프로파일링 필요

---

### 6.9) 최적화 레벨

컴파일러 옵션으로 최적화 단계 제어:

```bash
# -O0: 최적화 없음 (디버그용)
./v4c -O0 main.b

# -O1: 기본 최적화 (빠른 컴파일)
./v4c -O1 main.b
# - Constant folding
# - Dead code elimination
# - Copy propagation

# -O2: 표준 최적화 (권장)
./v4c -O2 main.b
# - O1의 모든 최적화
# - Global CSE
# - SCCP
# - Loop optimizations (LICM, unrolling)

# -O3: 공격적 최적화 (큰 코드)
./v4c -O3 main.b
# - O2의 모든 최적화
# - 함수 인라이닝
# - Loop unrolling (더 많이)
# - 자동 벡터화

# -Os: 크기 최적화
./v4c -Os main.b
# - 코드 크기 우선
# - 인라이닝 제한
```

---

### 6.10) 측정 및 검증

#### 성능 측정
```bash
# Before 최적화
time ./program
# 10.5초

# After 최적화
time ./program
# 3.2초 (3.3배 향상!)
```

#### 정확성 검증
```bash
# Golden test (최적화 전후 결과 동일)
./v4c -O0 test.b -o test_o0
./v4c -O2 test.b -o test_o2

./test_o0 > output_o0
./test_o2 > output_o2
diff output_o0 output_o2  # 동일해야 함
```

#### 코드 크기 비교
```bash
ls -lh test_o0  # 50KB
ls -lh test_o2  # 35KB (30% 감소)
```

---

### 6.11) 참고 자료

**교과서**:
- "Engineering a Compiler" (Cooper & Torczon)
- "Advanced Compiler Design and Implementation" (Muchnick)
- "Modern Compiler Implementation in C" (Appel)

**온라인 자료**:
- LLVM Optimization Passes Documentation
- GCC Optimization Options
- Cranelift Optimization Pipeline

**논문**:
- Cytron et al. (1991): SSA Form
- Click & Cooper (1995): Global Value Numbering
- Allen & Cocke (1976): Program Optimization

