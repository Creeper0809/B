func id<T>(x: T) -> T {
	return x;
}

func main() -> u64 {
	var a: u64 = 1;
	var b: u64 = 2;
	var c: bool = a < b;
	var y: u64 = id<u64>(10);
	if (c) { }
	return y;
}
