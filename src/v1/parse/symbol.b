// v1 symbol table
// Roadmap: docs/roadmap.md (stage 6: symbol table)
// layout Symbol { kind; name:Slice; ... }
// Planned kinds: SYM_VAR, SYM_ALIAS, SYM_CONST

func symtab_new() {
	// Returns: rax = Vec* (of Symbol*)
	rdi = 16;
	vec_new(rdi);
}

func symtab_put(tab, kind, name_ptr, name_len, value) {
	// tab: Vec* of Symbol*
	// Returns: rax = Symbol*
	var tab0;
	var kind0;
	var np0;
	var nl0;
	var val0;
	var sym0;

	ptr64[tab0] = rdi;
	ptr64[kind0] = rsi;
	ptr64[np0] = rdx;
	ptr64[nl0] = rcx;
	ptr64[val0] = r8;

	heap_alloc(32);
	ptr64[sym0] = rax;

	alias r9 : s;
	alias r10 : addr;
	alias r11 : tmp;
	s = ptr64[sym0];
	addr = s;
	tmp = ptr64[kind0];
	ptr64[addr] = tmp;
	addr = s;
	addr += 8;
	tmp = ptr64[np0];
	ptr64[addr] = tmp;
	addr = s;
	addr += 16;
	tmp = ptr64[nl0];
	ptr64[addr] = tmp;
	addr = s;
	addr += 24;
	tmp = ptr64[val0];
	ptr64[addr] = tmp;

	rdi = ptr64[tab0];
	rsi = s;
	vec_push(rdi, rsi);

	rax = s;
}

func symtab_find(tab, kind, name_ptr, name_len) {
	// Returns: rax = Symbol* or 0
	// NOTE: Avoid Stage1 `if`/`while` here (global label collisions in merged units).
	// Use asm-local labels instead.
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"

		// stack locals (24 bytes): name_ptr, name_len, found
		"sub rsp, 24\n"
		"mov [rsp+0], rdx\n"
		"mov [rsp+8], rcx\n"
		"mov qword [rsp+16], 0\n"

		// keep args in callee-saved regs
		"mov r12, rdi\n"      // tab
		"mov r13, rsi\n"      // kind

		// n = vec_len(tab)
		"mov rdi, r12\n"
		"call vec_len\n"
		"mov r14, rax\n"      // n

		// i = 0
		"xor ebx, ebx\n"

		".loop:\n"
		"cmp rbx, r14\n"
		"jae .done\n"

		// sym = vec_get(tab, i)
		"mov rdi, r12\n"
		"mov rsi, rbx\n"
		"call vec_get\n"
		"mov r15, rax\n"      // sym*

		// if (sym->kind != kind) continue
		"mov r11, [r15+0]\n"
		"cmp r11, r13\n"
		"jne .next\n"

		// if (!slice_eq_parts(sym->name_ptr, sym->name_len, name_ptr, name_len)) continue
		"mov rdi, [r15+8]\n"
		"mov rsi, [r15+16]\n"
		"mov rdx, [rsp+0]\n"
		"mov rcx, [rsp+8]\n"
		"call slice_eq_parts\n"
		"test rax, rax\n"
		"je .next\n"

		// found
		"mov [rsp+16], r15\n"
		"jmp .done\n"

		".next:\n"
		"inc rbx\n"
		"jmp .loop\n"

		".done:\n"
		"mov rax, [rsp+16]\n"
		"add rsp, 24\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}
