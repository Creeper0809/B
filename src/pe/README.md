# PE (Portable Executable) Module

Windows PE32+ 실행 파일 생성 모듈.

## 파일 구조

```
src/pe/
├── format.b   - PE32+ 구조체 정의 및 상수
├── builder.b  - PE 파일 빌더
└── README.md  - 이 파일
```

## format.b - PE 포맷 정의

### 주요 구조체
- **DOS Header**: MZ 헤더 (호환성)
- **PE Signature**: "PE\0\0"
- **COFF Header**: 기계 타입, 섹션 수, 특성
- **Optional Header**: 엔트리 포인트, 이미지 베이스, 서브시스템
- **Section Headers**: .text, .data, .rdata, .idata

### 상수
- `IMAGE_BASE = 0x140000000` - 64비트 실행 파일 기본 주소
- `SECTION_ALIGNMENT = 4096` - 메모리 정렬 (4 KB)
- `FILE_ALIGNMENT = 512` - 파일 정렬 (512 B)
- `IMAGE_FILE_MACHINE_AMD64 = 0x8664` - x64 아키텍처

## builder.b - PE 빌더

### 함수

#### 헤더 생성
- `pe_write_dos_header(buf)` - DOS 헤더 + 스텁 작성
- `pe_write_headers(buf, offset, ...)` - PE/COFF/Optional 헤더 작성
- `pe_write_section_header(buf, offset, ...)` - 섹션 헤더 작성

#### 빌더
- `pe_build(text, text_len, data, data_len, entry)` - 완전한 PE 파일 생성 (Phase 0.3)

## PE32+ 파일 레이아웃

```
Offset  | Section              | Size
--------|----------------------|-------
0x0000  | DOS Header           | 64 bytes
0x0040  | DOS Stub             | 64 bytes
0x0080  | PE Signature         | 4 bytes
0x0084  | COFF Header          | 20 bytes
0x0098  | Optional Header      | 240 bytes
0x0178  | Section Headers      | 40 × N bytes
0x0200  | (File alignment)     |
--------|----------------------|-------
0x0200  | .text section        | code
0x????  | .data section        | initialized data
0x????  | .rdata section       | read-only data (strings)
0x????  | .idata section       | imports (IAT)
```

## 섹션 특성

### .text (코드)
- Characteristics: `CODE | EXECUTE | READ`
- RVA: 0x1000
- 용도: 실행 가능한 기계어 코드

### .data (데이터)
- Characteristics: `INITIALIZED_DATA | READ | WRITE`
- RVA: (after .text)
- 용도: 전역 변수, 초기화된 데이터

### .rdata (읽기 전용 데이터)
- Characteristics: `INITIALIZED_DATA | READ`
- RVA: (after .data)
- 용도: 문자열 리터럴, 상수

### .idata (임포트)
- Characteristics: `INITIALIZED_DATA | READ | WRITE`
- RVA: (after .rdata)
- 용도: Import Directory, IAT (Import Address Table)

## Import Address Table (IAT)

Windows API 함수 호출을 위한 테이블:

```
Import Directory:
  - OriginalFirstThunk (INT - Import Name Table)
  - TimeDateStamp
  - ForwarderChain
  - Name (DLL name RVA)
  - FirstThunk (IAT)

IAT Entry:
  - RVA to hint/name structure
  - Hint (ordinal)
  - Function name (null-terminated)
```

## 필수 임포트

### kernel32.dll
- `ExitProcess` - 프로세스 종료
- `WriteFile` - 파일/콘솔 쓰기
- `ReadFile` - 파일/콘솔 읽기
- `CreateFileA` - 파일 열기
- `CloseHandle` - 핸들 닫기
- `GetFileSizeEx` - 파일 크기 가져오기
- `VirtualAlloc` - 메모리 할당
- `VirtualFree` - 메모리 해제
- `GetStdHandle` - 표준 핸들 가져오기

## 사용 예제

```b
import pe.format;
import pe.builder;

func generate_windows_exe(code, code_len, data, data_len) {
    // Initialize PE builder
    pe_init();
    
    // Add imports
    pe_add_import("kernel32.dll", 12, "ExitProcess", 11);
    pe_add_import("kernel32.dll", 12, "WriteFile", 9);
    
    // Build PE file
    var pe_data = pe_build(code, code_len, data, data_len, 0);
    
    return pe_data;  // (ptr, len)
}
```

## Phase 0.3 구현 계획

### 완료
- ✅ PE 포맷 구조체 정의
- ✅ 헤더 생성 함수 (DOS, PE, COFF, Optional)
- ✅ 섹션 헤더 생성 함수

### 진행 중
- ⏳ IAT 생성 로직
- ⏳ Import Directory 구축
- ⏳ 전체 PE 파일 어셈블리

### 예정
- ⬜ v3_hosted/codegen.b 통합
- ⬜ --target=windows 플래그 처리
- ⬜ Windows 빌드 테스트

## 참조

- [Microsoft PE/COFF Specification](https://docs.microsoft.com/en-us/windows/win32/debug/pe-format)
- [PE Format - OSDev Wiki](https://wiki.osdev.org/PE)
- [v4_roadmap.md Phase 0](/docs/v4_roadmap.md)
- [v4_todo.md Phase 0.3](/docs/v4_todo.md)
