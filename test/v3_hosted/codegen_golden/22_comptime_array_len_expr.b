// Phase 5.1: comptime constant folding in array lengths

struct S {
	a: [10 + 5]u8;
	b: u8;
}

func main() -> u64 {
	return offsetof(S, b);
}
