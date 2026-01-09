// Phase 5.1: generic struct type instantiation (MVP builtin-only)

struct Vector<T> {
	data: *T;
	len: u64;
}

func main() -> u64 {
	return offsetof(Vector<u64>, len);
}
