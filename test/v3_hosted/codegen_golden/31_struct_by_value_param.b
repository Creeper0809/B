// Phase 3.1.1: struct by-value parameter passing (stack ABI)

struct S {
	a: u64;
	b: u64;
};

func sum(s: S) -> u64 {
	// Mutate param; caller's struct must remain unchanged.
	s.a = 100;
	return s.a + s.b;
}

func main() {
	var s: S;
	s.a = 4;
	s.b = 5;
	var r = sum(s);
	return r + s.a;
}
