// library/v1 core: StringInterner
// Roadmap: docs/v2_roadmap.md (P0.5)
// Depends on:
// - src/v1/core/vec.b (Vec u64)
// - src/library/v1/core/hashmap.b (HashMap: bytes->u64)
// - src/v1/std/std1_memstrnum.b (heap_alloc/memcpy)
// layout declarations live in src/library/v1/prelude.b.
//
// API:
// - string_interner_new(cap) -> interner*
// - string_interner_intern(si, ptr, len) -> rax=id (1-based)
// - string_interner_get(si, id) -> rax=ptr, rdx=len (0/0 if invalid)

func string_interner_new(cap) {
	// Args: rdi=cap (expected unique strings)
	// Returns: rax=StringInterner*
	var cap0;
	var si0;
	var map0;
	var vec0;

	ptr64[cap0] = rdi;

	// si = heap_alloc(sizeof(StringInterner)=16)
	heap_alloc(16);
	ptr64[si0] = rax;

	// map = hashmap_new(cap)
	rdi = ptr64[cap0];
	hashmap_new(rdi);
	ptr64[map0] = rax;

	// vec = vec_new(cap)
	rdi = ptr64[cap0];
	vec_new(rdi);
	ptr64[vec0] = rax;

	// si->map = map; si->items = vec
	alias r8 : si;
	alias r9 : tmp;
	si = ptr64[si0];
	tmp = ptr64[map0];
	ptr64[si] = tmp;
	si += 8;
	tmp = ptr64[vec0];
	ptr64[si] = tmp;

	rax = ptr64[si0];
}

func string_interner_intern(si, p, n) {
	// Args: rdi=si*, rsi=p, rdx=n
	// Returns: rax=id (1-based)
	// Implemented in asm to avoid Stage1 high-level control-flow.
	asm {
		"push rbp\n"
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		// spill slots (64 bytes):
		// [rsp+0]  = dst
		// [rsp+8]  = slice_ptr
		// [rsp+16] = id
		// [rsp+24] = vec
		// [rsp+32] = map
		// [rsp+40] = n
		// [rsp+48] = p
		// [rsp+56] = si
		"sub rsp, 64\n"
		"mov [rsp+56], rdi\n"
		"mov [rsp+48], rsi\n"
		"mov [rsp+40], rdx\n"

		// load map/vec from si
		"mov rbx, [rsp+56]\n"
		"mov r12, [rbx+0]\n" // map
		"mov r13, [rbx+8]\n" // vec
		"mov [rsp+32], r12\n"
		"mov [rsp+24], r13\n"

		// lookup: hashmap_get(map, p, n)
		"mov rdi, r12\n"
		"mov rsi, [rsp+48]\n"
		"mov rdx, [rsp+40]\n"
		"call hashmap_get\n"
		"test rdx, rdx\n"
		"jnz .found\n"

		// dst = heap_alloc(n + 1)
		"mov rdi, [rsp+40]\n"
		"inc rdi\n"
		"call heap_alloc\n"
		"mov [rsp+0], rax\n"

		// memcpy(dst, p, n)
		"mov rdi, [rsp+0]\n"
		"mov rsi, [rsp+48]\n"
		"mov rdx, [rsp+40]\n"
		"call memcpy\n"
		// dst[n] = 0
		"mov rcx, [rsp+0]\n"
		"mov rdx, [rsp+40]\n"
		"add rcx, rdx\n"
		"mov byte [rcx], 0\n"

		// slice_ptr = heap_alloc(16)
		"mov rdi, 16\n"
		"call heap_alloc\n"
		"mov [rsp+8], rax\n"
		// slice_ptr->ptr = dst; slice_ptr->len = n
		"mov rcx, [rsp+0]\n"
		"mov [rax+0], rcx\n"
		"mov rcx, [rsp+40]\n"
		"mov [rax+8], rcx\n"

		// id = vec_push(vec, slice_ptr)
		"mov rdi, [rsp+24]\n"
		"mov rsi, [rsp+8]\n"
		"call vec_push\n"
		"mov [rsp+16], rax\n"

		// hashmap_put(map, dst, n, id)
		"mov rdi, [rsp+32]\n"
		"mov rsi, [rsp+0]\n"
		"mov rdx, [rsp+40]\n"
		"mov rcx, [rsp+16]\n"
		"call hashmap_put\n"

		"mov rax, [rsp+16]\n"
		"jmp .ret\n"
		".found:\n"
		// rax already holds the existing id
		".ret:\n"
		"add rsp, 64\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"pop rbp\n"
	};
}

func string_interner_get(si, id) {
	// Args: rdi=si*, rsi=id (1-based)
	// Returns: rax=ptr, rdx=len (0/0 if invalid)
	asm {
		"push rbp\n"
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		// spill slots (32 bytes):
		// [rsp+24] = id
		// [rsp+16] = i
		// [rsp+8]  = vec
		// [rsp+0]  = si
		"sub rsp, 32\n"
		"mov [rsp+0], rdi\n"
		"mov [rsp+24], rsi\n"

		// if id==0 => invalid
		"mov rax, [rsp+24]\n"
		"test rax, rax\n"
		"jnz .id_nz\n"
		"xor rax, rax\n"
		"xor rdx, rdx\n"
		"jmp .ret\n"
		".id_nz:\n"

		// vec = si->items
		"mov rbx, [rsp+0]\n"
		"mov r12, [rbx+8]\n"
		"mov [rsp+8], r12\n"

		// i = id-1
		"mov r13, [rsp+24]\n"
		"dec r13\n"
		"mov [rsp+16], r13\n"

		// len = vec_len(vec)
		"mov rdi, r12\n"
		"call vec_len\n"
		// bounds: i < len
		"cmp r13, rax\n"
		"jb .in_range\n"
		"xor rax, rax\n"
		"xor rdx, rdx\n"
		"jmp .ret\n"
		".in_range:\n"

		// slice_ptr = vec_get(vec, i)
		"mov rdi, r12\n"
		"mov rsi, r13\n"
		"call vec_get\n"
		// load ptr/len from Slice
		"mov rdx, [rax+8]\n"
		"mov rax, [rax+0]\n"

		".ret:\n"
		"add rsp, 32\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"pop rbp\n"
	};
}
