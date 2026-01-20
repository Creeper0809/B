// library/v1 core: HashMap (Slice/ptr+len keys)
// Roadmap: docs/v2_roadmap.md (P0.5)
// layout declarations live in src/library/v1/prelude.b.
//
// Minimal API:
// - hashmap_new(cap) -> map*
// - hashmap_put(map, key_ptr, key_len, value) -> rax=inserted(1 new, 0 updated)
// - hashmap_get(map, key_ptr, key_len) -> rax=value, rdx=ok
// - hashmap_has(map, key_ptr, key_len) -> rax=1/0
//
// Notes (Stage1 constraints):
// - Avoid Stage1 high-level if/while here; use asm-local labels for loops.
// - Do not assume any register survives helper calls (heap_alloc/memset).

func hashmap_hash(p, n) {
	// FNV-1a 64-bit
	// Calling convention: rdi=p, rsi=n
	// Returns: rax=hash
	asm {
		"mov rax, 14695981039346656037\n" // offset basis
		"mov rcx, rsi\n"                  // n
		"test rcx, rcx\n"
		"jz .done\n"
		"xor r8, r8\n"                    // i=0
		".loop:\n"
		"movzx r9d, byte [rdi+r8]\n"
		"xor rax, r9\n"
		"mov r10, 1099511628211\n"        // prime
		"imul rax, r10\n"
		"inc r8\n"
		"cmp r8, rcx\n"
		"jb .loop\n"
		".done:\n"
	};
}

func hashmap_entries_put(entries, cap, key_ptr, key_len, hash, value) {
	// Insert/update into the entries array.
	// Args: rdi=entries, rsi=cap, rdx=key_ptr, rcx=key_len, r8=hash, r9=value
	// Returns: rax=1 if inserted new, 0 if updated existing
	// No calls.
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"mov r11, rsi\n"
		"dec r11\n"               // mask = cap-1
		"mov r10, r8\n"
		"and r10, r11\n"          // idx = hash & mask
		".probe:\n"
		// entry_ptr = entries + idx*40
		"mov r12, r10\n"
		"mov r13, r10\n"
		"shl r12, 5\n"            // idx*32
		"lea r12, [r12 + r13*8]\n"// idx*32 + idx*8 = idx*40
		"lea r14, [rdi + r12]\n"  // entry_ptr
		// if used==0 => insert
		"mov r15, [r14+32]\n"
		"test r15, r15\n"
		"jz .insert\n"
		// if hash mismatch => next
		"mov r15, [r14+24]\n"
		"cmp r15, r8\n"
		"jne .next\n"
		// if len mismatch => next
		"mov r15, [r14+8]\n"
		"cmp r15, rcx\n"
		"jne .next\n"
		// byte-compare keys
		"mov r15, [r14+0]\n"      // entry key_ptr
		"mov rbx, rcx\n"          // len
		"test rbx, rbx\n"
		"jz .equal\n"
		"xor rax, rax\n"          // i=0
		".cmp_loop:\n"
		"movzx esi, byte [r15+rax]\n"
		"cmp sil, byte [rdx+rax]\n"
		"jne .next\n"
		"inc rax\n"
		"cmp rax, rbx\n"
		"jb .cmp_loop\n"
		".equal:\n"
		// update value
		"mov [r14+16], r9\n"
		"xor rax, rax\n"          // updated
		"jmp .ret\n"
		".insert:\n"
		"mov [r14+0], rdx\n"      // key_ptr
		"mov [r14+8], rcx\n"      // key_len
		"mov [r14+16], r9\n"      // value
		"mov [r14+24], r8\n"      // hash
		"mov qword [r14+32], 1\n" // used=1
		"mov rax, 1\n"
		"jmp .ret\n"
		".next:\n"
		"inc r10\n"
		"and r10, r11\n"
		"jmp .probe\n"
		".ret:\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func hashmap_entries_get(entries, cap, key_ptr, key_len, hash) {
	// Args: rdi=entries, rsi=cap, rdx=key_ptr, rcx=key_len, r8=hash
	// Returns: rax=value (undefined if ok=0), rdx=ok
	// No calls.
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"push r15\n"
		"mov r11, rsi\n"
		"dec r11\n"               // mask
		"mov r10, r8\n"
		"and r10, r11\n"          // idx
		".probe:\n"
		// entry_ptr
		"mov r12, r10\n"
		"mov r13, r10\n"
		"shl r12, 5\n"
		"lea r12, [r12 + r13*8]\n"
		"lea r14, [rdi + r12]\n"
		// if used==0 => not found
		"mov r15, [r14+32]\n"
		"test r15, r15\n"
		"jz .nf\n"
		// if hash mismatch => next
		"mov r15, [r14+24]\n"
		"cmp r15, r8\n"
		"jne .next\n"
		// if len mismatch => next
		"mov r15, [r14+8]\n"
		"cmp r15, rcx\n"
		"jne .next\n"
		// byte-compare
		"mov r15, [r14+0]\n"      // entry key_ptr
		"mov rbx, rcx\n"          // len
		"test rbx, rbx\n"
		"jz .found\n"
		"xor rax, rax\n"          // i=0
		".cmp_loop:\n"
		"movzx esi, byte [r15+rax]\n"
		"cmp sil, byte [rdx+rax]\n"
		"jne .next\n"
		"inc rax\n"
		"cmp rax, rbx\n"
		"jb .cmp_loop\n"
		".found:\n"
		"mov rax, [r14+16]\n"     // value
		"mov rdx, 1\n"
		"jmp .ret\n"
		".next:\n"
		"inc r10\n"
		"and r10, r11\n"
		"jmp .probe\n"
		".nf:\n"
		"xor rax, rax\n"
		"xor rdx, rdx\n"
		".ret:\n"
		"pop r15\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
	};
}

func hashmap_round_cap(cap) {
	// Round cap up to power-of-two, min 8.
	// Args: rdi=cap
	// Returns: rax=rounded
	asm {
		"mov rax, rdi\n"
		"cmp rax, 8\n"
		"jae .ge8\n"
		"mov rax, 8\n"
		"jmp .done\n"
		".ge8:\n"
		"mov rcx, 8\n"        // pow2
		".loop:\n"
		"cmp rcx, rax\n"
		"jae .done_pow\n"
		"shl rcx, 1\n"
		"jmp .loop\n"
		".done_pow:\n"
		"mov rax, rcx\n"
		".done:\n"
	};
}

func hashmap_new(cap) {
	// Args: rdi=cap
	// Returns: rax=map*
	var cap0;
	var cap1;
	var map0;
	var entries0;
	var bytes0;

	ptr64[cap0] = rdi;
	rdi = ptr64[cap0];
	hashmap_round_cap(rdi);
	ptr64[cap1] = rax;

	// map = heap_alloc(24)
	heap_alloc(24);
	ptr64[map0] = rax;

	// bytes = cap * 40 = cap*32 + cap*8
	alias r8 : capv;
	alias r9 : b;
	capv = ptr64[cap1];
	b = capv;
	b <<= 5;
	alias r10 : b2;
	b2 = capv;
	b2 <<= 3;
	b += b2;
	ptr64[bytes0] = b;

	// entries = heap_alloc(bytes)
	rdi = ptr64[bytes0];
	heap_alloc(rdi);
	ptr64[entries0] = rax;

	// memset(entries,0,bytes)
	rdi = ptr64[entries0];
	rsi = 0;
	rdx = ptr64[bytes0];
	memset(rdi, rsi, rdx);

	// map->entries/cap/len
	alias r11 : mapv;
	alias r12 : addr;
	mapv = ptr64[map0];

	addr = mapv;
	alias r13 : tmp;
	tmp = ptr64[entries0];
	ptr64[addr] = tmp;
	addr = mapv;
	addr += 8;
	tmp = ptr64[cap1];
	ptr64[addr] = tmp;
	addr = mapv;
	addr += 16;
	ptr64[addr] = 0;

	rax = mapv;
}

func hashmap_rehash(map, new_cap) {
	// Args: rdi=map*, rsi=new_cap
	// Replaces map->entries and map->cap. Leaves map->len unchanged.
	// Implementation is fully in asm with stack spill slots.
	asm {
		"push rdi\n" // map*
		"push rsi\n" // new_cap
		// reserve 48 bytes spill:
		// [rsp+0]  = new_entries
		// [rsp+8]  = old_entries
		// [rsp+16] = old_cap
		// [rsp+24] = new_cap
		// [rsp+32] = map*
		// [rsp+40] = i
		"sub rsp, 48\n"
		"mov rax, [rsp+56]\n"     // map* (saved by push)
		"mov [rsp+32], rax\n"
		"mov rax, [rsp+48]\n"     // new_cap
		"mov [rsp+24], rax\n"

		// load old_entries/old_cap
		"mov r8, [rsp+32]\n"      // map*
		"mov r9, [r8+0]\n"        // old_entries
		"mov r10, [r8+8]\n"       // old_cap
		"mov [rsp+8], r9\n"
		"mov [rsp+16], r10\n"

		// bytes = new_cap*40 = (new_cap<<5) + (new_cap<<3)
		"mov r11, [rsp+24]\n"     // new_cap
		"mov rcx, r11\n"
		"shl rcx, 5\n"
		"mov rdx, r11\n"
		"shl rdx, 3\n"
		"add rcx, rdx\n"          // bytes

		// new_entries = heap_alloc(bytes)
		"mov rdi, rcx\n"
		"call heap_alloc\n"
		"mov [rsp+0], rax\n"

		// memset(new_entries,0,bytes)
		"mov rdi, [rsp+0]\n"
		"xor rsi, rsi\n"
		"mov rdx, rcx\n"
		"call memset\n"

		// loop i over old_cap
		"xor r8, r8\n"            // i=0
		".loop:\n"
		"cmp r8, [rsp+16]\n"
		"jae .done\n"
		// old_entry_ptr = old_entries + i*40
		"mov r9, r8\n"
		"mov r10, r8\n"
		"shl r9, 5\n"
		"lea r9, [r9 + r10*8]\n"
		"mov r11, [rsp+8]\n"     // old_entries
		"lea r12, [r11 + r9]\n"  // old_entry_ptr
		"mov r13, [r12+32]\n"    // used
		"test r13, r13\n"
		"jz .next\n"
		// spill i across call
		"mov [rsp+40], r8\n"
		// insert into new_entries
		"mov rdi, [rsp+0]\n"     // new_entries
		"mov rsi, [rsp+24]\n"    // new_cap
		"mov rdx, [r12+0]\n"     // key_ptr
		"mov rcx, [r12+8]\n"     // key_len
		"mov r8,  [r12+24]\n"    // hash
		"mov r9,  [r12+16]\n"    // value
		"call hashmap_entries_put\n"
		"mov r8, [rsp+40]\n"     // reload i
		".next:\n"
		"inc r8\n"
		"jmp .loop\n"
		".done:\n"

		// update map fields
		"mov r8, [rsp+32]\n"     // map*
		"mov r9, [rsp+0]\n"      // new_entries
		"mov [r8+0], r9\n"
		"mov r10, [rsp+24]\n"    // new_cap
		"mov [r8+8], r10\n"

		"add rsp, 48\n"
		"pop rsi\n"
		"pop rdi\n"
	};
}

func hashmap_put(map, key_ptr, key_len, value) {
	// Args: rdi=map*, rsi=key_ptr, rdx=key_len, rcx=value
	// Returns: rax=1 if inserted new, 0 if updated
	var map0;
	var kptr0;
	var klen0;
	var val0;
	var h0;
	var cap0;

	ptr64[map0] = rdi;
	ptr64[kptr0] = rsi;
	ptr64[klen0] = rdx;
	ptr64[val0] = rcx;

	// hash
	rdi = ptr64[kptr0];
	rsi = ptr64[klen0];
	hashmap_hash(rdi, rsi);
	ptr64[h0] = rax;

	// entries_put (MVP: assumes map has enough capacity; caller can rehash manually later)
	alias r10 : mp;
	alias r11 : addr;
	alias r12 : capv;
	mp = ptr64[map0];
	addr = mp;
	rdi = ptr64[addr];
	addr = mp;
	addr += 8;
	capv = ptr64[addr];
	ptr64[cap0] = capv;
	rsi = ptr64[cap0];
	rdx = ptr64[kptr0];
	rcx = ptr64[klen0];
	r8  = ptr64[h0];
	r9  = ptr64[val0];
	hashmap_entries_put(rdi, rsi, rdx, rcx, r8, r9);

	// if inserted, map->len++
	rdi = ptr64[map0];
	asm {
		"test rax, rax\n"
		"jz .done\n"
		"mov rcx, [rdi+16]\n"
		"inc rcx\n"
		"mov [rdi+16], rcx\n"
		".done:\n"
	};
}

func hashmap_get(map, key_ptr, key_len) {
	// Args: rdi=map*, rsi=key_ptr, rdx=key_len
	// Returns: rax=value (undefined if ok=0), rdx=ok
	var map0;
	var kptr0;
	var klen0;
	var h0;
	ptr64[map0] = rdi;
	ptr64[kptr0] = rsi;
	ptr64[klen0] = rdx;

	rdi = ptr64[kptr0];
	rsi = ptr64[klen0];
	hashmap_hash(rdi, rsi);
	ptr64[h0] = rax;

	// Avoid using r8 for map pointer; r8 is reserved for hash arg.
	alias r10 : m0;
	alias r11 : addr0;
	m0 = ptr64[map0];
	addr0 = m0;
	rdi = ptr64[addr0];
	addr0 = m0;
	addr0 += 8;
	rsi = ptr64[addr0];
	rdx = ptr64[kptr0];
	rcx = ptr64[klen0];
	r8  = ptr64[h0];
	hashmap_entries_get(rdi, rsi, rdx, rcx, r8);
}

func hashmap_has(map, key_ptr, key_len) {
	// Returns: rax=1 if present else 0
	asm { "call hashmap_get\n" };
	asm {
		"test rdx, rdx\n"
		"jz .no\n"
		"mov rax, 1\n"
		"jmp .ret\n"
		".no:\n"
		"xor rax, rax\n"
		".ret:\n"
	};
}
