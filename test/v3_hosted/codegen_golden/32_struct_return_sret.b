// Phase 3.1.1: struct return via sret (hidden out-pointer)

struct S {
	a: u64;
	b: u64;
};

func make(a: u64, b: u64) -> S {
	var s: S;
	s.a = a;
	s.b = b;
	return s;
}

func main() {
	var s = make(7, 11);
	return s.a + s.b;
}
