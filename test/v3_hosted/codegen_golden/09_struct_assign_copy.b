// Struct by-value init/assignment (local copy)

struct S {
	a: u64;
	b: u64;
};

func main() {
	var s: S;
	s.a = 1;
	s.b = 2;

	var t: S = s;
	t.a = t.a + 3;
	return t.a + t.b;
}
