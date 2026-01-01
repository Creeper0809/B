// v1 core: Vec (push-only, u64 elements)
// Roadmap: docs/roadmap.md (2.2)
// layout Vec { ptr; len; cap; }
// Planned:
// - vec_init(cap)
// - vec_push(vec*, item)
// - vec_get(vec*, i)
// - vec_len(vec*)

func vec_new(cap) {
	// Allocate a Vec struct and backing storage for `cap` u64 items.
	// Returns: rax = vec*
	// Calling convention: rdi=cap

	var cap_slot;
	var vec_slot;

	ptr64[cap_slot] = rdi;

	// vec = heap_alloc(24)
	heap_alloc(24);
	ptr64[vec_slot] = rax;

	// buf = heap_alloc(cap * 8)
	alias r8 : bytes;
	bytes = ptr64[cap_slot];
	bytes <<= 3;
	rdi = bytes;
	heap_alloc(rdi);

	// vec->ptr = buf
	alias r9 : vecp;
	vecp = ptr64[vec_slot];
	ptr64[vecp] = rax;

	// vec->len = 0
	alias r10 : addr;
	addr = vecp;
	addr += 8;
	ptr64[addr] = 0;

	// vec->cap = cap
	alias r11 : cap0;
	cap0 = ptr64[cap_slot];
	addr = vecp;
	addr += 16;
	ptr64[addr] = cap0;

	rax = vecp;
}

func vec_len(v) {
	// Returns: rax = v->len
	// Calling convention: rdi=v
	alias r8 : addr;
	addr = rdi;
	addr += 8;
	rax = ptr64[addr];
}

func vec_get(v, i) {
	// Returns: rax = v->ptr[i]
	// Calling convention: rdi=v, rsi=i
	alias r8 : vecp;
	alias r9 : buf;
	alias r10 : off;
	alias r11 : addr;

	vecp = rdi;
	buf = ptr64[vecp];
	off = rsi;
	off <<= 3;
	addr = buf;
	addr += off;
	rax = ptr64[addr];
}

func vec_push(v, item) {
	// Push `item` into `v`, growing capacity when full.
	// Returns: rax = new length
	// Calling convention: rdi=v, rsi=item
	// NOTE: implemented with asm-local labels to avoid Stage1 high-level if/while.

	asm {
		"push rdi\n"
		"push rsi\n"

		// load vec fields
		"mov rdi, [rsp+8]\n"      // vec*
		"mov r8,  [rdi+0]\n"      // buf
		"mov rsi, r8\n"           // keep old buf across heap_alloc (clobbers r8)
		"mov r9,  [rdi+8]\n"      // len
		"mov r10, [rdi+16]\n"     // cap
		"cmp r9, r10\n"
		"jb .have_cap\n"

		// grow: new_cap = (cap==0 ? 1 : cap*2)
		"mov r11, r10\n"
		"test r11, r11\n"
		"jnz .cap_nz\n"
		"mov r11, 1\n"
		"jmp .cap_done\n"
		".cap_nz:\n"
		"shl r11, 1\n"
		".cap_done:\n"

		// bytes_new = new_cap * 8
		"mov rcx, r11\n"
		"shl rcx, 3\n"
		"mov rdi, rcx\n"
		"call heap_alloc\n"
		"test rax, rax\n"
		"jnz .alloc_ok\n"
		"mov rdi, 1\n"
		"call sys_exit\n"
		".alloc_ok:\n"

		// memcpy(new_buf, old_buf, len*8)
		"mov rdi, rax\n"          // dst
		"mov rdx, r9\n"
		"shl rdx, 3\n"
		"call memcpy\n"

		// update vec->ptr = new_buf, vec->cap = new_cap
		"mov rdi, [rsp+8]\n"
		"mov [rdi+0], rax\n"
		"mov [rdi+16], r11\n"
		"mov r8, rax\n"           // buf = new_buf
		"mov r10, r11\n"          // cap = new_cap

		".have_cap:\n"
		// store item at buf + len*8
		"mov rcx, r9\n"
		"shl rcx, 3\n"
		"lea rdx, [r8+rcx]\n"
		"mov rax, [rsp]\n"        // item
		"mov [rdx], rax\n"

		// len++ and store back
		"inc r9\n"
		"mov rdi, [rsp+8]\n"
		"mov [rdi+8], r9\n"
		"mov rax, r9\n"

		"pop rsi\n"
		"pop rdi\n"
	};
}
