// Generic test

struct Box<T> {
	value: *T;
	count: u64;
}

func main() -> u64 {
	var b: Box<u64>;
	return 42;
}
