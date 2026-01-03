// library/v1 core: StringBuilder (byte buffer)
// Roadmap: docs/v2_roadmap.md (P0.5)
// Depends on:
// - heap_alloc (Stage1 builtin)
// - memcpy/strlen/itoa_u64_dec (std1_memstrnum.b)
// layout declarations live in src/library/v1/prelude.b.
//
// API:
// - sb_new(cap) -> sb*
// - sb_clear(sb)
// - sb_len(sb) -> rax
// - sb_ptr(sb) -> rax (NUL-terminated)
// - sb_append_bytes(sb, p, n)
// - sb_append_cstr(sb, cstr)
// - sb_append_u64_dec(sb, x)

func sb_new(cap) {
	// Args: rdi=cap (bytes, excluding trailing NUL)
	// Returns: rax=StringBuilder*
	var cap0;
	var sb0;
	var buf0;

	// cap = max(cap, 8)
	asm {
		"cmp rdi, 8\n"
		"jae .cap_ok\n"
		"mov rdi, 8\n"
		".cap_ok:\n"
	};
	ptr64[cap0] = rdi;

	// sb = heap_alloc(24)
	heap_alloc(24);
	ptr64[sb0] = rax;

	// buf = heap_alloc(cap + 1)
	rdi = ptr64[cap0];
	rdi += 1;
	heap_alloc(rdi);
	ptr64[buf0] = rax;

	// sb->ptr = buf
	alias r8 : sb;
	alias r9 : tmp;
	sb = ptr64[sb0];
	tmp = ptr64[buf0];
	ptr64[sb] = tmp;

	// sb->len = 0
	sb += 8;
	ptr64[sb] = 0;

	// sb->cap = cap
	sb += 8;
	tmp = ptr64[cap0];
	ptr64[sb] = tmp;

	// buf[0] = 0
	alias r10 : addr;
	addr = ptr64[buf0];
	ptr8[addr] = 0;

	rax = ptr64[sb0];
}

func sb_clear(sb) {
	// Args: rdi=sb*
	// Sets len=0 and maintains NUL terminator.
	asm {
		"mov r8,  [rdi+0]\n"   // ptr
		"mov qword [rdi+8], 0\n" // len
		"mov byte [r8], 0\n"
	};
}

func sb_len(sb) {
	// Args: rdi=sb*
	// Returns: rax=len
	asm { "mov rax, [rdi+8]\n" };
}

func sb_ptr(sb) {
	// Args: rdi=sb*
	// Returns: rax=ptr (NUL-terminated)
	asm { "mov rax, [rdi+0]\n" };
}

func sb_reserve(sb, add) {
	// Args: rdi=sb*, rsi=add bytes
	// Ensures capacity for len+add+1 (NUL)
	// No return.
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		// spill slots (40 bytes):
		// [rsp+0]  = need_total
		// [rsp+8]  = new_cap
		// [rsp+16] = new_buf
		// [rsp+24] = old_buf
		// [rsp+32] = sb*
		"sub rsp, 40\n"
		"mov [rsp+32], rdi\n"

		// need_total = len + add + 1
		"mov rax, [rdi+8]\n"   // len
		"add rax, rsi\n"
		"inc rax\n"
		"mov [rsp+0], rax\n"

		// if need_total <= cap => ok
		"mov rbx, [rdi+16]\n"  // cap
		"cmp rax, rbx\n"
		"jbe .ok\n"

		// new_cap = cap; while new_cap < need_total: new_cap*=2
		"mov r12, rbx\n"
		"test r12, r12\n"
		"jnz .cap_nz\n"
		"mov r12, 8\n"
		".cap_nz:\n"
		".grow:\n"
		"cmp r12, [rsp+0]\n"
		"jae .cap_ready\n"
		"shl r12, 1\n"
		"jmp .grow\n"
		".cap_ready:\n"
		"mov [rsp+8], r12\n"

		// new_buf = heap_alloc(new_cap + 1)
		"mov rdi, r12\n"
		"inc rdi\n"
		"call heap_alloc\n"
		"mov [rsp+16], rax\n"

		// copy old bytes: memcpy(new_buf, old_buf, len)
		"mov r14, [rsp+32]\n"  // sb*
		"mov r15, [r14+0]\n"   // old_buf
		"mov [rsp+24], r15\n"
		"mov rdx, [r14+8]\n"   // len
		"mov rdi, [rsp+16]\n"  // dst
		"mov rsi, r15\n"       // src
		"call memcpy\n"

		// NUL terminate at new_buf[len]
		"mov rcx, [rsp+16]\n"
		"add rcx, [r14+8]\n"
		"mov byte [rcx], 0\n"

		// sb->ptr = new_buf; sb->cap = new_cap
		"mov rax, [rsp+16]\n"
		"mov [r14+0], rax\n"
		"mov rax, [rsp+8]\n"
		"mov [r14+16], rax\n"

		".ok:\n"
		"add rsp, 40\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func sb_append_bytes(sb, p, n) {
	// Args: rdi=sb*, rsi=p, rdx=n
	// Appends bytes and maintains trailing NUL.
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		// spill slots (32 bytes):
		// [rsp+0]  = sb*
		// [rsp+8]  = p
		// [rsp+16] = n
		// [rsp+24] = len
		"sub rsp, 32\n"
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"
		"mov [rsp+16], rdx\n"

		// reserve(sb, n)
		"mov rsi, [rsp+16]\n"
		"call sb_reserve\n"

		// dst = sb->ptr + sb->len
		"mov r12, [rsp+0]\n"   // sb*
		"mov r13, [r12+0]\n"   // ptr
		"mov r14, [r12+8]\n"   // len
		"mov [rsp+24], r14\n"
		"lea rdi, [r13+r14]\n" // dst
		"mov rsi, [rsp+8]\n"   // src
		"mov rdx, [rsp+16]\n"  // n
		"call memcpy\n"

		// len += n
		"mov rax, [rsp+24]\n"
		"add rax, [rsp+16]\n"
		"mov [r12+8], rax\n"
		// NUL at ptr[len]
		"mov rcx, [r12+0]\n"
		"add rcx, rax\n"
		"mov byte [rcx], 0\n"

		"add rsp, 32\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func sb_append_cstr(sb, s) {
	// Args: rdi=sb*, rsi=cstr
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		// spill slots (24 bytes):
		// [rsp+0]  = sb*
		// [rsp+8]  = s
		// [rsp+16] = n
		"sub rsp, 24\n"
		"mov [rsp+0], rdi\n"
		"mov [rsp+8], rsi\n"

		// n = strlen(s)
		"mov rdi, [rsp+8]\n"
		"call strlen\n"
		"mov [rsp+16], rax\n"

		// sb_append_bytes(sb, s, n)
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"call sb_append_bytes\n"

		"add rsp, 24\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func sb_append_u64_dec(sb, x) {
	// Args: rdi=sb*, rsi=x
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		// spill slots (32 bytes):
		// [rsp+0]  = sb*
		// [rsp+8]  = ptr
		// [rsp+16] = len
		// [rsp+24] = x
		"sub rsp, 32\n"
		"mov [rsp+0], rdi\n"
		"mov [rsp+24], rsi\n"

		// (ptr,len) = itoa_u64_dec(x)
		"mov rdi, [rsp+24]\n"
		"call itoa_u64_dec\n"
		"mov [rsp+8], rax\n"
		"mov [rsp+16], rdx\n"

		// sb_append_bytes(sb, ptr, len)
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+8]\n"
		"mov rdx, [rsp+16]\n"
		"call sb_append_bytes\n"

		"add rsp, 32\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}
