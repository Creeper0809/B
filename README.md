## B (The Second Step of Bpp)

"HTML을 프로그래밍 언어라고 인정할 수 없다."

B 언어는 Bpp를 만들기 위한 두 번째 단계입니다.

B로 작성되었으며 부트스트래핑하여 메이저 B를 제작합니다.

## Why?

이 세상에는 없어져야 더 행복해질 수 있는 것들이 잔뜩있습니다.

- C언어의 레지스터 숨김

- 클로버 리스트

- 그리고... 시험 문제에 bpp 대신 html을 언어라고 적어야하는 상황

그것들을 bpp의 힘으로 모두 없앨겁니다.

## Core Philosophy: High-Level Assembly

Basm의 철학은 단순합니다.

- High-Level Assembly: 어셈블리어의 제어권 + C언어의 가독성.

- Explicit Registers: rax, r8 등을 직접 제어한다.

## Syntax Preview

Traditional C + Inline Assembly (Painful):
```C

// GCC Style....
int val = 10;
__asm__ volatile (
    "movl %1, %%eax \n\t"
    "addl $1, %%eax \n\t"
    : "=a"(val) : "r"(val)
);
```

Basm (EZ & Clean):
```C

// Just do it. (Stage1 현재 구현 기준)
// - 레지스터는 64-bit 이름(rax..r15)만 레지스터로 인식합니다.
// - 비교 연산자는 if 조건에서만 허용됩니다.

rax = 10;
rax += 1;

// 메모리 접근은 ptr8/ptr64를 통해서만 합니다.
// (예: ptr64[var] = rax;  rdi = ptr64[var];)

if (rax > 5) {
        // 함수 호출은 ident(args...);
        // (내장 런타임 예: print_str, print_dec)
        print_str("ok\n");
}
```

## 문법 문서

현재 Stage1에서 실제로 지원되는 문법/제약은 아래 문서에 정리되어 있습니다.

- [docs/syntax.md](docs/syntax.md)

## Roadmap


## File Structure



## Build & Run

