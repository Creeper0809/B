// Phase 3.7 MVP: impl block + method call sugar
// x.f(y) <-> f(x, y)

struct S {
	a: u64;
};

impl S {
	func add(self: S, x: u64) -> u64 {
		return self.a + x;
	}
}

func main() {
	var s: S;
	s.a = 7;
	return s.add(5);
}
