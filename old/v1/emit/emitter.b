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

	// Default buffer size: 128 KiB.
	// Note: the current Stage1 runtime heap is small; large buffers reduce
	// headroom for read_file() and parsing when compiling big programs.
	asm {
		"mov rdi, 131072\n"
		"call heap_alloc\n"
		"test rax, rax\n"
		"jnz .ok\n"
		"call die_emit_init_oom\n"
		".ok:\n"
		"mov [rel emit_buf], rax\n"
		"mov qword [rel emit_len], 0\n"
		"mov qword [rel emit_cap], 131072\n"
		"mov qword [rel emit_fd], 0\n"
	};
}

func emit_str(ptr, len) {
	// Append bytes to the global buffer.
	// Convention: rdi=ptr, rsi=len
	// Returns: rax = new length
	// NOTE: uses asm-local labels to avoid Stage1 high-level if label collisions.

	// NOTE(Stage1): some helpers do not reliably preserve callee-saved regs.
	// The compiler keeps long-lived state in rbx/r12-r15, so we must preserve
	// them across calls to emit_flush/memcpy.
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 32\n" // [0]=src [8]=len [16]=need
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		// len0 = [emit_len], cap0 = [emit_cap]
		"mov r8,  [rel emit_len]\n"
		"mov r9,  [rel emit_cap]\n"
		// need = len0 + len
		"mov r10, r8\n"
		"add r10, [rsp+8]\n"
		"cmp r10, r9\n"
		"jbe .ok\n"
		// If we have an output fd, flush and retry.
		"mov rdi, [rel emit_fd]\n"
		"test rdi, rdi\n"
		"jz .overflow_die\n"
		"call emit_flush\n"
		// Defensive: ensure emit_len is cleared after a flush so we don't
		// accidentally flush the same buffer contents twice.
		"mov qword [rel emit_len], 0\n"
		"mov r8,  [rel emit_len]\n" // should be 0
		"mov r9,  [rel emit_cap]\n"
		"mov r10, r8\n"
		"add r10, [rsp+8]\n"      // need = len
		"cmp r10, r9\n"
		"jbe .ok\n"
		".overflow_die:\n"
		"call die_emit_overflow\n"
		".ok:\n"
		"mov [rsp+16], r10\n" // spill need across memcpy

		// dst = emit_buf + len0
		"mov r11, [rel emit_buf]\n"
		"lea rdi, [r11+r8]\n"   // dst
		"mov rsi, [rsp+0]\n"    // src
		"mov rdx, [rsp+8]\n"    // n
		"call memcpy\n"

		// emit_len = need
		"mov r10, [rsp+16]\n"
		"mov [rel emit_len], r10\n"
		"mov rax, r10\n"

		"add rsp, 32\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func emit_u64(x) {
	// Append decimal form of x.
	// Convention: rdi=x

	// NOTE: The Stage1 runtime heap is small (currently 1 MiB). Converting numbers
	// via itoa_u64_dec() allocates on the heap, which can cause the compiler
	// itself to hit OOM and crash while emitting large outputs.
	//
	// To keep compilation stable, format into a stack scratch buffer and emit
	// directly from there (no heap allocation).
	asm {
		"push rdi\n"  // save x
		"push rax\n"  // align
		"sub rsp, 48\n" // scratch buffer (48 bytes)

		// r8 = x
		"mov r8, [rsp+56]\n"
		// r9 = cur (end), keep NUL at end
		"lea r9, [rsp+47]\n"
		"mov byte [r9], 0\n"
		// r10 = len
		"xor r10, r10\n"
		"cmp r8, 0\n"
		"jne .eu64_loop\n"
		"dec r9\n"
		"mov byte [r9], '0'\n"
		"mov r10, 1\n"
		"jmp .eu64_done\n"

		".eu64_loop:\n"
		"xor rdx, rdx\n"
		"mov rax, r8\n"
		"mov rcx, 10\n"
		"div rcx\n"
		"mov r8, rax\n"
		"add dl, '0'\n"
		"dec r9\n"
		"mov [r9], dl\n"
		"inc r10\n"
		"test r8, r8\n"
		"jnz .eu64_loop\n"

		".eu64_done:\n"
		"mov rdi, r9\n"
		"mov rsi, r10\n"
		"call emit_str\n"

		"add rsp, 48\n"
		"pop rax\n"
		"pop rdi\n"
	};
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

	// NOTE(Stage1): some helpers do not reliably preserve callee-saved regs.
	// Since the compiler keeps long-lived state in rbx/r12-r15, clobbering
	// them during an internal flush can cause duplicated output.
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"sub rsp, 16\n" // [0]=fd
		"mov [rsp+0], rdi\n"

		"mov r8,  [rel emit_len]\n"
		"test r8, r8\n"
		"jnz .do\n"
		"xor rax, rax\n"
		"jmp .done\n"

		".do:\n"
		// Clear length *before* writing to avoid any chance of re-flushing the
		// same buffer contents twice if a later store is missed/clobbered.
		"mov qword [rel emit_len], 0\n"
		"mov rsi, [rel emit_buf]\n"
		"mov rdx, r8\n"
		"mov rdi, [rsp+0]\n" // fd
		"call sys_write\n"

		".done:\n"
		"add rsp, 16\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func emit_open(path) {
	// Open path for writing and store fd into global emit_fd.
	// Convention: rdi=path (NUL-terminated)
	asm {
		"push rdi\n"
		"push rax\n" // align
		// fd = sys_open(path, O_CREAT|O_TRUNC|O_WRONLY, 0644)
		"mov rdi, [rsp+8]\n"
		"mov rsi, 577\n"
		"mov rdx, 420\n"
		"call sys_open\n"
		"test rax, rax\n"
		"jns .open_ok\n"
		"call die_emit_open_fail\n"
		".open_ok:\n"
		"mov [rel emit_fd], rax\n"
		"pop rax\n"
		"pop rdi\n"
	};
}

func emit_close() {
	// Flush+close global emit_fd if set.
	asm {
		"push rax\n" // align
		"mov rdi, [rel emit_fd]\n"
		"test rdi, rdi\n"
		"jz .done\n"
		"call emit_flush\n"
		"mov rdi, [rel emit_fd]\n"
		"call sys_close\n"
		"mov qword [rel emit_fd], 0\n"
		".done:\n"
		"pop rax\n"
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
