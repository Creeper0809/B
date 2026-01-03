# v3 Roadmap (Draft)

이 문서는 v2 이후(v3)에서 보완/확장할 항목을 모아 둔 초안입니다.

원칙:
- v3는 v2의 MVP를 깨지지 않게 유지하면서, 표현력/타입/컨테이너 지원을 확장합니다.

---

## foreach 보완(typed/width-aware)

v2의 `foreach`는 구현 단순화를 위해 **`Slice*`의 byte 순회**만 지원합니다.
(v2에서 `Slice`는 메모리 상 `[ptr:u64][len:u64]` 레이아웃을 가정)

v3 목표:
- [ ] `foreach`가 요소 폭/타입을 알 수 있을 때(예: `u64` 배열/슬라이스) 요소 단위로 순회
- [ ] `foreach` 대상 확장: 로컬 배열 `var a[N]` / (향후) 타입드 컨테이너
- [ ] 루프 변수 선언 문법 옵션 검토: `foreach (var x in expr) { ... }`
