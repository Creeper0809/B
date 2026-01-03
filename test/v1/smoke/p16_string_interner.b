// P16: StringInterner runtime smoke (library/v1)
// Validates:
// - intern returns stable ids
// - re-interning same bytes returns same id
// - id->(ptr,len) roundtrip

func main() {
	var si;
	var id1;
	var id2;
	var id3;
	var p;
	var n;

	alias rax : tmp;
	alias rbx : a;
	alias r12 : b;

	string_interner_new(8);
	ptr64[si] = rax;

	rdi = ptr64[si];
	string_interner_intern(rdi, "abc", 3);
	ptr64[id1] = rax;
	rdi = ptr64[si];
	string_interner_intern(rdi, "abc", 3);
	ptr64[id2] = rax;
	rdi = ptr64[si];
	string_interner_intern(rdi, "def", 3);
	ptr64[id3] = rax;

	// expect id1 == id2
	a = ptr64[id1];
	b = ptr64[id2];
	if (a != b) {
		sys_exit(1);
	}

	// expect id3 != id1
	a = ptr64[id3];
	b = ptr64[id1];
	if (a == b) {
		sys_exit(2);
	}

	// get(id1) => "abc"
	ptr64[p] = 0;
	ptr64[n] = 0;
	rdi = ptr64[si];
	rsi = ptr64[id1];
	string_interner_get(rdi, rsi);
	ptr64[p] = rax;
	ptr64[n] = rdx;

	tmp = ptr64[n];
	if (tmp != 3) {
		sys_exit(3);
	}

	a = ptr64[p];
	streq(a, "abc");
	if (tmp != 1) {
		sys_exit(4);
	}

	sys_exit(0);
}
