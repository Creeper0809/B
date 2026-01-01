// v1 std (stage 0): failure paths and thin OS access.
//
// Note: Stage1 basm already injects runtime builtins for:
//   sys_exit/sys_write/sys_open/sys_read/sys_close/sys_fstat
// and printing helpers:
//   print_str/print_dec
//
// This file provides higher-level helpers needed by the bootstrap compiler.
//
// Declarations (`layout`/`const`/`var`) live in src/v1/prelude.b.

func panic() {
	// Convention: input message pointer is passed in rdi.
	alias r12 : msg;
	msg = rdi;

	print_str("panic: ");
	rdi = msg;
	print_str(rdi);
	print_str("\n");

	rdi = 1;
	sys_exit(1);
}

func panic_at() {
	// Convention: rdi=line (u64), rsi=msg (cstr)
	alias r12 : line;
	alias r13 : msg;

	line = rdi;
	msg = rsi;

	print_str("panic at line ");
	rdi = line;
	print_dec(rdi);
	print_str(": ");
	rdi = msg;
	print_str(rdi);
	print_str("\n");

	rdi = 1;
	sys_exit(1);
}

func die(msg) {
	// Convention: rdi=msg (cstr)
	asm {
		"call panic\n"
	};
}

func die_read_file_open_fail() {
	die("read_file: open failed");
}

func die_read_file_fstat_fail() {
	die("read_file: fstat failed");
}

func die_read_file_read_fail() {
	die("read_file: read failed");
}

func die_read_file_oom() {
	die("read_file: out of memory");
}

func die_emit_overflow() {
	die("emit: buffer overflow");
}

func die_emit_open_fail() {
	die("emit_to_file: open failed");
}

func die_emit_init_oom() {
	die("emit_init: out of memory");
}

func sys_brk(addr) {
	// API: sys_brk(addr) -> rax
	// Returns: rax = new program break
	// Linux x86_64 syscall: brk = 12
	//
	// Stage1 note:
	// - This implementation does not assume rdi is stable across any prologue.
	// - We immediately spill the incoming addr (passed via rdi) to a local slot
	//   and reload it right before the syscall.
	var addr0;
	ptr64[addr0] = rdi;
	rdi = ptr64[addr0];

	asm {
		"mov rax, 12\n"
		"syscall\n"
	};
}
