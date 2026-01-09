// os/common.b - Cross-platform OS abstraction layer
// 
// Provides unified interface for:
// - File I/O (open, read, write, close)
// - Memory management (alloc, free)
// - Process control (exit)
//
// Platform detection at runtime via os_detect()

// OS types
const OS_UNKNOWN = 0;
const OS_LINUX = 1;
const OS_WINDOWS = 2;

// File access modes (unified)
const O_RDONLY = 0;
const O_WRONLY = 1;
const O_RDWR = 2;
const O_CREAT = 64;
const O_TRUNC = 512;

// File permissions (Unix-style, ignored on Windows)
const MODE_0644 = 420;  // rw-r--r--

// Error codes (unified)
const ERR_SUCCESS = 0;
const ERR_NOENT = -2;     // File not found
const ERR_PERM = -13;     // Permission denied
const ERR_NOMEM = -12;    // Out of memory

// Global: detected OS type
var g_os_type;
var g_os_detected;

// OS detection (called once at startup)
func os_detect() {
	// Strategy: Check for Windows-specific behavior
	// - On Windows: certain syscalls will fail/behave differently
	// - On Linux: standard syscall numbers work
	//
	// For v3 hosted compiler (running on build machine):
	// We can use compile-time detection based on where v2c runs
	
	if (g_os_detected != 0) {
		return g_os_type;
	}
	
	// TODO: Add runtime detection logic
	// For now, assume Linux (since v2c runs on Linux)
	g_os_type = OS_LINUX;
	g_os_detected = 1;
	
	return g_os_type;
}

// ============================================================================
// Cross-platform API (delegates to platform-specific implementations)
// ============================================================================

// Exit process with code
func os_exit(code) {
	var os = os_detect();
	if (os == OS_LINUX) {
		return linux_exit(code);
	}
	if (os == OS_WINDOWS) {
		return windows_exit(code);
	}
	// Fallback: raw syscall
	asm {
		mov rax, 60
		syscall
	}
	return 0;
}

// Read from file descriptor
// Returns: number of bytes read, or negative error code
func os_read(fd, buf, len) {
	var os = os_detect();
	if (os == OS_LINUX) {
		return linux_read(fd, buf, len);
	}
	if (os == OS_WINDOWS) {
		return windows_read(fd, buf, len);
	}
	return ERR_NOENT;
}

// Write to file descriptor
// Returns: number of bytes written, or negative error code
func os_write(fd, buf, len) {
	var os = os_detect();
	if (os == OS_LINUX) {
		return linux_write(fd, buf, len);
	}
	if (os == OS_WINDOWS) {
		return windows_write(fd, buf, len);
	}
	return ERR_NOENT;
}

// Open file
// Returns: file descriptor (>=0), or negative error code
func os_open(path, flags, mode) {
	var os = os_detect();
	if (os == OS_LINUX) {
		return linux_open(path, flags, mode);
	}
	if (os == OS_WINDOWS) {
		return windows_open(path, flags, mode);
	}
	return ERR_NOENT;
}

// Close file descriptor
// Returns: 0 on success, negative error code on failure
func os_close(fd) {
	var os = os_detect();
	if (os == OS_LINUX) {
		return linux_close(fd);
	}
	if (os == OS_WINDOWS) {
		return windows_close(fd);
	}
	return ERR_NOENT;
}

// Get file statistics
// Returns: 0 on success, negative error code on failure
func os_fstat(fd, statbuf) {
	var os = os_detect();
	if (os == OS_LINUX) {
		return linux_fstat(fd, statbuf);
	}
	if (os == OS_WINDOWS) {
		return windows_fstat(fd, statbuf);
	}
	return ERR_NOENT;
}

// Allocate memory
// Returns: pointer to allocated memory, or 0 on failure
func os_mem_alloc(size) {
	var os = os_detect();
	if (os == OS_LINUX) {
		return linux_mem_alloc(size);
	}
	if (os == OS_WINDOWS) {
		return windows_mem_alloc(size);
	}
	return 0;
}

// Free memory
// Returns: 0 on success, negative error code on failure
func os_mem_free(ptr, size) {
	var os = os_detect();
	if (os == OS_LINUX) {
		return linux_mem_free(ptr, size);
	}
	if (os == OS_WINDOWS) {
		return windows_mem_free(ptr, size);
	}
	return ERR_NOENT;
}
