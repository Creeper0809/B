// P17: Arena runtime smoke (library/v1)
// Validates:
// - bump allocation
// - alignment handling
// - reset

func main() {
	var arena;
	var v1;
	var v2;
	var v3;

	alias rax : tmp;
	alias rbx : a;
	alias r12 : p1;
	alias r13 : p2;
	alias r14 : p3;
	alias r15 : t;
	alias r11 : addr;

	// arena = arena_new(64)
	arena_new(64);
	ptr64[arena] = rax;
	a = ptr64[arena];

	// p1 = arena_alloc(a, 3, 1)
	rdi = a;
	rsi = 3;
	rdx = 1;
	arena_alloc(rdi, rsi, rdx);
	ptr64[v1] = rax;
	p1 = ptr64[v1];
	if (p1 == 0) {
		sys_exit(1);
	}

	// p2 = arena_alloc(a, 8, 8)
	rdi = a;
	rsi = 8;
	rdx = 8;
	arena_alloc(rdi, rsi, rdx);
	ptr64[v2] = rax;
	p2 = ptr64[v2];
	if (p2 == 0) {
		sys_exit(2);
	}
	// check p2 alignment: (p2 & 7) == 0
	asm {
		"mov rax, r13\n"
		"and rax, 7\n"
		"jz .p2_ok\n"
		"mov rdi, 3\n"
		"call sys_exit\n"
		".p2_ok:\n"
	};

	// p3 = arena_alloc(a, 16, 16)
	rdi = a;
	rsi = 16;
	rdx = 16;
	arena_alloc(rdi, rsi, rdx);
	ptr64[v3] = rax;
	p3 = ptr64[v3];
	if (p3 == 0) {
		sys_exit(4);
	}
	// check p3 alignment: (p3 & 15) == 0
	asm {
		"mov rax, r14\n"
		"and rax, 15\n"
		"jz .p3_ok\n"
		"mov rdi, 5\n"
		"call sys_exit\n"
		".p3_ok:\n"
	};

	// write a few bytes (basic sanity)
	addr = p1;
	ptr8[addr] = 0x11;
	addr += 1;
	ptr8[addr] = 0x22;
	addr += 1;
	ptr8[addr] = 0x33;

	// reset and allocate again; should succeed
	rdi = a;
	arena_reset(rdi);
	rdi = a;
	rsi = 8;
	rdx = 8;
	arena_alloc(rdi, rsi, rdx);
	if (tmp == 0) {
		sys_exit(6);
	}

	sys_exit(0);
}
