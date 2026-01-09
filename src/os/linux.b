// os/linux.b - Linux syscall wrappers
//
// Provides thin wrappers around Linux x86_64 syscalls.
// ABI: System V AMD64 calling convention
// - Args: rdi, rsi, rdx, r10, r8, r9
// - Return: rax
// - Syscall clobbers: rcx, r11
//
// Syscall numbers (Linux x86_64):
// - exit:  60
// - read:  0
// - write: 1
// - open:  2
// - close: 3
// - fstat: 5
// - brk:   12

// ============================================================================
// Process control
// ============================================================================

func linux_exit(code) {
	// syscall(60, code)
	// Does not return
	asm {
		mov rax, 60
		syscall
	}
	return 0;  // unreachable
}

// ============================================================================
// File I/O
// ============================================================================

func linux_read(fd, buf, len) {
	// syscall(0, fd, buf, len)
	// Returns: bytes read (>=0) or -errno
	asm {
		mov rax, 0
		syscall
	}
	return;  // rax preserved
}

func linux_write(fd, buf, len) {
	// syscall(1, fd, buf, len)
	// Returns: bytes written (>=0) or -errno
	asm {
		mov rax, 1
		syscall
	}
	return;  // rax preserved
}

func linux_open(path, flags, mode) {
	// syscall(2, path, flags, mode)
	// Returns: fd (>=0) or -errno
	asm {
		mov rax, 2
		syscall
	}
	return;  // rax preserved
}

func linux_close(fd) {
	// syscall(3, fd)
	// Returns: 0 or -errno
	asm {
		mov rax, 3
		syscall
	}
	return;  // rax preserved
}

func linux_fstat(fd, statbuf) {
	// syscall(5, fd, statbuf)
	// Returns: 0 or -errno
	// statbuf: 144 bytes, file size at offset 48
	asm {
		mov rax, 5
		syscall
	}
	return;  // rax preserved
}

// ============================================================================
// Memory management
// ============================================================================

// Global heap state (brk-based allocator)
var linux_heap_inited;
var linux_heap_brk;

func linux_brk(addr) {
	// syscall(12, addr)
	// Returns: new program break address
	asm {
		mov rax, 12
		syscall
	}
	return;  // rax preserved
}

func linux_mem_alloc(size) {
	// Simple bump allocator using brk()
	// Returns: pointer or 0 on failure
	
	if (size == 0) {
		return 0;
	}
	
	// Initialize heap on first use
	if (linux_heap_inited == 0) {
		linux_heap_brk = linux_brk(0);
		linux_heap_inited = 1;
	}
	
	var p = linux_heap_brk;
	var new_brk = p + size;
	
	// Request new break
	var result = linux_brk(new_brk);
	
	// Check if allocation succeeded
	if (result < new_brk) {
		return 0;  // OOM
	}
	
	linux_heap_brk = new_brk;
	return p;
}

func linux_mem_free(ptr, size) {
	// brk-based allocator doesn't support free
	// (This is a limitation of the simple bump allocator)
	return 0;
}
