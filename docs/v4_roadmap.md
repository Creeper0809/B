# v4 Roadmap (Draft)

v4는 v3(MVP)에서 의도적으로 뒤로 미룬 “블랙홀 위험 기능”을 다룹니다.
목표는 기능을 더 넣는 것보다, **컴파일러/IR/표준 라이브러리 기반이 충분히 단단해진 뒤**
고급 기능을 안전하게 확장하는 것입니다.

원칙:
- v3에서 미룬 기능은 “그냥 나중에”가 아니라, v4에서 **명시적 범위/제약/실패 모드**를 먼저 고정한다.
- 컴파일러 내부 실행기/검증/퍼징은 쉽게 규모가 커지므로, 결정성/샌드박스/리소스 제한을 최우선으로 둔다.

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
