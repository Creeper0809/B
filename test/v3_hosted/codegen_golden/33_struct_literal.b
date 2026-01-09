struct Pair {
	a: u64;
	b: u64;
}

func make_pair(x: u64, y: u64) -> Pair {
	return Pair{ a: x, b: y };
}

func main() {
	var p: Pair = Pair{ 1, 2 };
	p.a = 10;
	var q = make_pair(3, 4);
	return p.a + p.b + q.a + q.b;
}
