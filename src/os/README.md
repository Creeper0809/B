# OS 추상화 레이어

이 폴더는 운영체제별 차이를 추상화하는 모듈을 포함합니다.

## 파일 구조

```
src/os/
├── common.b      # 통합 크로스 플랫폼 API
├── linux.b       # Linux syscall 구현 (완료)
├── windows.b     # Windows API 구현 (스켈레톤)
├── path.b        # 경로 처리 유틸리티
└── README.md     # 이 파일
```

## path.b - 경로 처리

### 기능
- 경로 구분자 자동 감지 (Linux: `/`, Windows: `\`)
- 디렉토리/베이스명 추출
- 경로 결합
- 경로 정규화
- 절대 경로 판별

### 사용 예제

```b
import os.path;

func main() {
    // 초기화 (OS 감지)
    path_init();
    
    // 경로 분석
    var dir_len = path_dir_len("src/v3_hosted/main.b");
    // Linux: 16 ("src/v3_hosted/")
    // Windows: 16 ("src\v3_hosted\")
    
    // 베이스명 추출
    path_basename_no_ext("main.b");
    // rax = "main", rdx = 4
    
    // 경로 결합
    var full = path_join("src", 3, "main.b", 6);
    // Linux: "src/main.b"
    // Windows: "src\main.b"
}
```

### 마이그레이션 가이드

기존 코드:
```b
// driver.b
if (ptr8[path + i] == 47) { // '/' 하드코딩
    last_slash = i;
}
```

새 코드:
```b
import os.path;

// 초기화
path_init();

// 크로스 플랫폼 방식
var sep_pos = path_find_last_separator(path);
```

## common.b - 통합 API

### 기능
- 플랫폼 자동 감지 (`os_detect()`)
- 파일 I/O: `os_read`, `os_write`, `os_open`, `os_close`, `os_fstat`
- 메모리: `os_mem_alloc`, `os_mem_free`
- 프로세스: `os_exit`

### 사용 예제

```b
import os.common;

func main() {
    // OS 자동 감지
    var os_type = os_detect();  // OS_LINUX or OS_WINDOWS
    
    // 파일 열기 (크로스 플랫폼)
    var fd = os_open("test.txt", 0, 0);  // O_RDONLY
    if (fd < 0) {
        os_exit(1);
    }
    
    // 읽기
    var buf = os_mem_alloc(1024);
    var n = os_read(fd, buf, 1024);
    os_close(fd);
    os_mem_free(buf, 1024);
    
    return 0;
}
```

## linux.b - Linux 구현 (완료)

### 기능
- `linux_exit(code)` - syscall(60)
- `linux_read/write/open/close/fstat` - syscall(0/1/2/3/5)
- `linux_brk(addr)` - syscall(12)
- `linux_mem_alloc(size)` - brk 기반 할당자

### 상태
- ✅ 모든 필수 syscall 래퍼 구현
- ✅ 간단한 bump allocator (brk 기반)
- ✅ 기존 코드와 ABI 호환

## windows.b - Windows 구현 (스켈레톤)

### 기능 (Phase 0.3에서 구현 예정)
- `windows_exit(code)` - ExitProcess
- `windows_read/write` - ReadFile/WriteFile
- `windows_open` - CreateFileA
- `windows_close` - CloseHandle
- `windows_fstat` - GetFileSizeEx
- `windows_mem_alloc` - VirtualAlloc
- `windows_mem_free` - VirtualFree

### 상태
- ⏳ 스켈레톤 코드만 작성 (placeholder 함수)
- ⏳ PE32+ 코드 생성 필요 (Phase 0.3)
- ⏳ IAT (Import Address Table) 설정 필요

## Phase 0.2 완료 현황

- ✅ `common.b` - 통합 API 및 OS 감지
- ✅ `linux.b` - 완전한 Linux syscall 래퍼
- ✅ `windows.b` - Win32 API 스켈레톤
- ✅ `path.b` - 크로스 플랫폼 경로 처리
- ⏳ 통합 테스트 - Phase 0.3 이후
- ⏳ v3 컴파일러 마이그레이션 - Phase 0.4

## 참조
- [v4_roadmap.md Phase 0](/docs/v4_roadmap.md)
- [v4_todo.md Phase 0.2](/docs/v4_todo.md)

