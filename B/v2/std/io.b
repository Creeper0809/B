// v2 library: minimal IO helpers (syscall-backed)
//
// Notes:
// - Only these syscall wrappers use `asm`.
// - These wrappers rely on the v2 codegen calling convention:
//   args in rdi/rsi/rdx/r10/r8/r9, return in rax.
// - We use `return;` (no expression) to forward the syscall's rax.
//
// Provided syscalls (Linux x86_64):
// - sys_exit(60), sys_read(0), sys_write(1), sys_open(2), sys_close(3), sys_fstat(5), sys_brk(12)

// Simple heap for v2 output binaries (brk-backed).
// Returns 0 on OOM.
var heap_inited;
var heap_brk;

func sys_exit(code) {
	asm {
		mov rax, 60
		syscall
	}
	// unreachable
	return 0;
}

func sys_read(fd, buf, len) {
	asm {
		mov rax, 0
		syscall
	}
	return;
}

// write(fd, buf, len)
func sys_write(fd, buf, len) {
	asm {
		mov rax, 1
		syscall
	}
	return;
}

// open(path, flags, mode)
func sys_open(path, flags, mode) {
	asm {
		mov rax, 2
		syscall
	}
	return;
}

func sys_close(fd) {
	asm {
		mov rax, 3
		syscall
	}
	return;
}

// fstat(fd, stbuf)
func sys_fstat(fd, stbuf) {
	asm {
		mov rax, 5
		syscall
	}
	return;
}

func sys_brk(addr) {
	asm {
		mov rax, 12
		syscall
	}
	return;
}

func heap_alloc(n) {
	if (n == 0) {
		return 0;
	}

	if (heap_inited == 0) {
		heap_brk = sys_brk(0);
		heap_inited = 1;
	}

	var p = heap_brk;
	var new_brk = p + n;
	new_brk = (new_brk + 15) & (~15);
	var res = sys_brk(new_brk);
	if (res < new_brk) {
		return 0;
	}
	heap_brk = new_brk;
	return p;
}

func read_stdin_cap(cap) {
	// Returns: rax=ptr, rdx=len
	// Reads from stdin (fd=0) up to cap bytes; NUL-terminates.
	// Exits on error/oom (consistent with other low-level helpers).

	var buf = heap_alloc(cap + 1);
	if (buf == 0) {
		sys_exit(3);
		return 0;
	}

	var pos = 0;
	while (pos < cap) {
		var want = cap - pos;
		var n = sys_read(0, buf + pos, want);
		if (n == 0) {
			break;
		}
		if (n < 0) {
			sys_exit(2);
			return 0;
		}
		pos = pos + n;
	}

	ptr8[buf + pos] = 0;
	alias rdx : len_reg;
	len_reg = pos;
	return buf;
}

func strlen(s) {
	var i = 0;
	while (ptr8[s + i] != 0) {
		i = i + 1;
	}
	return i;
}

func print_str_len(s, n) {
	sys_write(1, s, n);
	return 0;
}

func print_str(s) {
	var n = strlen(s);
	sys_write(1, s, n);
	return 0;
}

func emit(s, len) {
	sys_write(1, s, len);
	return 0;
}

func emit_stderr(s, len) {
	sys_write(2, s, len);
	return 0;
}

func print_char(ch) {
	var buf[2];
	var p = addr[buf];
	ptr8[p] = ch;
	ptr8[p + 1] = 0;
	sys_write(1, p, 1);
	return 0;
}

func print_u64(n) {
	if (n == 0) {
		print_char(48);
		return 0;
	}

	// Enough for max u64 (20 digits) + slack.
	var buf[32];
	var p = addr[buf];
	var end = 31;
	ptr8[p + end] = 0;

	var i = end;
	while (n > 0) {
		i = i - 1;
		var digit = n % 10;
		ptr8[p + i] = digit + 48;
		n = n / 10;
	}

	sys_write(1, p + i, end - i);
	return 0;
}
