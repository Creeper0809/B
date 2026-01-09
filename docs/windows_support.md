# Windows Support

B 컴파일러의 Windows 10/11 지원 문서.

## 개요

Phase 0 (Windows Support) 완료 상태:
- ✅ **Phase 0.1**: CMake 빌드 시스템
- ✅ **Phase 0.2**: OS 추상화 레이어 (syscall + Win32 API)
- ✅ **Phase 0.3**: PE32+ 파일 포맷 설계
- ⏳ **Phase 0.4**: CI/CD 및 통합 테스트

## 빌드 방법

### Linux에서 빌드
```bash
# 의존성 설치
sudo apt-get install nasm cmake build-essential

# 빌드
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build

# 실행
./bin/v3c
```

### Windows에서 빌드
```powershell
# Chocolatey로 의존성 설치
choco install nasm mingw cmake -y

# 빌드
cmake -B build -G "MinGW Makefiles" -DCMAKE_BUILD_TYPE=Release
cmake --build build

# 실행
.\bin\v3c.exe
```

## 아키텍처

### OS 추상화 레이어
```
Application (driver.b, codegen.b)
    ↓
os/common.b (통합 API)
    ↓
    ├─ os/linux.b (syscall)
    └─ os/windows.b (Win32 API)
```

### 파일 포맷
- **Linux**: ELF 64-bit (현재 지원)
- **Windows**: PE32+ 64-bit (Phase 0.3 설계 완료, Phase 0.4 통합 예정)

## 주요 모듈

### src/os/common.b
크로스 플랫폼 통합 API:
- `os_exit(code)` - 프로세스 종료
- `os_read(fd, buf, len)` - 파일 읽기
- `os_write(fd, buf, len)` - 파일 쓰기
- `os_open(path, flags, mode)` - 파일 열기
- `os_close(fd)` - 파일 닫기
- `os_fstat(fd, statbuf)` - 파일 정보
- `os_mem_alloc(size)` - 메모리 할당
- `os_mem_free(ptr, size)` - 메모리 해제

### src/os/linux.b
Linux syscall 구현 (완료):
- syscall(60) - exit
- syscall(0) - read
- syscall(1) - write
- syscall(2) - open
- syscall(3) - close
- syscall(5) - fstat
- syscall(12) - brk (메모리 할당)

### src/os/windows.b
Win32 API 구현 (스켈레톤):
- ExitProcess - 프로세스 종료
- ReadFile/WriteFile - 파일 I/O
- CreateFileA - 파일 열기
- CloseHandle - 핸들 닫기
- GetFileSizeEx - 파일 크기
- VirtualAlloc/VirtualFree - 메모리 관리

**Note**: Windows API 실제 구현은 PE32+ 코드 생성 후 완성 예정.

### src/pe/
PE32+ 파일 포맷 모듈 (Phase 0.3 완료):
- `pe/format.b` - PE 구조체 및 상수
- `pe/builder.b` - PE 파일 빌더
- `pe/iat.b` - Import Address Table
- `pe/README.md` - PE 포맷 문서

## 크로스 컴파일

### Linux → Windows (향후)
```bash
# mingw-w64 설치
sudo apt-get install mingw-w64

# Windows 타겟 빌드
cmake -B build-win -DCMAKE_TOOLCHAIN_FILE=cmake/mingw-w64.cmake
cmake --build build-win

# 출력: bin/v3c.exe
```

### Windows → Linux (향후)
```powershell
# WSL 사용 권장
wsl bash -c "cmake -B build && cmake --build build"
```

## CI/CD

GitHub Actions 워크플로우 (`.github/workflows/ci.yml`):
- **Linux build**: Ubuntu 최신 버전
- **Windows build**: Windows Server 2022
- **테스트**: Lexer, Codegen golden tests

## 현재 제한 사항

1. **Windows 실행 파일 생성**: 아직 PE32+ 생성 미구현
   - 현재: Linux ELF만 생성
   - 향후: `--target=windows` 플래그로 PE 생성

2. **Windows API 호출**: 스켈레톤만 존재
   - 실제 구현은 PE Import Table 완성 후

3. **크로스 컴파일**: 미지원
   - 향후: CMake 툴체인 파일로 지원

## 테스트

### Linux
```bash
# Lexer 테스트
bash test/v3_hosted/run_lexer_golden.sh

# Codegen 테스트
bash test/v3_hosted/run_codegen_golden.sh
```

### Windows
```powershell
# 향후 구현 예정
.\test\v3_hosted\run_lexer_golden.ps1
.\test\v3_hosted\run_codegen_golden.ps1
```

## 향후 계획

### Phase 0.4 (진행 중)
- [ ] PE 빌더와 codegen 통합
- [x] GitHub Actions CI/CD
- [ ] Windows 실제 테스트
- [ ] 문서 완성

### v3.5
- [ ] Windows API 실제 구현
- [ ] PE 파일 생성 완료
- [ ] 크로스 컴파일 지원
- [ ] Windows 네이티브 개발 환경

## 문제 해결

### NASM not found
```bash
# Linux
sudo apt-get install nasm

# Windows
choco install nasm
```

### MinGW not found
```powershell
# Windows
choco install mingw
# PATH에 추가: C:\ProgramData\chocolatey\lib\mingw\tools\install\mingw64\bin
```

### CMake 버전 에러
```bash
# 최소 버전: 3.16
cmake --version

# 업그레이드
# Ubuntu: sudo apt-get install cmake
# Windows: choco upgrade cmake
```

## 참조

- [v4_roadmap.md Phase 0](/docs/v4_roadmap.md)
- [v4_todo.md](/docs/v4_todo.md)
- [devlog-2026-01-09.md](/pages/devlog-2026-01-09.md)
- [PE Format Spec](https://docs.microsoft.com/en-us/windows/win32/debug/pe-format)
