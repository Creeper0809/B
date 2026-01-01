// v1 core: label_gen
// Roadmap: docs/roadmap.md (2.3)
// Planned:
// - global label_counter
// - label_next() -> Slice  ("L_1", "L_2", ...)

func label_next() {
	// Returns: rax = ptr to a heap-allocated Slice { ptr, len }
	// Label format: "L_<n>" (e.g. L_1)

	alias rax : tmp;
	alias r12 : cnt;
	alias r13 : num_ptr;
	alias r14 : num_len;
	alias r15 : prefix_ptr;
	alias rbx : addr;

	// cnt = ++label_counter
	cnt = ptr64[label_counter];
	cnt += 1;
	ptr64[label_counter] = cnt;

	// num = itoa_u64_dec(cnt)
	rdi = cnt;
	itoa_u64_dec(rdi);
	num_ptr = tmp;
	num_len = rdx;

	// prefix = "L_"
	slice_to_cstr("L_", 2);
	prefix_ptr = tmp;

	// full = str_concat(prefix, 2, num, num_len)
	rdi = prefix_ptr;
	rsi = 2;
	rdx = num_ptr;
	rcx = num_len;
	str_concat(rdi, rsi, rdx, rcx);

	// Preserve full string parts across heap_alloc.
	// Reuse num_ptr/num_len registers (r13/r14) now that the inputs are no longer needed.
	num_ptr = tmp;
	num_len = rdx;

	// Make a Slice struct on heap and return it.
	// Slice layout: ptr@+0, len@+8
	heap_alloc(16);
	addr = tmp;
	ptr64[addr] = num_ptr;
	addr += 8;
	ptr64[addr] = num_len;

	rax = tmp;
}
