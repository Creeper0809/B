// v1 std (stage 1): memory/string/number utils
// Roadmap: docs/roadmap.md (stage 1)
// Depends on: std0_sys.b
//
// Planned exports:
// - heap_alloc(n)
// - memcpy(dst, src, n)
// - memset(dst, byte, n)
// - strlen(s)
// - streq(a, b)
// - itoa_u64_dec(x) -> (ptr,len)
// - atoi(slice) -> u64 (decimal / hex 0x...)
// - str_concat(s1, s2) -> Slice
// - slice_to_cstr(slice) -> ptr

func memset(dst, byte, n) {
	// API: memset(dst, byte, n) -> rax=dst
	// Convention: args are passed in rdi/rsi/rdx.
	// NOTE: Stage1 control-flow labels are global across the whole compile unit,
	// so std functions avoid Stage1 `if`/`while` and use asm-local labels instead.
	asm {
		// Save return value.
		"mov r8, rdi\n"
		// rcx = n
		"mov rcx, rdx\n"
		"test rcx, rcx\n"
		"jz .memset_done\n"
		// al = byte (stosb uses AL)
		"mov al, sil\n"
		// Ensure forward direction for rep stosb.
		"cld\n"
		"rep stosb\n"
		".memset_done:\n"
		"mov rax, r8\n"
	};
}

func itoa_u64_dec(x) {
	// u64 -> decimal string
	// Returns:
	// - rax = ptr to NUL-terminated digits (within an allocated buffer)
	// - rdx = digit length (excluding NUL)
	//
	// Notes:
	// - Stage1 has no / or %, so we use an asm div-by-10 step.
	// - Buffer is owned by the caller (heap_alloc).
	// - Uses only caller-saved regs for internal state.

	// Spill input across heap_alloc (calls clobber caller-saved regs).
	var x_slot;
	ptr64[x_slot] = rdi;

	// Allocate 32 bytes and reserve the last byte for NUL.
	heap_alloc(32);
	alias r8 : val;
	val = ptr64[x_slot];
	asm {
		// r9  = cur (end-1), keep NUL at end
		"mov r9, rax\n"
		"add r9, 31\n"
		"mov byte [r9], 0\n"
		// r10 = len
		"xor r10, r10\n"
		"cmp r8, 0\n"
		"jne .itoa_loop\n"
		"dec r9\n"
		"mov byte [r9], '0'\n"
		"mov r10, 1\n"
		"jmp .itoa_done\n"
		".itoa_loop:\n"
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
		"jnz .itoa_loop\n"
		".itoa_done:\n"
		"mov rax, r9\n"
		"mov rdx, r10\n"
	};
}

func require_ok_rdx(msg) {
	// If rdx==0, panic(msg).
	// Calling convention: rdi=msg
	asm {
		"test rdx, rdx\n"
		"jnz .ok\n"
		"call panic\n"
		".ok:\n"
	};
}

func atoi_u64_slice(s) {
	// Parse a Slice as u64.
	// Supports:
	// - decimal:  "123"
	// - hex:      "0x1f" or "0X1F"
	// Returns:
	// - rax = value (undefined if ok=0)
	// - rdx = ok (1 on success, 0 on failure)
	//
	// Note: avoid basm(Stage1) high-level if/while statements here.
	// Stage1 emits globally-numbered labels for those, which can collide across functions.
	// Use asm-local labels (e.g. `.loop:`) and jumps instead.

	alias rdi : slice;
	alias r8  : p;
	alias r9  : n;

	// Use asm loads to avoid Stage1 parser edge-cases around ptr64[...] in high-level code.
	asm {
		"mov r8,  [rdi+0]\n"
		"mov r9,  [rdi+8]\n"
	};

	atoi_u64(p, n);
}

func atoi_u64_or_panic(p, n) {
	// Parse (ptr,len) as u64; panic on failure.
	// Returns: rax=value
	var v_slot;

	// Stage1 does not reliably bind named parameters to locals.
	// Use ABI registers directly (rdi=p, rsi=n).
	asm {
		"call atoi_u64\n"
	};
	ptr64[v_slot] = rax;
	require_ok_rdx("Invalid number format");
	rax = ptr64[v_slot];
}

func atoi_u64_slice_or_panic(s) {
	// Parse Slice as u64; panic on failure.
	// Returns: rax=value
	var v_slot;

	// Calling convention: rdi = Slice*
	asm {
		"call atoi_u64_slice\n"
	};
	ptr64[v_slot] = rax;
	require_ok_rdx("Invalid number format");
	rax = ptr64[v_slot];
}

func atoi_u64(p, n) {
	// Parse (ptr,len) as u64.
	// Supports:
	// - decimal:  "123"
	// - hex:      "0x1f" or "0X1F"
	// Returns:
	// - rax = value (undefined if ok=0)
	// - rdx = ok (1 on success, 0 on failure)
	//
	// Note: avoid basm(Stage1) high-level if/while statements here.
	// Stage1 emits globally-numbered labels for those, which can collide across functions.
	// Use asm-local labels (e.g. `.loop:`) and jumps instead.

	alias rdi : ptr;
	alias rsi : len;
	alias r8  : p0;
	alias r9  : n0;

	p0 = ptr;
	n0 = len;

	asm {
		"xor r11, r11\n"
		"xor r10, r10\n"
		"mov rcx, 10\n"
		"test r9, r9\n"
		"jz .fail\n"

		"cmp r9, 2\n"
		"jb .loop\n"
		"mov al, byte [r8]\n"
		"cmp al, '0'\n"
		"jne .loop\n"
		"mov al, byte [r8+1]\n"
		"cmp al, 'x'\n"
		"je .hex\n"
		"cmp al, 'X'\n"
		"jne .loop\n"
		".hex:\n"
		"mov rcx, 16\n"
		"mov r10, 2\n"

		".loop:\n"
		"cmp r10, r9\n"
		"jae .done\n"
		"movzx eax, byte [r8+r10]\n"

		"cmp rcx, 10\n"
		"jne .hex_digit\n"
		"cmp al, '0'\n"
		"jb .fail\n"
		"cmp al, '9'\n"
		"ja .fail\n"
		"sub al, '0'\n"
		"movzx edx, al\n"
		"jmp .acc\n"

		".hex_digit:\n"
		"cmp al, '0'\n"
		"jb .hex_af\n"
		"cmp al, '9'\n"
		"ja .hex_af\n"
		"sub al, '0'\n"
		"movzx edx, al\n"
		"jmp .acc\n"

		".hex_af:\n"
		"cmp al, 'a'\n"
		"jb .hex_AF\n"
		"cmp al, 'f'\n"
		"ja .hex_AF\n"
		"sub al, 'a'\n"
		"add al, 10\n"
		"movzx edx, al\n"
		"jmp .acc\n"

		".hex_AF:\n"
		"cmp al, 'A'\n"
		"jb .fail\n"
		"cmp al, 'F'\n"
		"ja .fail\n"
		"sub al, 'A'\n"
		"add al, 10\n"
		"movzx edx, al\n"

		".acc:\n"
		"imul r11, rcx\n"
		"add r11, rdx\n"
		"inc r10\n"
		"jmp .loop\n"

		".done:\n"
		"mov rax, r11\n"
		"mov rdx, 1\n"
		"jmp .ret\n"

		".fail:\n"
		"xor rax, rax\n"
		"xor rdx, rdx\n"
		".ret:\n"
	};
}

func slice_to_cstr(p, n) {
	// Allocate and return a NUL-terminated copy of (ptr,len).
	// Returns:
	// - rax = ptr to NUL-terminated string

	var p_slot;
	var n_slot;
	var dst_slot;

	ptr64[p_slot] = rdi;
	ptr64[n_slot] = rsi;

	// dst = heap_alloc(n + 1)
	rdi = ptr64[n_slot];
	rdi += 1;
	heap_alloc(rdi);
	ptr64[dst_slot] = rax;

	// memcpy(dst, p, n)
	rdi = ptr64[dst_slot];
	rsi = ptr64[p_slot];
	rdx = ptr64[n_slot];
	memcpy(rdi, rsi, rdx);

	// dst[n] = 0
	alias r8 : addr;
	alias r9 : n0;
	n0 = ptr64[n_slot];
	addr = ptr64[dst_slot];
	addr += n0;
	ptr8[addr] = 0;

	rax = ptr64[dst_slot];
}

func str_concat(p1, n1, p2, n2) {
	// Concatenate (p1,n1) + (p2,n2) into a new NUL-terminated string.
	// Returns:
	// - rax = ptr to NUL-terminated concatenation
	// - rdx = total length (excluding NUL)

	var p1_slot;
	var n1_slot;
	var p2_slot;
	var n2_slot;
	var dst_slot;
	var total_slot;

	// Spill args across heap_alloc/memcpy (calls clobber caller-saved regs).
	ptr64[p1_slot] = rdi;
	ptr64[n1_slot] = rsi;
	ptr64[p2_slot] = rdx;
	ptr64[n2_slot] = rcx;

	// total = n1 + n2
	alias r8 : total;
	alias r9 : n10;
	alias r10 : n20;
	n10 = ptr64[n1_slot];
	n20 = ptr64[n2_slot];
	total = n10;
	total += n20;
	ptr64[total_slot] = total;

	// dst = heap_alloc(total + 1)
	rdi = total;
	rdi += 1;
	heap_alloc(rdi);
	ptr64[dst_slot] = rax;

	// memcpy(dst, p1, n1)
	rdi = ptr64[dst_slot];
	rsi = ptr64[p1_slot];
	rdx = ptr64[n1_slot];
	memcpy(rdi, rsi, rdx);

	// memcpy(dst + n1, p2, n2)
	alias r9 : dst2;
	alias r10 : n1v;
	n1v = ptr64[n1_slot];
	dst2 = ptr64[dst_slot];
	dst2 += n1v;
	rdi = dst2;
	rsi = ptr64[p2_slot];
	rdx = ptr64[n2_slot];
	memcpy(rdi, rsi, rdx);

	// dst[total] = 0
	alias r10 : endp;
	alias r11 : totalv;
	totalv = ptr64[total_slot];
	endp = ptr64[dst_slot];
	endp += totalv;
	ptr8[endp] = 0;

	rax = ptr64[dst_slot];
	rdx = ptr64[total_slot];
}
