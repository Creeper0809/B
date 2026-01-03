// P18: StringBuilder runtime smoke

// Decls must appear before funcs in Stage1.

// Expect libc-like helpers exist in std1.

func main() {
	var sb;
	var p;

	// sb = sb_new(8)
	sb_new(8);
	ptr64[sb] = rax;

	// append "ab"
	rdi = ptr64[sb];
	sb_append_cstr(rdi, "ab");
	// append "cd"
	rdi = ptr64[sb];
	sb_append_cstr(rdi, "cd");
	// append number 12345
	rdi = ptr64[sb];
	rsi = 12345;
	sb_append_u64_dec(rdi, rsi);

	// ptr
	rdi = ptr64[sb];
	sb_ptr(rdi);
	ptr64[p] = rax;

	// should be "abcd12345"
	rdi = ptr64[p];
	streq(rdi, "abcd12345");
	if (rax == 0) {
		sys_exit(1);
	}

	// len should be 9
	rdi = ptr64[sb];
	sb_len(rdi);
	if (rax != 9) {
		sys_exit(2);
	}

	// clear, then should be empty
	rdi = ptr64[sb];
	sb_clear(rdi);
	rdi = ptr64[sb];
	sb_ptr(rdi);
	ptr64[p] = rax;
	rdi = ptr64[p];
	streq(rdi, "");
	if (rax == 0) {
		sys_exit(3);
	}

	sys_exit(0);
}
