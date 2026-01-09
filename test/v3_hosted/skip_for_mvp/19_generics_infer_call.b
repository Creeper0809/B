// Phase 5.1: infer type args at call sites.

func id<T>(x: T) -> T {
	return x;
}

func main() {
	var x = id(9);
	return x;
}
