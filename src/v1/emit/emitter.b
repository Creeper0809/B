// v1 emitter
// Roadmap: docs/roadmap.md (stage 4: emitter)
// Depends on: std (sys_write/sys_open etc), Slice
// Planned:
// - emit_init()
// - emit_str(ptr, len)
// - emit_u64(x)
// - emit_flush(fd)
// - emit_to_file(path)

func emit_init() {
	// Initialize a global output buffer.
	// Returns: rax = buf ptr

	// Default buffer size: 64 KiB.
	// Note: the current Stage1 runtime heap is 1 MiB total; allocating 1 MiB here
	// would frequently fail after read_file() allocations.
	asm {
		"mov rdi, 65536\n"
		"call heap_alloc\n"
		"test rax, rax\n"
		"jnz .ok\n"
		"call die_emit_init_oom\n"
		".ok:\n"
		"mov [rel emit_buf], rax\n"
		"mov qword [rel emit_len], 0\n"
		"mov qword [rel emit_cap], 65536\n"
	};
}

func emit_str(ptr, len) {
	// Append bytes to the global buffer.
	// Convention: rdi=ptr, rsi=len
	// Returns: rax = new length
	// NOTE: uses asm-local labels to avoid Stage1 high-level if label collisions.

	asm {
		"push rdi\n"
		"push rsi\n"
		// keep stack aligned for calls and reserve a spill slot
		"sub rsp, 16\n"

		// len0 = [emit_len], cap0 = [emit_cap]
		"mov r8,  [rel emit_len]\n"
		"mov r9,  [rel emit_cap]\n"
		// need = len0 + len
		"mov r10, r8\n"
		"add r10, [rsp+16]\n"
		"cmp r10, r9\n"
		"jbe .ok\n"
		"call die_emit_overflow\n"
		".ok:\n"
		// spill need across memcpy (caller-saved regs may be clobbered)
		"mov [rsp+8], r10\n"

		// dst = emit_buf + len0
		"mov r11, [rel emit_buf]\n"
		"lea rdi, [r11+r8]\n"   // dst
		"mov rsi, [rsp+24]\n"   // src (saved ptr)
		"mov rdx, [rsp+16]\n"   // n   (saved len)
		"call memcpy\n"

		// emit_len = need
		"mov r10, [rsp+8]\n"
		"mov [rel emit_len], r10\n"
		"mov rax, r10\n"

		"add rsp, 16\n"
		"pop rsi\n"
		"pop rdi\n"
	};
}

func emit_u64(x) {
	// Append decimal form of x.
	// Convention: rdi=x

	var x0;
	var p0;
	var n0;

	ptr64[x0] = rdi;
	rdi = ptr64[x0];
	itoa_u64_dec(rdi);
	ptr64[p0] = rax;
	ptr64[n0] = rdx;

	rdi = ptr64[p0];
	rsi = ptr64[n0];
	emit_str(rdi, rsi);
}

func emit_cstr(s) {
	// Append a NUL-terminated string.
	// Convention: rdi = cstr
	// Returns: rax = new length
	var s0;
	var n0;
	ptr64[s0] = rdi;

	rdi = ptr64[s0];
	strlen(rdi);
	ptr64[n0] = rax;

	rdi = ptr64[s0];
	rsi = ptr64[n0];
	emit_str(rdi, rsi);
}

func emit_flush(fd) {
	// Write current buffer contents to fd, then reset length to 0.
	// Convention: rdi=fd
	// Returns: rax = bytes written (best effort)

	asm {
		"push rdi\n"
		"push rax\n" // align
		"mov r8,  [rel emit_len]\n"
		"test r8, r8\n"
		"jnz .do\n"
		"xor rax, rax\n"
		"pop rax\n"
		"pop rdi\n"
		"jmp .ret\n"

		".do:\n"
		"mov rsi, [rel emit_buf]\n"
		"mov rdx, r8\n"
		"mov rdi, [rsp+8]\n" // fd
		"call sys_write\n"
		"mov qword [rel emit_len], 0\n"
		"pop rax\n"
		"pop rdi\n"
		".ret:\n"
	};
}

func emit_to_file(path) {
	// Open path for writing, flush buffer to it, close.
	// Convention: rdi=path (NUL-terminated)

	asm {
		"push rdi\n"
		"push rax\n" // align
		"sub rsp, 16\n" // spills: [rsp+0]=fd, [rsp+8]=bytes
		// fd = sys_open(path, O_CREAT|O_TRUNC|O_WRONLY, 0644)
		"mov rdi, [rsp+24]\n"
		"mov rsi, 577\n"
		"mov rdx, 420\n"
		"call sys_open\n"
		"test rax, rax\n"
		"jns .open_ok\n"
		"call die_emit_open_fail\n"
		".open_ok:\n"
		"mov [rsp+0], rax\n"  // save fd

		// emit_flush(fd)
		"mov rdi, [rsp+0]\n"
		"call emit_flush\n"
		"mov [rsp+8], rax\n"  // bytes written

		// close(fd)
		"mov rdi, [rsp+0]\n"
		"call sys_close\n"

		// return bytes written
		"mov rax, [rsp+8]\n"
		"add rsp, 16\n"
		"pop rax\n"
		"pop rdi\n"
	};
}
