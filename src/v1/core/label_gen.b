// v1 core: label_gen
// Roadmap: docs/roadmap.md (2.3)
// Planned:
// - global label_counter
// - label_next() -> Slice  ("L_1", "L_2", ...)

func label_next() {
	// Returns: rax = ptr to a heap-allocated Slice { ptr, len }
	// Label format: "L_<n>" (e.g. L_1)
	//
	// IMPORTANT(Stage1): preserve callee-saved regs. Some compiler code uses r12/r13/r14/rbx
	// across helper calls; clobbering them can corrupt the compilation and yield duplicate labels.
	asm {
		"push rbx\n"
		"push r12\n"
		"push r13\n"
		"push r14\n"
		"sub rsp, 80\n" // [rsp+0..47]=scratch, [rsp+56]=full_ptr, [rsp+64]=full_len

		// cnt = ++label_counter
		"mov r12, [rel label_counter]\n"
		"inc r12\n"
		"mov [rel label_counter], r12\n"

		// Format cnt into decimal in scratch (NUL-terminated)
		"mov r8, r12\n"
		"lea r9, [rsp+47]\n"
		"mov byte [r9], 0\n"
		"xor r10, r10\n" // len
		"cmp r8, 0\n"
		"jne .ln_loop\n"
		"dec r9\n"
		"mov byte [r9], '0'\n"
		"mov r10, 1\n"
		"jmp .ln_done\n"
		".ln_loop:\n"
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
		"jnz .ln_loop\n"
		".ln_done:\n"
		"mov r13, r9\n"  // num_ptr
		"mov r14, r10\n" // num_len

		// full = str_concat("L_", 2, num_ptr, num_len)
		"lea rdi, [rel .s_prefix]\n"
		"mov rsi, 2\n"
		"mov rdx, r13\n"
		"mov rcx, r14\n"
		"call str_concat\n" // rax=ptr, rdx=len
		"mov [rsp+56], rax\n"
		"mov [rsp+64], rdx\n"

		// out = heap_alloc(16)
		"mov rdi, 16\n"
		"call heap_alloc\n" // rax=out
		"mov rbx, rax\n"
		"mov r12, [rsp+56]\n"
		"mov [rbx+0], r12\n"
		"mov r12, [rsp+64]\n"
		"mov [rbx+8], r12\n"
		"mov rax, rbx\n"

		"add rsp, 80\n"
		"pop r14\n"
		"pop r13\n"
		"pop r12\n"
		"pop rbx\n"
		"jmp near .exit\n"
		".s_prefix: db 'L','_',0\n"
		".exit:\n"
	};
}
