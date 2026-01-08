# v4 Roadmap (Draft)

v4는 v3(MVP)에서 의도적으로 뒤로 미룬 “블랙홀 위험 기능”을 다룹니다.
목표는 기능을 더 넣는 것보다, **컴파일러/IR/표준 라이브러리 기반이 충분히 단단해진 뒤**
고급 기능을 안전하게 확장하는 것입니다.

원칙:
- v3에서 미룬 기능은 “그냥 나중에”가 아니라, v4에서 **명시적 범위/제약/실패 모드**를 먼저 고정한다.
- 컴파일러 내부 실행기/검증/퍼징은 쉽게 규모가 커지므로, 결정성/샌드박스/리소스 제한을 최우선으로 둔다.

---
## 0) v3에서 이동된 항목 (Deferred from v3)

v3 MVP 구현 중 복잡도/블랙홀 리스크로 인해 v4로 미룬 항목들.

### 0.1) 구조체 리터럴 expression

v3 테스트 33에서 실패. typecheck 복잡도(필드 매칭, 순서 재정렬, 타입 추론 등)가 크기 때문에 v4로 이동.

- [ ] named: `Pair{ a: 1, b: 2 }`
- [ ] positional: `Pair{ 1, 2 }`
- [ ] codegen: BRACE_INIT → 스택 초기화, sret 반환, VAR 초기화
- DoD
    - struct 리터럴로 값 생성/전달 동작
    - 필드 순서와 무관하게 named init 동작 (e.g., `{ b: 2, a: 1 }`)

### 0.2) 조건부 컴파일 `@[cfg]`

플랫폼별 분기가 필요하지만, v3 MVP 범위에서는 단일 타겟(Linux x86-64)만 지원.

- [ ] 문법: `@[cfg(target_os="linux")]`
- [ ] 지원 대상: `target_os` (`linux`/`windows`)
- [ ] 분기 범위: 선언 + 문장(statement) 레벨
- DoD
    - `@[cfg(target_os="linux")]` 붙은 함수가 Linux에서만 컴파일됨

### 0.3) FFI extern 블록

v3에서는 단순 `extern func` 선언만 지원. 블록 방식 + 호출 규약 지정은 v4.

- [ ] 문법: `extern "C" { func ...; }`
- [ ] 호출 규약: `extern "sysv"`, `extern "win64"`
- [ ] 심볼 이름 매핑 (e.g., `@[link_name="custom_name"]`)
- DoD
    - C 라이브러리 함수 호출 예제 동작

### 0.4) 캡처 없는 익명 함수 / 함수 포인터

- [ ] 함수 포인터 타입: `func(T, U) -> R`
- [ ] 변수에 함수 주소 저장
- [ ] 간접 호출 코드젠
- [ ] (후순위) 익명 함수: `|x| x+1` 또는 `fn(x) { ... }` 형태
- [ ] (후순위) 클로저(캡처 있음)
- DoD
    - 콜백 함수 전달 예제 동작

### 0.5) 다중 리턴 (Multi-Return)

v3 테스트 24에서 실패. codegen 복잡도(rax/rdx 매핑, destructuring 등)로 인해 v4로 이동.

- [x] 함수 선언: `-> (T0, T1)` (파싱 완료)
- [x] return 문장: `return a, b;` (파싱 완료)
- [ ] destructuring: `var q, r = f();`, `q, r = f();`, `_` discard
- [ ] IR: `ret v0, v1` (ret value_list)
- [ ] ABI: `rax/rdx` 매핑
- DoD
    - 2리턴 함수 호출/바인딩이 end-to-end로 동작

### 0.6) 런타임 디버깅 인프라 (Location Info 고급)

v3에서는 컴파일 에러 위치만 지원. 런타임 위치 정보는 DWARF 등 복잡도로 인해 v4로 이동.

- [ ] IR → ASM 단계까지 파일/줄/컬럼 유지
- [ ] 런타임 패닉 시 스택 트레이스 출력
- [ ] `.loc` 지시어로 gdb 연동
- [ ] 스택 정리 정책 (panic 시 defer 실행 등)
- DoD
    - 패닉 메시지에 소스 위치 + 호출 스택 출력

---

## 1) 메타프로그래밍: `comptime`

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

#### 📊 v3 vs v4 비교 요약

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

### 🏁 결론

이 로드맵은 **컴파일러의 두뇌를 교체하는 대수술**이다.
v3에서 언어의 **"뼈대(Parser, CodeGen, Memory)"**를 완성하고,
v4에서 **"지능(Interpreter)"**을 심는다.

---

## 2) 테스트/검증 전략(v4)

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

## 3) GPU 병렬 컴퓨팅(Experimental): `gpu func` / `dispatch`

목표: GPU 가속을 라이브러리 호출(`opencl_run(...)`)로만 두지 않고,
언어 차원에서 “커널 정의 + 디스패치”를 문법으로 제공해 병렬 컴퓨팅을 1급 시민으로 취급한다.
그래픽 렌더링은 범위 밖이며, **Compute 전용**으로 시작한다.

### 3.1) 표면 문법(Syntax)

- [ ] 커널 정의: `gpu func`
	- [ ] 예(스케치): `gpu func vector_add(a: Vram[f32], b: Vram[f32], out: Vram[f32]) { ... }`
	- [ ] 제약(필수, 초기)
		- [ ] 커널 내부에서 I/O/시스템콜(`print`, 파일, 네트워크), FFI, `asm`, 힙 할당은 금지(컴파일 에러)
		- [ ] 포인터 기반 unsafe 연산은 금지(또는 매우 제한) — 커널은 “계산 중심”으로 고정
		- [ ] 결정성 우선: 시간/랜덤 등 비결정 요소 금지

- [ ] 내장 변수(필수)
	- [ ] `@global_id_x` (1D 기준) 제공
	- [ ] 확장(후순위): `@global_id_y/z`, 로컬/워그룹 ID, 워그룹 크기

- [ ] 실행(디스패치): `dispatch`
	- [ ] 문법(안): `dispatch(kernel, global_size[, local_size]) (args...)`
		- [ ] 1D부터 시작, 2D/3D는 후순위
	- [ ] 의미: 커널을 grid 형태로 실행하고, 기본적으로 완료까지 동기화(초기 단순화)
		- [ ] 확장(후순위): async dispatch + `wait`/fence

### 3.2) 메모리 모델(Host vs Device)

- [ ] 전용 버퍼 타입: `Vram[T]` (또는 `Buffer[T]`로 명명 — 택1)
	- [ ] 최소 API(표면/표준 라이브러리)
		- [ ] `Vram.from(host_slice)` : Host → Device 업로드
		- [ ] `Vram.alloc(n)` : Device 버퍼 할당
		- [ ] `to_host()` : Device → Host 다운로드(초기에는 동기)
	- [ ] `len` 노출(커널에서 bounds 체크에 사용)
	- [ ] 커널 인자 타입은 초기에는 `Vram[T]` 및 POD 스칼라만 허용(구조체/포인터는 후순위)

### 3.3) 컴파일러 구현 전략(3단계)

v4 컴파일러가 GPU 기계어를 직접 생성하는 방식은 범위 밖이다.
대신 “트랜스파일 + 런타임 런치”로 구현한다.

- [ ] 단계 1: 듀얼 컴파일(Split Compilation)
	- [ ] 프론트엔드에서 `gpu func`를 만나면 CPU 코드젠 경로가 아니라 “GPU 모듈”로 별도 수집
	- [ ] `dispatch`는 AST/IR에서 별도 노드로 유지(후에 런타임 호출로 lowering)

- [ ] 단계 2: SPIR-V Compute(또는 GLSL/HLSL)로 변환
	- [ ] 타깃 우선순위(권장): SPIR-V Compute (Vulkan/WebGPU 계열)
	- [ ] 내장 변수 매핑
		- [ ] `@global_id_x` → `gl_GlobalInvocationID.x`(GLSL) 또는 동등 SPIR-V builtin
	- [ ] 타입/연산 매핑은 “정수/부동/벡터 최소”부터 시작

- [ ] 단계 3: 런타임 임베딩(Runtime Embedding) + 런치로 lowering
	- [ ] 변환된 셰이더(텍스트 또는 바이너리)를 실행 파일 `.rodata`에 임베드
	- [ ] lowering:
		- [ ] Before: `dispatch(vector_add, 1024)(a, b, out)`
		- [ ] After: `std_gpu_launch_kernel(embedded_shader_id, 1024, a, b, out)`
	- [ ] 런타임 백엔드(택1): Vulkan 기반 또는 WebGPU(wgpu-native) 기반
		- [ ] 정책: CUDA 종속은 기본 비권장(후순위)
