// Field access + assignment on stack-allocated struct

struct S {
	a: u64;
	b: u64;
};

func main() {
	var s: S;
	s.a = 3;
	s.b = 5;
	return s.a + s.b;
}
