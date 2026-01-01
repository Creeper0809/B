// v1 core: Slice
// Roadmap: docs/roadmap.md (2.1)
// layout Slice { ptr; len; }
// Planned:
// - slice_eq(s1, s2)
// NOTE:
// - `layout Slice { ptr; len; }` is declared in src/v1/std/std0_sys.b so it appears
//   in the merged compile unit before any function definitions.
// - Avoid basm(Stage1) high-level `if`/`while` inside std/core helpers because Stage1
//   emits globally-numbered labels that can collide across functions.

func slice_eq_parts(p1, n1, p2, n2) {
	// Compare two (ptr,len) pairs.
	// Returns: rax=1 if equal, else 0.
	// Calling convention: rdi=p1, rsi=n1, rdx=p2, rcx=n2

	asm {
		"cmp rsi, rcx\n"
		"jne .ne\n"
		"xor r8, r8\n"            // i=0
		"test rsi, rsi\n"
		"jz .eq\n"
		".loop:\n"
		"mov al, byte [rdi+r8]\n"
		"cmp al, byte [rdx+r8]\n"
		"jne .ne\n"
		"inc r8\n"
		"cmp r8, rsi\n"
		"jb .loop\n"
		".eq:\n"
		"mov rax, 1\n"
		"jmp .ret\n"
		".ne:\n"
		"xor rax, rax\n"
		".ret:\n"
	};
}

func slice_parts(sl) {
	// Extract fields from Slice*.
	// Returns: rax = sl->ptr, rdx = sl->len
	// Calling convention: rdi = sl

	asm {
		"mov rax, [rdi+0]\n"
		"mov rdx, [rdi+8]\n"
	};
}
