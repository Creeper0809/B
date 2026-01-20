// library/v1 core: Arena (bump allocator)
// Roadmap: docs/v2_roadmap.md (P0.5)
// Depends on: heap_alloc (Stage1 builtin)
// layout declarations live in src/library/v1/prelude.b.
//
// API:
// - arena_new(cap) -> Arena*
// - arena_alloc(a, size, align_pow2) -> rax=ptr (0 on OOM)
// - arena_reset(a)

func arena_new(cap) {
	// Args: rdi=cap(bytes)
	// Returns: rax=Arena*
	var cap0;
	var a0;
	var buf0;
	var base0;

	ptr64[cap0] = rdi;

	// a = heap_alloc(24)
	heap_alloc(24);
	ptr64[a0] = rax;

	// buf = heap_alloc(cap + 15) (for 16-byte alignment)
	rdi = ptr64[cap0];
	rdi += 15;
	heap_alloc(rdi);
	ptr64[buf0] = rax;
	// base = align16(buf)
	alias r10 : buf;
	buf = ptr64[buf0];
	asm {
		"mov rax, r10\n"
		"add rax, 15\n"
		"and rax, -16\n"
	};
	ptr64[base0] = rax;

	// a->base = base
	alias r8 : a;
	alias r9 : tmp;
	a = ptr64[a0];
	tmp = ptr64[base0];
	ptr64[a] = tmp;

	// a->cap = cap
	a += 8;
	tmp = ptr64[cap0];
	ptr64[a] = tmp;

	// a->off = 0
	a += 8;
	ptr64[a] = 0;

	rax = ptr64[a0];
}

func arena_reset(a) {
	// Args: rdi=Arena*
	// Sets off=0
	asm {
		"mov qword [rdi+16], 0\n"
	};
}

func arena_alloc(a, size, align_pow2) {
	// Args: rdi=Arena*, rsi=size(bytes), rdx=align(power-of-two, >=1)
	// Returns: rax=ptr or 0 if not enough space
	// No calls.
	asm {
		// load fields
		"mov r8,  [rdi+0]\n"   // base
		"mov r9,  [rdi+8]\n"   // cap
		"mov r10, [rdi+16]\n"  // off
		// if align==0 treat as 1
		"test rdx, rdx\n"
		"jnz .align_ok\n"
		"mov rdx, 1\n"
		".align_ok:\n"
		// mask = align-1 (r11)
		"mov r11, rdx\n"
		"dec r11\n"
		// aligned = (off + mask) & ~mask
		"mov rcx, r10\n"
		"add rcx, r11\n"
		"not r11\n"
		"and rcx, r11\n"
		// new_off = aligned + size (r11)
		"mov r11, rcx\n"
		"add r11, rsi\n"
		// if new_off > cap => OOM
		"cmp r11, r9\n"
		"ja .oom\n"
		// ptr = base + aligned
		"lea rax, [r8+rcx]\n"
		// store off = new_off
		"mov [rdi+16], r11\n"
		"jmp .done\n"
		".oom:\n"
		"xor eax, eax\n"
		".done:\n"
	};
}
