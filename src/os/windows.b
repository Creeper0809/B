// os/windows.b - Windows API wrappers
//
// Provides wrappers around Win32 API for basic I/O and memory management.
// 
// NOTE: This is a skeleton implementation for Phase 0.2.
// Actual Windows support requires:
// - PE32+ executable generation (Phase 0.3)
// - Import Address Table (IAT) setup
// - Proper linkage to kernel32.dll
//
// Win32 API functions needed:
// - ExitProcess (kernel32.dll)
// - ReadFile, WriteFile (kernel32.dll)
// - CreateFileA, CloseHandle (kernel32.dll)
// - GetFileSizeEx (kernel32.dll)
// - VirtualAlloc, VirtualFree (kernel32.dll)
//
// Calling convention: Microsoft x64 (different from System V!)
// - Args: rcx, rdx, r8, r9, [stack]
// - Return: rax
// - Caller must reserve 32 bytes shadow space on stack

// ============================================================================
// Constants
// ============================================================================

// File access modes (Windows)
const GENERIC_READ = 2147483648;   // 0x80000000
const GENERIC_WRITE = 1073741824;  // 0x40000000

// File creation disposition
const CREATE_NEW = 1;
const CREATE_ALWAYS = 2;
const OPEN_EXISTING = 3;
const OPEN_ALWAYS = 4;

// File attributes
const FILE_ATTRIBUTE_NORMAL = 128;  // 0x80

// Standard handles
const STD_INPUT_HANDLE = -10;
const STD_OUTPUT_HANDLE = -11;
const STD_ERROR_HANDLE = -12;

// Invalid handle value
const INVALID_HANDLE_VALUE = -1;

// Memory allocation flags
const MEM_COMMIT = 4096;    // 0x1000
const MEM_RESERVE = 8192;   // 0x2000
const MEM_RELEASE = 32768;  // 0x8000

// Memory protection flags
const PAGE_READWRITE = 4;   // 0x04

// ============================================================================
// Process control
// ============================================================================

func windows_exit(code) {
	// ExitProcess(uExitCode)
	// Does not return
	//
	// TODO: This requires IAT setup (Phase 0.3)
	// For now, this is a placeholder
	asm {
		// Call ExitProcess from IAT
		// mov rcx, [rbp-8]  // code
		// call [ExitProcess_IAT]
		
		// Temporary: infinite loop (until PE generation works)
		.hang:
		jmp .hang
	}
	return 0;  // unreachable
}

// ============================================================================
// File I/O
// ============================================================================

func windows_read(fd, buf, len) {
	// ReadFile(hFile, lpBuffer, nNumberOfBytesToRead, lpNumberOfBytesRead, lpOverlapped)
	// Returns: bytes read via stack-allocated DWORD
	//
	// TODO: Implement with proper Win32 call (Phase 0.3)
	return -1;  // Not yet implemented
}

func windows_write(fd, buf, len) {
	// WriteFile(hFile, lpBuffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten, lpOverlapped)
	// Returns: bytes written via stack-allocated DWORD
	//
	// TODO: Implement with proper Win32 call (Phase 0.3)
	return -1;  // Not yet implemented
}

func windows_open(path, flags, mode) {
	// CreateFileA(lpFileName, dwDesiredAccess, dwShareMode, lpSecurityAttributes,
	//             dwCreationDisposition, dwFlagsAndAttributes, hTemplateFile)
	// Returns: HANDLE or INVALID_HANDLE_VALUE
	//
	// Map Unix flags to Windows parameters:
	// - O_RDONLY (0) -> GENERIC_READ
	// - O_WRONLY (1) -> GENERIC_WRITE
	// - O_RDWR (2) -> GENERIC_READ | GENERIC_WRITE
	// - O_CREAT (64) -> CREATE_ALWAYS
	// - O_TRUNC (512) -> CREATE_ALWAYS
	//
	// TODO: Implement with proper Win32 call (Phase 0.3)
	return INVALID_HANDLE_VALUE;  // Not yet implemented
}

func windows_close(fd) {
	// CloseHandle(hObject)
	// Returns: nonzero on success, 0 on failure
	//
	// TODO: Implement with proper Win32 call (Phase 0.3)
	return -1;  // Not yet implemented
}

func windows_fstat(fd, statbuf) {
	// GetFileSizeEx(hFile, lpFileSize)
	// Returns: file size in LARGE_INTEGER (64-bit)
	//
	// Note: Windows doesn't have fstat, need to emulate
	// - Get file size with GetFileSizeEx
	// - Fill statbuf at offset 48 (Unix stat.st_size location)
	//
	// TODO: Implement with proper Win32 call (Phase 0.3)
	return -1;  // Not yet implemented
}

// ============================================================================
// Memory management
// ============================================================================

func windows_mem_alloc(size) {
	// VirtualAlloc(lpAddress, dwSize, flAllocationType, flProtect)
	// Returns: pointer or NULL on failure
	//
	// Call: VirtualAlloc(NULL, size, MEM_COMMIT | MEM_RESERVE, PAGE_READWRITE)
	//
	// TODO: Implement with proper Win32 call (Phase 0.3)
	return 0;  // Not yet implemented
}

func windows_mem_free(ptr, size) {
	// VirtualFree(lpAddress, dwSize, dwFreeType)
	// Returns: nonzero on success, 0 on failure
	//
	// Call: VirtualFree(ptr, 0, MEM_RELEASE)
	// Note: When using MEM_RELEASE, dwSize must be 0
	//
	// TODO: Implement with proper Win32 call (Phase 0.3)
	return -1;  // Not yet implemented
}

// ============================================================================
// Helper: Get standard handles
// ============================================================================

func windows_get_std_handle(nStdHandle) {
	// GetStdHandle(nStdHandle)
	// Returns: HANDLE or INVALID_HANDLE_VALUE
	//
	// Used to get stdin/stdout/stderr handles:
	// - STD_INPUT_HANDLE (-10)
	// - STD_OUTPUT_HANDLE (-11)
	// - STD_ERROR_HANDLE (-12)
	//
	// TODO: Implement with proper Win32 call (Phase 0.3)
	return INVALID_HANDLE_VALUE;  // Not yet implemented
}
