// Phase 5.1: value generics + const array length expr

struct Buf<N: u64> {
	data: [N + 3]u8;
	tag: u64;
}

func main() -> u64 {
	return offsetof(Buf<13>, tag);
}
