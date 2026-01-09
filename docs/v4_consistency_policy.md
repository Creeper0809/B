# v4 문법 일관성 정책 (Consistency Policy)

v4 개발 전 반드시 확정된 문법 규칙입니다. 이 문서는 roadmap의 논리적 모순을 해결한 최종 결정사항입니다.

## 1. 메모리 할당 (`new`)

**문제**: 섹션 0.0에서 "생성자 없음"이라고 했는데, 섹션 0.20에서 `new Socket(8080)` 예제가 등장

**해결**:
- **`new T`**: 단순 할당 + 0 초기화 (생성자 호출 안 함)
- **`new T(...)`**: 할당 + 생성자 호출 (Syntactic Sugar, `malloc + T.constructor(...)`)
- 명확한 역할 분담으로 혼란 방지

**예제**:
```b
// 할당만
var p1 = new Circle;  // malloc + memset(0)

// 할당 + 초기화
var p2 = new Circle { radius: 10.0 };  // 리터럴

// 할당 + 생성자
var p3 = new Socket(8080);  // malloc + Socket.constructor(8080)
```

---

## 2. 에러 처리

**문제**: `try` 전위 연산자와 `?` 접미사가 혼용됨

**해결**:
- **`?` 접미사**만 사용 (Rust-style)
- `try` 키워드는 도입하지 않음 (try-catch 블록과 혼동 방지)

**이유**:
- 체이닝 편의성: `obj.func()?.next()?.final()?`
- 제어 흐름 명시성: `?`가 어디서 early return하는지 코드에 명확히 보임

**예제**:
```b
func read_config() -> Result<Config, str> {
    var file = open_file("config.txt")?;  // Err 시 즉시 리턴
    var data = file.read()?;
    return parse_config(data)?;
}
```

---

## 3. 제네릭 문법 위계

**문제**: `[]`, `<>`, `()` 세 가지 제네릭 문법이 혼재

**해결**:
- **진실(Truth)**: `func f(comptime T: type)` - 타입도 값이다 (Zig-style, Phase 4)
- **설탕(Sugar)**: `func f<T>()` - 가독성을 위한 편의 문법 (C++-style, Phase 0~3)
- 내부적으로 `<T>`는 `(comptime T)`로 변환됨
- 장기적으로 `Vec(u64)` 스타일로 통합 예정

**예제**:
```b
// Phase 0~3 (Sugar)
func max<T>(a: T, b: T) -> T { ... }
var m = max<i32>(10, 20);

// Phase 4 (Truth)
func max(comptime T: type, a: T, b: T) -> T { ... }
var m = max(i32, 10, 20);

// 둘 다 동일한 IR로 변환됨
```

---

## 4. 패턴 매칭 역할 분담 (`match` vs `switch`)

**문제**: `match`와 `switch`의 역할이 겹침

**해결**:
- **`match`**: enum/union variant 분기 + 디스트럭처링 전용 (패턴 매칭)
- **`switch`**: 정수/문자열 등 원시 타입 분기 (점프 테이블 최적화)
- 원시 타입에 `match` 사용 가능하지만, 성능상 `switch` 권장

**예제**:
```b
// match: enum 전용
match result {
    Result.Ok(val) => process(val),
    Result.Err(e) => handle(e),
}

// switch: 정수 전용 (점프 테이블)
switch (code) {
    1 | 2 | 3 => println("small");
    default => println("large");
}
```

---

## 5. 상속 문법 (`struct : Parent, Trait`)

**문제**: 데이터 상속과 trait 구현이 같은 `:` 문법을 쓰면 숨겨진 VPtr 존재 여부를 알 수 없음

**해결** (현행 유지):
- `struct Child : Parent, Trait` - 동일 문법 사용
- **규칙**: Trait 하나라도 있으면 숨겨진 `$vptr_TraitName` 필드 생성
- 문서화 강조: "Trait 상속 시 메모리 레이아웃 변경" 경고
- 해커는 `sizeof(Child)`로 레이아웃 검증 가능

**예제**:
```b
struct Animal { hp: u64; }
trait Drawable { func draw(self: *Self); }

struct Lion : Animal, Drawable {
    mane: u64;
}

// 메모리 레이아웃:
// [0..7]    hp (Animal)
// [8..15]   $vptr_Drawable  ← 숨겨진 필드!
// [16..23]  mane (Lion)

println(sizeof(Lion));  // 24 (해커는 이걸로 검증)
```

---

## 요약

| 항목 | 결정 | 이유 |
|------|------|------|
| **new** | `new T` (할당), `new T(...)` (할당+생성자) | 역할 명확화 |
| **에러 처리** | `?` 접미사만 | 체이닝 편의성 |
| **제네릭** | `<T>` 설탕, `(comptime T)` 진실 | Phase별 진화 |
| **패턴 매칭** | `match` (enum), `switch` (정수) | 최적화 힌트 |
| **상속** | `:` 동일 문법, Trait 시 VPtr 생성 | C++ 스타일, sizeof로 검증 |

이 정책은 v4 roadmap 전체에 적용됩니다.
